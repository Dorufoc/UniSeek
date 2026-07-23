import { router } from '@kit.ArkUI';
import { AppAnimation, AppColors, AppFontSize, AppRadius, AppSpacing } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { CategoryNode, DataService, RegionNode } from '../services/DataService';
import { RecruiterService } from '../services/RecruiterService';
import { RecruiterJobRequest } from '../services/RecruiterTypes';

interface SelectorOption {
  id: number
  label: string
}

interface ChoiceOption {
  value: number
  label: string
}

const SALARY_UNIT_OPTIONS: ChoiceOption[] = [
  { value: 0, label: '日薪' },
  { value: 1, label: '时薪' },
  { value: 2, label: '月薪' }
]

const JOB_TYPE_OPTIONS: ChoiceOption[] = [
  { value: 1, label: '全职' },
  { value: 2, label: '兼职' },
  { value: 3, label: '实习' }
]

@Entry
@Component
struct RecruiterJobFormPage {
  @State title: string = ''
  @State categoryId: number = 0
  @State categoryLabel: string = ''
  @State regionId: number = 0
  @State regionLabel: string = ''
  @State description: string = ''
  @State salaryMin: string = ''
  @State salaryMax: string = ''
  @State salaryUnit: number = 0
  @State jobType: number = 1
  @State totalQuota: string = '1'
  @State address: string = ''
  @State tagsText: string = ''
  @State deadline: string = ''
  @State categoryOptions: SelectorOption[] = []
  @State regionOptions: SelectorOption[] = []
  @State showCategorySheet: boolean = false
  @State showRegionSheet: boolean = false
  @State showDeadlineSheet: boolean = false
  @State isSubmitting: boolean = false
  @State isLoading: boolean = true

