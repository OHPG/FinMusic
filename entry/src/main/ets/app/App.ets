import { AbilityStage, Configuration, ConfigurationConstant } from "@kit.AbilityKit";
import { Proxy } from "@ohpg/proxy";
import { AVPlayerKit } from '@ohpg/player'
import { Logger, ConsoleLogOutput } from '@ohpg/core'
import { AppPrefer } from "../prefer/AppPrefer";
import { AppPlayerFactory } from "../player/AppPlayerFactory";
import { AppPlayerContextFactory } from "../player/AppPlayerContextFactory";
import BuildProfile from 'entry/BuildProfile';
import { Repository } from "../data/Repository";
import { LyricCache } from "../player/LyricCache";
import { AppMediaResolver } from "../player/AppMediaResolver";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 9:35
 * @Version V1.0
 * @Description
 */
export default class App extends AbilityStage {

  onCreate(): void {
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-light-dark-color-adaptation-V5#section1421172621111
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    const appContext = this.context.getApplicationContext()
    // Logger
    const logger = new Logger(Logger.DEFAULT_BUFFER_CAPACITY, false)
    logger.addOutput(new ConsoleLogOutput())
    AppStorage.setOrCreate(Logger.LOGGER_KEY, logger)

    // 初始化播放器库
    AVPlayerKit.init(appContext, new AppPlayerFactory())
    AVPlayerKit.setContextFactory(new AppPlayerContextFactory())
    AppStorage.setOrCreate(AppPrefer.PREFER, new AppPrefer(appContext))

    // lrc
    let lyricCache = new LyricCache(appContext)
    AppStorage.setOrCreate(LyricCache.LYRIC_CACHE, lyricCache)

    let repository = new Repository(appContext)
    AppStorage.setOrCreate(Repository.REPOSITORY, repository)

    // 注册媒体解析器（将 assetId 解析为流 URL + 歌词缓存）
    AVPlayerKit.setMediaResolver(new AppMediaResolver())

    // 提前配置 Proxy 缓存目录，使 getCacheSize/clearCache 随时可用
    let prefer = AppStorage.get<AppPrefer>(AppPrefer.PREFER)!
    let cacheDir = appContext.cacheDir + '/audio_cache'
    let maxSizeBytes = prefer.getCacheMaxSizeMB() * 1024 * 1024
    let maxCount = prefer.getCacheMaxCount()
    Proxy.setCacheConfig(cacheDir, maxSizeBytes, maxCount)
    Proxy.setLogEnabled(BuildProfile.DEBUG)
  }

  onConfigurationUpdate(newConfig: Configuration): void {
  }

}