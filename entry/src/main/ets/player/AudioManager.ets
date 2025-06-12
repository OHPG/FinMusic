import { AudioControl } from './AudioControl'
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

  constructor(context: Context) {
    this.audioPlayer = new AudioPlayer(context)
    this.audioQueue = new AudioQueue()
    this.audioSession = new AudioSession(context, this.audioQueue, this.audioPlayer)
    this.audioControl = new AudioControl(context, this.audioQueue, this.audioSession)
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

  public release() {
    this.audioSession.release()
  }

}