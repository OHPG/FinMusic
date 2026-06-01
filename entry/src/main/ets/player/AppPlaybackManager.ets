import { AVWidgetPlaybackManager } from '@ohpg/widget'
import { BaseItemDto } from '@ohpg/jellyfin'
import { Repository } from '../data/Repository'
import { PlayArgs } from './AppPlayerContext'

/**
 * FinMusic 播放管理器。
 * 继承 AVWidgetPlaybackManager，统一播放入口：
 * - 音乐始终后台播放，退出播放页不销毁播放器
 * - 页面隐藏不暂停
 * - 返回键不拦截
 * - 播放列表持久化和冷启动恢复
 *
 * 播放上下文通过 AVPlayerKit.setContextFactory() 注册的工厂创建。
 */
export class AppPlaybackManager extends AVWidgetPlaybackManager {

  private readonly repository: Repository = AppStorage.get(Repository.REPOSITORY)!

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
   * 覆写 playAll：如果播放器已存在，使用 replaceAndPlay 替换播放（音乐场景复用播放器）
   */
  public playAll(args: Object): boolean {
    console.info("FinMusic: AppPlaybackManager.playAll hasPlayer=" + this.hasPlayer())
    if (this.hasPlayer()) {
      console.info("FinMusic: replaceAndPlay (reuse existing player)")
      this.getPlayerContext()!.replaceAndPlay(args).catch((e: Error) => {
        console.error("FinMusic: replaceAndPlay error: " + e.message)
      })
      return true
    }
    let result = super.playAll(args)
    console.info("FinMusic: super.playAll result=" + result)
    return result
  }

  // ─── 播放列表入口 ──────────────────────────────────────────────────────────

  /**
   * 播放全部
   * @param items 播放列表
   * @param startId 起始播放项 ID
   * @returns true=播放成功，false=播放器未初始化
   */
  public playItems(items: Array<BaseItemDto>, startId: string): boolean {
    console.info("FinMusic: playItems startId=" + startId + ", items=" + items.length)
    let args: PlayArgs = { items: items, startId: startId }
    let result = this.playAll(args)
    console.info("FinMusic: playItems result=" + result)
    if (result) {
      this.saveAudioQueue(items)
    }
    return result
  }

  /**
   * 恢复上次播放列表（App 启动时调用）。
   * 只加载队列和 prepare，不自动播放，等待用户手动触发。
   */
  public async resumeAudioQueue(): Promise<void> {
    let items = await this.repository.getPlayList()
    console.info("FinMusic: resumeAudioQueue items=" + (items ? items.length : 0))
    if (!items || items.length <= 0) return

    // 找到最近播放的项
    let lastItem: BaseItemDto | undefined = undefined
    for (let item of items) {
      if (lastItem) {
        if (item.UserData?.LastPlayedDate
          && lastItem.UserData?.LastPlayedDate
          && item.UserData.LastPlayedDate > lastItem.UserData.LastPlayedDate) {
          lastItem = item
        }
      } else {
        lastItem = item
      }
    }

    if (lastItem) {
      console.info("FinMusic: resumeAudioQueue loadAll startId=" + lastItem.Id)
      let args: PlayArgs = { items: items, startId: lastItem.Id! }
      this.loadAll(args)
    } else {
      console.info("FinMusic: resumeAudioQueue - no lastItem found")
    }
  }

  /**
   * 保存播放列表到服务端
   */
  private saveAudioQueue(items: Array<BaseItemDto>): void {
    if (!items || items.length <= 0) return
    this.repository.setPlaylist(items)
  }
}
