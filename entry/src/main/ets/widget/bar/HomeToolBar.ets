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

      Row() {
        Text(this.title)
          .fontSize($r('app.float.header_font_size'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .fontFamily(CommonConstants.HARMONY_HEITI_BOLD_FONT_FAMILY)

        Blank()

        Row({ space: CommonConstants.SPACE_4 }) {
          SourceMenu()

          SymbolGlyph($r('sys.symbol.gearshape_fill'))
            .fontSize(22)
            .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
            .padding(8)
            .borderRadius(20)
            .onClick(() => {
              router.pushUrl({ url: "pages/setting/SettingPage" })
            })
        }
      }
      .alignItems(VerticalAlign.Center)
      .padding({
        left: $r('sys.float.ohos_id_default_padding_start'),
        right: $r('sys.float.ohos_id_default_padding_end')
      })
      .width(CommonConstants.FULL_PERCENT)
      .height($r('app.float.top_navigation_height'))
    }
  }

}