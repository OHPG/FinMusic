import { CommonConstants, ListRefreshView } from "@ohpg/fin-framework"
import { BaseItemDto, BaseItemKind, ImageType } from "@ohpg/jellyfin"
import { Repository } from "../../../data/Repository"
import { MediaArgs } from "../../detail/MediaArgs"
import { MainCategory } from "./MainCategory"
import { MainGroup } from "./MainGroup"
import { MainViewModel } from "./MainViewModel"
import { router, window } from "@kit.ArkUI"
import { BreakpointSystem } from "@ohpg/fin-core"
import { AudioManager } from "../../../player/AudioManager"
import { PlayerRouter } from "@ohpg/widget"

@Component
export struct MainPage {

  private readonly viewModel = new MainViewModel(getContext())

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp('playerHeight') currentAvoidMedia: number = 0

  aboutToAppear(): void {
  }

  @Builder
  private mainGroup(groupInfo: MainGroup) {
    if (groupInfo.category === MainCategory.DAY) {
      MainGroupGrid({group: groupInfo})
    } else {
      MainGroupList({group: groupInfo})
    }
  }

  build() {

    ListRefreshView({
      source: this.viewModel,
      itemLayout: (group: MainGroup) => {
        this.mainGroup(group)
      },
      listAttribute: (attr) => {
        attr.divider = {
          color: Color.Transparent,
          strokeWidth: CommonConstants.SPACE_12,
        }
        attr.width = CommonConstants.FULL_PERCENT
        attr.height = CommonConstants.FULL_PERCENT
        attr.contentEndOffset = px2vp(this.currentAvoidArea?.bottomRect.height) + this.currentAvoidMedia
      },
    })
    .width('100%')
    .height('100%')

  }

  aboutToDisappear(): void {

  }

}

async function onMainItemClick(context: UIContext, group: MainGroup, item: BaseItemDto) {
  if (item.Type === BaseItemKind.MusicAlbum) {
    let args: MediaArgs = {
      id: item.Id!,
      name: item.Name!
    }
    router.pushUrl({url: 'pages/detail/album/AlbumPage', params: args})
  } else if (item.Type === BaseItemKind.Audio) {
    let audioManager: AudioManager = AppStorage.get(AudioManager.AUDIO_MANAGER)!
    console.info("FinMusic: onMainItemClick Audio id=" + item.Id)
    let result = audioManager.playAll(group.items, item.Id!)
    console.info("FinMusic: onMainItemClick playAll result=" + result + ", pushing PlayerRouter")
    PlayerRouter.push(context)
  }
}

@Component
struct MainGroupHeader {

  @Require category?: MainCategory

  @State categoryName?: ResourceStr = undefined

  aboutToAppear(): void {
    switch (this.category) {
      case MainCategory.DAY:
        this.categoryName = $r('app.string.home_main_day')
        break
      case MainCategory.RECENT:
        this.categoryName = $r('app.string.home_main_recent')
        break
      case MainCategory.MOST:
        this.categoryName = $r('app.string.home_main_most')
        break
      case MainCategory.NEW:
        this.categoryName = $r('app.string.home_main_new')
        break
      case MainCategory.RANDOM:
        this.categoryName = $r('app.string.home_main_random')
        break
    }
  }

  build() {
    Text(this.categoryName)
      .fontSize($r('app.float.lg_font_size'))
      .fontWeight(FontWeight.Medium)
      .fontFamily(CommonConstants.HARMONY_HEITI_MEDIUM_FONT_FAMILY)
      .width('100%')
      .height(36)
      .padding({
        left: 16,
        right: 16
      })
  }

}

@Component
struct MainGroupList{

  @Require group?: MainGroup

  private callback: Callback<BaseItemDto> = (item: BaseItemDto) => {
    onMainItemClick(this.getUIContext(), this.group!, item)
  }

  build() {
    Column() {
      MainGroupHeader({category: this.group?.category})
      List({space: 12}) {
        ForEach(this.group?.items, (item: BaseItemDto) => {
          ListItem() {
            MainMediaListItem({item: item, callback: this.callback})
          }
        })
      }
      .width('100%')
      .contentStartOffset(16)
      .contentEndOffset(16)
      .scrollBar(BarState.Off)
      .alignListItem(ListItemAlign.Start)
      .listDirection(Axis.Horizontal)
    }
  }
}

@Component
struct MainGroupGrid{

  @Require group?: MainGroup

  private callback: Callback<BaseItemDto> = (item: BaseItemDto) => {
    onMainItemClick(this.getUIContext(), this.group!, item)
  }

  build() {
    Column() {
      MainGroupHeader({category: this.group?.category})
      Grid() {
        ForEach(this.group?.items, (item: BaseItemDto) => {
          GridItem() {
            MainMediaGridItem({item: item, callback: this.callback})
          }
        })
      }
      .width('100%')
      .height(240)
      .scrollBar(BarState.Off)
      .rowsTemplate("1fr 1fr 1fr")
      .layoutDirection(GridDirection.Column)
    }
  }
}


@Reusable
@Component
struct MainMediaListItem {

  @StorageLink("Repository") repository?: Repository = undefined

  @Require @State item?: BaseItemDto = undefined

  @Require callback?: Callback<BaseItemDto>

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params["item"] as BaseItemDto
  }

  build() {

    Column({space: 4}) {
      Image(this.repository?.buildImage(this.item!, ImageType.Primary))
        .alt($r('app.media.default_cover'))
        .objectFit(ImageFit.Cover)
        .autoResize(true)
        .width(160)
        .height(160)
        .borderRadius($r('app.float.lg_border_radius'))

      Text(this.item?.Name)
        .fontSize($r('app.float.md_font_size'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .maxLines(1)
        .width('100%')

      Text(this.item?.AlbumArtist)
        .fontSize($r('app.float.sm_font_size'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(1)
        .width('100%')
    }
    .width(160)
    .onClick(() => {
      this.callback?.(this.item)
    })
  }

}
@Reusable
@Component
struct MainMediaGridItem {

  @StorageLink("Repository") repository?: Repository = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;

  @Require @State item?: BaseItemDto = undefined

  @Require callback?: Callback<BaseItemDto>

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params["item"] as BaseItemDto
  }

  build() {

    Row({space: 12}) {
      Image(this.repository?.buildImage(this.item!, ImageType.Primary))
        .alt($r('app.media.default_cover'))
        .objectFit(ImageFit.Cover)
        .autoResize(true)
        .width(60)
        .height(60)
        .borderRadius($r('app.float.sm_border_radius'))
        .aspectRatio(1)

      Column({space: 6}) {
        Text(this.item?.Name)
          .fontSize($r('app.float.md_font_size'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .width('100%')
          .maxLines(1)

        Text(this.item?.AlbumArtist + "-" + this.item?.Album)
          .fontSize($r('app.float.sm_font_size'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .width('100%')
          .maxLines(1)
      }
      .layoutWeight(1)
    }
    .padding({left: 16, right: 16})
    .height(80)
    .width(this.currentBreakpoint >= WidthBreakpoint.WIDTH_MD ? '50%' : '100%')
    .onClick(() => {
      this.callback?.(this.item)
    })
  }

}



