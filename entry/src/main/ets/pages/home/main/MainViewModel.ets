import { LoadType } from "@ohpg/fin-core";
import { ListViewModel } from "../../../lifecycle/ListViewModel";
import { MainCategory } from "./MainCategory";
import { MainGroup } from "./MainGroup";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/6/7 7:38
 * @Version V1.0
 * @Description
 */
export class MainViewModel extends ListViewModel {

  async loadData(type?: LoadType): Promise<void> {
    let categoryArray = new Array<MainGroup>()

    await this.repository.assertLibraryList()

    // 每日推荐
    let day = await this.repository.getRandomMedia()
    if (day.length > 0) {
      categoryArray.push({category: MainCategory.DAY, items: day})
    }

    // 最近播放
    let recent = await this.repository.getLatestAudio()
    if (recent.length > 0) {
      categoryArray.push({category: MainCategory.RECENT, items: recent})
    }

    // 最常播放
    let most = await this.repository.getMostAudio()
    if (most.length > 0) {
      categoryArray.push({category: MainCategory.MOST, items: most})
    }

    // 最新专辑
    let newest = await this.repository.getLatestMedia()
    if (newest.length > 0) {
      categoryArray.push({category: MainCategory.NEW, items: newest})
    }

    // 随机专辑
    let random = await this.repository.getRandomAlbum()
    if (random.length > 0) {
      categoryArray.push({category: MainCategory.RANDOM, items: random})
    }
    this.dataSource.initData(categoryArray)
  }

}