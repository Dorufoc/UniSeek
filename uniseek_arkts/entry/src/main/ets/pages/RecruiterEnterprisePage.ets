import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { AppColors, AppRadius, AppSpacing, AppFontSize } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { StandardCard } from '../common/StandardCard';
import { UploadPolicy } from '../common/FormValidators';
import { ErrorView } from '../components/ErrorView';
import { SelectorSheet, SelectorOption } from '../components/filter/SelectorSheet';
import { SelectorField } from '../components/filter/SelectorField';
import { RecruiterService } from '../services/RecruiterService';
import { RecruiterEnterpriseVO, RecruiterEnterpriseRequest } from '../services/RecruiterTypes';
import { CategoryNode, DataService, RegionNode } from '../services/DataService';
import { ChatService } from '../services/ChatService';
import { StatusBanner } from '../components/enterprise/StatusBanner';
import { LicenseUploader } from '../components/enterprise/LicenseUploader';

const CREDIT_CODE_REGEX: RegExp = /^[0-9A-HJ-NPQRTUWXY]{18}$/i

enum PageMode {
  VIEW,
  EDIT,
  CREATE
}

interface RegionOption {
  id: number
  label: string
}

interface IndustryOption {
  label: string
}

@Entry
@Component
struct RecruiterEnterprisePage {
  @State mode: PageMode = PageMode.VIEW
  @State enterpriseInfo: RecruiterEnterpriseVO | null = null

  @State companyName: string = ''
  @State creditCode: string = ''
  @State industry: string = ''
  @State regionId: number = 0
  @State regionName: string = ''
  @State description: string = ''
  @State licenseImgUrl: string = ''

  @State isLoading: boolean = false
  @State isSaving: boolean = false
  @State uploadingLicense: boolean = false
  @State errorText: string = ''

  @State regionOptions: RegionOption[] = []
  @State industryOptions: IndustryOption[] = []
  @State showRegionSheet: boolean = false
  @State showIndustrySheet: boolean = false
  @State showLicensePreview: boolean = false

  aboutToAppear(): void {
    void this.loadData()
  }

  private async loadData(): Promise<void> {
    this.isLoading = true
    this.errorText = ''
    try {
      await Promise.all([
        this.loadRegions(),
        this.loadIndustries()
      ])
      await this.loadEnterpriseInfo()
    } catch {
      this.errorText = '页面初始化失败，请稍后重试'
    } finally {
      this.isLoading = false
    }
  }

  private async loadIndustries(): Promise<void> {
    try {
      const categories: CategoryNode[] = await DataService.getCategoryTree()
      this.industryOptions = this.flattenIndustries(categories, '')
    } catch {
      console.error('[RecruiterEnterprisePage] 行业数据加载失败')
    }
  }

  private flattenIndustries(nodes: CategoryNode[], prefix: string): IndustryOption[] {
    const result: IndustryOption[] = []
    for (const node of nodes) {
      const label: string = prefix ? prefix + ' / ' + node.name : node.name
      if (node.children.length === 0) {
        result.push({ label: label })
      } else {
        const children: IndustryOption[] = this.flattenIndustries(node.children, label)
        for (const child of children) {
          result.push(child)
        }
      }
    }
    return result
  }

  private async loadRegions(): Promise<void> {
    try {
      const regions: RegionNode[] = await DataService.getRegionTree()
      this.regionOptions = this.flattenRegions(regions, '')
    } catch {
      console.error('[RecruiterEnterprisePage] 地区数据加载失败')
    }
  }

  private flattenRegions(nodes: RegionNode[], prefix: string): RegionOption[] {
    const result: RegionOption[] = []
    for (const node of nodes) {
      const label = prefix ? prefix + ' / ' + node.name : node.name
      result.push({ id: node.id, label: label })
      if (node.children.length > 0) {
        const children: RegionOption[] = this.flattenRegions(node.children, label)
        for (const child of children) {
          result.push(child)
        }
      }
    }
    return result
  }

