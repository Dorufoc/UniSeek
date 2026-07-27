import { RecruiterService } from '../services/RecruiterService';
import { ChatService } from '../services/ChatService';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import {
  RecruiterJobVO,
  RecruiterEnterpriseRequest,
  RecruiterEnterpriseVO,
  JOB_STATUS_LABELS,
  JOB_TYPE_LABELS,
  SALARY_UNIT_LABELS,
  AUDIT_STATUS_LABELS
} from '../services/RecruiterTypes';
import { CategoryNode, DataService, RegionNode } from '../services/DataService';
import { AppColors, AppSpacing, AppRadius, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { StandardCard } from '../common/StandardCard';
import { ErrorView } from '../components/ErrorView';
import { EmptyView } from '../components/EmptyView';
import { SelectorSheet, SelectorOption } from '../components/filter/SelectorSheet';
import { SelectorField } from '../components/filter/SelectorField';
import { UploadPolicy } from '../common/FormValidators';
import { LicenseUploader } from '../components/enterprise/LicenseUploader';

@Entry
@Component
struct RecruiterPublishJobPage {
  @State jobList: RecruiterJobVO[] = []
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State auditErrorText: string = ''
  @State auditStatus: number = -1
  @State enterpriseInfo: RecruiterEnterpriseVO | null = null
  @State companyName: string = ''
  @State creditCode: string = ''
  @State industry: string = ''
  @State regionId: number = 0
  @State regionName: string = ''
  @State description: string = ''
  @State licenseImgUrl: string = ''
  @State licenseFileName: string = ''
  @State industryOptions: SelectorOption[] = []
  @State regionOptions: SelectorOption[] = []
  @State showIndustrySheet: boolean = false
  @State showRegionSheet: boolean = false
  @State showEnterpriseForm: boolean = false
  @State uploadingLicense: boolean = false
  @State savingEnterprise: boolean = false

  aboutToAppear(): void {
    this.loadJobs()
    this.loadAuditStatus()
    this.loadEnterpriseInfo()
    this.loadEnterpriseOptions()
  }

  onPageShow(): void {
    this.loadJobs()
    this.loadAuditStatus()
    this.loadEnterpriseInfo()
  }

  loadAuditStatus(): void {
    this.auditErrorText = ''
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info) {
        this.auditStatus = info.auditStatus
      }
    }).catch(() => {
      this.auditErrorText = '企业资质状态加载失败'
    })
  }

  loadEnterpriseInfo(): void {
    RecruiterService.getEnterpriseInfo().then((info: RecruiterEnterpriseVO | null) => {
      this.enterpriseInfo = info
      if (!info) {
        this.auditStatus = -1
        return
      }
      this.auditStatus = info.auditStatus
      this.companyName = info.companyName || ''
      this.creditCode = info.creditCode || ''
      this.industry = info.industry || ''
      this.regionId = info.regionId || 0
      this.regionName = info.regionName || ''
      this.description = info.description || ''
      this.licenseImgUrl = info.licenseImgUrl || ''
      this.licenseFileName = this.licenseImgUrl.split('/').pop() || ''
    }).catch(() => {
      this.auditErrorText = '企业资质信息加载失败'
    })
  }

  async loadEnterpriseOptions(): Promise<void> {
    try {
      const categories: CategoryNode[] = await DataService.getCategoryTree()
      const regions: RegionNode[] = await DataService.getRegionTree()
      this.industryOptions = this.flattenIndustries(categories, '')
      this.regionOptions = this.flattenRegions(regions, '')
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: '企业选项加载失败，请稍后重试' })
    }
  }

  flattenIndustries(nodes: CategoryNode[], prefix: string): SelectorOption[] {
    const result: SelectorOption[] = []
    for (const node of nodes) {
      const label: string = prefix ? prefix + ' / ' + node.name : node.name
      if (node.children.length === 0) {
        result.push({ id: label, label: label })
      } else {
        result.push(...this.flattenIndustries(node.children, label))
      }
    }
    return result
  }

  flattenRegions(nodes: RegionNode[], prefix: string): SelectorOption[] {
    const result: SelectorOption[] = []
    for (const node of nodes) {
      const label: string = prefix ? prefix + ' / ' + node.name : node.name
      result.push({ id: node.id, label: label })
      if (node.children.length > 0) {
        result.push(...this.flattenRegions(node.children, label))
      }
    }
    return result
  }

  selectEnterpriseRegion(option: SelectorOption): void {
    this.regionId = Number(option.id)
    this.regionName = option.label
    this.showRegionSheet = false
  }

  selectEnterpriseIndustry(option: SelectorOption): void {
    this.industry = option.label
    this.showIndustrySheet = false
  }

  selectLicenseFile(): void {
    const picker = new photoAccessHelper.PhotoViewPicker()
    picker.select({ MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1 }).then((result: photoAccessHelper.PhotoSelectResult) => {
      if (!result.photoUris || result.photoUris.length === 0) return
      const uri: string = result.photoUris[0]
      const fileName: string = uri.split('/').pop() || '营业执照'
      try {
        const stat = fileIo.statSync(uri)
        const message: string = UploadPolicy.validateLicense(fileName, Number(stat.size))
        if (message) {
          this.getUIContext().getPromptAction().showToast({ message: message })
          return
        }
      } catch {
        this.getUIContext().getPromptAction().showToast({ message: '无法读取营业执照文件' })
        return
      }
      this.uploadingLicense = true
      ChatService.uploadImage(uri).then((url: string) => {
        this.licenseImgUrl = url
        this.licenseFileName = fileName
        this.getUIContext().getPromptAction().showToast({ message: '营业执照上传成功' })
      }).catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '营业执照上传失败，请重试' })
      }).finally(() => { this.uploadingLicense = false })
    }).catch(() => {})
  }

  submitEnterprise(): void {
    const code: string = this.creditCode.trim()
    if (!this.companyName.trim() || !code || !this.licenseImgUrl || !this.industry.trim() || this.regionId <= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请完整填写企业名称、信用代码、营业执照、行业和地区' })
      return
    }
    if (!/^[0-9A-HJ-NPQRTUWXY]{18}$/i.test(code)) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入正确的18位统一社会信用代码' })
      return
    }
    const data: RecruiterEnterpriseRequest = {
      companyName: this.companyName.trim(),
      creditCode: code.toUpperCase(),
      licenseImgUrl: this.licenseImgUrl,
      industry: this.industry.trim(),
      regionId: this.regionId,
      description: this.description.trim()
    }
    this.savingEnterprise = true
    RecruiterService.saveEnterpriseInfo(data, this.enterpriseInfo !== null).then((success: boolean) => {
      if (success) {
        this.getUIContext().getPromptAction().showToast({ message: '企业资料已提交审核' })
        this.loadEnterpriseInfo()
      } else {
        this.getUIContext().getPromptAction().showToast({ message: '企业资料提交失败，请重试' })
      }
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '企业资料提交失败，请重试' })
    }).finally(() => { this.savingEnterprise = false })
  }

  loadJobs(): void {
    this.isLoading = true
    this.errorText = ''
    RecruiterService.getMyJobs().then((list: RecruiterJobVO[]) => {
      this.jobList = list
      this.isLoading = false
    }).catch(() => {
      this.jobList = []
      this.isLoading = false
      this.errorText = '职位列表加载失败，请检查网络后重试'
    })
  }

  build() {
    Column() {
      NavBar({
        title: '发布职位',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(AppSpacing.ICON_MD)
            .height(AppSpacing.ICON_MD)
            .color(AppColors.PRIMARY)
          Text('正在加载职位')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorText) {
        ErrorView({
          message: this.errorText,
          retryText: '重新加载',
          onRetry: () => { this.loadJobs() }
        })
          .width('100%')
          .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            this.auditStatusContent()
            if (this.auditStatus !== 1) {
              this.enterpriseFormContent()
            } else {
              this.enterpriseSummaryContent()
            }

            Button({ type: ButtonType.Capsule }) {
              Text('发布新职位')
                .fontSize(AppFontSize.MD)
                .fontColor('#FFFFFF')
            }
              .width('100%')
              .height(AppSpacing.INPUT_HEIGHT)
              .backgroundColor(this.auditStatus === 1 ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
              .margin({ top: AppSpacing.SM })
              .enabled(this.auditStatus === 1)
              .onClick(() => {
                if (this.auditStatus !== 1) {
                  this.getUIContext().showAlertDialog({ message: '企业资质审核未通过，暂无法发布职位', confirm: { value: '确定', action: () => {} } })
                  return
                }
                this.getUIContext().getRouter().pushUrl({ url: 'pages/RecruiterJobFormPage' })
              })
              .stateStyles({
                pressed: {
                  .scale({ x: 0.97, y: 0.97 })
                  .opacity(0.9)
                },
                normal: {
                  .scale({ x: 1, y: 1 })
                  .opacity(1)
                }
              })
              .animation({ duration: 200 })

            this.jobListContent()
          }
          .padding(AppSpacing.MD)
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .bindSheet($$this.showRegionSheet, this.regionSheet(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
    .bindSheet($$this.showIndustrySheet, this.industrySheet(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
  }

  @Builder
  auditStatusContent() {
    if (this.auditErrorText) {
              Row({ space: AppSpacing.SM }) {
                Text(this.auditErrorText)
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.DANGER)
                  .layoutWeight(1)
                Button('重试', { type: ButtonType.Capsule })
                  .height(AppSpacing.BUTTON_HEIGHT_MINI)
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.PRIMARY)
                  .backgroundColor(AppColors.SELECTED_BG)
                  .onClick(() => { this.loadAuditStatus() })
              }
              .width('100%')
              .padding(AppSpacing.SM)
              .backgroundColor(AppColors.ERROR_BG)
              .borderRadius(AppRadius.SM)
              .margin({ top: AppSpacing.SM })
    } else if (this.auditStatus !== 1) {
              Row() {
                Text(this.auditStatus === -1 ? '请先完成企业资质认证，再发布职位' :
                  '企业资质' + AUDIT_STATUS_LABELS[this.auditStatus] + '，暂无法发布新职位')
                  .fontSize(AppFontSize.XS)
                  .fontColor(AppColors.WARNING)
                  .layoutWeight(1)
                if (this.auditStatus === -1) {
                  Button('去认证', { type: ButtonType.Capsule })
                    .height(AppSpacing.BUTTON_HEIGHT_MINI)
                    .fontSize(AppFontSize.XS)
                    .fontColor(AppColors.PRIMARY)
                    .backgroundColor(AppColors.SELECTED_BG)
                    .onClick(() => { this.getUIContext().getRouter().pushUrl({ url: 'pages/RecruiterEnterprisePage' }) })
                }
              }
              .width('100%')
              .padding(AppSpacing.SM)
              .backgroundColor(AppColors.WARNING_BG)
              .borderRadius(AppRadius.SM)
              .margin({ top: AppSpacing.SM })
    }
  }

  @Builder
  enterpriseSummaryContent() {
    if (this.enterpriseInfo) {
      StandardCard() {
        Column({ space: AppSpacing.SM }) {
          Text('企业资质已认证')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.SUCCESS)
          this.infoRow('公司全称', this.enterpriseInfo.companyName)
          this.infoRow('统一社会信用代码', this.enterpriseInfo.creditCode)
          this.infoRow('所属行业', this.enterpriseInfo.industry || '未设置')
          this.infoRow('所在地区', this.enterpriseInfo.regionName || '未设置')
          if (this.enterpriseInfo.licenseImgUrl) {
            Image(this.enterpriseInfo.licenseImgUrl)
              .width(120)
              .height(80)
              .objectFit(ImageFit.Cover)
              .borderRadius(AppRadius.SM)
          }
          Text(this.enterpriseInfo.description || '未填写公司简介')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .wordBreak(WordBreak.BREAK_ALL)
          Button('编辑企业信息', { type: ButtonType.Capsule })
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .onClick(() => { this.showEnterpriseForm = true })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
  }

  @Builder
  enterpriseFormContent() {
    if (this.auditStatus === -1 || this.auditStatus === 2 || this.showEnterpriseForm) {
      StandardCard() {
        Column({ space: AppSpacing.MD }) {
          Text(this.auditStatus === 2 ? '修改企业资质并重新提交' : '完善企业资质')
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
          this.inputField('公司全称', '与营业执照一致', this.companyName, (value: string) => { this.companyName = value }, 100, true)
          this.inputField('统一社会信用代码', '18 位统一社会信用代码', this.creditCode, (value: string) => { this.creditCode = value }, 18, true)
          SelectorField({
            label: '所属行业',
            value: this.industry,
            placeholder: '请选择所属行业',
            required: true,
            onFieldClick: () => { this.showIndustrySheet = true }
          })
          SelectorField({
            label: '所在地区',
            value: this.regionName,
            placeholder: '请选择省 / 市 / 区',
            onFieldClick: () => { this.showRegionSheet = true }
          })
          LicenseUploader({
            url: this.licenseImgUrl,
            uploading: this.uploadingLicense,
            onUpload: () => { this.selectLicenseFile() },
            onRemove: () => { this.licenseImgUrl = '' },
            onPreview: () => {}
          })
          this.textAreaField('公司简介', '公司业务和规模介绍（选填）', this.description, (value: string) => { this.description = value }, 2000)
          Button({ type: ButtonType.Capsule }) {
            Text(this.savingEnterprise ? '提交中...' : '提交企业资质')
              .fontSize(AppFontSize.MD)
              .fontColor('#FFFFFF')
          }
            .width('100%')
            .height(AppSpacing.BUTTON_HEIGHT_MD)
            .backgroundColor(this.savingEnterprise || this.uploadingLicense ? AppColors.DISABLED : AppColors.PRIMARY)
            .enabled(!this.savingEnterprise && !this.uploadingLicense)
            .onClick(() => { this.submitEnterprise() })
        }
        .width('100%')
      }
    }
  }

  @Builder
  jobListContent() {
    if (this.jobList.length === 0) {
              EmptyView({ message: '暂无已发布职位' })
                .width('100%')
                .layoutWeight(1)
            } else {
              ForEach(this.jobList, (job: RecruiterJobVO) => {
                Column() {
                  StandardCard({
                    onClickAction: () => {
                      this.getUIContext().getRouter().pushUrl({
                        url: 'pages/JobDetailPage',
                        params: {
                          jobData: JSON.stringify(job),
                          hideActions: 'true'
                        }
                      })
                    },
                    accessibilityLabel: job.title
                  }) {
                    JobManageCard({
                      job: job,
                      onDelete: () => { this.confirmStatusChange(job) },
                      onApplications: () => { this.openApplications(job) },
                      onEdit: () => { this.openEdit(job) },
                      onResubmit: () => { this.confirmResubmit(job) }
                    })
                  }
                }
                .width('100%')
                .margin({ top: AppSpacing.SM })
              }, (job: RecruiterJobVO) => job.id.toString())
    }
  }

  @Builder
  inputField(label: string, placeholder: string, value: string, onChange: (value: string) => void, maxLength: number, required: boolean = false) {
    Column() {
      Row() {
        Text(label).fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_SECONDARY)
        if (required) {
          Text(' *').fontSize(AppFontSize.XS).fontColor(AppColors.DANGER)
        }
      }
      .width('100%')
      TextInput({ placeholder: placeholder, text: value })
        .height(AppSpacing.INPUT_HEIGHT)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .fontSize(AppFontSize.SM)
        .maxLength(maxLength)
        .margin({ top: AppSpacing.XS })
        .onChange(onChange)
    }
    .width('100%')
  }

  @Builder
  textAreaField(label: string, placeholder: string, value: string, onChange: (value: string) => void, maxLength: number) {
    Column() {
      Row() {
        Text(label).fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_SECONDARY)
        Blank()
        Text(value.length.toString() + '/' + maxLength.toString()).fontSize(AppFontSize.XXS).fontColor(AppColors.TEXT_MUTED)
      }
      .width('100%')
      TextArea({ placeholder: placeholder, text: value })
        .height(120)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .fontSize(AppFontSize.SM)
        .maxLength(maxLength)
        .margin({ top: AppSpacing.XS })
        .onChange(onChange)
    }
    .width('100%')
  }

  @Builder
  infoRow(label: string, value: string) {
    Column() {
      Text(label).fontSize(AppFontSize.XS).fontColor(AppColors.TEXT_SECONDARY)
      Text(value).fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_PRIMARY).margin({ top: AppSpacing.XS }).wordBreak(WordBreak.BREAK_ALL)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  regionSheet() {
    SelectorSheet({
      title: '选择企业所在地区',
      options: this.regionOptions,
      selectedId: this.regionId,
      emptyMessage: '暂无地区数据',
      onSelect: (option: SelectorOption): void => { this.selectEnterpriseRegion(option) }
    })
  }

  @Builder
  industrySheet() {
    SelectorSheet({
      title: '选择所属行业',
      options: this.industryOptions,
      selectedId: this.industry,
      emptyMessage: '暂无行业数据',
      onSelect: (option: SelectorOption): void => { this.selectEnterpriseIndustry(option) }
    })
  }

  confirmStatusChange(job: RecruiterJobVO): void {
    const targetStatus = job.status === 1 ? 4 : 1
    const action = targetStatus === 1 ? '上架' : '下架'
    this.getUIContext().showAlertDialog({
      message: '确定要' + action + '“' + job.title + '”吗？',
      confirm: {
        value: '确定',
        action: (): void => {
          RecruiterService.updateJobStatus(job.id, targetStatus).then((success: boolean) => {
            if (success) {
              this.loadJobs()
            } else {
              this.getUIContext().getPromptAction().showToast({ message: action + '失败，请稍后重试' })
            }
          }).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: action + '失败，请稍后重试' })
          })
        }
      },
      cancel: (): void => {}
    })
  }

  confirmResubmit(job: RecruiterJobVO): void {
    this.getUIContext().showAlertDialog({
      message: '确定重新提交“' + job.title + '”审核吗？',
      confirm: {
        value: '重新提交',
        action: (): void => {
          RecruiterService.resubmitJob(job.id).then((success: boolean) => {
            if (success) {
              this.loadJobs()
            } else {
              this.getUIContext().getPromptAction().showToast({ message: '重新提交失败，请稍后重试' })
            }
          }).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: '重新提交失败，请稍后重试' })
          })
        }
      },
      cancel: (): void => {}
    })
  }
  deleteJob(jobId: number): void {
    RecruiterService.deleteJob(jobId).then((success: boolean) => {
      if (success) {
        this.loadJobs()
      } else {
        this.getUIContext().getPromptAction().showToast({ message: '删除失败，请稍后重试' })
      }
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '删除失败，请稍后重试' })
    })
  }

  openEdit(job: RecruiterJobVO): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RecruiterJobFormPage',
      params: { jobId: String(job.id) }
    })
  }

  openApplications(job: RecruiterJobVO): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RecruiterApplicationsPage',
      params: { jobId: String(job.id), jobTitle: job.title }
    })
  }
}

