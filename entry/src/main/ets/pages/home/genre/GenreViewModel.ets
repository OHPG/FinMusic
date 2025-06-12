import { LoadType } from "@ohpg/fin-core";
import { ListViewModel } from "../../../lifecycle/ListViewModel";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/6/7 7:43
 * @Version V1.0
 * @Description
 */
export class GenreViewModel extends ListViewModel {

  async loadData(type?: LoadType): Promise<void> {
    await this.repository.assertLibraryList()
    let genres = await this.repository.getGenres()
    this.dataSource.initData(genres)
  }

}