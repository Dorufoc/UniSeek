export interface ResumeEditAuthData {
  isAuth: boolean
  realName: string | null
  birthDate: string | null
  gender: number
}

export interface ResumeEditState {
  name: string
  gender: number
  birthDate: string
  education: string
  school: string
  graduationDate: string
  skills: string
  experience: string
  attachmentUrl: string
}

export interface ResumeEditRequest {
  gender?: number
  birthDate?: string
  education?: string
  school?: string
  graduationDate?: string
  skills?: string
  experience?: string
  attachmentUrl?: string
}

export class ResumeEditPolicy {
  // 判断是否已实名认证
  static isRealNameAuth(auth: ResumeEditAuthData | null): boolean {
    return auth !== null && auth.isAuth
  }

  // 实名用户性别是否只读（已实名且有合法性别值）
  static isGenderLocked(auth: ResumeEditAuthData | null): boolean {
    if (auth === null || !auth.isAuth) {
      return false
    }
    return auth.gender === 0 || auth.gender === 1
  }

  // 实名用户出生日期是否只读（已实名且有出生日期）
  static isBirthDateLocked(auth: ResumeEditAuthData | null): boolean {
    if (auth === null || !auth.isAuth) {
      return false
    }
    return auth.birthDate !== null && auth.birthDate.length > 0
  }

  static mergeAuthData(state: ResumeEditState, auth: ResumeEditAuthData): ResumeEditState {
    const merged: ResumeEditState = {
      name: state.name,
      gender: state.gender,
      birthDate: state.birthDate,
      education: state.education,
      school: state.school,
      graduationDate: state.graduationDate,
      skills: state.skills,
      experience: state.experience,
      attachmentUrl: state.attachmentUrl
    }
    if (auth.isAuth) {
      merged.name = auth.realName || state.name
      if (auth.gender === 0 || auth.gender === 1) {
        merged.gender = auth.gender
      }
      if (auth.birthDate) {
        merged.birthDate = ResumeEditPolicy.normalizeDate(auth.birthDate)
      }
    }
    return merged
  }

  static normalizeDate(value: string): string {
    const trimmed: string = value.trim()
    if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
      return trimmed
    }
    if (/^\d{4}\d{2}\d{2}$/.test(trimmed)) {
      return `${trimmed.substring(0, 4)}-${trimmed.substring(4, 6)}-${trimmed.substring(6, 8)}`
    }
    return trimmed
  }

  static buildRequest(state: ResumeEditState): ResumeEditRequest {
    return {
      gender: state.gender === 0 || state.gender === 1 ? state.gender : undefined,
      birthDate: ResumeEditPolicy.normalizeDate(state.birthDate) || undefined,
      education: state.education || undefined,
      school: state.school || undefined,
      graduationDate: ResumeEditPolicy.normalizeDate(state.graduationDate) || undefined,
      skills: state.skills || undefined,
      experience: state.experience || undefined,
      attachmentUrl: state.attachmentUrl || undefined
    }
  }

  static canAutoSave(isInitializing: boolean, isSaving: boolean): boolean {
    return !isInitializing && !isSaving
  }
}