@Component
struct JobManageCard {
  job: RecruiterJobVO = {
    id: 0, title: '', salaryMin: 0, salaryMax: 0, salaryUnit: 0,
    jobType: 1, address: '', status: 0, applicationCount: 0,
    remainingQuota: 0, totalQuota: 0, deadline: '', createTime: '', rejectReason: ''
  }
  onDelete?: () => void
  onApplications?: () => void
  onEdit?: () => void
  onResubmit?: () => void

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.job.title)
            .fontSize(AppFontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.job.salaryMin.toString() + '-' + this.job.salaryMax.toString() + '元/'
            + SALARY_UNIT_LABELS[this.job.salaryUnit] + ' · '
            + JOB_TYPE_LABELS[this.job.jobType])
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.WARNING)
            .margin({ top: AppSpacing.XS })

          Row() {
            Text(JOB_STATUS_LABELS[this.job.status])
              .fontSize(AppFontSize.XS)
              .fontColor(this.job.status === 1 ? AppColors.SUCCESS : AppColors.TEXT_MUTED)
              .backgroundColor(this.job.status === 1 ? AppColors.SUCCESS_BG : AppColors.INPUT_BG)
              .borderRadius(AppRadius.SM)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })

            Text(this.job.applicationCount.toString() + '人投递')
              .fontSize(AppFontSize.XS)
              .fontColor(AppColors.TEXT_MUTED)
              .margin({ left: AppSpacing.SM })
          }
          .margin({ top: AppSpacing.XS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: AppSpacing.XS }) {
        Button(this.job.applicationCount + '份投递', { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT_MINI)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.SELECTED_BG)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
          .onClick(() => {
            this.onApplications?.()
          })

        if (this.job.status === 0 && this.job.rejectReason) {
          Button('编辑', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor(AppColors.SELECTED_BG)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .onClick(() => { this.onEdit?.() })
          Button('重新提交', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.SUCCESS)
            .backgroundColor(AppColors.SUCCESS_BG)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .onClick(() => { this.onResubmit?.() })
        } else if (this.job.status === 0) {
          Text('审核中')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.WARNING)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.SM, bottom: AppSpacing.SM })
        } else if (this.job.status === 1 || this.job.status === 4) {
          Button(this.job.status === 1 ? '下架' : '上架', { type: ButtonType.Capsule })
            .height(AppSpacing.BUTTON_HEIGHT_MINI)
            .fontSize(AppFontSize.XS)
            .fontColor(this.job.status === 1 ? AppColors.DANGER : AppColors.SUCCESS)
            .backgroundColor(this.job.status === 1 ? AppColors.ERROR_BG : AppColors.SUCCESS_BG)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .onClick(() => { this.onDelete?.() })
            .stateStyles({
              pressed: {
                .opacity(0.6)
              }
            })
        }
      }
      .width('100%')
      .margin({ top: AppSpacing.SM })
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
  }
}
