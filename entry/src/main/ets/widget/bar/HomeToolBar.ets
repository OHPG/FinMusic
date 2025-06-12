import { CommonConstants } from "../../common/CommonConstants"
import { router, window } from "@kit.ArkUI"
import { SourceMenu } from "../source/SourceMenu"

@Component
export struct HomeToolBar {

  @Require @Prop title: ResourceStr

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  build() {
    Column() {
      Column()
        .width('100%')
        .height(px2vp(this.avoidArea?.topRect.height))

      Row({space: CommonConstants.SPACE_16}) {
        Text(this.title)
          .fontSize($r('app.float.header_font_size'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .fontFamily(CommonConstants.HARMONY_HEITI_BOLD_FONT_FAMILY)
          .margin({ right: $r('app.float.sm_padding_margin') })

          Blank()

        // Search({ placeholder: $r('app.string.search') })
        //   .focusable(false)
        //   .fontColor($r('sys.color.ohos_id_color_text_primary'))
        //   .textFont({ size: $r('app.float.large_text_size') })
        //   .width($r('app.float.search_width'))
        //   .height($r('app.float.search_height'))
        //   .onClick(() => {
        //     this.getUIContext().getRouter().pushUrl({
        //       url: "pages/search/SearchPage"
        //     })
        //   })

        SourceMenu()

        SymbolGlyph($r('sys.symbol.gearshape_fill'))
          .fontSize($r('sys.float.Title_M'))
          // .fontSize($r('app.float.header_font_size'))
          .fontColor([$r('sys.color.font_primary')])
          .onClick(() => {
            router.pushUrl({url: "pages/setting/SettingPage"})
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_default_padding_start'),
        right: $r('sys.float.ohos_id_default_padding_end')
      })
      .width(CommonConstants.FULL_PERCENT)
      .height($r('app.float.top_navigation_height'))
    }
  }

}