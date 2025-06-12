import { CommonConstants, GridRefreshView } from '@ohpg/fin-framework'
import { ToolBar } from '@ohpg/fin-framework'
import { MediaArgs } from '../MediaArgs'
import { router, window } from '@kit.ArkUI'
import { Repository } from '../../../data/Repository'
import { BaseItemDto } from '@ohpg/jellyfin'
import { AlbumGridItem } from '../../../widget/item/AlbumGridItem'
import { GenreViewModel } from './GenreViewModel'

@Entry
@Component
struct GenrePage {

  private args: MediaArgs = router.getParams() as MediaArgs

  @StorageProp("currentAvoidArea") currentAvoidArea?: window.AvoidArea = undefined

  @StorageProp('playerHeight') currentAvoidMedia: number = 0

  @StorageLink(Repository.REPOSITORY) repository?: Repository = undefined

  private viewModel = new GenreViewModel(getContext(), this.args)

  @Builder
  artistGridView(info: BaseItemDto) {
    AlbumGridItem({item: info})
  }

  build() {

    Column() {
      ToolBar({
        title: this.args.name
      })

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
        itemLayout: this.artistGridView
      })
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
    }
  }

}