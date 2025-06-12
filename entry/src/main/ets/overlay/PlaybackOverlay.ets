import { avSession } from "@kit.AVSessionKit"
import { BreakpointSystem } from "@ohpg/fin-core"
import { AudioManager } from "../player/AudioManager"
import { CommonConstants } from "../common/CommonConstants"
import { ComponentContent, OverlayManager, router, window } from "@kit.ArkUI"
import { AbilityConstant, EnvironmentCallback, Configuration } from "@kit.AbilityKit"

export class PlaybackOverlay {

  private readonly context: Context

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

  constructor(context: Context) {
    this.context = context
    // 注：目前属性变化传递不到封装好的列表组件，暂时写死。
    AppStorage.setOrCreate("playerHeight", 60)
  }

  public attach(context: UIContext) {
    this.overlayNode = new ComponentContent(context, wrapBuilder(playbackOverlayBuilder))
    this.overlayManager = context.getOverlayManager()
    this.overlayManager.addComponentContent(this.overlayNode)
    this.environmentCallbackId = this.context.getApplicationContext().on('environment', this.environmentCallback);
  }

  public detach() {
    if (this.environmentCallbackId !== undefined) {
      this.context.getApplicationContext().off("environment", this.environmentCallbackId)
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

  @State playRes: Resource = $r('sys.symbol.play_fill')

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
    Stack({alignContent: Alignment.Bottom}) {
      Row({space: CommonConstants.SPACE_8}) {
        Image(this.mediaMetadata?.mediaImage)
          .alt($r('app.media.alt'))
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
              this.audioManager.getAudioControl().pause()
            } else {
              this.audioManager.getAudioControl().play()
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
            this.audioManager.getAudioControl().next()
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
          router.pushUrl({url: "pages/player/PlayerPage"})
      })
    }
    .hitTestBehavior(HitTestMode.Transparent)
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  private updateMetadata(metadata: avSession.AVMetadata) {
    this.mediaMetadata = metadata
    // AppStorage.setOrCreate("playerHeight", 56)
  }

  private updatePlaybackState(state: avSession.AVPlaybackState) {
    this.mediaState = state.state
    this.playRes = state.state === avSession.PlaybackState.PLAYBACK_STATE_PLAY
      ? $r('sys.symbol.pause_fill')
      : $r('sys.symbol.play_fill')
  }

  aboutToDisappear(): void {
    this.audioManager.getAudioControl().offMetadataChange(this.metadataCallback)
    this.audioManager.getAudioControl().offPlaybackStateChange(this.stateCallback)
  }
}