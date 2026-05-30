import { BaseItemDto } from '@ohpg/jellyfin'
import { AVPlaybackManager, AVPlayerKit } from '@ohpg/player'
import { Repository } from '../data/Repository'
import { AppPlaybackManager } from './AppPlaybackManager'
import { AppMediaResolver } from './AppMediaResolver'
import { PlayArgs } from './AppPlayerContext'

/**
 * FinMusic 音频管理器。
 * 持有 AppPlaybackManager，提供播放入口和播放列表持久化。
 */
export class AudioManager {

  public static readonly AUDIO_MANAGER = 'audioManager'

  public readonly repository: Repository

  private playbackManager?: AppPlaybackManager

  constructor(context: Context) {
    this.repository = AppStorage.get(Repository.REPOSITORY)!
    // 注册媒体解析器（将 assetId 解析为流 URL）
    AVPlayerKit.setMediaResolver(new AppMediaResolver(this.repository))
  }

  /**
   * 初始化播放管理器（需要 UIContext，由首个页面调用）
   */
  public initPlaybackManager(uiContext: UIContext): AppPlaybackManager {
    if (!this.playbackManager) {
      this.playbackManager = new AppPlaybackManager(uiContext)
      AppStorage.setOrCreate(AVPlaybackManager.AV_PLAYER_MANAGER, this.playbackManager)
    }
    return this.playbackManager
  }

  public getPlaybackManager(): AppPlaybackManager | undefined {
    return this.playbackManager
  }

  /**
   * 播放全部
   * @param items 播放列表
   * @param startId 起始播放项 ID
   * @returns true=播放成功，false=播放器未初始化
   */
  public playAll(items: Array<BaseItemDto>, startId: string): boolean {
    console.info("FinMusic: playAll startId=" + startId + ", items=" + items.length)
    if (!this.playbackManager) {
      console.warn("FinMusic: playAll failed - playbackManager not initialized")
      return false
    }
    let args: PlayArgs = { items: items, startId: startId }
    let result = this.playbackManager.playAll(args)
    console.info("FinMusic: playAll result=" + result)
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
    if (!this.playbackManager) {
      console.warn("FinMusic: resumeAudioQueue - playbackManager not initialized")
      return
    }

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
      this.playbackManager.loadAll(args)
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

  /**
   * 释放资源
   */
  public async release(): Promise<void> {
    await this.playbackManager?.release()
  }
}
