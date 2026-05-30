import {
  AVPlayerContext,
  PlayData,
  AVPlayerKit,
  PlaybackState,
} from '@ohpg/player'
import { avSession } from '@kit.AVSessionKit'
import { BaseItemDto, ImageType } from '@ohpg/jellyfin'
import { Repository } from '../data/Repository'

export interface PlayArgs {
  items: Array<BaseItemDto>
  startId: string
}

/**
 * FinMusic 的播放上下文实现。
 * 继承 AVPlayerContext 基类，实现：
 * - 队列构建（从 BaseItemDto[] 构建 AVQueueItem）
 * - 服务端播放进度上报（start/progress/stop）
 */
export class AppPlayerContext extends AVPlayerContext {

  private readonly repository: Repository

  /** 上报防重入标记 */
  private reportingPlayback = false

  /** 上次上报的进度位置（ticks） */
  private reportPosition?: number = undefined

  constructor(uiContext: UIContext, repository: Repository) {
    let playerPrefer = AVPlayerKit.getPrefer()
    let config = playerPrefer.toPlayerConfig()
    // 音乐始终后台播放
    config.backgroundPlay = true
    super(uiContext, config)
    this.repository = repository
    // 音乐 App 不需要画中画
    this.control.setPipEnabled(false)
  }

  // ─── 抽象方法实现 ──────────────────────────────────────────────────────────

  protected buildPlayData(args: Object): PlayData {
    let playArgs = args as PlayArgs
    console.info("FinMusic: buildPlayData startId=" + playArgs.startId + ", items=" + playArgs.items.length)
    let items = this.buildQueue(playArgs.items)
    return { items: items, startId: playArgs.startId }
  }

  protected async onHistorySave(assetId: string, state: PlaybackState, _notify: boolean): Promise<void> {
    // 进度上报：position 是 ms，Jellyfin 需要 ticks（100ns = ms * 10000）
    this.reportPlaybackUpdate(assetId, state.position * 10000)
  }

  // ─── 覆写方法 ──────────────────────────────────────────────────────────────

  protected onAssetChanged(assetId: string, _description: avSession.AVMediaDescription): void {
    this.reportPlaybackStop()
    this.reportPosition = undefined
    this.reportPlaybackStart(assetId)
  }

  resetItemState(): void {
    this.reportPlaybackStop()
  }

  // ─── 内部方法 ──────────────────────────────────────────────────────────────

  private buildQueue(items: Array<BaseItemDto>): Array<avSession.AVQueueItem> {
    let queueItems = new Array<avSession.AVQueueItem>()

    items.forEach((dto: BaseItemDto, i: number) => {
      let mediaImage = this.repository.buildImage(dto, ImageType.Primary)
      // RunTimeTicks 是 100ns 单位，转为 ms
      let duration: number | undefined = dto.RunTimeTicks ? dto.RunTimeTicks / 10000 : undefined

      queueItems.push({
        itemId: i,
        description: {
          assetId: dto.Id!,
          title: dto.Name ?? undefined,
          mediaType: 'audio',
          mediaImage: mediaImage,
          mediaUri: dto.Id!,
          subtitle: dto.AlbumArtist ?? undefined,
          description: dto.Album ?? undefined,
          duration: duration,
        }
      })
    })

    return queueItems
  }

  // ─── 服务端上报 ────────────────────────────────────────────────────────────

  private reportPlaybackStart(assetId: string): void {
    if (this.reportingPlayback) return
    this.reportingPlayback = true
    this.repository.onPlaybackStart(assetId)
      .then(() => { this.reportingPlayback = false })
      .catch((_e: Error) => { this.reportingPlayback = false })
  }

  private reportPlaybackUpdate(assetId: string, positionTicks: number): void {
    if (this.reportingPlayback) return
    if (this.reportPosition !== undefined
      && Math.abs(positionTicks - this.reportPosition) < 50000000) return // < 5s in ticks
    this.reportingPlayback = true
    this.reportPosition = positionTicks
    this.repository.onPlaybackProgress(assetId, positionTicks, this.control.isPlaying())
      .then(() => { this.reportingPlayback = false })
      .catch((_e: Error) => { this.reportingPlayback = false })
  }

  private reportPlaybackStop(): void {
    if (!this.currentAssetId) return
    this.reportingPlayback = true
    this.repository.onPlaybackStopped(this.currentAssetId, this.reportPosition || 0)
      .then(() => { this.reportingPlayback = false })
      .catch((_e: Error) => { this.reportingPlayback = false })
  }

  // ─── 销毁 ──────────────────────────────────────────────────────────────────

  async destroy(): Promise<void> {
    this.reportPlaybackStop()
    await super.destroy()
  }
}
