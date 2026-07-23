/** 表单输入校验器，集中维护登录、注册与实名认证规则。 */
export class InputValidator {
  static isPhone(value: string): boolean {
    return /^1[3-9]\d{9}$/.test(value.trim())
  }

  static isEmail(value: string): boolean {
    return /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(value.trim())
  }

  static isStrongPassword(value: string): boolean {
    return /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!@#$%^&*()_+\-=]{8,20}$/.test(value)
  }

  static isNickname(value: string): boolean {
    const length: number = value.trim().length
    return length >= 2 && length <= 20
  }

  static isValidIdCard(value: string): boolean {
    const idCard: string = value.trim().toUpperCase()
    if (!/^[0-9]{17}[0-9X]$/.test(idCard)) {
      return false
    }
    if (!InputValidator.isValidBirthDate(idCard.substring(6, 14))) {
      return false
    }
    const weights: number[] = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
    const checkCodes: string[] = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2']
    let sum: number = 0
    for (let index: number = 0; index < 17; index++) {
      sum += Number(idCard.substring(index, index + 1)) * weights[index]
    }
    return checkCodes[sum % 11] === idCard.substring(17)
  }

  private static isValidBirthDate(value: string): boolean {
    const year: number = Number(value.substring(0, 4))
    const month: number = Number(value.substring(4, 6))
    const day: number = Number(value.substring(6, 8))
    const today: Date = new Date()
    if (year < 1900 || year > today.getFullYear() || month < 1 || month > 12 || day < 1) {
      return false
    }
    const daysInMonth: number[] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    const isLeapYear: boolean = year % 400 === 0 || (year % 4 === 0 && year % 100 !== 0)
    if (isLeapYear) {
      daysInMonth[1] = 29
    }
    if (day > daysInMonth[month - 1]) {
      return false
    }
    if (year === today.getFullYear()) {
      const currentMonth: number = today.getMonth() + 1
      return month < currentMonth || (month === currentMonth && day <= today.getDate())
    }
    return true
  }
}

/** 上传文件的客户端前置校验。 */
export class UploadPolicy {
  private static readonly RESUME_MAX_SIZE: number = 10 * 1024 * 1024
  private static readonly IMAGE_MAX_SIZE: number = 5 * 1024 * 1024

  static validateResume(fileName: string, size: number): string {
    if (!fileName.trim().toLowerCase().endsWith('.pdf')) {
      return '仅支持 PDF 格式'
    }
    if (size > UploadPolicy.RESUME_MAX_SIZE) {
      return '文件大小不能超过 10MB'
    }
    return ''
  }

  static validateLicense(fileName: string, size: number): string {
    const lowerName: string = fileName.trim().toLowerCase()
    const isImage: boolean = lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') ||
      lowerName.endsWith('.png') || lowerName.endsWith('.gif') || lowerName.endsWith('.webp')
    if (!isImage) {
      return '请选择 JPG、PNG、GIF 或 WebP 图片'
    }
    if (size > UploadPolicy.IMAGE_MAX_SIZE) {
      return '图片大小不能超过 5MB'
    }
    return ''
  }
}
