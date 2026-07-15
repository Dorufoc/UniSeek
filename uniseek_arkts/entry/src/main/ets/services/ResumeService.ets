import { preferences } from '@kit.ArkData';

export interface ResumeData {
  name: string
  school: string
  education: string
  isFullTime: boolean
  skills: string
  experience: string
  attachmentUrl: string
  attachmentName: string
}

const DB_NAME = 'resume_db'
const KEY_RESUME = 'resume_data'

function getPref(): preferences.Preferences {
  return preferences.getPreferencesSync(getContext(), { name: DB_NAME })
}

export class ResumeService {
  static saveResume(data: ResumeData): void {
    const pref = getPref()
    pref.putSync(KEY_RESUME, JSON.stringify(data))
    pref.flushSync()
  }

  static loadResume(): ResumeData | null {
    const pref = getPref()
    const raw = pref.getSync(KEY_RESUME, '') as string
    if (!raw) {
      return null
    }
    return JSON.parse(raw) as ResumeData
  }

  static clearResume(): void {
    const pref = getPref()
    pref.putSync(KEY_RESUME, '')
    pref.flushSync()
  }
}
