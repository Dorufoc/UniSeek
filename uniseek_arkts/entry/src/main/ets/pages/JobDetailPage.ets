/**
 * 职位详情页 — 双参数兼容，标准页面转场，统一 HMOS 视觉风格
 * 双参数兼容：新 {jobId} / 旧 {jobData, hideActions}
 */
import { ApiClient } from '../services/ApiClient';
import { JobData, TaskVO, mapTaskToJobData } from '../services/ChatTypes';
import { RecordService } from '../services/RecordService';
import { FavoriteService } from '../services/FavoriteService';
import { ChatService } from '../services/ChatService';
import { AuthService } from '../services/AuthService';
import { UserSession } from '../services/UserSession';
import { DataService } from '../services/DataService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { StandardCard } from '../common/StandardCard';
import { ErrorView } from '../components/ErrorView';

@Entry
@Component
struct JobDetailPage {
  @State job: JobData | null = null;
  @State taskVO: TaskVO | null = null;
  @State loading: boolean = true;
  @State error: string = '';
  @State hasApplied: boolean = false;
  @State hasFavorited: boolean = false;
  @State hideActions: boolean = false;
  private jobId: number = 0;
  private currentApplicationId: number = 0;

  // ===== 格式化工具 =====
  formatSalaryValue(val: number): string {
    if (val >= 10000) {
      const wan: number = val / 10000;
      return wan % 1 === 0 ? wan + '万' : wan.toFixed(1) + '万';
    }
    if (val >= 1000) {
      const k: number = val / 1000;
      return k % 1 === 0 ? k + 'K' : k.toFixed(1) + 'K';
    }
    return String(val);
  }

  salaryRangeText(min: number, max: number, unit: number): string {
    if (min === 0 && max === 0) return '面议';
    const suffixMap: Record<number, string> = { 0: '/日', 1: '/时', 2: '/月' };
    const suffix: string = suffixMap[unit] ?? '/月';
    if (min > 0 && max > 0) return this.formatSalaryValue(min) + '-' + this.formatSalaryValue(max) + suffix;
    if (min > 0) return '≥' + this.formatSalaryValue(min) + suffix;
    if (max > 0) return '≤' + this.formatSalaryValue(max) + suffix;
    return '';
  }

  jobTypeLabel(type: number): string {
    const m: Record<number, string> = { 1: '全职', 2: '兼职', 3: '实习' };
    return m[type] || '未分类';
  }

  statusLabel(status: number): string {
    const m: Record<number, string> = { 0: '待审核', 1: '招聘中', 2: '已满员', 3: '已过期', 4: '已下架' };
    return m[status] || '未知';
  }

  statusColor(status: number): ResourceColor {
    const m: Record<number, ResourceColor> = {
      0: AppColors.WARNING,
      1: AppColors.SUCCESS,
      2: AppColors.TEXT_MUTED,
      3: AppColors.DANGER,
      4: AppColors.TEXT_MUTED
    };
    return m[status] || AppColors.TEXT_MUTED;
  }

  formatDate(dateStr: string): string {
    return (dateStr || '未设置').replace('T', ' ').substring(0, 16);
  }

  // ===== 生命周期 =====
  aboutToAppear(): void {
    // this.getUIContext().getRouter().getParams() 转 Record<string, string> — 唯一允许的 as
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    // 模式1：新参数 { jobId: string }
    if (params['jobId'] !== undefined) {
      this.jobId = Number(params['jobId']);
      this.loadJobFromApi(this.jobId);
      return;
    }
    // 模式2：旧参数 { jobData: string (JSON), hideActions: string }
    if (params['jobData'] !== undefined) {
      // JSON.parse 在 ArkTS 中返回 Object，需类型转换
      const jobData: JobData = JSON.parse(params['jobData']) as JobData;
      this.job = jobData;
      this.jobId = Number(jobData.id);
      this.hasApplied = jobData.hasApplied || false;
      this.hasFavorited = jobData.hasFavorited || false;
      this.hideActions = params['hideActions'] === 'true';
      RecordService.addViewedJob(jobData);
      this.loading = false;
      this.loadJobFromApi(this.jobId); // 后台异步刷新
      return;
    }
    this.error = '无效的职位ID';
    this.loading = false;
  }

