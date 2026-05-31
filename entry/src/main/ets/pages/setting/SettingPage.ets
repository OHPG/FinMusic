import { window } from '@kit.ArkUI'
import { WebTool } from '@ohpg/fin-core'
import { CommonConstants, FinRouter, ToolBar } from '@ohpg/fin-framework'
import { Repository } from '../../data/Repository'
import { pasteboard } from '@kit.BasicServicesKit'
import { groupAttributeModifier, itemDividerBuilder, windowAttributeModifier } from '../../style/Modifier'
import { PreferItem } from '../../widget/comp/PreferItem'
import router from '@ohos.router'

@Entry
@Component
struct SettingPage {

  private repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  @StorageProp('playerHeight') currentAvoidMedia: number = 0

  build() {
    Column({ space: CommonConstants.SPACE_8 }) {
      ToolBar({ title: $r('app.string.prefer') })

      Scroll() {
        Column({ space: CommonConstants.SPACE_12 }) {

          // ===== Group 1: 服务器和用户信息 =====
          Column() {
            PreferItem({
              icon: $r('sys.symbol.externaldrive'),
              title: $r('app.string.prefer_server'),
              tips: this.repository?.getActiveInfo()?.serverInfo.serverName ?? '',
              callback: () => { FinRouter.editServer(this.getUIContext()) }
            })
            itemDividerBuilder()
            PreferItem({
              icon: $r('sys.symbol.worldclock'),
              title: $r('app.string.prefer_address'),
              tips: this.repository?.getActiveInfo()?.addressInfo.address ?? '',
              callback: () => { FinRouter.editAddress(this.getUIContext()) }
            })
            itemDividerBuilder()
            PreferItem({
              icon: $r('sys.symbol.person'),
              title: $r('app.string.prefer_user'),
              tips: this.repository?.getActiveInfo()?.userInfo.userName ?? '',
              callback: () => { FinRouter.editUser(this.getUIContext()) }
            })
          }
          .attributeModifier(groupAttributeModifier)

          // ===== Group 2: 播放器和缓存 =====
          Column() {
            PreferItem({
              icon: $r('sys.symbol.play_circle'),
              title: $r('app.string.prefer_playback'),
              callback: () => { router.pushUrl({ url: "pages/setting/PlaybackSettingPage" }) }
            })
            itemDividerBuilder()
            PreferItem({
              icon: $r('sys.symbol.folder'),
              title: $r('app.string.prefer_cache'),
              callback: () => { router.pushUrl({ url: "pages/setting/CacheSettingPage" }) }
            })
          }
          .attributeModifier(groupAttributeModifier)

          // ===== Group 3: 关于等 =====
          Column() {
            PreferItem({
              icon: $r('sys.symbol.message'),
              title: $r('app.string.prefer_about'),
              callback: () => { router.pushUrl({ url: "pages/about/AboutPage" }) }
            })
            itemDividerBuilder()
            PreferItem({
              icon: $r('sys.symbol.doc_plaintext'),
              title: $r('app.string.prefer_privacy'),
              callback: () => {
                WebTool.openBrowser(getContext(),
                  "https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1571936775037801408")
              }
            })
          }
          .attributeModifier(groupAttributeModifier)

          // QQ群
          Row({ space: CommonConstants.SPACE_4 }) {
            Text($r('app.string.prefer_about_qq_group'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))

            Text($r('app.string.prefer_about_qq_group_value'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_component_activated'))
              .onClick(() => {
                let text = getContext().resourceManager
                  .getStringSync($r('app.string.prefer_about_qq_group_value'))
                const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
                const systemPasteboard = pasteboard.getSystemPasteboard()
                systemPasteboard.setData(pasteboardData)
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.prefer_about_qq_group_copied') })
              })
          }
          .padding({ top: CommonConstants.SPACE_8 })

          // ICP 备案
          Row({ space: CommonConstants.SPACE_4 }) {
            Text("ICP备案：")
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))

            Text("豫ICP备2025110731号-3A")
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_component_activated'))
              .onClick(() => {
                WebTool.openBrowser(getContext(), "https://beian.miit.gov.cn")
              })
          }
          .padding({ bottom: CommonConstants.SPACE_16 })
        }
        .constraintSize({
          minHeight: "100%"
        })
        .padding({
          bottom: px2vp(this.avoidArea?.bottomRect.height) + this.currentAvoidMedia
        })
      }
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Fade)
      .width(CommonConstants.FULL_PERCENT)
      .height('auto')
      .layoutWeight(1)
    }
    .attributeModifier(windowAttributeModifier)
  }

}
