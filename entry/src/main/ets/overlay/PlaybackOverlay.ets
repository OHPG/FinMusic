import { avSession } from "@kit.AVSessionKit"
import { BreakpointSystem } from "@ohpg/fin-core"
import { AudioManager } from "../player/AudioManager"
import { CommonConstants } from "../common/CommonConstants"
import { ComponentContent, OverlayManager, window } from "@kit.ArkUI"
import { AbilityConstant, EnvironmentCallback, Configuration } from "@kit.AbilityKit"
import { AVPlayerContext, MediaControl } from "@ohpg/player"
import { PlayerRouter } from "@ohpg/widget"

export class PlaybackOverlay {

  private readonly context: UIContext

  private readonly audioManager: AudioManager = AppStorage.get(AudioManager.AUDIO_MANAGER)!

  private overlayManager?: OverlayManager

  private overlayNode?: ComponentContent<object>

  private environmentCallback: EnvironmentCallback = {

    onMemoryLevel: (level: AbilityConstant.MemoryLevel): void => {
    },

    onConfigurationUpdated: (config: Configuration): void => {
      this.overlayNode?.updateConfiguration()
    }
  }

  private environmentCallbackId?: number

  constructor(context: UIContext) {
    this.context = context
    AppStorage.setOrCreate("playerHeight", 60)
  }

  public attach() {
    this.overlayNode = new ComponentContent(this.context, wrapBuilder(playbackOverlayBuilder))
    this.overlayManager = this.context.getOverlayManager()
    this.overlayManager.addComponentContent(this.overlayNode)
    this.environmentCallbackId = this.context.getHostContext()?.getApplicationContext().on('environment', this.environmentCallback);
    console.info("FinMusic: PlaybackOverlay.attach, start resumeAudioQueue")
    this.audioManager.resumeAudioQueue()
  }

  public detach() {
    if (this.environmentCallbackId !== undefined) {
      this.context.getHostContext()?.getApplicationContext().off("environment", this.environmentCallbackId)
    }
    this.environmentCallbackId = undefined
    if (this.overlayNode && this.overlayManager) {
      this.overlayManager.removeComponentContent(this.overlayNode)
      this.overlayNode.dispose()
    }
    this.overlayNode = undefined
    this.overlayManager = undefined
  }

}

@Builder
function playbackOverlayBuilder() {
  PlaybackOverlayComp()
    .hitTestBehavior(HitTestMode.Transparent)
}

@Component
struct PlaybackOverlayComp {

  private audioManager: AudioManager = AppStorage.get(AudioManager.AUDIO_MANAGER)!

  @State mediaMetadata?: avSession.AVMetadata = undefined

  @State mediaState?: avSession.PlaybackState = avSession.PlaybackState.PLAYBACK_STATE_INITIAL

  @StorageProp("playerVisible") playerVisible: boolean = false

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  @StorageProp(AVPlayerContext.AV_PLAYER_CONTEXT) @Watch('onPlayerContextChange') playerContextRef?: object = undefined

  @State playRes: Resource = $r('sys.symbol.play_fill')

  private control?: MediaControl

  private metadataCallback: Callback<avSession.AVMetadata> = (metadata: avSession.AVMetadata) => {
    this.updateMetadata(metadata)
  }

  private stateCallback: Callback<avSession.AVPlaybackState> = (state: avSession.AVPlaybackState) => {
    this.updatePlaybackState(state)
  }

  aboutToAppear(): void {
    let playerContext = AppStorage.get<AVPlayerContext>(AVPlayerContext.AV_PLAYER_CONTEXT)
    console.info("FinMusic: PlaybackOverlayComp.aboutToAppear, playerContext=" + (playerContext !== undefined))
    this.bindControl(playerContext)
  }

  private onPlayerContextChange(): void {
    let playerContext = AppStorage.get<AVPlayerContext>(AVPlayerContext.AV_PLAYER_CONTEXT)
    console.info("FinMusic: PlaybackOverlayComp.onPlayerContextChange, playerContext=" + (playerContext !== undefined))
    this.bindControl(playerContext)
  }

  private bindControl(playerContext?: AVPlayerContext): void {
    // 先解绑旧的
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
      console.info("FinMusic: PlaybackOverlayComp bindControl metadata: " + metadata.title)
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
    Stack({alignContent: Alignment.Bottom}) {
      Row({space: CommonConstants.SPACE_8}) {
        Image(this.mediaMetadata?.mediaImage)
          .alt($r('app.media.default_cover'))
          .objectFit(ImageFit.Cover)
          .autoResize(true)
          .height(56)
          .width(56)

        Column({space: CommonConstants.SPACE_8}) {
          Text(this.mediaMetadata?.title)
            .fontSize($r('app.float.md_font_size'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .width('100%')
            .maxLines(1)

          Text(this.mediaMetadata?.artist)
            .fontSize($r('app.float.sm_font_size'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .width('100%')
            .maxLines(1)
        }
        .width('auto')
        .layoutWeight(1)

        Row() {
          Stack() {
            SymbolGlyph(this.playRes)
              .fontSize(32)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          }
          .width(48)
          .height(48)
          .onClick(() => {
            if (this.mediaState === avSession.PlaybackState.PLAYBACK_STATE_PLAY) {
              this.control?.pause()
            } else {
              this.control?.play()
            }
          })

          Stack() {
            SymbolGlyph($r('sys.symbol.forward_end_fill'))
              .fontSize(32)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          }
          .width(48)
          .height(48)
          .onClick(() => {
            this.control?.next()
          })
        }
        .margin({right: CommonConstants.SPACE_8})

      }
      .clip(true)
      .borderRadius($r('app.float.sm_border_radius'))
      .backgroundColor($r('app.color.action_bar_background'))
      .visibility((this.mediaMetadata && !this.playerVisible) ? Visibility.Visible : Visibility.Hidden)
      .margin({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16,
        bottom: px2vp(this.avoidArea?.bottomRect.height)})
      .width(this.currentBreakpoint >= WidthBreakpoint.WIDTH_MD ? 480 : 'auto')
      .height(56)
      .onClick(() => {
        PlayerRouter.push(this.getUIContext())
      })
    }
    .hitTestBehavior(HitTestMode.Transparent)
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  private updateMetadata(metadata: avSession.AVMetadata) {
    console.info("FinMusic: PlaybackOverlayComp.updateMetadata title=" + metadata.title)
    this.mediaMetadata = metadata
  }

  private updatePlaybackState(state: avSession.AVPlaybackState) {
    this.mediaState = state.state
    this.playRes = state.state === avSession.PlaybackState.PLAYBACK_STATE_PLAY
      ? $r('sys.symbol.pause_fill')
      : $r('sys.symbol.play_fill')
  }

  aboutToDisappear(): void {
    this.bindControl(undefined)
  }
}
