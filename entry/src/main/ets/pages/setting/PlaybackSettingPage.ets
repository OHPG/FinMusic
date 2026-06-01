import { window } from '@kit.ArkUI'
import { CommonConstants, ToolBar } from '@ohpg/fin-framework'
import { AVPlayerKit, AVPlayerPrefer } from '@ohpg/player'
import { AppPrefer } from '../../prefer/AppPrefer'
import { groupAttributeModifier, itemDividerBuilder, windowAttributeModifier } from '../../style/Modifier'

@Entry
@Component
struct PlaybackSettingPage {

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  private playerPrefer: AVPlayerPrefer = AVPlayerKit.getPrefer()

  private appPrefer: AppPrefer = AppStorage.get<AppPrefer>(AppPrefer.PREFER)!

  @State autoNext: boolean = true

  @State castEnabled: boolean = true

  aboutToAppear(): void {
    this.autoNext = this.playerPrefer.getAutoNext()
    this.castEnabled = this.appPrefer.isCastEnabled()
  }

  build() {
    Column({ space: CommonConstants.SPACE_8 }) {
      ToolBar({ title: $r('app.string.prefer_playback') })

      Scroll() {
        Column({ space: CommonConstants.SPACE_8 }) {

          Column() {
            Row({ space: CommonConstants.SPACE_12 }) {
              SymbolGlyph($r('sys.symbol.music_note_list_fill'))
                .fontSize(24)
                .fontColor([$r('sys.color.ohos_id_color_text_primary')])
              Text($r('app.string.prefer_auto_next'))
                .fontSize(18)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.autoNext })
                .onChange((isOn: boolean) => {
                  this.autoNext = isOn
                  this.playerPrefer.setAutoNext(isOn)
                })
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({ left: CommonConstants.SPACE_16, right: CommonConstants.SPACE_16 })

            itemDividerBuilder()

            Row({ space: CommonConstants.SPACE_12 }) {
              SymbolGlyph($r('sys.symbol.statusbar_cast'))
                .fontSize(24)
                .fontColor([$r('sys.color.ohos_id_color_text_primary')])
              Text($r('app.string.prefer_cast'))
                .fontSize(18)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.castEnabled })
                .onChange((isOn: boolean) => {
                  this.castEnabled = isOn
                  this.appPrefer.setCastEnabled(isOn)
                })
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({ left: CommonConstants.SPACE_16, right: CommonConstants.SPACE_16 })
          }
          .attributeModifier(groupAttributeModifier)

        }
        .padding({
          bottom: px2vp(this.avoidArea?.bottomRect.height)
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

  aboutToDisappear(): void {
    this.playerPrefer.flush()
  }

}
