<script setup lang="ts">
import { useRouter } from 'vue-router'
import { ArrowLeft } from '@element-plus/icons-vue'

const router = useRouter()

// 返回登录页
const goBack = () => {
  router.push('/login')
}
</script>

<template>
  <div class="privacy-page">
    <div class="privacy-container">
      <!-- 页面头部 -->
      <div class="page-header">
        <button class="back-btn" @click="goBack">
          <el-icon :size="18"><ArrowLeft /></el-icon>
          <span>返回</span>
        </button>
        <h1 class="page-title">UniSeek 隐私政策</h1>
        <p class="page-subtitle">我们重视您的隐私保护</p>
      </div>

      <!-- 隐私政策内容 -->
      <div class="privacy-content">
        <div class="content-section">
          <h2>一、隐私政策总则</h2>
          <p>UniSeek 智能兼职招聘平台（以下简称"本平台"或"我们"）非常重视用户的隐私保护。本隐私政策（以下简称"本政策"）旨在向您说明我们如何收集、使用、存储和保护您的个人信息，以及您享有的相关权利。</p>
          <p>请您在使用本平台服务前，仔细阅读并充分理解本政策的全部内容。当您注册、登录或使用本平台服务时，即表示您已阅读、理解并同意接受本政策的全部内容。</p>
          <p>如果您不同意本政策的任何内容，请立即停止使用本平台服务。</p>
        </div>

        <div class="content-section">
          <h2>二、信息收集范围</h2>
          <p><strong>2.1 个人信息</strong></p>
          <p>为向您提供服务，我们可能会收集以下个人信息：</p>
          <ul>
            <li>基本信息：昵称、手机号码、邮箱地址</li>
            <li>求职信息：简历内容（教育经历、工作经历、技能特长等）</li>
            <li>企业信息（招聘者）：企业名称、营业执照、联系人信息</li>
            <li>实名认证信息：真实姓名、身份证号码（仅在需要实名认证时收集）</li>
          </ul>
          <p><strong>2.2 设备信息</strong></p>
          <p>当您使用本平台服务时，我们可能会自动收集您使用的设备信息，包括：</p>
          <ul>
            <li>设备型号、操作系统版本</li>
            <li>唯一设备标识符</li>
            <li>IP 地址</li>
            <li>浏览器类型和语言</li>
            <li>访问时间</li>
          </ul>
          <p><strong>2.3 日志信息</strong></p>
          <p>当您使用本平台服务时，我们可能会收集您的使用日志信息，包括：</p>
          <ul>
            <li>您访问的页面和功能</li>
            <li>操作记录（如投递职位、收藏职位等）</li>
            <li>搜索记录</li>
            <li>错误日志</li>
          </ul>
        </div>

        <div class="content-section">
          <h2>三、信息使用方式</h2>
          <p>我们收集您的信息主要用于以下目的：</p>
          <ul>
            <li><strong>提供核心服务：</strong>为您展示职位信息、处理简历投递、管理招聘流程</li>
            <li><strong>身份验证：</strong>验证您的身份，确保账号安全</li>
            <li><strong>服务优化：</strong>分析使用数据，改进和优化平台功能</li>
            <li><strong>安全保障：</strong>检测和防止欺诈、滥用等违规行为</li>
            <li><strong>通知提醒：</strong>向您发送服务通知、面试邀请、系统更新等信息</li>
            <li><strong>法律合规：</strong>遵守相关法律法规的要求</li>
          </ul>
        </div>

        <div class="content-section">
          <h2>四、信息存储与保护</h2>
          <p><strong>4.1 信息存储</strong></p>
          <p>您的个人信息存储在我们位于中华人民共和国境内的服务器上。我们采用加密存储、访问控制等安全措施保护您的信息。</p>
          <p><strong>4.2 存储期限</strong></p>
          <p>我们仅在实现服务目的所必需的最短时间内保留您的个人信息。具体存储期限如下：</p>
          <ul>
            <li>账号信息：账号存续期间</li>
            <li>简历信息：账号存续期间及注销后 30 天</li>
            <li>日志信息：不超过 6 个月</li>
          </ul>
          <p><strong>4.3 安全保护</strong></p>
          <p>我们采取以下措施保护您的信息安全：</p>
          <ul>
            <li>使用 HTTPS 加密传输数据</li>
            <li>密码采用加密算法存储</li>
            <li>限制员工访问个人信息的权限</li>
            <li>定期进行安全审计和漏洞修复</li>
          </ul>
          <p>尽管我们会尽最大努力保护您的信息安全，但请理解互联网环境并非百分之百安全。我们无法保证信息的绝对安全性。</p>
        </div>

        <div class="content-section">
          <h2>五、信息共享与披露</h2>
          <p><strong>5.1 共享原则</strong></p>
          <p>未经您同意，我们不会与任何第三方共享您的个人信息，但以下情况除外：</p>
          <ul>
            <li>获得您的明确同意后</li>
            <li>根据法律法规的要求</li>
            <li>为保护国家安全、公共利益或他人合法权益</li>
            <li>在紧急情况下，为保护用户或公众的人身安全</li>
          </ul>
          <p><strong>5.2 招聘场景</strong></p>
          <p>当您投递简历或申请职位时，您同意将简历信息提供给对应的招聘企业。招聘企业将根据其自身需求使用您的信息，我们建议您在使用服务前了解招聘企业的隐私政策。</p>
          <p><strong>5.3 第三方服务</strong></p>
          <p>我们可能会与第三方服务提供商合作，为您提供更完善的服务（如短信验证、云存储等）。这些第三方服务提供商将受到严格的数据保护义务约束。</p>
        </div>

        <div class="content-section">
          <h2>六、Cookie 使用</h2>
          <p><strong>6.1 Cookie 说明</strong></p>
          <p>为提升您的使用体验，我们可能会使用 Cookie 或类似技术。Cookie 是存储在您的设备上的小型文本文件，帮助我们记住您的偏好设置和登录状态。</p>
          <p><strong>6.2 Cookie 类型</strong></p>
          <p>我们使用的 Cookie 包括：</p>
          <ul>
            <li><strong>必要 Cookie：</strong>用于实现网站基本功能，如登录状态保持</li>
            <li><strong>性能 Cookie：</strong>用于收集访问数据，优化网站性能</li>
            <li><strong>功能 Cookie：</strong>用于记住您的偏好设置</li>
          </ul>
          <p><strong>6.3 Cookie 管理</strong></p>
          <p>您可以通过浏览器设置管理或删除 Cookie。请注意，如果您禁用 Cookie，可能无法正常使用本平台的部分功能。</p>
        </div>

        <div class="content-section">
          <h2>七、未成年人保护</h2>
          <p>本平台主要面向年满 16 周岁的用户。如果您是未满 16 周岁的未成年人，请在监护人的陪同下阅读本政策，并在征得监护人同意后使用本平台服务。</p>
          <p>如果我们发现您在未获得监护人同意的情况下收集了未成年人的个人信息，我们将尽快删除相关数据。</p>
        </div>

        <div class="content-section">
          <h2>八、您的权利</h2>
          <p>根据相关法律法规，您享有以下权利：</p>
          <ul>
            <li><strong>访问权：</strong>您可以查看我们收集的您的个人信息</li>
            <li><strong>更正权：</strong>当您发现信息有误时，可以要求我们更正</li>
            <li><strong>删除权：</strong>在特定情况下，您可以要求我们删除您的信息</li>
            <li><strong>撤回同意权：</strong>您可以随时撤回之前给予的同意</li>
            <li><strong>注销账号：</strong>您可以随时注销账号，我们将删除您的个人信息</li>
          </ul>
          <p>如需行使上述权利，请通过本政策底部的联系方式与我们联系。</p>
        </div>

        <div class="content-section">
          <h2>九、隐私政策更新</h2>
          <p>我们可能会不时修订本隐私政策。当政策发生重大变更时，我们会在平台显著位置通知您，或向您发送电子邮件通知。</p>
          <p>修订后的政策自公布之日起生效。如果您在政策更新后继续使用本平台服务，即表示您接受修订后的政策。</p>
        </div>

        <div class="content-section">
          <h2>十、联系我们</h2>
          <p>如果您对本隐私政策有任何疑问、意见或建议，或需要行使您的权利，请通过以下方式联系我们：</p>
          <p>邮箱：privacy@uniseek.com</p>
          <p>电话：400-XXX-XXXX</p>
          <p>地址：[公司地址]</p>
          <p>我们将在收到您的请求后 15 个工作日内回复。</p>
        </div>

        <div class="content-footer">
          <p>本隐私政策自 2024 年 1 月 1 日起生效。</p>
          <p>UniSeek 团队保留对本政策的最终解释权。</p>
        </div>
      </div>

      <!-- 底部操作 -->
      <div class="page-footer">
        <button class="back-btn-large" @click="goBack">
          <el-icon :size="20"><ArrowLeft /></el-icon>
          <span>返回登录页</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.privacy-page {
  min-height: 100vh;
  /* 防止被 #app 弹性容器压缩，确保背景随文档内容完整铺开 */
  flex-shrink: 0;
  background: #f5f7fa;
  padding: 24px;
  box-sizing: border-box;
}

