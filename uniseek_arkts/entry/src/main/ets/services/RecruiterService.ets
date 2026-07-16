import {
  RecruiterJobVO,
  RecruiterApplicationVO,
  RecruiterEnterpriseVO,
  RecruiterJobRequest,
  RecruiterEnterpriseRequest,
  RecruiterUpdateStatusRequest,
  RecruiterRequestVO
} from './RecruiterTypes';

export class RecruiterService {
  static getMyJobs(): Promise<RecruiterJobVO[]> {
    return new Promise((resolve) => { resolve([]) })
  }

  static createJob(data: RecruiterJobRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static updateJob(jobId: number, data: RecruiterJobRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static updateJobStatus(jobId: number, targetStatus: number): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static getJobApplications(taskId: number): Promise<RecruiterApplicationVO[]> {
    return new Promise((resolve) => { resolve([]) })
  }

  static updateApplicationStatus(applicationId: number, data: RecruiterUpdateStatusRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static getEnterpriseInfo(): Promise<RecruiterEnterpriseVO | null> {
    return new Promise((resolve) => { resolve(null) })
  }

  static saveEnterpriseInfo(data: RecruiterEnterpriseRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static deleteJob(jobId: number): Promise<boolean> {
    return new Promise((resolve) => { resolve(false) })
  }

  static getIncomingRequests(): Promise<RecruiterRequestVO[]> {
    const mock: RecruiterRequestVO[] = [
      { id: 1, applicantId: 101, applicantName: '张明', applicantAvatar: '', applicantAge: 24, applicantSchool: '北京大学', applicantMajor: '计算机科学与技术', applicantEducation: '本科', applicantExperience: '2年经验', applicantSkills: 'Vue, React, TypeScript', applicantRegion: '北京-海淀区', applicantType: '互联网/IT-前端工程师', applicantSalary: '20k-30k', jobTitle: '高级前端工程师', status: 0, interviewTime: '', interviewLocation: '', rejectReason: '', createTime: '2026-07-15 14:30' },
      { id: 2, applicantId: 102, applicantName: '李华', applicantAvatar: '', applicantAge: 26, applicantSchool: '浙江大学', applicantMajor: '软件工程', applicantEducation: '硕士', applicantExperience: '3年经验', applicantSkills: 'Java, Spring Cloud, MySQL', applicantRegion: '浙江-杭州-西湖区', applicantType: '互联网/IT-后端工程师', applicantSalary: '25k-35k', jobTitle: 'Java后端开发工程师', status: 0, interviewTime: '', interviewLocation: '', rejectReason: '', createTime: '2026-07-15 10:20' },
      { id: 3, applicantId: 103, applicantName: '王芳', applicantAvatar: '', applicantAge: 23, applicantSchool: '中国美术学院', applicantMajor: '视觉传达设计', applicantEducation: '本科', applicantExperience: '1年经验', applicantSkills: 'Figma, Sketch, Photoshop', applicantRegion: '广东-深圳-南山区', applicantType: '互联网/IT-UI设计师', applicantSalary: '15k-22k', jobTitle: 'UI/UX设计师', status: 0, interviewTime: '', interviewLocation: '', rejectReason: '', createTime: '2026-07-14 16:45' },
      { id: 4, applicantId: 104, applicantName: '赵雷', applicantAvatar: '', applicantAge: 21, applicantSchool: '华中科技大学', applicantMajor: '统计学', applicantEducation: '本科', applicantExperience: '应届生', applicantSkills: 'Python, SQL, Excel', applicantRegion: '北京-朝阳区', applicantType: '互联网/IT-数据分析师', applicantSalary: '4k-6k', jobTitle: '数据分析实习生', status: 1, interviewTime: '2026-07-20 10:00', interviewLocation: '北京朝阳区望京SOHO', rejectReason: '', createTime: '2026-07-13 09:15' },
      { id: 5, applicantId: 105, applicantName: '陈雪', applicantAvatar: '', applicantAge: 27, applicantSchool: '复旦大学', applicantMajor: '金融学', applicantEducation: '硕士', applicantExperience: '4年经验', applicantSkills: 'CFA, 风险管理, 产品设计', applicantRegion: '上海-浦东新区', applicantType: '金融-金融产品经理', applicantSalary: '28k-40k', jobTitle: '金融产品经理', status: 4, interviewTime: '', interviewLocation: '', rejectReason: '经验方向不匹配', createTime: '2026-07-12 11:00' }
    ]
    return new Promise((resolve) => { resolve(mock) })
  }

  static processRequest(requestId: number, data: RecruiterUpdateStatusRequest): Promise<boolean> {
    return new Promise((resolve) => { resolve(true) })
  }
}
