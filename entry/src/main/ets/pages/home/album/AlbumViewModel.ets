import { LoadType } from "@ohpg/fin-core";
import { BaseItemKind } from "@ohpg/jellyfin";
import { ListViewModel } from "../../../lifecycle/ListViewModel";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/6/7 7:40
 * @Version V1.0
 * @Description
 */
export class AlbumViewModel extends ListViewModel {

  async loadData(type: LoadType): Promise<void> {
    await this.repository.assertLibraryList()
    let mediaArray = await this.repository.getMediaList()
    if (mediaArray.length > 0) {
      let media = mediaArray[0]
      let albums = await this.repository.loadMediaList(media.Id!, [BaseItemKind.MusicAlbum], true)
      this.dataSource.initData(albums)
    }
  }
}