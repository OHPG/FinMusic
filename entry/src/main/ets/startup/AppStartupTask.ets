import { common, StartupTask } from "@kit.AbilityKit";
import { AVPlayerKit } from "@ohpg/player";
import { Repository } from "../data/Repository";
import { AppMediaResolver } from "../player/AppMediaResolver";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/11/10 1:04
 * @Version V1.0
 * @Description
 */
@Sendable
export class AppStartupTask extends StartupTask {

  public async init(context: common.AbilityStageContext): Promise<void> {
    console.log("AppStartupTask: init 1.")
    let repository = new Repository(context.getApplicationContext())
    AppStorage.setOrCreate(Repository.REPOSITORY, repository)
    // 注册媒体解析器（将 assetId 解析为流 URL + 歌词缓存）
    AVPlayerKit.setMediaResolver(new AppMediaResolver(context, repository))
    try {
      await repository.init()
    } catch (error) {
      console.error("AppStartupTask: init error " + error['message'])
    }
    console.log("AppStartupTask: init 2.")
  }

}