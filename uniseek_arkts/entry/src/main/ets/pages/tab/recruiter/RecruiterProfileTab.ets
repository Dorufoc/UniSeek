import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { AuthService } from '../../../services/AuthService';
import { RecruiterService } from '../../../services/RecruiterService';
import { AUDIT_STATUS_LABELS } from '../../../services/RecruiterTypes';

const PREF_NAME = 'user_profile_db';
const KEY_USERNAME = 'username';

@Component
export struct RecruiterProfileTab {
  @State username: string = ''
  @State isVerified: boolean = false
  @State enterpriseAuditStatus: number = -1

  aboutToAppear(): void {
    this.loadUsername()
    this.isVerified = AuthService.isRealNameVerified()
    RecruiterService.getEnterpriseInfo().then((info) => {
      if (info) {
        this.enterpriseAuditStatus = info.auditStatus
      }
    })
  }

  loadUsername(): void {
    let pref = preferences.getPreferencesSync(getContext(), { name: PREF_NAME })
    let saved = pref.getSync(KEY_USERNAME, '') as string
    if (saved) {
      this.username = saved
    } else {
      let num = Math.floor(10000 + Math.random() * 90000)
      this.username = '企业' + num
      pref.putSync(KEY_USERNAME, this.username)
      pref.flushSync()
    }
  }

  build() {
    Column() {
      Column() {
        Row() {
          Image($r('app.media.theme'))
            .width(68)
            .height(68)
            .borderRadius(34)

          Column() {
            Text(this.username)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Row() {
              Text(this.isVerified ? '已实名' : '去实名')
                .fontSize(13)
                .fontColor(this.isVerified ? '#8CE0FF' : '#FFFFFF')
              if (!this.isVerified) {
                Image($r('app.media.right_arrow'))
                  .width(14)
                  .height(14)
                  .fillColor('#FFFFFF')
                  .margin({ left: 2 })
              }
            }
            .margin({ top: 6 })
            .onClick(() => {
              if (!this.isVerified) {
                router.pushUrl({ url: 'pages/RealNameAuthPage' })
              }
            })

            Row() {
              Text('企业资质：')
                .fontSize(13)
                .fontColor('#CCCCCC')
              Text(this.enterpriseAuditStatus >= 0 ? AUDIT_STATUS_LABELS[this.enterpriseAuditStatus] : '未提交')
                .fontSize(13)
                .fontColor(this.enterpriseAuditStatus === 1 ? '#8CE0FF' : '#FFFFFF')
              if (this.enterpriseAuditStatus !== 1) {
                Image($r('app.media.right_arrow'))
                  .width(14)
                  .height(14)
                  .fillColor('#FFFFFF')
                  .margin({ left: 2 })
              }
            }
            .margin({ top: 4 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/RecruiterEnterprisePage' })
            })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 16 })

          Image($r('app.media.right_arrow'))
            .width(16)
            .height(16)
            .onClick(() => {
              router.pushUrl({ url: 'pages/ProfileDetailPage' })
            })
        }
        .width('100%')
        .height(116)
        .padding({ left: 25, right: 25 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')

      Column() {
        Divider()
          .width('100%')
          .color('#F0F0F0')
          .height(6)

        Column() {
          this.menuItemCheck('资质审核', $r('app.media.resume2'), () => {
            if (!this.isVerified) {
              this.getUIContext().showAlertDialog({ message: '请先完成实名认证', confirm: { value: '确定', action: () => {} } })
              return
            }
            router.pushUrl({ url: 'pages/RecruiterEnterprisePage' })
          })
          Divider().width('100%').color('#F0F0F0').height(0.5)
          this.menuItemCheck('发布职位', $r('app.media.resume1'), () => {
            if (this.enterpriseAuditStatus !== 1) {
              this.getUIContext().showAlertDialog({ message: '企业资质审核未通过，暂无法发布职位', confirm: { value: '确定', action: () => {} } })
              return
            }
            router.pushUrl({ url: 'pages/RecruiterPublishJobPage' })
          })
          Divider().width('100%').color('#F0F0F0').height(0.5)
          this.menuItemCheck('请求处理', $r('app.media.star'), () => {
            router.pushUrl({ url: 'pages/RecruiterRequestsPage' })
          })
          Divider().width('100%').color('#F0F0F0').height(0.5)
          this.menuItemCheck('设置', $r('app.media.setting'), () => {
            router.pushUrl({ url: 'pages/SettingsPage' })
          })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
      }
      .width('80%')
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#ff4eb2e9', 0], ['#ff18e2fd', 0.08], ['#ffa1e7e4', 0.16], ['#FFFFFF', 0.24], ['#FFFFFF', 1]]
    })
  }

  @Builder menuItemCheck(text: string, icon: Resource, onClick: () => void) {
    Row() {
      Image(icon)
        .width(22)
        .height(22)
        .margin({ right: 12 })
      Text(text)
        .fontSize(16)
        .fontColor('#333333')
    }
    .width('100%')
    .height(56)
    .onClick(onClick)
  }
}
