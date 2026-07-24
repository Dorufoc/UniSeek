// JobCard — 职位卡片包装组件
// 职责：为需要复用“完整职位卡片”的页面提供统一入口，内部委托 JobFeedCard 渲染

import { JobData } from '../services/ChatTypes';
import { JobFeedCard } from './JobFeedCard';

@Component
export struct JobCard {
  @Prop job: JobData = {
    id: '', title: '', company: '', salary: '',
    salaryMid: 0, popularity: 0, region: '',
    type: '', category: '', description: '',
    enterpriseId: 0, categoryId: 0, regionId: 0,
    salaryMin: 0, salaryMax: 0, salaryUnit: 0,
    jobType: 0, status: 0, hasApplied: false,
    applicationId: 0,
    tag: [], remainingQuota: 0,
    hrName: '', hrAvatar: '',
    enterpriseName: '', totalQuota: 0, address: '', deadline: '',
    applicationCount: 0, hasFavorited: false
  }

  build() {
    JobFeedCard({ job: this.job })
  }
}
