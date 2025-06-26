import { CommonConstants } from '../../common/CommonConstants'
import { BreakpointSystem, TimeTool } from '@ohpg/fin-core'
import { ToolBar } from '@ohpg/fin-framework'
import { window } from '@kit.ArkUI'
import { AudioManager } from '../../player/AudioManager'
import { avSession } from '@kit.AVSessionKit'
import { image } from '@kit.ImageKit'
import { PlayListSheet } from './PlayListSheet'
import { decodeBlurHash, getBlurHashAverageColor } from 'fast-blurhash'
import { Repository } from '../../data/Repository'
import { ImageType } from '@ohpg/jellyfin'

@Entry
@Component
struct PlayerPage {

  private readonly repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  private audioManager: AudioManager = AppStorage.get(AudioManager.AUDIO_MANAGER)!

  private playlistSheet: PlayListSheet = new PlayListSheet(this.getUIContext())

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;

  private blurhashKey: string | undefined | null

  @State primaryColor: ResourceColor = $r('sys.color.ohos_id_color_text_primary')

  @State blurhash?: PixelMap = undefined

  @State state?: avSession.PlaybackState = avSession.PlaybackState.PLAYBACK_STATE_INITIAL

  @State modeRes: Resource = $r('sys.symbol.repeat')

  @State playRes: Resource = $r('sys.symbol.play_fill')

  @State favourite: boolean = false

  @State progress: number = 0

  @State duration: number = 100

  @State title?: string = undefined

  @State album?: string = undefined

  @State artist?: string = undefined

  @State art?: image.PixelMap | string | ResourceStr = undefined

  private metadataCallback: ((data: avSession.AVMetadata) => void) = (metadata) => {
    this.updateMetadata(metadata)
  }

  private stateCallback: ((data: avSession.AVPlaybackState) => void) = (state) => {
    this.updatePlaybackState(state)
  }

