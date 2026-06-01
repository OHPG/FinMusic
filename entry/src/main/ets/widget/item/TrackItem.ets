import { BaseItemDto } from '@ohpg/jellyfin'
import { CommonConstants } from '../../common/CommonConstants'

@Reusable
@Component
export struct TrackItem {

  @Require @State item: BaseItemDto = {}

  @Require @State isFavorite: boolean = false

  onPlay: () => void = () => {}

  onFavoriteToggle: () => void = () => {}

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params['item'] as BaseItemDto
    this.isFavorite = params['isFavorite'] as boolean
  }

  build() {
    Row({ space: CommonConstants.SPACE_12 }) {
      Column({ space: CommonConstants.SPACE_4 }) {
        Text(this.item.Name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(CommonConstants.FULL_PERCENT)

        Text(this.buildSubtitle())
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(CommonConstants.FULL_PERCENT)
      }
      .layoutWeight(1)

      SymbolGlyph(this.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
        .fontSize(20)
        .fontColor([this.isFavorite ? Color.Red : $r('sys.color.ohos_id_color_text_secondary')])
        .onClick(() => {
          this.onFavoriteToggle()
        })
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(60)
    .padding({ left: CommonConstants.SPACE_16, right: CommonConstants.SPACE_16 })
    .onClick(() => {
      this.onPlay()
    })
  }

  private buildSubtitle(): string {
    let parts: string[] = []
    if (this.item.AlbumArtist) {
      parts.push(this.item.AlbumArtist)
    }
    if (this.item.Album) {
      parts.push(this.item.Album)
    }
    if (parts.length > 0) {
      return parts.join(' - ')
    }
    return this.formatDuration(this.item.RunTimeTicks)
  }

  private formatDuration(ticks?: number | null): string {
    if (!ticks) return ''
    let totalSeconds = Math.floor(ticks / 10000000)
    let minutes = Math.floor(totalSeconds / 60)
    let seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

}
