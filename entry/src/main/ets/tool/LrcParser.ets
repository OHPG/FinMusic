/**
 * Jellyfin LyricDto 中的歌词行
 */
export interface LyricLine {
  Start?: number
  Text?: string
}

/**
 * Jellyfin LyricDto
 */
export interface LyricDto {
  Metadata?: object
  Lyrics?: Array<LyricLine>
}

/**
 * 将 Jellyfin LyricDto JSON 转为标准 LRC 格式字符串。
 * Jellyfin 的 Start 单位是 ticks（1 tick = 100ns = 0.0001ms）。
 */
export class LrcParser {

  /**
   * 将 LyricDto 转为 LRC 字符串
   * @param dto Jellyfin 返回的歌词对象
   * @returns LRC 格式字符串，无有效歌词时返回 undefined
   */
  public static toLrc(dto: LyricDto): string | undefined {
    if (!dto.Lyrics || dto.Lyrics.length <= 0) {
      return undefined
    }
    return LrcParser.linesToLrc(dto.Lyrics)
  }

  /**
   * 将歌词行数组转为 LRC 字符串
   * @param lines 歌词行数组
   * @returns LRC 格式字符串
   */
  public static linesToLrc(lines: Array<LyricLine>): string {
    let lrcLines = new Array<string>()
    for (const line of lines) {
      if (line.Text === undefined || line.Text === null) {
        continue
      }
      if (line.Start !== undefined && line.Start !== null) {
        let ms = line.Start / 10000 // ticks → ms
        let totalSeconds = Math.floor(ms / 1000)
        let minutes = Math.floor(totalSeconds / 60)
        let seconds = totalSeconds % 60
        let centiseconds = Math.floor((ms % 1000) / 10)
        let timestamp = `${LrcParser.pad(minutes)}:${LrcParser.pad(seconds)}.${LrcParser.pad(centiseconds)}`
        lrcLines.push(`[${timestamp}]${line.Text}`)
      } else {
        lrcLines.push(line.Text)
      }
    }
    return lrcLines.join('\n')
  }

  private static pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`
  }
}
