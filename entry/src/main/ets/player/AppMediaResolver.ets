import { avSession } from '@kit.AVSessionKit'
import { AVMediaResolver, AVMediaResolveResult, PlaybackParams } from '@ohpg/player'
import { Repository } from '../data/Repository'
import { LyricDto } from '../tool/LrcParser'
import { LyricCache } from './LyricCache'

/**
 * FinMusic 的媒体解析器实现。
 * 负责：
 * 1. 从 queue item 中提取真实播放 URL（mediaUri 即 itemId，需要转为流地址）
 * 2. 通过 LyricCache 获取歌词文件路径，传递给播放器
 */
export class AppMediaResolver implements AVMediaResolver {

  private readonly repository: Repository

  private readonly lyricCache: LyricCache

  constructor() {
    this.repository = AppStorage.get(Repository.REPOSITORY)!
    this.lyricCache = AppStorage.get(LyricCache.LYRIC_CACHE)!
  }

  async resolve(item: avSession.AVQueueItem): Promise<AVMediaResolveResult> {
    let desc = item.description!
    let itemId = desc.assetId

    // 获取音频流 URL
    let url = await this.repository.loadStreamUrl(itemId, itemId)

    // 获取歌词文件路径
    let params: PlaybackParams | undefined = undefined
    try {
      let lrcPath = await this.lyricCache.resolve(itemId, (): Promise<LyricDto | undefined> => {
        return this.repository.getLyrics(itemId) as Promise<LyricDto | undefined>
      })
      if (lrcPath) {
        params = { subtitles: [lrcPath] }
      }
    } catch (e) {
      console.info("FinMusic: AppMediaResolver resolveLyric failed: " + (e as Error).message)
    }

    return { url, params }
  }
}
