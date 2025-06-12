import { LoadType } from "@ohpg/fin-core";
import { SimpleRepository } from "@ohpg/fin-framework";
import { BaseItemDto, BaseItemKind, ImageType } from "@ohpg/jellyfin";
import { GroupInfo } from "../../../entity/GroupInfo";
import { AppViewModel } from "../../../lifecycle/AppViewModel";
import { AudioItem } from "../../../player/AudioItem";
import { MediaArgs } from "../MediaArgs";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 11:54
 * @Version V1.0
 * @Description
 */
export class AlbumViewModel extends AppViewModel implements SimpleRepository {

  private readonly args: MediaArgs

  private readonly audioItems = new Array<AudioItem>()

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
  }

  public audios(): Array<AudioItem> {
    return this.audioItems
  }

  async loadData(type: LoadType): Promise<Object> {
    let album = await this.repository.loadMovie(this.args.id)
    let audioArray = await this.repository.loadMediaList(album.Id!, [BaseItemKind.Audio], true)
    audioArray.sort((left: BaseItemDto, right: BaseItemDto) => {
      return left.IndexNumber! - right.IndexNumber!
    })
    let groupInfo: GroupInfo = {
      group: album,
      items: audioArray
    }
    this.audioItems.splice(0)
    for (let item of audioArray) {
      this.audioItems.push({
        id: item.Id!,
        name: item.Name!,
        art: this.repository.buildImage(item, ImageType.Primary)!,
        url: await this.repository.loadStreamUrl(item.Id!, item.Id!),
        extra: item
      })
    }
    return groupInfo
  }

}