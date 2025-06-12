import { AlbumViewModel } from './AlbumViewModel'
import { ScrollRefreshView, ToolBar } from '@ohpg/fin-framework'
import { BaseItemDto, ImageType } from '@ohpg/jellyfin'
import { CommonConstants } from '../../../common/CommonConstants'
import { MediaArgs } from '../MediaArgs'
import router from '@ohos.router'
import { window } from '@kit.ArkUI'
import { Repository } from '../../../data/Repository'
import { GroupInfo } from '../../../entity/GroupInfo'
import { AudioManager } from '../../../player/AudioManager'
import { BreakpointSystem } from '@ohpg/fin-core'

@Entry
@Component
struct AlbumPage {

  private args: MediaArgs = router.getParams() as MediaArgs

  private audioManager: AudioManager = AppStorage.get(AudioManager.AUDIO_MANAGER)!

  public readonly repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  private viewModel = new AlbumViewModel(getContext(), this.args)

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  @StorageProp('playerHeight') currentAvoidMedia: number = 0

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;

  @Builder
  movieScrollView(group?: GroupInfo) {
    Column({ space: CommonConstants.SPACE_12 }) {
      Image(this.repository?.buildImage(group!.group!, ImageType.Primary))
        .alt($r('app.media.alt'))
        .objectFit(ImageFit.Cover)
        .autoResize(true)
        .width(CommonConstants.FULL_PERCENT)
        .aspectRatio(this.currentBreakpoint > WidthBreakpoint.WIDTH_SM ? 4 : 2)

      Column({ space: CommonConstants.SPACE_12 }) {

        Text(group?.group?.Name)
          .fontSize($r('sys.float.Title_M'))

        Text(group?.group?.AlbumArtist)
          .fontSize($r('sys.float.Title_S'))

        Row({ space: CommonConstants.SPACE_8 }) {
          Text(group?.group?.ProductionYear?.toString())

          Text(Math.round(((group?.group?.RunTimeTicks!) / 600000000)) + "min")

          Text(group?.group?.OfficialRating)

          Text(group?.group?.CommunityRating?.toString())

        }

        // list
        if (group?.items) {
          List() {
            ForEach(group.items, (item: BaseItemDto, index) => {
              ListItem() {
                Text(`${index + 1} ${item.Name}`)
                  .textAlign(TextAlign.Start)
                  .width(CommonConstants.FULL_PERCENT)
                  .height(60)
              }
              .onClick(() => {
                let queueManager = this.audioManager.getAudioQueue()
                queueManager.resetItem(this.viewModel.audios())
                this.audioManager.getAudioControl().playItem(item.Id!)
                router.pushUrl({url: 'pages/player/PlayerPage'})
              })
            })
          }
          .width(CommonConstants.FULL_PERCENT)
          .divider({
            color: $r('sys.color.ohos_id_divider_color'),
            strokeWidth: 1
          })
        }

      }
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16
      })
      .width(CommonConstants.FULL_PERCENT)
      .alignItems(HorizontalAlign.Start)
    }
    .align(Alignment.Top)
    .padding({
      bottom: px2vp(this.avoidArea?.bottomRect.height) + this.currentAvoidMedia
    })
    .width(CommonConstants.FULL_PERCENT)
  }

  build() {

    Stack() {

      ScrollRefreshView({
        source: this.viewModel,
        itemLayout: (info: ESObject) => {
          this.movieScrollView(info)
        }
      })
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)

      ToolBar({
        color: $r('sys.color.font_on_primary'),
      })
    }
    .alignContent(Alignment.Top)
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)

  }
}