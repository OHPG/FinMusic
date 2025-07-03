import { CommonConstants, GridRefreshView } from "@ohpg/fin-framework";
import { BaseItemDto, ImageType } from "@ohpg/jellyfin";
import { Repository } from "../../../data/Repository";
import { ArtistViewModel } from "./ArtistViewModel";
import { router, window } from "@kit.ArkUI";
import { MediaArgs } from "../../detail/MediaArgs";

@Component
export struct ArtistPage {

  private viewModel = new ArtistViewModel(getContext())

  @StorageProp('currentAvoidArea') currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp('playerHeight') currentAvoidMedia: number = 0

  @Builder
  private artistItemBuilder(item: BaseItemDto) {
    ArtistListItem({item: item})
  }

  build() {
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
      itemLayout: this.artistItemBuilder
    })
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
  }

}

@Reusable
@Component
struct ArtistListItem {

  @StorageLink("Repository") repository?: Repository = undefined

  @Require @State item?: BaseItemDto = undefined

  aboutToReuse(params: Record<string, object>): void {
    this.item = params['item'] as BaseItemDto
  }

  build() {
    Column() {
      Image(this.repository?.buildImage(this.item!, ImageType.Primary))
        .alt($r('app.media.alt'))
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
      let args: MediaArgs = {
        id: this.item?.Id!,
        name: this.item?.Name!
      }
      router.pushUrl({url: 'pages/detail/artist/ArtistPage', params: args})
    })
  }

  aboutToRecycle(): void {
  }


}