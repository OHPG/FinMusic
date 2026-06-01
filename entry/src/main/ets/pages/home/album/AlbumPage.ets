import { BaseItemDto, ImageType } from "@ohpg/jellyfin";
import { AlbumViewModel } from "./AlbumViewModel";
import { window } from "@kit.ArkUI";
import { CommonConstants, GridRefreshView } from "@ohpg/fin-framework";
import { Repository } from "../../../data/Repository";
import { AppRouter } from "../../../router/AppRouter";

@Component
export struct AlbumPage {

  private viewModel = new AlbumViewModel(getContext())

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp('playerHeight') currentAvoidMedia: number = 0

  @Builder
  mediaListView(info: BaseItemDto) {
    MediaItem({item: info})
  }

  build() {

    Column() {
      GridRefreshView({
        source: this.viewModel,
        gridAttribute: (attr) => {
          attr.padding = {
            left: CommonConstants.SPACE_16,
            right: CommonConstants.SPACE_16,
            bottom: px2vp(this.currentAvoidArea?.bottomRect.height) + this.currentAvoidMedia
          }
          attr.rowsGap = CommonConstants.SPACE_12
          attr.columnsGap = CommonConstants.SPACE_12
          attr.columnsTemplate = 'repeat(auto-fit, 140)'
          attr.width = CommonConstants.FULL_PERCENT
          attr.height = CommonConstants.FULL_PERCENT
        },
        itemLayout: this.mediaListView
      })
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)

    }

  }
}

@Reusable
@Component
struct MediaItem {

  @StorageLink("Repository") repository?: Repository = undefined

  @Require @State item?: BaseItemDto = undefined

  aboutToReuse(params: Record<string, object>): void {
    this.item = params['item'] as BaseItemDto
  }

  build() {
    Column() {
      Image(this.repository?.buildImage(this.item!, ImageType.Primary))
        .alt($r('app.media.default_cover'))
        .objectFit(ImageFit.Cover)
        .autoResize(true)
        .borderRadius($r('app.float.lg_border_radius'))
        .width('100%')
        .aspectRatio(1)

      Text(this.item?.Name)
        .width('100%')
        .maxLines(1)
      Text(this.item?.AlbumArtist)
        .width('100%')
        .maxLines(1)
    }
    .onClick(() => {
      AppRouter.goToAlbum(this.getUIContext(), this.item?.Id!, this.item?.Name!)
    })
  }

}