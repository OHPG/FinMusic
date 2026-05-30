import { AVCodecType, AVPlayer, AVPlayerFactory, AVRenderType } from '@ohpg/player'
import { SystemPlayer } from '@ohpg/system'

export class AppPlayerFactory implements AVPlayerFactory {
  create(context: Context, render: AVRenderType, codec?: AVCodecType): AVPlayer {
    return new SystemPlayer(context, render, codec)
  }
}