  private async loadEnterpriseInfo(): Promise<void> {
    const info = await RecruiterService.getEnterpriseInfo()
    this.enterpriseInfo = info
    if (info) {
      this.populateFromInfo(info)
      this.mode = PageMode.VIEW
    } else {
      this.clearForm()
      this.mode = PageMode.CREATE
    }

    // 支持从外部传入 edit=1 直接进入编辑态
    const params = this.getUIContext().getRouter().getParams() as Record<string, string | undefined>
    if (params && params['edit'] === '1' && this.enterpriseInfo) {
      this.mode = PageMode.EDIT
    }
  }

  private populateFromInfo(info: RecruiterEnterpriseVO): void {
    this.companyName = info.companyName || ''
    this.creditCode = info.creditCode || ''
    this.industry = info.industry || ''
    this.regionId = info.regionId || 0
    this.regionName = info.regionName || this.findRegionName(info.regionId)
    this.description = info.description || ''
    this.licenseImgUrl = info.licenseImgUrl || ''
  }

  private findRegionName(regionId: number | undefined): string {
    if (!regionId) {
      return ''
    }
    const option = this.regionOptions.find((item: RegionOption): boolean => item.id === regionId)
    return option ? option.label : ''
  }

  private clearForm(): void {
    this.companyName = ''
    this.creditCode = ''
    this.industry = ''
    this.regionId = 0
    this.regionName = ''
    this.description = ''
    this.licenseImgUrl = ''
  }

  private isCreateMode(): boolean {
    return this.mode === PageMode.CREATE
  }

  private startEdit(): void {
    if (this.enterpriseInfo) {
      this.populateFromInfo(this.enterpriseInfo)
    }
    this.mode = PageMode.EDIT
  }

  private cancelEdit(): void {
    if (this.enterpriseInfo) {
      this.populateFromInfo(this.enterpriseInfo)
      this.mode = PageMode.VIEW
    } else {
      this.clearForm()
      this.mode = PageMode.CREATE
    }
  }

