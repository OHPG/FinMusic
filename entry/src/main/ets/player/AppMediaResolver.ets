import { avSession } from '@kit.AVSessionKit'
import { AVMediaResolver, AVMediaResolveResult, PlaybackParams } from '@ohpg/player'
import { FileTool } from '@ohpg/fin-core'
import { Repository } from '../data/Repository'
import { LyricDto, LrcParser } from '../tool/LrcParser'

/**
 * FinMusic 的媒体解析器实现。
 * 负责：
 * 1. 从 queue item 中提取真实播放 URL（mediaUri 即 itemId，需要转为流地址）
 * 2. 获取歌词并缓存为 LRC 文件，通过 subtitles 传递给播放器
 */
export class AppMediaResolver implements AVMediaResolver {

  private readonly repository: Repository

  private readonly lrcDir: string

  constructor(context: Context, repository: Repository) {
    this.repository = repository
    this.lrcDir = context.getApplicationContext().filesDir + '/lrc'
    FileTool.ensureDir(this.lrcDir)
  }

  async resolve(item: avSession.AVQueueItem): Promise<AVMediaResolveResult> {
    let desc = item.description!
    let itemId = desc.assetId

    // 获取音频流 URL
    let url = await this.repository.loadStreamUrl(itemId, itemId)

    // 获取歌词缓存文件路径
    let params: PlaybackParams | undefined = undefined
    try {
      let lrcPath = await this.resolveLyric(itemId)
      if (lrcPath) {
        params = { subtitles: [lrcPath] }
      }
    } catch (e) {
      console.info("FinMusic: AppMediaResolver resolveLyric failed: " + (e as Error).message)
    }

    return { url, params }
  }

  /**
   * 获取歌词文件路径（优先读缓存，无缓存则拉取并写入）
   * @returns 缓存文件路径，无歌词时返回 undefined
   */
  private async resolveLyric(itemId: string): Promise<string | undefined> {
    let filePath = `${this.lrcDir}/${itemId}.lrc`

    // 缓存命中
    if (FileTool.exists(filePath)) {
      return filePath
    }

    // 拉取歌词
    let lyricDto = await this.repository.getLyrics(itemId) as LyricDto | undefined
    if (!lyricDto) {
      return undefined
    }

    // 转 LRC
    let lrcContent = LrcParser.toLrc(lyricDto)
    if (!lrcContent) {
      return undefined
    }

    // 写入缓存
    FileTool.writeText(filePath, lrcContent)
    return filePath
  }
}
