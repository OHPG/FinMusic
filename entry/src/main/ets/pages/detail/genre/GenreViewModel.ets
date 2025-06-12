import { LoadType } from "@ohpg/fin-core"
import { ListViewModel } from "../../../lifecycle/ListViewModel"
import { MediaArgs } from "../MediaArgs"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/6/8 17:14
 * @Version V1.0
 * @Description
 */
export class GenreViewModel extends ListViewModel {

  private readonly args: MediaArgs

  constructor(context: Context, args: MediaArgs) {
    super(context)
    this.args = args
  }

  async loadData(type?: LoadType): Promise<void> {
    let albumArray = await this.repository.getGenreAlbums(this.args.id)
    this.dataSource.initData(albumArray)
  }
}