  aboutToAppear(): void {
    AppStorage.setOrCreate("playerVisible", true)
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
    Stack() {

      // Image(this.blurhash)
      //   .width(CommonConstants.FULL_PERCENT)
      //   .height(CommonConstants.FULL_PERCENT)

      // content
      Column({ space: CommonConstants.SPACE_16 }) {
        // cover
        Stack() {

          Image(this.art)
            .width(CommonConstants.FULL_PERCENT)
            .height(CommonConstants.FULL_PERCENT)
            .backgroundImage(this.blurhash)
            .alt($r('app.media.alt'))
            .onError(() => {
              this.art = $r('app.media.alt')
            })
            .objectFit(ImageFit.Cover)
            .autoResize(true)
            .borderRadius($r('app.float.lg_border_radius'))
            .aspectRatio(1)
            .constraintSize({maxWidth: 320})
            .margin(CommonConstants.SPACE_16)

        }
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)

        // info
        Stack() {
          Column({space: CommonConstants.SPACE_8}) {
            Text(this.title)
              .fontColor(this.primaryColor)
              .fontSize($r('sys.float.Title_M'))
              .maxLines(1)
            Text(this.album)
              .fontColor(this.primaryColor)
              .fontSize($r('sys.float.Title_S'))
              .maxLines(1)
            Text(this.artist)
              .fontColor(this.primaryColor)
              .fontSize($r('sys.float.Title_S'))
              .maxLines(1)
          }
          .margin({right: 48})
          .alignItems(HorizontalAlign.Start)
          .width(CommonConstants.FULL_PERCENT)

          SymbolGlyph(this.favourite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
            .fontSize(32)
            .fontColor([this.favourite ? $r('sys.color.ohos_id_color_badge_red') : this.primaryColor])
            .onClick(() => {
              this.audioManager.getAudioControl().toggleFavourite()
            })
        }
        .alignContent(Alignment.TopEnd)

        // progress
        Row() {
          Text(TimeTool.formatMillionSecondsToHMS(this.progress))
            .fontColor(this.primaryColor)
          Blank()
            .layoutWeight(1)
          Text(TimeTool.formatMillionSecondsToHMS(this.duration))
            .fontColor(this.primaryColor)
        }

        Slider({
          value: this.progress >= 0 ? this.progress : 0,
          max: this.duration > 0 ? this.duration : 100
        })
          .blockColor(this.primaryColor)
          .enabled(this.state === avSession.PlaybackState.PLAYBACK_STATE_PLAY
            || this.state === avSession.PlaybackState.PLAYBACK_STATE_PAUSE)
          .onChange((num, mode) => {
            if (this.duration > 0 && mode === SliderChangeMode.End) {
              this.audioManager.getAudioControl().seek(num)
            }
          })


        // operate
        Row() {

          SymbolGlyph(this.modeRes)
            .fontSize(32)
            .fontColor([this.primaryColor])
            .onClick(() => {
              this.audioManager.getAudioControl().switchMode()
            })

          SymbolGlyph($r('sys.symbol.backward_end_fill'))
            .fontSize(32)
            .fontColor([this.primaryColor])
            .onClick(() => {
              this.audioManager.getAudioControl().pre()
            })

          SymbolGlyph(this.playRes)
            .fontSize(48)
            .fontColor([this.primaryColor])
            .onClick(() => {
              if (this.state === avSession.PlaybackState.PLAYBACK_STATE_PLAY) {
                this.audioManager.getAudioControl().pause()
              } else {
                this.audioManager.getAudioControl().play()
              }
            })

          SymbolGlyph($r('sys.symbol.forward_end_fill'))
            .fontSize(32)
            .fontColor([this.primaryColor])
            .onClick(() => {
              this.audioManager.getAudioControl().next()
            })

          SymbolGlyph($r('sys.symbol.music_note_list_fill'))
            .fontSize(32)
            .fontColor([this.primaryColor])
            .onClick(() => {
              this.playlistSheet.show()
            })
        }
        .alignItems(VerticalAlign.Center)
        .width(CommonConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.SpaceBetween)

        Blank(CommonConstants.SPACE_16)
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
      .padding({
        top: px2vp(this.avoidArea?.topRect.height),
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16,
        bottom: px2vp(this.avoidArea?.bottomRect.height)
      })

      // title bar
      ToolBar({
        color: this.primaryColor
      })
    }
    .alignContent(Alignment.Top)
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  private updateMetadata(metadata: avSession.AVMetadata) {
    this.title = metadata.title
    this.album = metadata.album
    this.artist = metadata.artist
    this.art = metadata.mediaImage
    try {
      let item = this.audioManager.getAudioQueue().getCurrent()
      if (item) {
        let url = this.repository.buildImage(item.extra, ImageType.Primary)
        let bh = this.repository.buildImageBlur(item.extra, ImageType.Primary)
        console.log(JSON.stringify(item.extra, undefined, 4) + "\n" + "blurhash: " + bh + ", url: " + url)
        if (bh && bh !== this.blurhashKey) {
          let array = decodeBlurHash(bh, 32, 32, 1)
          this.blurhash = image.createPixelMapSync(array.buffer as ArrayBuffer, {
            size: {width: 32, height: 32},
            srcPixelFormat: image.PixelMapFormat.RGBA_8888
          })
          this.blurhashKey = bh
          let rgb = getBlurHashAverageColor(bh);
          this.primaryColor = 0xff << 24 | rgb[0] << 16 | rgb[1] << 8 | rgb[2]
          // const luminance = 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2];
          // this.primaryColor = luminance > 186 ? 0x000000 : 0xFFFFFF;
        }
      }
    } catch (e) {
      // ignore
    }
  }

  private updatePlaybackState(state: avSession.AVPlaybackState) {
    this.duration = state.duration !== undefined ? state.duration : -1
    this.progress = state.position !== undefined ? state.position.elapsedTime : -1
    this.state = state.state
    this.favourite = state.isFavorite ? true : false
    this.playRes = state.state === avSession.PlaybackState.PLAYBACK_STATE_PLAY ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill')
    switch (state.loopMode) {
      case avSession.LoopMode.LOOP_MODE_SEQUENCE:
        this.modeRes = $r('sys.symbol.order_play')
        break
      case avSession.LoopMode.LOOP_MODE_SINGLE:
        this.modeRes = $r('sys.symbol.repeat_1')
        break
      case avSession.LoopMode.LOOP_MODE_LIST:
        this.modeRes = $r('sys.symbol.repeat')
        break
      case avSession.LoopMode.LOOP_MODE_SHUFFLE:
        this.modeRes = $r('sys.symbol.shuffle')
        break
      default :
        this.modeRes = $r('sys.symbol.repeat')
        break
    }
  }

  aboutToDisappear(): void {
    this.audioManager.getAudioControl().offMetadataChange(this.metadataCallback)
    this.audioManager.getAudioControl().offPlaybackStateChange(this.stateCallback)
    AppStorage.setOrCreate("playerVisible", false)
  }

}