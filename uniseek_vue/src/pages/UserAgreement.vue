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
  <div class="agreement-page">
    <div class="agreement-container">
      <!-- 页面头部 -->
      <div class="page-header">
        <button class="back-btn" @click="goBack">
          <el-icon :size="18"><ArrowLeft /></el-icon>
          <span>返回</span>
        </button>
        <h1 class="page-title">UniSeek 用户协议</h1>
        <p class="page-subtitle">请仔细阅读以下条款</p>
      </div>

      <!-- 协议内容 -->
      <div class="agreement-content">
        <div class="content-section">
          <h2>一、协议总则</h2>
          <p>欢迎使用 UniSeek 智能兼职招聘平台（以下简称"本平台"）。本用户协议（以下简称"本协议"）是您与 UniSeek 平台运营方（以下简称"我们"）之间关于使用本平台服务所订立的协议。</p>
          <p>请您务必审慎阅读、充分理解各条款内容，特别是免除或者限制责任的条款、法律适用和争议解决条款。当您按照注册页面提示填写信息、阅读并同意本协议且完成全部注册程序后，即表示您已充分阅读、理解并接受本协议的全部内容，并与 UniSeek 平台达成一致，成为 UniSeek 平台的"用户"。</p>
          <p>如果您不同意本协议的任意内容，或者无法准确理解我们对条款的解释，请不要进行后续操作。</p>
        </div>

        <div class="content-section">
          <h2>二、账号注册与使用规范</h2>
          <p><strong>2.1 账号注册</strong></p>
          <p>您在使用本平台服务前，需要注册一个账号。注册时，您应当提供真实、准确、完整的个人信息，并在信息发生变更时及时更新。</p>
          <p><strong>2.2 账号安全</strong></p>
          <p>您应当妥善保管您的账号和密码，并对该账号下的所有行为承担法律责任。如发现账号被盗用或存在其他安全问题，请立即通知我们。</p>
          <p><strong>2.3 账号使用限制</strong></p>
          <p>您不得将账号转让、出售或出借给他人使用。每个用户只能注册一个账号，不得重复注册。</p>
        </div>

        <div class="content-section">
          <h2>三、用户权利与义务</h2>
          <p><strong>3.1 用户权利</strong></p>
          <p>您有权依据本协议使用本平台提供的各项服务。您有权对我们的服务提出意见和建议。您有权查询、更正、删除您的个人信息。</p>
          <p><strong>3.2 用户义务</strong></p>
          <p>您应当遵守国家法律法规和本协议的规定，不得利用本平台从事违法违规活动。您应当保证上传的信息真实、准确、完整，不得发布虚假信息。您应当尊重其他用户的合法权益，不得侵犯他人隐私、名誉等权利。</p>
        </div>

        <div class="content-section">
          <h2>四、服务内容与限制</h2>
          <p><strong>4.1 服务内容</strong></p>
          <p>本平台为用户提供兼职招聘信息发布、简历投递、职位搜索、企业展示等服务。具体服务内容以平台实际提供为准。</p>
          <p><strong>4.2 服务限制</strong></p>
          <p>我们有权根据业务需要调整服务内容，包括但不限于暂停、终止部分或全部服务。如因系统维护、升级等原因导致服务中断，我们将提前公告。</p>
        </div>

        <div class="content-section">
          <h2>五、知识产权声明</h2>
          <p>本平台的所有内容，包括但不限于文字、图片、音频、视频、软件、程序、版面设计等，其知识产权均归我们所有，受《中华人民共和国著作权法》《中华人民共和国商标法》《中华人民共和国专利法》等法律法规保护。</p>
          <p>未经我们书面许可，任何单位或个人不得以任何方式使用、复制、传播、展示、翻录上述内容。</p>
        </div>

        <div class="content-section">
          <h2>六、免责声明</h2>
          <p><strong>6.1 信息真实性</strong></p>
          <p>本平台上的招聘信息、企业信息等均由用户自行发布，我们无法保证所有信息的真实性、准确性和合法性。请您在求职或招聘过程中自行核实相关信息，谨慎决策。</p>
          <p><strong>6.2 服务中断</strong></p>
          <p>因不可抗力、系统故障、网络问题等原因导致服务中断或数据丢失，我们不承担责任，但将尽力恢复服务。</p>
          <p><strong>6.3 第三方链接</strong></p>
          <p>本平台可能包含指向第三方网站或服务的链接，这些链接仅为方便用户提供。我们对第三方网站的内容、隐私政策或做法不承担任何责任。</p>
        </div>

        <div class="content-section">
          <h2>七、协议修改与终止</h2>
          <p><strong>7.1 协议修改</strong></p>
          <p>我们有权根据需要随时修改本协议的条款。修改后的协议将在平台公布，自公布之日起生效。如果您继续使用本平台服务，即表示您接受修改后的协议。</p>
          <p><strong>7.2 协议终止</strong></p>
          <p>如您违反本协议的任何条款，我们有权立即终止或暂停您使用本平台的权利，并保留追究法律责任的权利。您也可随时注销账号，终止本协议。</p>
        </div>

        <div class="content-section">
          <h2>八、争议解决</h2>
          <p>本协议的订立、执行、解释及争议解决均适用中华人民共和国法律。因本协议产生的任何争议，双方应首先通过友好协商解决。协商不成的，任何一方均有权向我们所在地有管辖权的人民法院提起诉讼。</p>
        </div>

        <div class="content-section">
          <h2>九、联系方式</h2>
          <p>如果您对本协议有任何疑问、意见或建议，请通过以下方式联系我们：</p>
          <p>邮箱：support@uniseek.com</p>
          <p>电话：400-XXX-XXXX</p>
          <p>地址：[公司地址]</p>
        </div>

        <div class="content-footer">
          <p>本协议自 2024 年 1 月 1 日起生效。</p>
          <p>UniSeek 团队保留对本协议的最终解释权。</p>
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
.agreement-page {
  min-height: 100vh;
  /* 防止被 #app 弹性容器压缩，确保背景随文档内容完整铺开 */
  flex-shrink: 0;
  background: #f5f7fa;
  padding: 24px;
  box-sizing: border-box;
}

.agreement-container {
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
  background: rgba(23, 98, 251, 0.06);
  border: 1px solid rgba(23, 98, 251, 0.2);
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 16px;
}

.back-btn:hover {
  background: rgba(23, 98, 251, 0.12);
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

.agreement-content {
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
  .agreement-page {
    padding: 16px 12px;
  }

  .page-header {
    padding: 20px 16px;
  }

  .page-title {
    font-size: 22px;
  }

  .agreement-content {
    padding: 20px 16px;
  }

  .content-section h2 {
    font-size: 16px;
  }

  .content-section p {
    font-size: 13px;
  }
}
</style>