  private showToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2000 })
  }

  private validateForm(): boolean {
    if (!this.companyName.trim()) {
      this.showToast('请填写企业名称')
      return false
    }
    const code = this.creditCode.trim()
    if (!code) {
      this.showToast('请填写统一社会信用代码')
      return false
    }
    if (!CREDIT_CODE_REGEX.test(code)) {
      this.showToast('请输入正确的 18 位统一社会信用代码')
      return false
    }
    if (!this.industry.trim()) {
      this.showToast('请选择所属行业')
      return false
    }
    return true
  }

  private async handleSave(): Promise<void> {
    if (!this.validateForm() || this.isSaving) {
      return
    }

    const request: RecruiterEnterpriseRequest = {
      companyName: this.companyName.trim(),
      creditCode: this.creditCode.trim().toUpperCase(),
      licenseImgUrl: this.licenseImgUrl,
      industry: this.industry.trim(),
      regionId: this.regionId || 0,
      description: this.description.trim()
    }

    this.isSaving = true
    const hasEnterprise = this.enterpriseInfo !== null
    try {
      const success = await RecruiterService.saveEnterpriseInfo(request, hasEnterprise)
      if (success) {
        this.showToast(this.enterpriseInfo ? '企业信息已更新，等待重新审核' : '企业信息提交成功，等待审核')
        await this.loadEnterpriseInfo()
      } else {
        this.showToast('提交失败，请稍后重试')
      }
    } catch {
      this.showToast('提交失败，请稍后重试')
    } finally {
      this.isSaving = false
    }
  }

  private selectLicenseFile(): void {
    const photoPicker = new photoAccessHelper.PhotoViewPicker()
    photoPicker.select({
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 1
    }).then((result: photoAccessHelper.PhotoSelectResult) => {
      if (!result.photoUris || result.photoUris.length === 0) {
        return
      }
      const uri = result.photoUris[0]
      const fileName = uri.split('/').pop() || '营业执照'
      try {
        const stat = fileIo.statSync(uri)
        const validationMessage: string = UploadPolicy.validateLicense(fileName, Number(stat.size))
        if (validationMessage) {
          this.showToast(validationMessage)
          return
        }
      } catch {
        this.showToast('无法读取营业执照文件，请重新选择')
        return
      }
      this.uploadingLicense = true
      ChatService.uploadImage(uri).then((url: string) => {
        this.licenseImgUrl = url
        this.showToast('营业执照上传成功')
      }).catch(() => {
        this.licenseImgUrl = ''
        this.showToast('营业执照上传失败，请重试')
      }).finally(() => {
        this.uploadingLicense = false
      })
    }).catch(() => {
      this.showToast('未选择文件')
    })
  }

  private removeLicense(): void {
    this.licenseImgUrl = ''
  }

  private previewLicense(): void {
    if (this.licenseImgUrl) {
      this.showLicensePreview = true
    }
  }

  private selectRegion(option: RegionOption): void {
    this.regionId = option.id
    this.regionName = option.label
    this.showRegionSheet = false
  }

  private selectIndustry(option: SelectorOption): void {
    this.industry = option.label
    this.showIndustrySheet = false
  }

  private regionSelectorOptions(): SelectorOption[] {
    return this.regionOptions.map((option: RegionOption): SelectorOption => ({
      id: option.id,
      label: option.label
    }))
  }

  private industrySelectorOptions(): SelectorOption[] {
    return this.industryOptions.map((option: IndustryOption): SelectorOption => ({
      id: option.label,
      label: option.label
    }))
  }

  build() {
    Column() {
      NavBar({
        title: '企业资质',
        showBack: true,
        onBack: () => this.getUIContext().getRouter().back()
      })

      Scroll() {
        Column({ space: AppSpacing.SM }) {
          if (this.isLoading) {
            this.loadingContent()
          } else if (this.errorText) {
            ErrorView({
              message: this.errorText,
              retryText: '重新加载',
              onRetry: () => { void this.loadData() }
            })
              .width('100%')
              .layoutWeight(1)
          } else {
            if (this.mode === PageMode.VIEW && this.enterpriseInfo) {
              this.viewContent()
            } else {
              this.formContent()
            }
          }
        }
        .width('100%')
        .padding(AppSpacing.MD)
        .padding({ bottom: AppSpacing.XXL })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .align(Alignment.TopStart)
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
    .bindSheet($$this.showLicensePreview, this.licensePreviewSheet(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_PAGE
    })
  }

  @Builder
  loadingContent() {
    Row({ space: AppSpacing.SM }) {
      LoadingProgress()
        .width(AppSpacing.ICON_MD)
        .height(AppSpacing.ICON_MD)
        .color(AppColors.PRIMARY)
      Text('正在加载企业信息')
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(AppSpacing.XL)
  }

  @Builder
  viewContent() {
    if (this.enterpriseInfo) {
      StandardCard() {
        StatusBanner({ status: this.enterpriseInfo.auditStatus })
      }

      StandardCard() {
        Column({ space: AppSpacing.MD }) {
          this.infoRow('公司全称', this.enterpriseInfo.companyName)
          this.infoRow('统一社会信用代码', this.enterpriseInfo.creditCode)
          if (this.enterpriseInfo.licenseImgUrl) {
            this.licenseViewRow()
          }
          this.infoRow('所属行业', this.enterpriseInfo.industry || '未设置')
          this.infoRow('所在地区', this.enterpriseInfo.regionName || '未设置')
          this.infoRow('公司简介', this.enterpriseInfo.description || '未设置')
        }
        .width('100%')
      }

      Button({ type: ButtonType.Capsule }) {
        Text('编辑企业信息')
          .fontSize(AppFontSize.MD)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(AppSpacing.BUTTON_HEIGHT_MD)
      .backgroundColor(AppColors.PRIMARY)
      .margin({ top: AppSpacing.LG })
      .onClick(() => {
        this.startEdit()
      })
      .stateStyles({
        pressed: {
          .backgroundColor(AppColors.PRIMARY_HOVER)
        }
      })
    }
  }

  @Builder
  infoRow(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      Text(value)
        .fontSize(AppFontSize.SM)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .margin({ top: AppSpacing.XS })
        .wordBreak(WordBreak.BREAK_ALL)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  licenseViewRow() {
    Column() {
      Text('营业执照')
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      Row({ space: AppSpacing.SM }) {
        Image(this.licenseImgUrl)
          .width(72)
          .height(54)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppRadius.SM)
        Text('点击查看营业执照')
          .fontSize(AppFontSize.SM)
          .fontColor(AppColors.PRIMARY)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: AppSpacing.XS })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.showLicensePreview = true
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  formContent() {
    StandardCard() {
      Column({ space: AppSpacing.LG }) {
        Column() {
          Text(this.isCreateMode() ? '企业资质认证' : '编辑企业信息')
            .fontSize(AppFontSize.XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
          Text(this.isCreateMode() ? '填写企业信息提交审核，认证通过后可发布职位' : '修改企业基本信息')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ top: AppSpacing.XS })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        this.inputField('公司全称', '与企业营业执照一致', this.companyName, (v: string) => { this.companyName = v }, 100, true)
        this.inputField('统一社会信用代码', '18 位统一社会信用代码', this.creditCode, (v: string) => { this.creditCode = v }, 18, true)

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
          onRemove: () => { this.removeLicense() },
          onPreview: () => { this.previewLicense() }
        })

        this.textAreaField('公司简介', '公司业务和规模介绍（选填）', this.description, (v: string) => { this.description = v }, 2000)

        Row({ space: AppSpacing.SM }) {
          if (!this.isCreateMode()) {
            Button('取消', { type: ButtonType.Capsule })
              .height(AppSpacing.BUTTON_HEIGHT_MD)
              .fontSize(AppFontSize.MD)
              .fontColor(AppColors.TEXT_PRIMARY)
              .backgroundColor(AppColors.INPUT_BG)
              .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
              .layoutWeight(1)
              .onClick(() => { this.cancelEdit() })
          }

          Button({ type: ButtonType.Capsule }) {
            Text(this.isSaving ? '保存中...' : '保存')
              .fontSize(AppFontSize.MD)
              .fontColor('#FFFFFF')
          }
          .height(AppSpacing.BUTTON_HEIGHT_MD)
          .backgroundColor(this.isSaving || this.uploadingLicense ? AppColors.DISABLED : AppColors.PRIMARY)
          .layoutWeight(1)
          .enabled(!this.isSaving && !this.uploadingLicense)
          .onClick(() => { void this.handleSave() })
        }
        .width('100%')
      }
      .width('100%')
    }
  }

  @Builder
  inputField(label: string, placeholder: string, value: string, onChange: (v: string) => void, maxLength: number, required: boolean = false) {
    Column() {
      Row() {
        Text(label)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_SECONDARY)
        if (required) {
          Text(' *')
            .fontSize(AppFontSize.XS)
            .fontColor(AppColors.DANGER)
        }
      }
      .width('100%')

      TextInput({ placeholder: placeholder, text: value })
        .height(AppSpacing.INPUT_HEIGHT)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM })
        .fontSize(AppFontSize.SM)
        .maxLength(maxLength)
        .margin({ top: AppSpacing.XS })
        .onChange(onChange)
    }
    .width('100%')
  }

  @Builder
  textAreaField(label: string, placeholder: string, value: string, onChange: (v: string) => void, maxLength: number) {
    Column() {
      Row() {
        Text(label)
          .fontSize(AppFontSize.XS)
          .fontColor(AppColors.TEXT_SECONDARY)
        Blank()
        Text(`${value.length}/${maxLength}`)
          .fontSize(AppFontSize.XXS)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .width('100%')

      TextArea({ placeholder: placeholder, text: value })
        .height(120)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM })
        .fontSize(AppFontSize.SM)
        .maxLength(maxLength)
        .margin({ top: AppSpacing.XS })
        .onChange(onChange)
    }
    .width('100%')
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
      onEmptyAction: (): void => { void this.loadRegions() }
    })
  }

  @Builder
  industrySheet() {
    SelectorSheet({
      title: '选择所属行业',
      options: this.industrySelectorOptions(),
      selectedId: this.industry,
      emptyMessage: '暂无行业数据',
      onSelect: (option: SelectorOption): void => {
        this.selectIndustry(option)
      }
    })
  }

  @Builder
  licensePreviewSheet() {
    Column() {
      Row() {
        Text('营业执照预览')
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')
      .height(56)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .justifyContent(FlexAlign.Center)

      Image(this.licenseImgUrl)
        .width('100%')
        .layoutWeight(1)
        .objectFit(ImageFit.Contain)
        .margin(AppSpacing.MD)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
