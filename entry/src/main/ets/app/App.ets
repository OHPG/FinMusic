import { AbilityStage, Configuration, ConfigurationConstant } from "@kit.AbilityKit";
import { AVPlayerKit } from '@ohpg/player'
import { Logger, ConsoleLogOutput } from '@ohpg/core'
import { AppPrefer } from "../prefer/AppPrefer";
import { AppPlayerFactory } from "../player/AppPlayerFactory";
import { AppPlayerContextFactory } from "../player/AppPlayerContextFactory";

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
  }

  onConfigurationUpdate(newConfig: Configuration): void {
  }

}