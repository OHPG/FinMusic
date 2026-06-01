import { avSession } from "@kit.AVSessionKit"
import { AVPlayerContext, MediaControl } from "@ohpg/player"
import { AppRouter } from "../../router/AppRouter"

@Component
export struct MediaMenu {

  @StorageProp(AVPlayerContext.AV_PLAYER_CONTEXT) @Watch('onPlayerContextChange') playerContextRef?: object = undefined

  @State mediaMetadata?: avSession.AVMetadata = undefined

  @State mediaState?: avSession.PlaybackState = avSession.PlaybackState.PLAYBACK_STATE_INITIAL

  private control?: MediaControl

  private metadataCallback: ((data: avSession.AVMetadata) => void) = (metadata) => {
    this.updateMetadata(metadata)
  }

  private stateCallback: ((data: avSession.AVPlaybackState) => void) = (state) => {
    this.updatePlaybackState(state)
  }

  aboutToAppear(): void {
    let playerContext = AppStorage.get<AVPlayerContext>(AVPlayerContext.AV_PLAYER_CONTEXT)
    this.bindControl(playerContext)
  }

  private onPlayerContextChange(): void {
    let playerContext = AppStorage.get<AVPlayerContext>(AVPlayerContext.AV_PLAYER_CONTEXT)
    this.bindControl(playerContext)
  }

  private bindControl(playerContext?: AVPlayerContext): void {
    if (this.control) {
      this.control.offMetadataChange(this.metadataCallback)
      this.control.offPlaybackStateChange(this.stateCallback)
      this.control = undefined
    }
    if (!playerContext) {
      this.mediaMetadata = undefined
      this.mediaState = avSession.PlaybackState.PLAYBACK_STATE_INITIAL
      return
    }
    this.control = playerContext.control
    let metadata = this.control.getMetadata()
    if (metadata) {
      this.updateMetadata(metadata)
    }
    let playbackState = this.control.getPlaybackState()
    if (playbackState) {
      this.updatePlaybackState(playbackState)
    }
    this.control.onMetadataChange(this.metadataCallback)
    this.control.onPlaybackStateChange(this.stateCallback)
  }

  build() {
    if (this.mediaMetadata) {
      SymbolGlyph(this.mediaState === avSession.PlaybackState.PLAYBACK_STATE_PLAY
        ? $r('sys.symbol.pause_round_triangle_fill')
        :  $r('sys.symbol.play_round_triangle_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.font_primary')])
        .onClick(() => {
          AppRouter.goToPlayer(this.getUIContext())
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
    this.bindControl(undefined)
  }

}
