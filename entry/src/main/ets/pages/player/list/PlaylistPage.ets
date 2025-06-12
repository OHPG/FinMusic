import { CommonConstants } from "../../../common/CommonConstants";
import { AudioItem } from "../../../player/AudioItem";
import { AudioManager } from "../../../player/AudioManager";

@Component
export struct PlaylistPage {

  @Require callback?: Callback<void> = undefined

  private audioManager: AudioManager = AppStorage.get(AudioManager.AUDIO_MANAGER)!

  aboutToAppear(): void {
    this.audioManager.getAudioQueue().getQueue()
  }

  build() {
    Column() {
      List() {
        ForEach(this.audioManager.getAudioQueue().getQueue(), (item: AudioItem, index) => {
          ListItem() {
            Text(`${index + 1} ${item.name}`)
              .height(60)
              .textAlign(TextAlign.Start)
              .width(CommonConstants.FULL_PERCENT)
          }
          .padding({
            left: CommonConstants.SPACE_16,
            right: CommonConstants.SPACE_16
          })
          .onClick(() => {
            this.audioManager.getAudioControl().playItem(item.id)
            this.callback?.()
          })
        })
      }
      .width(CommonConstants.FULL_PERCENT)
      .constraintSize({maxHeight: '60%'})
      .constraintSize({})
      .divider({
        color: $r('sys.color.ohos_id_divider_color'),
        strokeWidth: 1
      })
    }
    .padding(CommonConstants.SPACE_16)
    .width(CommonConstants.FULL_PERCENT)
  }

  aboutToDisappear(): void {

  }

}