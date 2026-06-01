import { AVCodecType, AVRenderType } from '@ohpg/player'
import { SystemPlayer } from '@ohpg/system'
import { Proxy } from '@ohpg/proxy'
import { MD5 } from '@ohpg/fin-core'
import { AppPrefer } from '../prefer/AppPrefer'

/**
 * FinMusic 的播放器实现。
 * 继承 SystemPlayer，覆写 setData：
 * - 缓存开启时通过 Proxy 代理实现边播边缓存
 * - 代理启动失败则回退到非代理模式
 */
export class AppPlayer extends SystemPlayer {

  private proxyReady: boolean = false

  constructor(context: Context, render: AVRenderType, codec?: AVCodecType) {
    super(context, render, codec)
  }

  public async setData(url: string, header?: Record<string, string>): Promise<void> {
    let prefer = AppStorage.get<AppPrefer>(AppPrefer.PREFER)
    let cacheEnabled = prefer ? prefer.isCacheEnabled() : false

    if (cacheEnabled && url.startsWith('http')) {
      try {
        await this.ensureProxy()
        let cacheKey = this.extractCacheKey(url)
        let proxyUrl = Proxy.buildProxyUrl(url, header, cacheKey)
        console.info("FinMusic: AppPlayer proxy cache key=" + cacheKey)
        await super.setData(proxyUrl, undefined)
        return
      } catch (e) {
        console.error("FinMusic: AppPlayer proxy failed, fallback: " + (e as Error).message)
      }
    }

    await super.setData(url, header)
  }

  /**
   * 确保代理已启动，未启动则启动
   */
  private async ensureProxy(): Promise<void> {
    if (this.proxyReady && Proxy.isRunning()) {
      return
    }
    let prefer = AppStorage.get<AppPrefer>(AppPrefer.PREFER)!
    await Proxy.start()
    Proxy.setDnsCacheEnabled(prefer.isDnsCacheEnabled())
    this.proxyReady = true
    console.info("FinMusic: AppPlayer proxy started, port=" + Proxy.getPort())
  }

  /**
   * 从流地址中提取 cacheKey。
   * 优先提取 Jellyfin itemId，提取不到则用 MD5(url) 保底。
   */
  private extractCacheKey(url: string): string {
    try {
      let match = url.match(/\/Audio\/([a-f0-9\-]+)\//i)
      if (match && match[1]) {
        return match[1]
      }
      match = url.match(/\/Items\/([a-f0-9\-]+)\//i)
      if (match && match[1]) {
        return match[1]
      }
    } catch (_) {
    }
    return MD5.digestSync(url)
  }
}
