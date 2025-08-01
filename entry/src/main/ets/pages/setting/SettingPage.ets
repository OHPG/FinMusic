import { router, window } from '@kit.ArkUI'
import { WebTool } from '@ohpg/fin-core'
import { FinRouter, ToolBar } from '@ohpg/fin-framework'
import { Repository } from '../../data/Repository'
import { HomeToolBar } from '../../widget/bar/HomeToolBar'
import { CommonConstants } from '../../common/CommonConstants'

@Entry
@Component
struct AboutPage {

  private repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp('playerHeight') currentAvoidMedia: number = 0

  @Builder
  preferItemBuilder(icon: Resource, title: ResourceStr, callback: Callback<void>) {
    Row({space: CommonConstants.SPACE_12}) {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([$r('sys.color.ohos_id_color_text_primary')])
      Text(title)
        .fontSize(18)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
      Blank()
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(48)
    .padding({
      left: CommonConstants.SPACE_16,
      right: CommonConstants.SPACE_16
    })
    .onClick(() => {
      callback()
    })
  }

  build() {
    Column({space: CommonConstants.SPACE_8}) {
      ToolBar({
        title: $r('app.string.prefer')
      })

      Column({ space: CommonConstants.SPACE_12}) {
        Row() {
          Text($r('app.string.prefer_current_server'))
          Text(this.repository?.getActiveInfo()?.serverInfo.serverName)
        }
        Row() {
          Text($r('app.string.prefer_current_address'))
          Text(this.repository?.getActiveInfo()?.addressInfo.address)
        }
        Row() {
          Text($r('app.string.prefer_current_user'))
          Text(this.repository?.getActiveInfo()?.userInfo.userName)
        }
      }
      .width(CommonConstants.FULL_PERCENT)
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16
      })

      this.preferItemBuilder($r('sys.symbol.externaldrive'), $r('app.string.prefer_server'), () => {
        FinRouter.editServer()
      })
      this.preferItemBuilder($r('sys.symbol.worldclock'), $r('app.string.prefer_address'), () => {
        FinRouter.editAddress()
      })
      this.preferItemBuilder($r('sys.symbol.person'), $r('app.string.prefer_user'), () => {
        FinRouter.editUser()
      })

      this.preferItemBuilder($r('sys.symbol.message'), $r('app.string.prefer_about'), () => {
        router.push({url: "pages/about/AboutPage"})
      })

      this.preferItemBuilder($r('sys.symbol.doc_plaintext'), $r('app.string.prefer_privacy'), () => {
        WebTool.openBrowser(getContext(), "https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1571936775037801408")
      })

      Blank()

      Text("ICP备案：豫ICP备2025110731号-3A")
        .fontColor($r('sys.color.ohos_id_color_component_activated'))
        .margin(CommonConstants.SPACE_16)
        .onClick(() => {
          WebTool.openBrowser(getContext(), "https://beian.miit.gov.cn")
        })

    }
    .padding({
      bottom: px2vp(this.currentAvoidArea?.bottomRect.height) + this.currentAvoidMedia
    })
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }
}