  // ===== 数据加载 =====
  async loadJobFromApi(id: number): Promise<void> {
    try {
      const full: TaskVO = await ApiClient.getTaskById(id);
      this.taskVO = full;
      this.job = mapTaskToJobData(full);
      this.hasApplied = full.hasApplied;
      this.hasFavorited = full.hasFavorited;
      RecordService.addViewedJob(this.job);
    } catch (e) {
      if (this.job === null) this.error = '加载失败，请检查网络或登录状态';
    } finally {
      this.loading = false;
    }
  }

  // ===== 交互 =====
  async handleApply(): Promise<void> {
    this.error = '';
    if (!ApiClient.hasToken()) { this.getUIContext().getRouter().pushUrl({ url: 'pages/LoginPage' }); return; }
    if (UserSession.role !== 0) { this.error = '仅求职者可投递简历'; return; }
    if (this.hasApplied) { this.error = '您已投递过该职位'; return; }
    try {
      const rn = await AuthService.getRealNameStatus();
      if (rn.status !== 1) {
        AlertDialog.show({
          title: '实名认证提示',
          message: '投递职位前需要先完成实名认证，是否前往认证？',
          primaryButton: { value: '前往认证', action: (): void => { this.getUIContext().getRouter().pushUrl({ url: 'pages/RealNameAuthPage' }); } },
          cancel: (): void => {}
        });
        return;
      }
    } catch { /* 忽略，继续投递 */ }
    try {
      const app = await ChatService.createApplication(this.jobId);
      this.hasApplied = true;
      if (app && app.id) this.currentApplicationId = app.id;
      this.loadJobFromApi(this.jobId);
    } catch (e) { this.error = (e as Record<string, string>)?.message || '投递失败，请稍后重试'; }
  }

