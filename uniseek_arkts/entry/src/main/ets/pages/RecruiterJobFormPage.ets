import { AppAnimation, AppColors, AppFilter, AppFontSize, AppRadius, AppSpacing } from '../common/AppStyles';
import { NavBar } from '../common/NavBar';
import { CategoryNode, DataService, RegionNode } from '../services/DataService';
import { RecruiterService } from '../services/RecruiterService';
import { formatDeadlineForApi, RecruiterJobRequest } from '../services/RecruiterTypes';
import { SelectorOption } from '../components/filter/SelectorSheet';
import { SelectorField } from '../components/filter/SelectorField';
import { ChoiceChips, ChoiceOption } from '../components/filter/ChoiceChips';

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

@CustomDialog
struct RecruiterDeadlinePickerDialog {
  controller?: CustomDialogController
  currentDate: string = ''
  onConfirm?: (value: string) => void
  onCancel?: () => void

  @State selectedDate: Date = new Date()

  aboutToAppear(): void {
    if (this.currentDate.trim().length >= 10) {
      const parsed = new Date(this.currentDate.replace(' ', 'T'))
      if (parsed.getTime() > 0) {
        this.selectedDate = parsed
      }
    }
  }

  private twoDigits(value: number): string {
    return value < 10 ? '0' + String(value) : String(value)
  }

  private formatDate(value: Date): string {
    return String(value.getFullYear()) + '-' + this.twoDigits(value.getMonth() + 1) + '-' + this.twoDigits(value.getDate())
  }

