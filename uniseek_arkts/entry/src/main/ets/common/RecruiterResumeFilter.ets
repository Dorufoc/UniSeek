import { ResumeCardData } from '../services/RecruiterTypes'

export class RecruiterResumeFilter {
  static filter(resumes: ResumeCardData[], regions: string[], types: string[]): ResumeCardData[] {
    const hasRegionMetadata: boolean = resumes.some((resume: ResumeCardData): boolean => resume.region.length > 0)
    const hasTypeMetadata: boolean = resumes.some((resume: ResumeCardData): boolean => resume.type.length > 0)

    return resumes.filter((resume: ResumeCardData): boolean => {
      if (regions.length > 0 && hasRegionMetadata && !regions.some((region: string): boolean => resume.region.startsWith(region))) {
        return false
      }
      if (types.length > 0 && hasTypeMetadata && !types.some((type: string): boolean => resume.type.startsWith(type))) {
        return false
      }
      return true
    })
  }
}