.privacy-container {
  max-width: 800px;
  margin: 0 auto;
}

.page-header {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 20px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  text-align: center;
}

.back-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  font-size: 14px;
  color: #1762FB;
  background: rgba(0, 122, 255, 0.06);
  border: 1px solid rgba(0, 122, 255, 0.2);
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 16px;
}

.back-btn:hover {
  background: rgba(0, 122, 255, 0.12);
}

.page-title {
  font-size: 28px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 8px;
}

.page-subtitle {
  font-size: 14px;
  color: #666;
  margin: 0;
}

.privacy-content {
  background: #fff;
  border-radius: 12px;
  padding: 32px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 20px;
}

.content-section {
  margin-bottom: 28px;
}

.content-section:last-child {
  margin-bottom: 0;
}

.content-section h2 {
  font-size: 18px;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0 0 12px;
  padding-left: 12px;
  border-left: 3px solid #1762FB;
  line-height: 1.4;
}

.content-section p {
  font-size: 14px;
  line-height: 1.8;
  color: #333;
  margin: 0 0 12px;
}

.content-section p:last-child {
  margin-bottom: 0;
}

.content-section strong {
  color: #1a1a2e;
  font-weight: 600;
}

.content-section ul {
  margin: 8px 0 12px 20px;
  padding: 0;
}

.content-section li {
  font-size: 14px;
  line-height: 1.8;
  color: #333;
  margin-bottom: 6px;
}

.content-section li:last-child {
  margin-bottom: 0;
}

.content-footer {
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid #f0f0f5;
  text-align: center;
}

.content-footer p {
  font-size: 13px;
  color: #888;
  margin: 0 0 8px;
  line-height: 1.6;
}

.content-footer p:last-child {
  margin-bottom: 0;
}

.page-footer {
  text-align: center;
  padding: 20px 0;
}

.back-btn-large {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 32px;
  font-size: 15px;
  font-weight: 500;
  color: #fff;
  background: #1762FB;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.back-btn-large:hover {
  opacity: 0.92;
}

.back-btn-large:active {
  transform: scale(0.98);
}

@media (max-width: 768px) {
  .privacy-page {
    padding: 16px 12px;
  }

  .page-header {
    padding: 20px 16px;
  }

  .page-title {
    font-size: 22px;
  }

  .privacy-content {
    padding: 20px 16px;
  }

  .content-section h2 {
    font-size: 16px;
  }

  .content-section p,
  .content-section li {
    font-size: 13px;
  }

  .content-section ul {
    margin-left: 16px;
  }
}
</style>