  async handleContactHr(): Promise<void> {
    this.error = '';
    if (!ApiClient.hasToken()) { this.getUIContext().getRouter().pushUrl({ url: 'pages/LoginPage' }); return; }
    if (UserSession.role !== 0) { this.error = '仅求职者可联系HR'; return; }
    if (!this.hasApplied) {
      try {
        const app = await ChatService.createApplication(this.jobId);
        this.hasApplied = true;
        if (app && app.id) this.currentApplicationId = app.id;
      } catch (e) { this.error = (e as Record<string, string>)?.message || '自动投递失败'; return; }
    }
    const appId: number = this.currentApplicationId || (this.job ? this.job.applicationId : 0) || 0;
    if (appId > 0) {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/ChatDetailPage',
        params: {
          applicationId: appId,
          counterpartName: (this.job ? this.job.hrName : '') || '招聘方',
          counterpartAvatar: (this.job ? this.job.hrAvatar : '') || ''
        }
      });
    } else {
      this.error = '未找到会话信息，请从消息列表进入';
    }
  }

  async handleToggleFavorite(): Promise<void> {
    this.error = '';
    if (!ApiClient.hasToken()) { this.getUIContext().getRouter().pushUrl({ url: 'pages/LoginPage' }); return; }
    const newFav: boolean = !this.hasFavorited;
    this.hasFavorited = newFav;
    try {
      if (newFav) await FavoriteService.addFavorite(this.jobId);
      else await FavoriteService.removeFavorite(this.jobId);
    } catch { this.hasFavorited = !this.hasFavorited; }
  }

  // ===== 底部按钮辅助 =====
  getMainButtonText(): string {
    if (!ApiClient.hasToken()) return '登录后投递';
    if (UserSession.role !== 0) return '仅限求职者';
    if (this.job !== null && this.job.status !== 1) return this.statusLabel(this.job.status);
    if (this.hasApplied) return '继续沟通';
    return '立即投递';
  }

  getMainButtonBg(): ResourceColor {
    if (this.hasApplied) return AppColors.SUCCESS;
    if (!ApiClient.hasToken() || UserSession.role !== 0) return AppColors.DISABLED;
    if (this.job !== null && this.job.status !== 1) return AppColors.DISABLED;
    return AppColors.PRIMARY;
  }

  isMainButtonEnabled(): boolean {
    if (!ApiClient.hasToken()) return true;
    if (UserSession.role !== 0) return false;
    if (this.job !== null && this.job.status !== 1) return false;
    return true;
  }

  // 将描述按段落拆分，过滤空行
  private getDescriptionParagraphs(): string[] {
    if (!this.job || !this.job.description || this.job.description.length === 0) {
      return [];
    }
    return this.job.description.split('\n').filter((s: string): boolean => s.trim().length > 0);
  }

  // ===== UI 构建 =====
  build() {
    Column() {
      NavBar({ title: '职位详情', showBack: true, onBack: (): void => this.getUIContext().getRouter().back() });

      // 加载中
      if (this.loading) {
        Column() {
          LoadingProgress().width(AppSpacing.BUTTON_HEIGHT).height(AppSpacing.BUTTON_HEIGHT).color(AppColors.PRIMARY);
          Text('加载中...').fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_MUTED).margin({ top: AppSpacing.MD });
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      }
      // 错误（无本地数据）
      else if (this.error !== '' && this.job === null) {
        Column() {
          ErrorView({
            message: this.error,
            retryText: this.jobId > 0 ? '重新加载' : '返回',
            onRetry: () => {
              if (this.jobId > 0) {
                this.loadJobFromApi(this.jobId);
              } else {
                this.getUIContext().getRouter().back();
              }
            }
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(AppSpacing.MD);
      }
      // 内容
      else if (this.job !== null) {
        Scroll() {
          Column({ space: AppSpacing.MD }) {
            // 内联错误提示（非阻断性，由交互操作触发）
            if (this.error !== '') {
              this.ErrorTipBuilder();
            }

            this.heroBuilder();
            this.hrCardBuilder();
            this.descriptionBuilder();
            this.companyCardBuilder();

            // 为底部固定操作栏留出空间
            if (!this.hideActions) {
              Column().width('100%').height(AppSpacing.FOOTER_SPACER);
            }
          }
          .width('100%')
          .padding(AppSpacing.MD);
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(AppColors.BG_PAGE);

        // 底部操作栏
        if (!this.hideActions) {
          this.bottomBarBuilder();
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .alignItems(HorizontalAlign.Center);
  }

  // ===== 子组件构建辅助 =====

  // 顶部职位信息区：标题 + 状态、薪资、关键信息胶囊
  @Builder
  heroBuilder() {
    StandardCard() {
      Column({ space: AppSpacing.SM }) {
        Row() {
          Text(this.job!.title)
            .fontSize(AppFontSize.LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1);
          this.statusPillBuilder(this.job!.status);
        }
        .width('100%')
        .alignItems(VerticalAlign.Top);

        Text(this.salaryRangeText(this.job!.salaryMin, this.job!.salaryMax, this.job!.salaryUnit))
          .fontSize(AppFontSize.XXL)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.DANGER);

        // 关键信息胶囊
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          this.infoChipBuilder(this.jobTypeLabel(this.job!.jobType));
          this.infoChipBuilder(DataService.getRegionFullPath(this.job!.region) ?? this.job!.region);
          this.infoChipBuilder('截止 ' + this.formatDate(this.job!.deadline));
          this.infoChipBuilder('剩余 ' + String(this.job!.remainingQuota) + ' 个名额');
        }
        .width('100%');
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    }
  }

  @Builder
  statusPillBuilder(status: number) {
    Text(this.statusLabel(status))
      .fontSize(AppFontSize.XS)
      .fontColor(this.statusColor(status))
      .backgroundColor(status === 1 ? AppColors.SUCCESS_BG : AppColors.INPUT_BG)
      .borderRadius(AppRadius.PILL)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
      .margin({ left: AppSpacing.SM });
  }

  @Builder
  infoChipBuilder(label: string) {
    Text(label)
      .fontSize(AppFontSize.XS)
      .fontColor(AppColors.PRIMARY)
      .backgroundColor(AppColors.SELECTED_BG)
      .borderRadius(AppRadius.LG)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
      .margin({ right: AppSpacing.SM, bottom: AppSpacing.XS });
  }

  // HR 联系卡片
  @Builder
  hrCardBuilder() {
    StandardCard({
      onClickAction: () => {
        this.handleContactHr();
      },
      accessibilityLabel: '联系招聘HR'
    }) {
      Row() {
        this.avatarBuilder(this.job!.hrName || 'HR', AppSpacing.ICON_XL);
        Column({ space: AppSpacing.XS }) {
          Text(this.job!.hrName || '招聘方')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY);
          Text('招聘HR')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED);
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: AppSpacing.SM });

        this.chevronRightBuilder();
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
  }

  @Builder
  avatarBuilder(name: string, size: number) {
    if (this.job && this.job.hrAvatar && this.job.hrAvatar.length > 0) {
      Image(this.job.hrAvatar)
        .width(size)
        .height(size)
        .borderRadius(AppRadius.FULL)
        .objectFit(ImageFit.Cover);
    } else {
      Stack() {
        Text(this.getInitials(name))
          .fontSize(size * 0.4)
          .fontColor(AppColors.BG_CARD)
          .fontWeight(FontWeight.Bold);
      }
      .width(size)
      .height(size)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(AppColors.PRIMARY);
    }
  }

  getInitials(name: string): string {
    const safeName: string = name || 'HR';
    return safeName.charAt(0);
  }

  @Builder
  chevronRightBuilder() {
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(AppFontSize.MD)
      .fontColor([AppColors.TEXT_MUTED]);
  }

  // 职位描述区
  @Builder
  descriptionBuilder() {
    StandardCard() {
      Column({ space: AppSpacing.SM }) {
        this.SectionHeader('职位描述', $r('sys.symbol.doc_text'));

        if (this.job && this.job.description && this.job.description.length > 0) {
          ForEach(
            this.getDescriptionParagraphs(),
            (item: string): void => {
              Text(item)
                .fontSize(AppFontSize.SM)
                .fontColor(AppColors.TEXT_PRIMARY)
                .width('100%')
                .lineHeight(22);
            },
            (item: string, index: number): string => String(index)
          );
        } else {
          Text('暂无详细描述')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED);
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    }
  }

  // 公司信息卡片
  @Builder
  companyCardBuilder() {
    StandardCard({
      onClickAction: () => {
        if (this.job && this.job.enterpriseId > 0) {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/CompanyDetailPage',
            params: { enterpriseId: this.job.enterpriseId }
          });
        }
      },
      accessibilityLabel: '查看公司详情'
    }) {
      Column({ space: AppSpacing.SM }) {
        Row() {
          this.companyLogoBuilder();
          Column({ space: AppSpacing.XS }) {
            Text(this.job!.enterpriseName || this.job!.company || '未知企业')
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%');

            Row() {
              this.statCellBuilder(String(this.job!.applicationCount || 0), '投递人数');
              this.statCellBuilder(String(this.job!.totalQuota || 0), '招聘名额');
              this.statCellBuilder(String(this.job!.remainingQuota ?? 0), '剩余名额');
            }
            .width('100%');
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: AppSpacing.SM });

          this.chevronRightBuilder();
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        if (this.job!.address && this.job!.address.length > 0) {
          Text(this.job!.address)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.TEXT_MUTED)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    }
  }

  @Builder
  companyLogoBuilder() {
    Stack() {
      Text(this.getInitials(this.job!.enterpriseName || this.job!.company || '企'))
        .fontSize(AppFontSize.ICON_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.BG_CARD);
    }
    .width(AppSpacing.ICON_LG)
    .height(AppSpacing.ICON_LG)
    .borderRadius(AppRadius.MD)
    .backgroundColor(AppColors.PRIMARY);
  }

  @Builder
  statCellBuilder(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(AppFontSize.SM)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY);
      Text(label)
        .fontSize(AppFontSize.XXS)
        .fontColor(AppColors.TEXT_MUTED)
        .margin({ top: AppSpacing.XXS });
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center);
  }

  // 底部固定操作栏
  @Builder
  bottomBarBuilder() {
    Row() {
      // 收藏
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.star'))
          .fontSize(AppFontSize.LG)
          .fontColor([this.hasFavorited ? AppColors.BG_CARD : AppColors.TEXT_PRIMARY]);
      }
      .width(AppSpacing.ICON_LG)
      .height(AppSpacing.ICON_LG)
      .backgroundColor(this.hasFavorited ? AppColors.WARNING : AppColors.BG_CARD)
      .border({
        width: this.hasFavorited ? 0 : 1,
        color: this.hasFavorited ? AppColors.WARNING : AppColors.BORDER
      })
      .accessibilityText(this.hasFavorited ? '取消收藏职位' : '收藏职位')
      .onClick((): void => {
        this.handleToggleFavorite();
      });

      // 主操作
      Button(this.getMainButtonText(), { type: ButtonType.Capsule })
        .layoutWeight(1)
        .height(AppSpacing.BUTTON_HEIGHT_MD)
        .backgroundColor(this.getMainButtonBg())
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .enabled(this.isMainButtonEnabled())
        .margin({ left: AppSpacing.SM, right: AppSpacing.SM })
        .onClick((): void => {
          const btnText: string = this.getMainButtonText();
          if (btnText === '继续沟通') {
            const appId: number = this.currentApplicationId || this.job!.applicationId || 0;
            if (appId > 0) {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/ChatDetailPage',
                params: {
                  applicationId: appId,
                  counterpartName: this.job!.hrName || '招聘方',
                  counterpartAvatar: this.job!.hrAvatar || ''
                }
              });
            } else {
              this.error = '未找到会话信息，请从消息列表进入';
            }
            return;
          }
          if (!ApiClient.hasToken()) {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/LoginPage' });
            return;
          }
          this.handleApply();
        });

      // 联系 HR
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.message'))
          .fontSize(AppFontSize.LG)
          .fontColor([AppColors.BG_CARD]);
      }
      .width(AppSpacing.ICON_LG)
      .height(AppSpacing.ICON_LG)
      .backgroundColor(AppColors.PRIMARY)
      .accessibilityText('联系招聘方')
      .onClick((): void => {
        this.handleContactHr();
      });
    }
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.LG })
    .backgroundColor(AppColors.BG_CARD)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  ErrorTipBuilder() {
    Row() {
      SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
        .fontSize(AppFontSize.SM)
        .fontColor([AppColors.DANGER])
        .margin({ right: AppSpacing.XS });
      Text(this.error)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.DANGER)
        .layoutWeight(1);
    }
    .width('100%')
    .padding(AppSpacing.SM)
    .backgroundColor(AppColors.ERROR_BG)
    .borderRadius(AppRadius.MD)
    .alignItems(VerticalAlign.Center);
  }

  // 统一区块标题（带系统图标）
  @Builder
  SectionHeader(title: string, icon?: Resource) {
    Row() {
      if (icon) {
        SymbolGlyph(icon)
          .fontSize(AppFontSize.MD)
          .fontColor([AppColors.PRIMARY])
          .margin({ right: AppSpacing.XS });
      }
      Text(title)
        .fontSize(AppFontSize.MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY);
    }
    .width('100%')
    .alignItems(VerticalAlign.Center);
  }

  // ===== 页面转场 =====
  // 不再自定义 pageTransition，统一使用系统原生页面切换动画，避免与系统动画叠加产生两层效果。
}
