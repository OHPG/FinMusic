import { AVWidgetPlaybackManager } from '@ohpg/widget'

/**
 * FinMusic 播放管理器。
 * 继承 AVWidgetPlaybackManager，覆写页面生命周期方法：
 * - 音乐始终后台播放，退出播放页不销毁播放器
 * - 页面隐藏不暂停
 * - 返回键不拦截
 *
 * 播放上下文通过 AVPlayerKit.setContextFactory() 注册的工厂创建。
 */
export class AppPlaybackManager extends AVWidgetPlaybackManager {

  /**
   * 音乐播放页隐藏时不暂停（始终后台播放）
   */
  public onPageHide(): void {
    // no-op: 音乐不因页面隐藏而暂停
  }

  /**
   * 音乐播放页销毁时不销毁播放器（音乐持续播放）
   */
  public onPageDisappear(): void {
    // no-op: 退出播放页不销毁播放器
  }

  /**
   * 返回键不拦截，允许正常返回
   */
  public onBackPress(): boolean {
    return false
  }

  /**
   * 覆写 playAll：如果播放器已存在，直接替换播放（音乐场景复用播放器）
   */
  public playAll(args: Object): boolean {
    console.info("FinMusic: AppPlaybackManager.playAll hasPlayer=" + this.hasPlayer())
    if (this.hasPlayer()) {
      console.info("FinMusic: play (reuse existing player)")
      this.getPlayerContext()!.play(args).catch((e: Error) => {
        console.error("FinMusic: play error: " + e.message)
      })
      return true
    }
    let result = super.playAll(args)
    console.info("FinMusic: super.playAll result=" + result)
    return result
  }
}
