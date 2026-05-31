import { window } from '@kit.ArkUI'
import { CommonConstants, ToolBar } from '@ohpg/fin-framework'
import { windowAttributeModifier } from '../../style/Modifier'

@Entry
@Component
struct PlaybackSettingPage {

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  build() {
    Column({ space: CommonConstants.SPACE_8 }) {
      ToolBar({ title: $r('app.string.prefer_playback') })

      Scroll() {
        Column({ space: CommonConstants.SPACE_8 }) {
          // TODO: 播放器设置内容
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

}