  build() {
    Column({ space: AppSpacing.MD }) {
      Text('选择报名截止时间')
        .fontSize(AppFontSize.LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      DatePicker({
        start: new Date('2020-01-01'),
        end: new Date('2100-12-31'),
        selected: this.selectedDate
      })
        .lunar(false)
        .onChange((value: DatePickerResult): void => {
          const year: number = value.year === undefined ? this.selectedDate.getFullYear() : value.year
          const month: number = value.month === undefined ? this.selectedDate.getMonth() + 1 : value.month
          const day: number = value.day === undefined ? this.selectedDate.getDate() : value.day
          this.selectedDate = new Date(year, month - 1, day, this.selectedDate.getHours(), this.selectedDate.getMinutes())
        })
        .width('100%')
        .height(180)

      TimePicker({ selected: this.selectedDate })
        .onChange((value: TimePickerResult): void => {
          const hour: number = value.hour === undefined ? this.selectedDate.getHours() : value.hour
          const minute: number = value.minute === undefined ? this.selectedDate.getMinutes() : value.minute
          this.selectedDate = new Date(this.selectedDate.getFullYear(), this.selectedDate.getMonth(), this.selectedDate.getDate(), hour, minute)
        })
        .width('100%')
        .height(150)

      Row({ space: AppSpacing.SM }) {
        Button('取消', { type: ButtonType.Normal })
          .layoutWeight(1)
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontColor(AppColors.TEXT_PRIMARY)
          .backgroundColor(AppColors.INPUT_BG)
          .onClick((): void => { this.onCancel?.() })

        Button('确定', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(AppSpacing.BUTTON_HEIGHT)
          .fontSize(AppFontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(AppColors.PRIMARY)
          .onClick((): void => {
            const datePart = this.formatDate(this.selectedDate)
            const hourPart = this.twoDigits(this.selectedDate.getHours())
            const minutePart = this.twoDigits(this.selectedDate.getMinutes())
            this.onConfirm?.(datePart + ' ' + hourPart + ':' + minutePart)
          })
      }
      .width('100%')
    }
    .padding(AppSpacing.LG)
    .width('100%')
    .height('72%')
    .backgroundColor(AppColors.BG_CARD)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
  }
}

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
  @State isSubmitting: boolean = false
  @State isLoading: boolean = true

  private editJobId: number = 0

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>
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
          confirm: { value: '确定', action: (): void => { this.getUIContext().getRouter().back() } },
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
        confirm: { value: '确定', action: (): void => { this.getUIContext().getRouter().back() } },
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
        confirm: { value: '确定', action: (): void => { this.getUIContext().getRouter().back() } },
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

  openCategoryPicker(): void {
    this.getUIContext().showTextPickerDialog({
      range: this.buildCategoryRange(),
      selected: [0, 0],
      onAccept: (value: TextPickerResult): void => {
        const selectedValues: string[] = this.pickerValues(value.value)
        if (selectedValues.length === 0) {
          return
        }
        // 职位发布表单不允许选择"全部"，必须是具体叶子分类
        if (selectedValues.indexOf('全部') >= 0) {
          this.showValidation('请选择具体的职位分类')
          return
        }
        const label = selectedValues.join(' / ')
        const option = this.findOption(this.categoryOptions, label)
        if (option) {
          this.categoryId = Number(option.id)
          this.categoryLabel = option.label
        }
      }
    })
  }

  openRegionPicker(): void {
    this.getUIContext().showTextPickerDialog({
      range: this.buildRegionRange(),
      selected: [0, 0, 0],
      onAccept: (value: TextPickerResult): void => {
        const selectedValues: string[] = this.pickerValues(value.value)
        if (selectedValues.length === 0) {
          return
        }
        // 职位发布表单不允许选择"全部"，必须是具体区县
        if (selectedValues.indexOf('全部') >= 0) {
          this.showValidation('请选择具体的区县')
          return
        }
        const label = selectedValues.join(' / ')
        const option = this.findOption(this.regionOptions, label)
        if (option) {
          this.regionId = Number(option.id)
          this.regionLabel = option.label
        }
      }
    })
  }

  openDeadlinePicker(): void {
    const dialog = new CustomDialogController({
      builder: RecruiterDeadlinePickerDialog({
        currentDate: this.deadline,
        onConfirm: (value: string): void => {
          dialog.close()
          this.deadline = value
        },
        onCancel: (): void => {
          dialog.close()
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom
    })
    dialog.open()
  }

  findOption(options: SelectorOption[], label: string): SelectorOption | undefined {
    for (const option of options) {
      if (option.label === label || option.label.endsWith(label)) {
        return option
      }
    }
    return undefined
  }

  pickerValues(value: string | string[]): string[] {
    if (Array.isArray(value)) {
      return value
    }
    return [value]
  }

  buildCategoryRange(): TextCascadePickerRangeContent[] {
    return DataService.getFields().map((field): TextCascadePickerRangeContent => {
      const children = field.occupations.map((occupation): TextCascadePickerRangeContent => ({ text: occupation.name }))
      return { text: field.name, children: children }
    })
  }

  buildRegionRange(): TextCascadePickerRangeContent[] {
    return DataService.getProvinces().map((province): TextCascadePickerRangeContent => {
      const cities = province.cities.map((city): TextCascadePickerRangeContent => ({
        text: city.name,
        children: city.districts.map((district): TextCascadePickerRangeContent => ({ text: district.name }))
      }))
      return { text: province.name, children: cities }
    })
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
      deadline: formatDeadlineForApi(this.deadline)
    }
    this.isSubmitting = true
    try {
      if (this.editJobId > 0) {
        await RecruiterService.updateJob(this.editJobId, data)
      } else {
        await RecruiterService.createJob(data)
      }
      this.isSubmitting = false
      this.getUIContext().getRouter().back()
    } catch (err) {
      this.isSubmitting = false
      const message = err instanceof Error ? err.message : '提交失败，请稍后再试'
      this.showValidation(message)
    }
  }

  build() {
    Column() {
      NavBar({
        title: this.editJobId > 0 ? '编辑职位' : '发布职位',
        showBack: true,
        onBack: (): void => { this.getUIContext().getRouter().back() }
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(AppSpacing.ICON_MD).height(AppSpacing.ICON_MD).color(AppColors.PRIMARY)
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
            SelectorField({
              label: '职位分类',
              value: this.categoryLabel,
              placeholder: '请选择职位分类',
               onFieldClick: (): void => { this.openCategoryPicker() }
            })
            SelectorField({
              label: '工作地区',
              value: this.regionLabel,
              placeholder: '请选择省 / 市 / 区',
               onFieldClick: (): void => { this.openRegionPicker() }
            })

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
            Column() {
              Text('薪资单位')
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_SECONDARY)
                .width('100%')
              ChoiceChips({
                options: SALARY_UNIT_OPTIONS,
                selected: this.salaryUnit,
                onSelect: (value: number): void => { this.salaryUnit = value }
              })
                .margin({ top: AppSpacing.XS })
            }
            .width('100%')
            .margin({ top: AppSpacing.SM })
            Column() {
              Text('工作类型')
                .fontSize(AppFontSize.XS)
                .fontColor(AppColors.TEXT_SECONDARY)
                .width('100%')
              ChoiceChips({
                options: JOB_TYPE_OPTIONS,
                selected: this.jobType,
                onSelect: (value: number): void => { this.jobType = value }
              })
                .margin({ top: AppSpacing.XS })
            }
            .width('100%')
            .margin({ top: AppSpacing.SM })
            this.numberField('招聘人数', '至少 1 人', this.totalQuota, (value: string): void => { this.totalQuota = value })
            this.inputField('工作地址', '例如：北京市朝阳区建国路 88 号', this.address, (value: string): void => { this.address = value })
            this.inputField('职位标签', '以英文逗号分隔，例如：急招,可远程', this.tagsText, (value: string): void => { this.tagsText = value })
            SelectorField({
              label: '报名截止时间',
              value: this.deadline,
              placeholder: '请选择截止时间',
               onFieldClick: (): void => { this.openDeadlinePicker() }
            })

            Button(this.isSubmitting ? '提交中...' : (this.editJobId > 0 ? '保存修改' : '立即发布'), { type: ButtonType.Capsule })
              .width('100%')
              .height(AppSpacing.INPUT_HEIGHT)
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
        .height(AppSpacing.INPUT_HEIGHT)
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
        .height(AppSpacing.INPUT_HEIGHT)
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
        .height(AppSpacing.INPUT_HEIGHT)
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
}
