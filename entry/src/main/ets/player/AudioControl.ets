import { AudioSession } from "./AudioSession";
import { avSession } from "@kit.AVSessionKit";
import { AudioQueue } from "./AudioQueue";
import { Repository } from "../data/Repository";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 17:27
 * @Version V1.0
 * @Description
 */
export class AudioControl {

  private readonly context: Context

  private readonly queue: AudioQueue

  private readonly session: AudioSession

  private readonly repository: Repository

  private sessionControl?: avSession.AVSessionController

  private metadata?: avSession.AVMetadata

  private playbackState?: avSession.AVPlaybackState

  private metadataChangeSet = new Set<(data: avSession.AVMetadata) => void>()

  private playbackStateChangeSet = new Set<(data: avSession.AVPlaybackState) => void>()

  constructor(context: Context, queue: AudioQueue, session: AudioSession) {
    this.context = context
    this.queue = queue
    this.session = session
    this.repository = AppStorage.get(Repository.REPOSITORY)!
  }

  public getMetadata(): avSession.AVMetadata | undefined {
    return this.metadata
  }

  public getPlaybackState(): avSession.AVPlaybackState | undefined {
    return this.playbackState
  }

  private getSession(): Promise<avSession.AVSession> {
    return this.session.getSession()
  }

  private async getSessionControl(): Promise<avSession.AVSessionController> {
    if (!this.sessionControl) {
      this.sessionControl = await this.session.getSessionControl()
      this.sessionControl.on('metadataChange', 'all', (metadata) => {
        this.metadata = metadata
        this.metadataChangeSet.forEach((callback) =>{
          callback(metadata)
        })
      })
      this.sessionControl.on('playbackStateChange', 'all', (state) => {
        this.playbackState = state
        this.playbackStateChangeSet.forEach((callback) =>{
          callback(state)
        })
      })
      this.sessionControl.on('sessionDestroy', () => {
        this.sessionControl = undefined
      })
    }
    return this.sessionControl
  }

  onMetadataChange(callback: (data: avSession.AVMetadata) => void) {
    this.metadataChangeSet.add(callback)
  }

  offMetadataChange(callback?: (data: avSession.AVMetadata) => void) {
    if (callback) {
      this.metadataChangeSet.delete(callback)
    } else {
      this.metadataChangeSet.clear()
    }
  }

  onPlaybackStateChange(callback: (data: avSession.AVPlaybackState) => void) {
    this.playbackStateChangeSet.add(callback)
  }

  offPlaybackStateChange(callback?: (data: avSession.AVPlaybackState) => void) {
    if (callback) {
      this.playbackStateChangeSet.delete(callback)
    } else {
      this.playbackStateChangeSet.clear()
    }
  }

  public async switchMode(): Promise<void> {
    let control = await this.getSessionControl()
    return control.sendControlCommand({command: 'setLoopMode', parameter: this.queue.getMode()})
  }

  public async toggleFavourite() {
    let control = await this.getSessionControl()
    control.sendControlCommand({command: "toggleFavorite", parameter: this.metadata?.assetId})
  }

  public async prepareItem(id: string) {
    await this.getSessionControl()
    await this.session.prepareFromAssetId(id)
  }

  public async playItem(id: string) {
    await this.getSessionControl()
    await this.session.playFromAssetId(id)
  }

  public async play(): Promise<void> {
    let control = await this.getSessionControl()
    return control.sendControlCommand({command: 'play'})
  }

  public async pause(): Promise<void> {
    let control = await this.getSessionControl()
    return control.sendControlCommand({command: 'pause'})
  }

  public async seek(pos: number): Promise<void> {
    let control = await this.getSessionControl()
    return control.sendControlCommand({command: 'seek', parameter: pos})
  }

  public async next(): Promise<void> {
    let control = await this.getSessionControl()
    return control.sendControlCommand({command: 'playNext'})
  }

  public async pre(): Promise<void> {
    let control = await this.getSessionControl()
    return control.sendControlCommand({command: 'playPrevious'})
  }

}