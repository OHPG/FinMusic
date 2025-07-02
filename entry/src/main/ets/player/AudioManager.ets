import { BaseItemDto, ImageType } from '@ohpg/jellyfin'
import { Repository } from '../data/Repository'
import { AudioControl } from './AudioControl'
import { AudioItem } from './AudioItem'
import { AudioPlayer } from './AudioPlayer'
import { AudioQueue } from './AudioQueue'
import { AudioSession } from './AudioSession'
/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 17:15
 * @Version V1.0
 * @Description
 */
export class AudioManager {

  public static readonly AUDIO_MANAGER = 'audioManager'

  private readonly audioQueue: AudioQueue

  private readonly audioControl: AudioControl

  private readonly audioSession: AudioSession

  private readonly audioPlayer: AudioPlayer

  public readonly repository: Repository

  private ignoreQueueChanged = false

  constructor(context: Context) {
    this.audioPlayer = new AudioPlayer(context)
    this.audioQueue = new AudioQueue(context)
    this.audioQueue.on('queueChanged', () => {
      if (!this.ignoreQueueChanged) {
        this.saveAudioQueue()
      }
    })
    this.audioSession = new AudioSession(context, this.audioQueue, this.audioPlayer)
    this.audioControl = new AudioControl(context, this.audioQueue, this.audioSession)
    this.repository = AppStorage.get(Repository.REPOSITORY)!
  }

  public getAudioQueue(): AudioQueue {
    return this.audioQueue
  }

  public getAudioSession(): AudioSession {
    return this.audioSession
  }

  public getAudioControl(): AudioControl {
    return this.audioControl
  }

  public async resumeAudioQueue(): Promise<void> {
    let items = await this.repository.getPlayList()
    if (!items || items.length <= 0) {
      return
    }
    let audioItems = new Array<AudioItem>()
    let lastAudioItem: BaseItemDto | undefined = undefined
    for (let item of items) {
      audioItems.push({
        id: item.Id!,
        name: item.Name!,
        art: this.repository.buildImage(item, ImageType.Primary)!,
        url: await this.repository.loadStreamUrl(item.Id!, item.Id!),
        extra: item
      })
      if (lastAudioItem) {
        if (item.UserData?.LastPlayedDate
          && lastAudioItem.UserData?.LastPlayedDate
          && item.UserData.LastPlayedDate > lastAudioItem.UserData.LastPlayedDate) {
          lastAudioItem = item
        }
      } else {
        lastAudioItem = item
      }
    }
    if (lastAudioItem) {
      this.ignoreQueueChanged = true
      this.audioQueue.resetItem(audioItems)
      this.ignoreQueueChanged = false
      // TODO 进度恢复
      await this.audioControl.playItem(lastAudioItem.Id!)
    }
  }

  private saveAudioQueue() {
    let queue = this.audioQueue.getQueue()
    if (!queue || queue.length <= 0) {
      return
    }
    let itemArray = new Array<BaseItemDto>()
    for (const item of queue) {
      itemArray.push(item.extra)
    }
    this.repository.setPlaylist(itemArray)
  }

  public release() {
    this.audioSession.release()
    this.audioQueue.release()
  }

}