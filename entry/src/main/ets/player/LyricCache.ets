import { FileTool } from '@ohpg/fin-core'
import { AppPrefer } from '../prefer/AppPrefer'
import { LyricDto, LrcParser } from '../tool/LrcParser'

/**
 * 歌词缓存管理。
 * - 缓存开启：lrc 文件持久化到 filesDir/lrc/{itemId}.lrc
 * - 缓存关闭：写入固定文件 filesDir/lrc_temp.lrc，每次覆盖
 */
export class LyricCache {

  public static readonly LYRIC_CACHE = "lyric_cache"

  private readonly lrcDir: string

  private readonly tempFile: string

  private readonly prefer: AppPrefer

  constructor(context: Context) {
    let filesDir = context.getApplicationContext().filesDir
    this.lrcDir = filesDir + '/lrc'
    this.tempFile = filesDir + '/lrc_temp.lrc'
    this.prefer = AppStorage.get<AppPrefer>(AppPrefer.PREFER)!
    FileTool.ensureDir(this.lrcDir)
  }

  /**
   * 获取歌词文件路径。
   * @param itemId 音频 item id
   * @param fetcher 歌词拉取回调
   * @returns lrc 文件路径，无歌词时返回 undefined
   */
  async resolve(itemId: string, fetcher: () => Promise<LyricDto | undefined>): Promise<string | undefined> {
    if (this.prefer.isLyricCacheEnabled()) {
      return this.resolveWithCache(itemId, fetcher)
    } else {
      return this.resolveToTemp(itemId, fetcher)
    }
  }

  /**
   * 获取歌词缓存目录总大小（字节）
   */
  getCacheSize(): number {
    return FileTool.getDirSize(this.lrcDir)
  }

  /**
   * 清理所有歌词缓存文件
   */
  clearAll(): void {
    FileTool.clearDir(this.lrcDir)
  }

  /**
   * 持久化模式：优先读缓存，未命中则拉取并写入
   */
  private async resolveWithCache(itemId: string, fetcher: () => Promise<LyricDto | undefined>): Promise<string | undefined> {
    let filePath = `${this.lrcDir}/${itemId}.lrc`

    // 缓存命中
    if (FileTool.exists(filePath)) {
      return filePath
    }

    // 拉取并写入
    return this.fetchAndWrite(filePath, fetcher)
  }

  /**
   * 非持久化模式：写入固定临时文件，每次覆盖
   */
  private async resolveToTemp(itemId: string, fetcher: () => Promise<LyricDto | undefined>): Promise<string | undefined> {
    return this.fetchAndWrite(this.tempFile, fetcher)
  }

  /**
   * 拉取歌词并写入指定路径
   */
  private async fetchAndWrite(filePath: string, fetcher: () => Promise<LyricDto | undefined>): Promise<string | undefined> {
    let lyricDto = await fetcher()
    if (!lyricDto) {
      return undefined
    }

    let lrcContent = LrcParser.toLrc(lyricDto)
    if (!lrcContent) {
      return undefined
    }

    FileTool.writeText(filePath, lrcContent)
    return filePath
  }
}