  private editJobId: number = 0

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params['jobId']) {
      this.editJobId = Number(params['jobId'])
    }
    this.loadInitialData()
  }

  async loadInitialData(): Promise<void> {
    this.isLoading = true
    try {
      const enterprise = await RecruiterService.getEnterpriseInfo()
      if (!enterprise || enterprise.auditStatus !== 1) {
        this.getUIContext().showAlertDialog({
          message: '企业资质审核通过后才能发布或编辑职位',
          confirm: { value: '确定', action: (): void => { router.back() } },
          autoCancel: true
        })
        return
      }
      const categories = await DataService.getCategoryTree()
      const regions = await DataService.getRegionTree()
      this.categoryOptions = this.flattenCategories(categories, '')
      this.regionOptions = this.flattenRegions(regions, '')
      if (this.editJobId > 0) {
        await this.loadJobForEdit()
      }
    } catch {
      this.getUIContext().showAlertDialog({
        message: '表单数据加载失败，请稍后重试',
        confirm: { value: '确定', action: (): void => { router.back() } },
        autoCancel: true
      })
    }
    this.isLoading = false
  }

  flattenCategories(nodes: CategoryNode[], prefix: string): SelectorOption[] {
    const result: SelectorOption[] = []
    for (const node of nodes) {
      const label = prefix ? prefix + ' / ' + node.name : node.name
      result.push({ id: node.id, label: label })
      if (node.children.length > 0) {
        const children = this.flattenCategories(node.children, label)
        for (const child of children) {
          result.push(child)
        }
      }
    }
    return result
  }

  flattenRegions(nodes: RegionNode[], prefix: string): SelectorOption[] {
    const result: SelectorOption[] = []
    for (const node of nodes) {
      const label = prefix ? prefix + ' / ' + node.name : node.name
      result.push({ id: node.id, label: label })
      if (node.children.length > 0) {
        const children = this.flattenRegions(node.children, label)
        for (const child of children) {
          result.push(child)
        }
      }
    }
    return result
  }

  async loadJobForEdit(): Promise<void> {
    const job = await RecruiterService.getJobDetail(this.editJobId)
    if (!job) {
      this.getUIContext().showAlertDialog({
        message: '职位信息加载失败，请返回列表后重试',
        confirm: { value: '确定', action: (): void => { router.back() } },
        autoCancel: true
      })
      return
    }
    this.title = job.title || ''
    this.categoryId = job.categoryId || 0
    this.categoryLabel = this.labelForId(this.categoryOptions, this.categoryId, job.categoryName)
    this.regionId = job.regionId || 0
    this.regionLabel = this.labelForId(this.regionOptions, this.regionId, job.regionName)
    this.description = job.description || ''
    this.salaryMin = String(job.salaryMin || 0)
    this.salaryMax = String(job.salaryMax || 0)
    this.salaryUnit = job.salaryUnit
    this.jobType = job.jobType
    this.totalQuota = String(job.totalQuota || 1)
    this.address = job.address || ''
    this.tagsText = (job.tag || []).join(',')
    this.deadline = job.deadline || ''
  }

  labelForId(options: SelectorOption[], id: number, fallback: string): string {
    for (const option of options) {
      if (option.id === id) {
        return option.label
      }
    }
    return fallback || ''
  }

  selectCategory(option: SelectorOption): void {
    this.categoryId = option.id
    this.categoryLabel = option.label
    this.showCategorySheet = false
  }

  selectRegion(option: SelectorOption): void {
    this.regionId = option.id
    this.regionLabel = option.label
    this.showRegionSheet = false
  }

  showValidation(message: string): void {
    this.getUIContext().showAlertDialog({
      message: message,
      confirm: { value: '知道了', action: (): void => {} },
      autoCancel: true
    })
  }

  parseTags(): string[] {
    const result: string[] = []
    const values = this.tagsText.split(',')
    for (const value of values) {
      const tag = value.trim()
      if (tag && result.indexOf(tag) < 0) {
        result.push(tag)
      }
    }
    return result
  }

  async submit(): Promise<void> {
    const min = Number(this.salaryMin)
    const max = Number(this.salaryMax)
    const quota = Number(this.totalQuota)
    if (!this.title.trim() || this.categoryId <= 0 || this.regionId <= 0 || !this.description.trim()
      || !this.address.trim() || !this.deadline.trim()) {
      this.showValidation('请完整填写职位标题、分类、地区、描述、地址和截止时间')
      return
    }
    if (min < 0 || max < 0 || max < min || quota < 1) {
      this.showValidation('请检查薪资范围和招聘人数')
      return
    }
    const data: RecruiterJobRequest = {
      title: this.title.trim(),
      categoryId: this.categoryId,
      regionId: this.regionId,
      description: this.description.trim(),
      salaryMin: min,
      salaryMax: max,
      salaryUnit: this.salaryUnit,
      jobType: this.jobType,
      totalQuota: quota,
      address: this.address.trim(),
      tag: this.parseTags(),
      deadline: this.deadline.trim()
    }
    this.isSubmitting = true
    const success = this.editJobId > 0
      ? await RecruiterService.updateJob(this.editJobId, data)
      : await RecruiterService.createJob(data)
    this.isSubmitting = false
    if (!success) {
      this.showValidation('提交失败，请检查网络后重试')
      return
    }
    router.back()
  }

  build() {
    Column() {
      NavBar({
        title: this.editJobId > 0 ? '编辑职位' : '发布职位',
        showBack: true,
        onBack: (): void => { router.back() }
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(28).height(28).color(AppColors.PRIMARY)
          Text('加载表单中')
            .fontSize(AppFontSize.SM)
            .fontColor(AppColors.TEXT_MUTED)
            .margin({ top: AppSpacing.SM })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: AppSpacing.MD }) {
            this.sectionTitle('基本信息')
            this.inputField('职位标题', '例如：周末餐厅服务员', this.title, (value: string): void => { this.title = value })
            this.selectorField('职位分类', this.categoryLabel || '请选择职位分类', (): void => { this.showCategorySheet = true })
            this.selectorField('工作地区', this.regionLabel || '请选择省 / 市 / 区', (): void => { this.showRegionSheet = true })

            Column() {
              Text('职位描述')
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_SECONDARY)
                .width('100%')
              TextArea({ placeholder: '请描述工作内容、任职要求和福利待遇', text: this.description })
                .width('100%')
                .height(132)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(AppRadius.MD)
                .padding(AppSpacing.SM)
                .margin({ top: AppSpacing.XS })
                .onChange((value: string): void => { this.description = value })
            }
            .width('100%')

            this.sectionTitle('薪资与岗位')
            Row({ space: AppSpacing.SM }) {
              this.inputFieldHalf('最低薪资（元）', this.salaryMin, (value: string): void => { this.salaryMin = value })
              this.inputFieldHalf('最高薪资（元）', this.salaryMax, (value: string): void => { this.salaryMax = value })
            }
            .width('100%')
            this.choiceRow('薪资单位', this.salaryUnit, SALARY_UNIT_OPTIONS, (value: number): void => { this.salaryUnit = value })
            this.choiceRow('工作类型', this.jobType, JOB_TYPE_OPTIONS, (value: number): void => { this.jobType = value })
            this.numberField('招聘人数', '至少 1 人', this.totalQuota, (value: string): void => { this.totalQuota = value })
            this.inputField('工作地址', '例如：北京市朝阳区建国路 88 号', this.address, (value: string): void => { this.address = value })
            this.inputField('职位标签', '以英文逗号分隔，例如：急招,可远程', this.tagsText, (value: string): void => { this.tagsText = value })
            this.selectorField('报名截止时间', this.deadline || '请选择截止时间', (): void => { this.showDeadlineSheet = true })

            Button(this.isSubmitting ? '提交中...' : (this.editJobId > 0 ? '保存修改' : '立即发布'), { type: ButtonType.Capsule })
              .width('100%')
              .height(48)
              .fontSize(AppFontSize.MD)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor(AppColors.PRIMARY)
              .enabled(!this.isSubmitting)
              .margin({ top: AppSpacing.LG, bottom: AppSpacing.XXL })
              .onClick((): void => { this.submit() })
              .stateStyles({ pressed: { .opacity(0.85).scale({ x: 0.98, y: 0.98 }) } })
              .animation({ duration: 150, curve: AppAnimation.CURVE_DEFAULT })
          }
          .width('100%')
          .padding(AppSpacing.MD)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .bindSheet($$this.showCategorySheet, this.categorySheet(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
    .bindSheet($$this.showRegionSheet, this.regionSheet(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
    .bindSheet($$this.showDeadlineSheet, this.deadlineSheet(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.BG_CARD
    })
  }

  @Builder
  categorySheet() {
    Column() {
      Text('选择职位分类')
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.SM })
      List() {
        ForEach(this.categoryOptions, (option: SelectorOption) => {
          ListItem() {
            this.sheetOption(option, this.categoryId === option.id, (): void => { this.selectCategory(option) })
          }
        }, (option: SelectorOption) => String(option.id))
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 0.5, color: AppColors.BORDER, startMargin: AppSpacing.MD, endMargin: AppSpacing.MD })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  regionSheet() {
    Column() {
      Text('选择工作地区')
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.SM })
      List() {
        ForEach(this.regionOptions, (option: SelectorOption) => {
          ListItem() {
            this.sheetOption(option, this.regionId === option.id, (): void => { this.selectRegion(option) })
          }
        }, (option: SelectorOption) => String(option.id))
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 0.5, color: AppColors.BORDER, startMargin: AppSpacing.MD, endMargin: AppSpacing.MD })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  deadlineSheet() {
    Column() {
      Text('选择报名截止时间')
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .padding(AppSpacing.MD)
      DatePicker({
        start: new Date('2020-01-01'),
        end: new Date('2100-12-31'),
        selected: this.deadlinePickerDate()
      })
        .width('100%')
        .onChange((value: DatePickerResult): void => {
          const year: number = value.year === undefined ? new Date().getFullYear() : value.year
          const month: number = value.month === undefined ? 1 : value.month
          const day: number = value.day === undefined ? 1 : value.day
          const timePart: string = this.deadline.length >= 16 ? this.deadline.substring(11, 16) : '00:00'
          this.deadline = String(year) + '-' + this.twoDigits(month) + '-' + this.twoDigits(day) + ' ' + timePart
        })
      TimePicker({ selected: this.deadlinePickerDate() })
        .width('100%')
        .onChange((value: TimePickerResult): void => {
          const hour: number = value.hour === undefined ? 0 : value.hour
          const minute: number = value.minute === undefined ? 0 : value.minute
          const datePart: string = this.deadline.length >= 10 ? this.deadline.substring(0, 10) : this.todayDatePart()
          this.deadline = datePart + ' ' + this.twoDigits(hour) + ':' + this.twoDigits(minute)
        })
      Button('完成', { type: ButtonType.Capsule })
        .width('90%')
        .height(40)
        .fontSize(AppFontSize.MD)
        .fontColor('#FFFFFF')
        .backgroundColor(AppColors.PRIMARY)
        .margin({ top: AppSpacing.MD })
        .onClick((): void => { this.showDeadlineSheet = false })
    }
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, bottom: AppSpacing.XL })
  }

  deadlinePickerDate(): Date {
    if (this.deadline.trim().length >= 10) {
      const parsed: Date = new Date(this.deadline.replace(' ', 'T'))
      if (parsed.getTime() > 0) {
        return parsed
      }
    }
    return new Date()
  }

  todayDatePart(): string {
    const now = new Date()
    return String(now.getFullYear()) + '-' + this.twoDigits(now.getMonth() + 1) + '-' + this.twoDigits(now.getDate())
  }

  twoDigits(value: number): string {
    return value < 10 ? '0' + String(value) : String(value)
  }

  @Builder
  sheetOption(option: SelectorOption, selected: boolean, onClick: () => void) {
    Row() {
      Text(option.label)
        .fontSize(AppFontSize.SM)
        .fontColor(selected ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      if (selected) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(18)
          .fontColor([AppColors.PRIMARY])
      }
    }
    .height(52)
    .width('100%')
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
    .backgroundColor(selected ? AppColors.SELECTED_BG : AppColors.BG_CARD)
    .onClick(onClick)
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize(AppFontSize.MD)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.TEXT_PRIMARY)
      .width('100%')
      .margin({ top: AppSpacing.SM })
  }

  @Builder
  inputField(label: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      TextInput({ placeholder: placeholder, text: value })
        .height(44)
        .width('100%')
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
        .margin({ top: AppSpacing.XS })
        .onChange(onChange)
    }
    .width('100%')
  }

  @Builder
  inputFieldHalf(label: string, value: string, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      TextInput({ placeholder: '请输入金额', text: value })
        .height(44)
        .width('100%')
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
        .margin({ top: AppSpacing.XS })
        .type(InputType.Number)
        .onChange(onChange)
    }
    .layoutWeight(1)
  }

  @Builder
  numberField(label: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      TextInput({ placeholder: placeholder, text: value })
        .height(44)
        .width('100%')
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(AppRadius.SM)
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
        .margin({ top: AppSpacing.XS })
        .type(InputType.Number)
        .onChange(onChange)
    }
    .width('100%')
  }

  @Builder
  selectorField(label: string, value: string, onClick: () => void) {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      Button({ type: ButtonType.Normal }) {
        Row() {
          Text(value)
            .fontSize(AppFontSize.SM)
            .fontColor(value.indexOf('请选择') >= 0 ? AppColors.TEXT_MUTED : AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([AppColors.TEXT_MUTED])
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .height(44)
      .width('100%')
      .backgroundColor(AppColors.INPUT_BG)
      .borderRadius(AppRadius.SM)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
      .margin({ top: AppSpacing.XS })
      .onClick(onClick)
    }
    .width('100%')
  }

  @Builder
  choiceRow(label: string, selected: number, options: ChoiceOption[], onSelect: (value: number) => void) {
    Column() {
      Text(label)
        .fontSize(AppFontSize.XS)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
      Row({ space: AppSpacing.SM }) {
        ForEach(options, (option: ChoiceOption) => {
          Button(option.label, { type: ButtonType.Capsule })
            .height(32)
            .fontSize(AppFontSize.XS)
            .fontColor(selected === option.value ? '#FFFFFF' : AppColors.TEXT_SECONDARY)
            .backgroundColor(selected === option.value ? AppColors.PRIMARY : AppColors.INPUT_BG)
            .onClick((): void => { onSelect(option.value) })
            .animation({ duration: 150, curve: AppAnimation.CURVE_DEFAULT })
        }, (option: ChoiceOption) => String(option.value))
      }
      .width('100%')
      .margin({ top: AppSpacing.XS })
    }
    .width('100%')
  }
}
