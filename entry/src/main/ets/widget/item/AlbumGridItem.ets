import { BaseItemDto, ImageType } from '@ohpg/jellyfin'
import { Repository } from '../../data/Repository'
import { AppRouter } from '../../router/AppRouter'

@Reusable
@Component
export struct AlbumGridItem {

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