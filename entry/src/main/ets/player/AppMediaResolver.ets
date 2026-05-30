import { AVMediaResolver, AVMediaResolveResult } from '@ohpg/player'
import { avSession } from '@kit.AVSessionKit'
import { Repository } from '../data/Repository'

/**
 * FinMusic 媒体解析器。
 * 通过 AVPlayerKit.setMediaResolver() 全局注册，
 * 负责将队列项中的 assetId 解析为真实音频流 URL。
 */
export class AppMediaResolver implements AVMediaResolver {

  private readonly repository: Repository

  constructor(repository: Repository) {
    this.repository = repository
  }

  async resolve(item: avSession.AVQueueItem): Promise<AVMediaResolveResult> {
    let assetId = item.description?.assetId ?? ''
    console.info("FinMusic: resolve assetId=" + assetId)
    let url = await this.repository.loadStreamUrl(assetId, assetId)
    console.info("FinMusic: resolve url=" + url)
    let result: AVMediaResolveResult = {
      url: url
    }
    return result
  }
}
