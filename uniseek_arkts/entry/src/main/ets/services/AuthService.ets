import { preferences } from '@kit.ArkData';

const DB_NAME = 'auth_db'
const KEY_AUTH_STATUS = 'real_name_status'
const KEY_REAL_NAME = 'real_name'
const KEY_ID_CARD = 'id_card'

function getPref(): preferences.Preferences {
  return preferences.getPreferencesSync(getContext(), { name: DB_NAME })
}

export interface RealNameInfo {
  realName: string
}

export class AuthService {
  static isRealNameVerified(): boolean {
    const pref = getPref()
    return pref.getSync(KEY_AUTH_STATUS, 'false') as string === 'true'
  }

  static setRealNameVerified(realName: string, idCard: string): void {
    const pref = getPref()
    pref.putSync(KEY_AUTH_STATUS, 'true')
    pref.putSync(KEY_REAL_NAME, realName)
    pref.putSync(KEY_ID_CARD, idCard)
    pref.flushSync()
  }

  static getRealNameInfo(): RealNameInfo | null {
    const pref = getPref()
    if (pref.getSync(KEY_AUTH_STATUS, 'false') as string !== 'true') {
      return null
    }
    const info: RealNameInfo = {
      realName: pref.getSync(KEY_REAL_NAME, '') as string
    }
    return info
  }
}
