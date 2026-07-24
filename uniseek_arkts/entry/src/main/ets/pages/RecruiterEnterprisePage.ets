import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit'
import { ChatService } from '../services/ChatService';
import { CategoryNode, DataService, RegionNode } from '../services/DataService';
import { RecruiterService } from '../services/RecruiterService';
import { AUDIT_STATUS_LABELS, RecruiterEnterpriseRequest } from '../services/RecruiterTypes';
import { AppColors, AppRadius, AppSpacing, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { UploadPolicy } from '../common/FormValidators'
import { StandardCard } from '../common/StandardCard';
import { ErrorView } from '../components/ErrorView';
import { EmptyView } from '../components/EmptyView';
import { SelectorSheet, SelectorOption } from '../components/filter/SelectorSheet';
import { SelectorField } from '../components/filter/SelectorField';

interface EnterpriseRegionOption {
  id: number
  label: string
}

interface EnterpriseIndustryOption {
  label: string
}

@Entry
@Component
struct RecruiterEnterprisePage {
  @State companyName: string = ''
  @State creditCode: string = ''
  @State industry: string = ''
  @State regionId: number = 0
  @State regionName: string = ''
  @State description: string = ''
  @State licenseImgUrl: string = ''
  @State licenseFileName: string = ''
  @State uploadingLicense: boolean = false
  @State auditStatus: number = -1
  @State isSubmitted: boolean = false
  @State isLoading: boolean = false
  @State isSaving: boolean = false
  @State errorText: string = ''
  @State regionOptions: EnterpriseRegionOption[] = []
  @State industryOptions: EnterpriseIndustryOption[] = []
  @State showRegionSheet: boolean = false
  @State showIndustrySheet: boolean = false

  aboutToAppear(): void {
    this.loadEnterpriseInfo()
    this.loadRegions()
    this.loadIndustries()
  }

  async loadIndustries(): Promise<void> {
    try {
      const categories: CategoryNode[] = await DataService.getCategoryTree()
      this.industryOptions = this.flattenIndustries(categories, '')
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: '行业数据加载失败，请稍后重试' })
    }
  }

  flattenIndustries(nodes: CategoryNode[], prefix: string): EnterpriseIndustryOption[] {
    const result: EnterpriseIndustryOption[] = []
    for (const node of nodes) {
      const label: string = prefix ? prefix + ' / ' + node.name : node.name
      if (node.children.length === 0) {
        result.push({ label: label })
      } else {
        const children: EnterpriseIndustryOption[] = this.flattenIndustries(node.children, label)
        for (const child of children) {
          result.push(child)
        }
      }
    }
    return result
  }

  async loadRegions(): Promise<void> {
    try {
      const regions: RegionNode[] = await DataService.getRegionTree()
      this.regionOptions = this.flattenRegions(regions, '')
    } catch {
      this.getUIContext().getPromptAction().showToast({ message: '地区数据加载失败，请稍后重试' })
    }
  }

  flattenRegions(nodes: RegionNode[], prefix: string): EnterpriseRegionOption[] {
    const result: EnterpriseRegionOption[] = []
    for (const node of nodes) {
      const label = prefix ? prefix + ' / ' + node.name : node.name
      result.push({ id: node.id, label: label })
      if (node.children.length > 0) {
        const children: EnterpriseRegionOption[] = this.flattenRegions(node.children, label)
        for (const child of children) {
          result.push(child)
        }
      }
    }
    return result
  }

  selectRegion(option: EnterpriseRegionOption): void {
    this.regionId = option.id
    this.regionName = option.label
    this.showRegionSheet = false
  }

  private regionSelectorOptions(): SelectorOption[] {
    const options: SelectorOption[] = []
    for (const option of this.regionOptions) {
      options.push({ id: option.id, label: option.label })
    }
    return options
  }

  private industrySelectorOptions(): SelectorOption[] {
    const options: SelectorOption[] = []
    for (const option of this.industryOptions) {
      options.push({ id: option.label, label: option.label })
    }
    return options
  }

  loadEnterpriseInfo(): void {
    this.isLoading = true
    this.errorText = ''
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info) {
        this.companyName = info.companyName
        this.creditCode = info.creditCode
        this.industry = info.industry
        this.regionId = info.regionId || 0
        this.regionName = info.regionName
        this.description = info.description
        this.licenseImgUrl = info.licenseImgUrl || ''
        this.licenseFileName = info.licenseImgUrl ? info.licenseImgUrl.split('/').pop() || '营业执照' : ''
        this.auditStatus = info.auditStatus
        this.isSubmitted = true
      }
    }).catch(() => {
      this.errorText = '企业信息加载失败，您可以重试或直接完善资料'
    }).finally(() => {
      this.isLoading = false
    })
  }

  build() {
    Column() {
      NavBar({
        title: '企业资质',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      Scroll() {
        Column() {
          if (this.isLoading) {
            Row({ space: AppSpacing.SM }) {
              LoadingProgress().width(AppSpacing.ICON_XS).height(AppSpacing.ICON_XS).color(AppColors.PRIMARY)
              Text('正在加载企业信息').fontSize(AppFontSize.SM).fontColor(AppColors.TEXT_MUTED)
            }
            .width('100%')
            .padding(AppSpacing.SM)
          } else if (this.errorText) {
            // 全页/区块级错误使用统一错误视图
            ErrorView({
              message: this.errorText,
              retryText: '重试',
              onRetry: () => { this.loadEnterpriseInfo() }
            })
              .width('100%')
              .layoutWeight(1)
          }

          if (this.auditStatus >= 0) {
            // 审核状态作为独立信息卡片
            Column() {
              StandardCard() {
                this.auditContent()
              }
            }
            .width('100%')
            .margin({ top: AppSpacing.SM })
          }

          // 表单内容统一收纳在标准卡片中，保持层次清晰
          Column() {
            StandardCard() {
              this.formContent()
            }
          }
          .width('100%')
          .margin({ top: AppSpacing.SM })
        }
        .padding(AppSpacing.MD)
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
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
  auditContent() {
    Row() {
      Text('审核状态：')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_SECONDARY)
      Text(AUDIT_STATUS_LABELS[this.auditStatus])
        .fontSize(AppFontSize.SM)
        .fontColor(this.auditStatus === 1 ? AppColors.SUCCESS : this.auditStatus === 2 ? AppColors.DANGER : AppColors.WARNING)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding(AppSpacing.SM)
    .backgroundColor(this.auditStatus === 1 ? AppColors.SUCCESS_BG :
      this.auditStatus === 2 ? AppColors.ERROR_BG : AppColors.WARNING_BG)
    .borderRadius(AppRadius.LG)

    Text('修改企业信息后需重新提交审核')
      .fontSize(AppFontSize.XS)
      .fontColor(AppColors.TEXT_MUTED)
      .width('100%')
      .margin({ top: AppSpacing.MD, bottom: AppSpacing.SM })
  }

  @Builder
  industrySheet() {
    SelectorSheet({
      title: '选择所属行业',
      options: this.industrySelectorOptions(),
      selectedId: this.industry,
      emptyMessage: '暂无行业数据',
      onSelect: (option: SelectorOption): void => {
        this.industry = option.label
        this.showIndustrySheet = false
      }
    })
  }

  @Builder
  regionSheet() {
    SelectorSheet({
      title: '选择企业所在地区',
      options: this.regionSelectorOptions(),
      selectedId: this.regionId,
      emptyMessage: '暂无地区数据',
      emptyActionText: '重新加载',
      onSelect: (option: SelectorOption): void => {
        this.selectRegion({ id: Number(option.id), label: option.label })
      },
      onEmptyAction: (): void => {
        this.loadRegions()
      }
    })
  }

  @Builder
  formContent() {
    this.inputField('企业名称', this.companyName, (v: string) => { this.companyName = v })
    this.inputField('统一社会信用代码', this.creditCode, (v: string) => { this.creditCode = v })

    Text('营业执照图片')
      .fontSize(AppFontSize.XS)
      .fontColor(AppColors.TEXT_SECONDARY)
      .width('100%')
      .margin({ top: AppSpacing.SM })
    Button({ type: ButtonType.Normal }) {
      Row({ space: AppSpacing.SM }) {
        if (this.uploadingLicense) {
          LoadingProgress().width(AppSpacing.ICON_XS).height(AppSpacing.ICON_XS).color(AppColors.PRIMARY)
        } else {
          SymbolGlyph($r('sys.symbol.plus')).fontSize(AppFontSize.ICON_MD).fontColor([AppColors.PRIMARY])
        }
        Text(this.uploadingLicense ? '正在上传' : (this.licenseFileName || '上传营业执照'))
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.PRIMARY)
      }
    }
    .width('100%')
    .height(AppSpacing.INPUT_HEIGHT)
    .backgroundColor(AppColors.INPUT_BG)
    .borderRadius(AppRadius.SM)
    .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
    .margin({ top: AppSpacing.XS })
    .onClick(() => {
      this.selectLicenseFile()
    })
    .enabled(!this.uploadingLicense)
    .stateStyles({
      pressed: {
        .backgroundColor(AppColors.SELECTED_BG)
      }
    })

    if (this.licenseImgUrl) {
      Row({ space: AppSpacing.SM }) {
        Image(this.licenseImgUrl)
          .width(72)
          .height(54)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppRadius.SM)
        Text(this.licenseFileName || '营业执照')
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_SECONDARY)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button('删除', { type: ButtonType.Capsule })
          .height(AppSpacing.BUTTON_HEIGHT_MINI)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.DANGER)
          .backgroundColor(AppColors.ERROR_BG)
          .onClick((): void => {
            this.licenseImgUrl = ''
            this.licenseFileName = ''
          })
      }
      .width('100%')
      .padding({ top: AppSpacing.SM })
      .alignItems(VerticalAlign.Center)
    }

    SelectorField({
      label: '所属行业',
      value: this.industry,
      placeholder: '请选择所属行业',
      onFieldClick: (): void => { this.showIndustrySheet = true }
    })
      .margin({ top: AppSpacing.SM })

    SelectorField({
      label: '企业所在地区',
      value: this.regionName,
      placeholder: '请选择省 / 市 / 区',
      onFieldClick: (): void => { this.showRegionSheet = true }
    })
      .margin({ top: AppSpacing.SM })

    Column() {
      Text('公司简介')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      TextArea({ placeholder: '请输入公司简介', text: this.description })
        .height(100)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM })
        .margin({ top: AppSpacing.XS })
        .onChange((v: string) => { this.description = v })
    }
    .width('100%')
    .margin({ top: AppSpacing.SM })

    Button({ type: ButtonType.Capsule }) {
      Text(this.isSaving ? '正在提交...' : this.submitButtonText())
        .fontSize(AppFontSize.MD)
        .fontColor('#FFFFFF')
    }
      .width('100%')
      .height(AppSpacing.INPUT_HEIGHT)
      .backgroundColor(this.isSaving || this.uploadingLicense ? AppColors.DISABLED : AppColors.PRIMARY)
      .enabled(!this.isSaving && !this.uploadingLicense)
      .margin({ top: AppSpacing.XL, bottom: AppSpacing.XXL })
      .onClick(() => {
        this.handleSubmit()
      })
      .stateStyles({
        pressed: {
          .scale({ x: 0.97, y: 0.97 })
          .opacity(0.9)
          .backgroundColor(AppColors.PRIMARY_HOVER)
        },
        normal: {
          .scale({ x: 1, y: 1 })
          .opacity(1)
        }
      })
      .animation({
        duration: 200
      })
  }

  @Builder
  inputField(label: string, value: string, onChange: (v: string) => void): void {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      TextInput({ placeholder: '请输入' + label, text: value })
        .height(AppSpacing.INPUT_HEIGHT)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM })
        .margin({ top: AppSpacing.XS })
        .onChange(onChange)
    }
    .width('100%')
    .margin({ top: AppSpacing.SM })
  }

  selectLicenseFile(): void {
    const photoPicker = new photoAccessHelper.PhotoViewPicker()
    photoPicker.select({
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 1
    }).then((result: photoAccessHelper.PhotoSelectResult) => {
      if (!result.photoUris || result.photoUris.length === 0) {
        return
      }
      const uri = result.photoUris[0]
      this.licenseFileName = uri.split('/').pop() || '营业执照'
      try {
        const stat = fileIo.statSync(uri)
        const validationMessage: string = UploadPolicy.validateLicense(this.licenseFileName, Number(stat.size))
        if (validationMessage) {
          this.getUIContext().getPromptAction().showToast({ message: validationMessage })
          return
        }
      } catch {
        this.getUIContext().getPromptAction().showToast({ message: '无法读取营业执照文件，请重新选择' })
        return
      }
      this.uploadingLicense = true
      ChatService.uploadImage(uri).then((url: string) => {
        this.licenseImgUrl = url
        this.getUIContext().getPromptAction().showToast({ message: '营业执照上传成功' })
      }).catch(() => {
        this.licenseImgUrl = ''
        this.getUIContext().getPromptAction().showToast({ message: '营业执照上传失败，请重试' })
      }).finally(() => {
        this.uploadingLicense = false
      })
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '未选择文件' })
    })
  }

  submitButtonText(): string {
    if (this.auditStatus === -1) return '提交认证'
    if (this.auditStatus === 1) return '修改并重新提交审核'
    if (this.auditStatus === 2) return '重新提交审核'
    return '更新并重新提交'
  }

  handleSubmit(): void {
    if (!this.companyName.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请填写企业名称' })
      return
    }
    if (!this.creditCode.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请填写统一社会信用代码' })
      return
    }
    if (!/^[0-9A-HJ-NPQRTUWXY]{18}$/i.test(this.creditCode.trim())) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入正确的 18 位统一社会信用代码' })
      return
    }
    if (!this.licenseImgUrl) {
      this.getUIContext().getPromptAction().showToast({ message: '请上传营业执照' })
      return
    }
    if (!this.industry.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '请选择所属行业' })
      return
    }
    if (this.regionId <= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请选择企业所在地区' })
      return
    }

    const data: RecruiterEnterpriseRequest = {
      companyName: this.companyName.trim(),
      creditCode: this.creditCode.trim().toUpperCase(),
      licenseImgUrl: this.licenseImgUrl,
      industry: this.industry.trim(),
      regionId: this.regionId,
      description: this.description.trim()
    }

    this.isSaving = true
    RecruiterService.saveEnterpriseInfo(data, this.isSubmitted).then((success: boolean) => {
      if (success) {
        this.auditStatus = 0
        this.isSubmitted = true
        this.getUIContext().getPromptAction().showToast({ message: '企业资料已提交审核' })
        this.getUIContext().getRouter().back()
      } else {
        this.getUIContext().getPromptAction().showToast({ message: '企业认证提交失败，请稍后重试' })
      }
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '企业认证提交失败，请稍后重试' })
    }).finally(() => {
      this.isSaving = false
    })
  }
}
