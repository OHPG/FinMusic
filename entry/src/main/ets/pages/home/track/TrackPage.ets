import { CommonConstants, ListRefreshView } from "@ohpg/fin-framework"
import { BaseItemDto, ImageType } from "@ohpg/jellyfin"
import { Repository } from "../../../data/Repository"
import { TrackViewModel } from "./TrackViewModel"

@Component
export struct TrackPage {

  private viewModel = new TrackViewModel(getContext())


  @Builder
  private trackItemBuilder(item: BaseItemDto) {
    TrackListItem({item: item})
  }

  build() {
    ListRefreshView({
      source: this.viewModel,
      itemLayout: this.trackItemBuilder,
      listAttribute: (attr) => {
        attr.divider = {
          color: Color.Transparent,
          strokeWidth: CommonConstants.SPACE_12
        }
        attr.width = CommonConstants.FULL_PERCENT
        attr.height = CommonConstants.FULL_PERCENT
        attr.contentEndOffset
      },
    })
      .width('100%')
      .height('100%')
  }
}


@Reusable
@Component
struct TrackListItem {

  @StorageLink("Repository") repository?: Repository = undefined

  @Require @State item?: BaseItemDto = undefined

  aboutToReuse(params: Record<string, ESObject>): void {
    this.item = params['item']
  }

  build() {

    Row({space: 12}) {
      Image(this.repository?.buildImage(this.item!, ImageType.Primary))
        .alt($r('app.media.alt'))
        .objectFit(ImageFit.Cover)
        .autoResize(true)
        .width(60)
        .height(60)
        .borderRadius($r('app.float.sm_border_radius'))
        .aspectRatio(1)

      Text(this.item?.Name)
        .fontSize($r('app.float.md_font_size'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width('100%')
        .maxLines(1)
        .layoutWeight(1)
    }
    .padding({left: 16, right: 16})
    .height(80)
    .width('100%')
  }

}