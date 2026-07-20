/**
 * 职位详情页 — 双参数兼容，标准页面转场
 * 双参数兼容：新 {jobId} / 旧 {jobData, hideActions}
 */
import { router } from '@kit.ArkUI';
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

  statusColor(status: number): string {
    const m: Record<number, string> = { 0: '#f39c12', 1: '#27ae60', 2: '#7f8c8d', 3: '#e74c3c', 4: '#95a5a6' };
    return m[status] || '#7f8c8d';
  }

  formatDate(dateStr: string): string {
    return (dateStr || '未设置').replace('T', ' ').substring(0, 16);
  }

  // ===== 生命周期 =====
  aboutToAppear(): void {
    // router.getParams() 转 Record<string, string> — 唯一允许的 as
    const params = router.getParams() as Record<string, string>;
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
    if (!ApiClient.hasToken()) { router.pushUrl({ url: 'pages/LoginPage' }); return; }
    if (UserSession.role !== 0) { this.error = '仅求职者可投递简历'; return; }
    if (this.hasApplied) { this.error = '您已投递过该职位'; return; }
    try {
      const rn = await AuthService.getRealNameStatus();
      if (rn.status !== 1) {
        AlertDialog.show({
          title: '实名认证提示',
          message: '投递职位前需要先完成实名认证，是否前往认证？',
          primaryButton: { value: '前往认证', action: (): void => { router.pushUrl({ url: 'pages/ProfilePage', params: { tab: 'realNameAuth' } }); } },
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
    if (!ApiClient.hasToken()) { router.pushUrl({ url: 'pages/LoginPage' }); return; }
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
      router.pushUrl({
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
    if (!ApiClient.hasToken()) { router.pushUrl({ url: 'pages/LoginPage' }); return; }
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

  getMainButtonBg(): string {
    if (this.hasApplied) return AppColors.SUCCESS;
    if (!ApiClient.hasToken() || UserSession.role !== 0) return '#bdc3c7';
    if (this.job !== null && this.job.status !== 1) return '#bdc3c7';
    return AppColors.PRIMARY;
  }

  isMainButtonEnabled(): boolean {
    if (!ApiClient.hasToken()) return true;
    if (UserSession.role !== 0) return false;
    if (this.job !== null && this.job.status !== 1) return false;
    return true;
  }

  // ===== UI 构建 =====
  build() {
    Column() {
      NavBar({ title: '职位详情', showBack: true, onBack: (): void => router.back() });

      // 加载中
      if (this.loading) {
        Column() {
          LoadingProgress().width(40).height(40).color(AppColors.PRIMARY);
          Text('加载中...').fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_MUTED).margin({ top: AppSpacing.MD });
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
      }
      // 错误（无本地数据）
      else if (this.error !== '' && this.job === null) {
        Column() {
          Text(this.error).fontSize(AppFontSize.SM).fontColor(AppColors.DANGER).padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
            .backgroundColor(AppColors.ERROR_BG).borderRadius(AppRadius.MD).margin({ left: AppSpacing.MD, right: AppSpacing.MD });
          Button('返回').margin({ top: AppSpacing.LG }).onClick((): void => router.back());
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
      }
      // 内容
      else if (this.job !== null) {
        Scroll() {
          Column() {
            // 内联错误提示（非阻断性，由交互操作触发）
            if (this.error !== '') {
              Text(this.error).fontSize(AppFontSize.SM).fontColor(AppColors.DANGER).width('100%')
                .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.SM, bottom: AppSpacing.SM })
                .backgroundColor(AppColors.ERROR_BG).borderRadius(AppRadius.MD).margin({ bottom: AppSpacing.SM });
            }

            // === 区块1：职位名称 ===
            Column() {
              Row() {
                Text(this.job.title).fontSize(AppFontSize.XXXL).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1).lineHeight(40);
                Text(this.salaryRangeText(this.job.salaryMin, this.job.salaryMax, this.job.salaryUnit))
                  .fontSize(AppFontSize.XXL).fontWeight(FontWeight.Bold).fontColor('#e74c3c');
              }.width('100%').alignItems(VerticalAlign.Top);
              Divider().height(1).color(AppColors.BORDER).margin({ top: AppSpacing.MD });
            }.width('100%').margin({ bottom: AppSpacing.LG });

            // === 区块2：地点 + 技能标签（同行，自动换行） ===
            Flex({ wrap: FlexWrap.Wrap }) {
              // 地点标签（完整省市区县）
              this.chip(
                DataService.getRegionFullPath(this.job.region) ?? this.job.region,
                AppColors.PRIMARY, AppColors.SELECTED_BG
              )
              // 技能标签
              if (this.job.tag && this.job.tag.length > 0) {
                ForEach(this.job.tag, (tag: string): void => {
                  Text(tag).fontSize(AppFontSize.XS).fontColor(AppColors.PRIMARY).backgroundColor('#0F1762FB')
                    .border({ width: 1, color: 'rgba(23, 98, 251, 0.15)' }).borderRadius(AppRadius.LG)
                    .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS }).margin({ right: AppSpacing.SM, bottom: AppSpacing.XS });
                }, (tag: string): string => tag);
              }
            }.width('100%').margin({ bottom: AppSpacing.LG });

            // === 区块3：HR信息 ===
            Column() {
              Row() {
                if (this.job.hrAvatar && this.job.hrAvatar.length > 0) {
                  Image(this.job.hrAvatar).width(48).height(48).borderRadius(AppRadius.FULL).margin({ right: 12 });
                } else {
                  Stack() { Text('HR').fontSize(AppFontSize.SM).fontColor('#FFFFFF'); }
                    .width(48).height(48).borderRadius(AppRadius.FULL).backgroundColor(AppColors.PRIMARY).margin({ right: 12 });
                }
                Column() {
                  Text('招聘HR').fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED);
                  Text(this.job.hrName || '招聘方').fontSize(AppFontSize.MD).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY).margin({ top: AppSpacing.XS });
                }.alignItems(HorizontalAlign.Start);
              }.width('100%');
            }.width('100%').padding(AppSpacing.LG).backgroundColor(AppColors.BG_CARD).borderRadius(AppRadius.LG).margin({ bottom: AppSpacing.LG });

            // === 区块4：职位简介 ===
            Column() {
              Text('职位描述').fontSize(AppFontSize.LG).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY).margin({ bottom: AppSpacing.SM });
              if (this.job.description && this.job.description.length > 0) {
                ForEach(
                  this.job.description.split('\n').filter((s: string): boolean => s.trim().length > 0),
                  (item: string): void => { Text(item).fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_PRIMARY).width('100%').lineHeight(24).margin({ bottom: AppSpacing.SM }); },
                  (item: string): string => item
                );
              } else {
                Text('暂无详细描述').fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_MUTED);
              }
            }.width('100%').padding(AppSpacing.LG).backgroundColor(AppColors.BG_CARD).borderRadius(AppRadius.LG).margin({ bottom: AppSpacing.LG });

            // === 区块5：公司信息 ===
            Column() {
              // 公司名
              Text(this.job.enterpriseName || this.job.company || '未知企业').fontSize(AppFontSize.LG).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY).width('100%');

              // 企业头像 + 统计数据 横向排布
              Row() {
                Stack() {
                  Text((this.job.enterpriseName || this.job.company || '企').charAt(0)).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFF');
                }.width(52).height(52).borderRadius(AppRadius.MD)
                  .linearGradient({ direction: GradientDirection.Bottom, colors: [['#1762FB', 0.0], ['#5856d6', 1.0]] }).margin({ right: AppSpacing.MD });

                Column() {
                  Row() {
                    this.statCell(String(this.job.applicationCount || 0), '投递人数');
                    this.statCell(String(this.job.totalQuota || 0), '招聘名额');
                    this.statCell(String(this.job.remainingQuota ?? 0), '剩余名额');
                  }.width('100%');
                }.layoutWeight(1);
              }.width('100%').margin({ top: AppSpacing.MD ,bottom: AppSpacing.MD});

              // 信息网格
              this.infoRow('工作类型', this.jobTypeLabel(this.job.jobType), '薪资', this.salaryRangeText(this.job.salaryMin, this.job.salaryMax, this.job.salaryUnit));
              this.infoRow('工作地点', this.job.address || '未填写', '截止时间', this.formatDate(this.job.deadline));
            }
            .width('100%').padding(AppSpacing.LG).backgroundColor(AppColors.BG_CARD).borderRadius(AppRadius.LG).margin({ bottom: AppSpacing.LG });

            if (!this.hideActions) Column().height(88).width('100%');
          }.padding(AppSpacing.MD).width('100%');
        }
        .layoutWeight(1).width('100%').backgroundColor(AppColors.BG_PAGE);

        // === 底部操作栏 ===
        if (!this.hideActions) {
          Row() {
            // 收藏 — 图标按钮
            Button() {
              SymbolGlyph($r('sys.symbol.star')).fontSize(20).fontColor([this.hasFavorited ? '#e67e22' : AppColors.TEXT_PRIMARY]);
            }
            .width(52).height(52).backgroundColor(this.hasFavorited ? '#fef3e7' : AppColors.BG_CARD)
            .border({ width: 1, color: this.hasFavorited ? '#e67e22' : AppColors.BORDER }).borderRadius(AppRadius.LG).margin({ right: AppSpacing.SM })
            .onClick((): void => { this.handleToggleFavorite(); });

            // 主按钮 — 文字按钮（立即投递 / 继续沟通 / etc）
            Button() { Text(this.getMainButtonText()).fontSize(AppFontSize.MD).fontWeight(FontWeight.Bold).fontColor('#FFFFFF'); }
              .layoutWeight(1).height(52).backgroundColor(this.getMainButtonBg()).borderRadius(AppRadius.LG).margin({ right: AppSpacing.SM })
              .enabled(this.isMainButtonEnabled())
              .onClick((): void => {
                const btnText: string = this.getMainButtonText();
                if (btnText === '继续沟通') {
                  const appId: number = this.currentApplicationId || this.job!.applicationId || 0;
                  if (appId > 0) {
                    router.pushUrl({ url: 'pages/ChatDetailPage', params: { applicationId: appId, counterpartName: this.job!.hrName || '招聘方', counterpartAvatar: this.job!.hrAvatar || '' } });
                  } else { this.error = '未找到会话信息，请从消息列表进入'; }
                  return;
                }
                if (!ApiClient.hasToken()) { router.pushUrl({ url: 'pages/LoginPage' }); return; }
                this.handleApply();
              });

            // 联系HR — 图标按钮
            Button() {
              SymbolGlyph($r('sys.symbol.message')).fontSize(20).fontColor([AppColors.PRIMARY]);
            }
            .width(52).height(52).backgroundColor(AppColors.BG_CARD).borderRadius(AppRadius.LG).border({ width: 1, color: AppColors.PRIMARY })
            .onClick((): void => { this.handleContactHr(); });
          }
          .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.LG })
          .backgroundColor(AppColors.BG_CARD);
        }
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BG_PAGE).alignItems(HorizontalAlign.Center);
  }

  // ===== 子组件构建辅助 =====
  @Builder chip(label: string, textColor: string, bgColor: string) {
    Text(label).fontSize(AppFontSize.XS).fontColor(textColor).backgroundColor(bgColor)
      .border({ width: 1, color: 'rgba(0, 0, 0, 0.06)' }).borderRadius(AppRadius.LG)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS });
  }

  @Builder statCell(value: string, label: string) {
    Column() {
      Text(value).fontSize(AppFontSize.XL).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY);
      Text(label).fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED).margin({ top: AppSpacing.XS });
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center);
  }

  @Builder infoRow(label1: string, value1: string, label2: string, value2: string) {
    Row() {
      Column() {
        Text(label1).fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED);
        Text(value1).fontSize(AppFontSize.MD).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY).margin({ top: AppSpacing.XS });
      }.layoutWeight(1).alignItems(HorizontalAlign.Start);
      Column() {
        Text(label2).fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_MUTED);
        Text(value2).fontSize(AppFontSize.MD).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY).margin({ top: AppSpacing.XS });
      }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: AppSpacing.LG });
    }.width('100%').margin({ bottom: AppSpacing.MD });
  }

  // ===== 页面转场 =====
  pageTransition() {
    PageTransitionEnter({ duration: 300 }).slide(SlideEffect.Right);
    PageTransitionExit({ duration: 300 }).slide(SlideEffect.Right);
  }
}
