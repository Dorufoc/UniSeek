import { JobData } from '../../../services/ChatTypes'

export interface TabDataState {
  jobs: JobData[]
  page: number
  hasMore: boolean
  loading: boolean
  errorText: string
}
