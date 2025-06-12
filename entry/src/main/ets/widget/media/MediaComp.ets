import { router } from "@kit.ArkUI"
import { avSession } from "@kit.AVSessionKit"
import { AudioManager } from "../../player/AudioManager"

@Component
export struct MediaMenu {

  private audioManager: AudioManager = AppStorage.get(AudioManager.AUDIO_MANAGER)!

  @State mediaMetadata?: avSession.AVMetadata = undefined

  @State mediaState?: avSession.PlaybackState = avSession.PlaybackState.PLAYBACK_STATE_INITIAL

  private metadataCallback: ((data: avSession.AVMetadata) => void) = (metadata) => {
    this.updateMetadata(metadata)
  }

  private stateCallback: ((data: avSession.AVPlaybackState) => void) = (state) => {
    this.updatePlaybackState(state)
  }

  aboutToAppear(): void {
    let metadata = this.audioManager.getAudioControl().getMetadata()
    if (metadata) {
      this.updateMetadata(metadata)
    }
    let playbackState = this.audioManager.getAudioControl().getPlaybackState()
    if (playbackState) {
      this.updatePlaybackState(playbackState)
    }
    this.audioManager.getAudioControl().onMetadataChange(this.metadataCallback)
    this.audioManager.getAudioControl().onPlaybackStateChange(this.stateCallback)
  }

  build() {
    if (this.mediaMetadata) {
      SymbolGlyph(this.mediaState === avSession.PlaybackState.PLAYBACK_STATE_PLAY
        ? $r('sys.symbol.pause_round_triangle_fill')
        :  $r('sys.symbol.play_round_triangle_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.font_primary')])
        .onClick(() => {
          router.pushUrl({url: "pages/player/PlayerPage"})
        })
    }
  }

  private updateMetadata(metadata: avSession.AVMetadata) {
    this.mediaMetadata = metadata
  }

  private updatePlaybackState(state: avSession.AVPlaybackState) {
    this.mediaState = state.state
  }

  aboutToDisappear(): void {
    this.audioManager.getAudioControl().offMetadataChange(this.metadataCallback)
    this.audioManager.getAudioControl().offPlaybackStateChange(this.stateCallback)
  }

}