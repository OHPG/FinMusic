import { media } from "@kit.MediaKit";
import { Repository } from "../data/Repository";
import { ErrorCallback } from "@ohos.base";
import { AudioItem } from "./AudioItem";
import { BaseItemDto } from "@ohpg/jellyfin";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 17:00
 * @Version V1.0
 * @Description
 */
export class AudioPlayer {

  private readonly context: Context

  private readonly repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  private reportingPlayback: boolean = false

  private lastPosition = 0

  private playWhenReady = false

  private seekWhenReady = -1

  private avPlayer?: media.AVPlayer

  private avPlayerPrepared = false

  private avState: media.AVPlayerState = 'idle';

  private itemDto?: BaseItemDto

  private avTimer?: number = 0

  private avSpeed?: media.PlaybackSpeed

  private avData?: AudioItem = undefined

  private stateChangeCallback?: media.OnAVPlayerStateChangeHandle

  private progressCallback?: Callback<number>

  private errorCallback?: ErrorCallback

  constructor(context: Context) {
    this.context = context
  }

  private async requireAvPlayer(): Promise<media.AVPlayer> {
    if (this.avPlayer) {
      return this.avPlayer
    }
    // player
    this.avPlayer = await media.createAVPlayer()
    this.avPlayer.on('stateChange', (state, reason) => {
      console.log("AudioPlayer: onStateChange state = " + state + ", reason = " + reason)
      this.avState = state
      if (state === 'initialized') {
        this.avPlayer?.prepare()
      }
      if (state === 'prepared') {
        this.avPlayerPrepared = true
        console.log("AudioPlayer: duration = " + this.avPlayer?.duration)
        if (this.avSpeed !== undefined) {
          this.avPlayer?.setSpeed(this.avSpeed)
        }
        if (this.seekWhenReady > 0) {
          this.seek(this.seekWhenReady)
          this.seekWhenReady = -1
        }
        if (this.playWhenReady) {
          this.start()
          this.playWhenReady = false
        }
      }
      if (state === 'playing') {
        this.startTimer()
      } else {
        this.stopTimer()
      }
      this.stateChangeCallback?.(state, reason)
    })
    this.avPlayer.on('seekDone', (position) => {
      console.log("AudioPlayer: onSeekDone position = " + position)
    })
    this.avPlayer.on('bufferingUpdate', (type, value) => {
      // console.log("AudioPlayer: onBufferUpdate type = " + type + ", value = " + value)
    })
    this.avPlayer.on('trackChange', (index, selected) => {
      console.log("AudioPlayer: onTrackChange index = " + index + ", selected = " + selected)
    })
    this.avPlayer.on('durationUpdate', (duration) => {
      console.log("AudioPlayer: onDurationUpdate duration = " + duration)
    })
    this.avPlayer.on('error', (error) => {
      this.avPlayerPrepared = false
      console.log("AudioPlayer: onError error = " + JSON.stringify(error))
      this.errorCallback?.(error)
    })
    return this.avPlayer
  }

  onProgressChange(callback: Callback<number>) {
    this.progressCallback = callback
  }

  offProgressChange() {
    this.progressCallback = undefined
  }

  onStateChange(callback: media.OnAVPlayerStateChangeHandle) {
    this.stateChangeCallback = callback
  }

  offStateChange() {
    this.stateChangeCallback = undefined
  }

  onError(callback: ErrorCallback) {
    this.errorCallback = callback
  }

  offError() {
    this.errorCallback = undefined
  }

  private count = 0

  private startTimer() {
    if (this.avTimer) return
    this.avTimer = setInterval(() => {
      this.progressCallback?.(this.getPosition())
      this.count ++
      if (this.count >= 5) {
        this.reportPlaybackUpdate()
        this.count = 0
      }
    }, 1000)
  }

  private stopTimer() {
    if (this.avTimer) {
      clearInterval(this.avTimer)
      this.avTimer = undefined
    }
  }

  public getDuration(): number {
    if (this.avPlayer) {
      return this.avPlayer.duration
    }
    return 0
  }

  public getPosition(): number {
    if (this.avPlayer) {
      return this.avPlayer.currentTime
    }
    return 0
  }

  public getData(): AudioItem | undefined {
    return this.avData
  }

  public async setData(item: AudioItem): Promise<void> {
    this.itemDto = item.extra
    let url = await this.repository.loadStreamUrl(item.id, item.id)
    let avPlayer = await this.requireAvPlayer()
    avPlayer.url = url
    this.reportPlaybackStart()
  }

  public async prepare(): Promise<void> {
    if (this.avState === 'initialized') {
      let avPlayer = await this.requireAvPlayer()
      await avPlayer.prepare()
    } else {
      // prepare auto
    }
  }

  public getState(): media.AVPlayerState {
    return this.avState
  }

  public isPrepared(): boolean {
    return this.avPlayerPrepared
  }

  public getSpeed(): media.PlaybackSpeed {
    if (this.avSpeed === undefined) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_00_X
    }
    return this.avSpeed
  }

  public setSpeed(speed: media.PlaybackSpeed) {
    this.avSpeed = speed
    this.avPlayer?.setSpeed(speed)
  }

  public async getTrackInfo(type: media.MediaType): Promise<Array<media.MediaDescription>> {
    let trackArray = new Array<media.MediaDescription>()
    if (this.avPlayer) {
      let allTracks = await this.avPlayer!.getTrackDescription()
      allTracks.forEach((track) => {
        let trackType = track[media.MediaDescriptionKey.MD_KEY_TRACK_TYPE] as media.MediaType
        if (trackType === type) {
          trackArray.push(track)
        }
      })
    }
    return trackArray
  }

  public async getCurrentTrack(): Promise<Array<number>> {
    if (this.avPlayer) {
      return this.avPlayer.getSelectedTracks()
    } else {
      return []
    }
  }

  public selectTrack(index: number) {
    this.avPlayer?.selectTrack(index)
  }

  public async start(): Promise<void> {
    if (this.isPrepared()) {
      console.log("AudioPlayer: start")
      await this.avPlayer?.play()
      this.reportPlaybackUpdate()
    } else {
      console.log("AudioPlayer: start (when ready)")
      this.playWhenReady = true
    }
  }

  public async seek(position: number): Promise<void> {
    if (this.isPrepared()) {
      console.log("AudioPlayer: seek")
      this.avPlayer?.seek(position, media.SeekMode.SEEK_CLOSEST)
    } else {
      console.log("AudioPlayer: seek (when ready)")
      this.seekWhenReady = position
    }
  }

  public async pause(): Promise<void> {
    await this.avPlayer?.pause()
    this.reportPlaybackUpdate()
  }

  public async stop(): Promise<void> {
    await this.avPlayer?.stop()
  }

  public async reset(): Promise<void> {
    try {
      console.log("AudioPlayer: reset")
      this.playWhenReady = false
      this.avPlayerPrepared = false
      await this.avPlayer?.reset()
      this.reportPlaybackStop()
      this.itemDto = undefined
    } catch (e) {
      console.log("AudioPlayer: reset: " + JSON.stringify(e))
      throw e as Error
    }
  }

  private reportPlaybackStart() {
    if (!this.itemDto) {
      return
    }
    // console.log("AbstractController: reportPlaybackStart " + this.itemDto.Id)
    this.reportingPlayback = true
    this.repository.onPlaybackStart(this.itemDto.Id!)
      .then(() => {
        this.reportingPlayback = false
        // console.log("AbstractController: reportPlaybackStart success.")
      })
      .catch((error: Error) => {
        this.reportingPlayback = false
        // console.warn("AbstractController: reportPlaybackStart fail " + JSON.stringify(error))
      })
  }

  private reportPlaybackUpdate() {
    if (!this.itemDto || this.reportingPlayback) {
      return
    }
    this.reportingPlayback = true
    this.lastPosition = this.getPosition() * 10000
    // console.log("AbstractController: reportPlaybackUpdate " + this.itemDto.Id + ", position = " + this.lastPosition)
    this.repository.onPlaybackUpdate(this.itemDto.Id!, this.lastPosition, this.avState === 'playing')
      .then(() => {
        this.reportingPlayback = false
        // console.log("AbstractController: reportPlaybackUpdate success.")
      })
      .catch((error: Error) => {
        this.reportingPlayback = false
        // console.warn("AbstractController: reportPlaybackUpdate fail " + JSON.stringify(error))
      })
  }

  private reportPlaybackStop() {
    if (!this.itemDto) {
      return
    }
    this.reportingPlayback = true
    // console.log("AbstractController: reportPlaybackStop " + this.itemDto.Id)
    this.repository.onPlaybackStop(this.itemDto.Id!, this.lastPosition)
      .then(() => {
        this.reportingPlayback = false
        // console.log("AbstractController: reportPlaybackStop success.")
      })
      .catch((error: Error) => {
        this.reportingPlayback = false
        // console.warn("AbstractController: reportPlaybackStop fail " + JSON.stringify(error))
      })
  }

  public async release(): Promise<void> {
    await this.reset()
    this.progressCallback = undefined
    this.errorCallback = undefined
    this.stateChangeCallback = undefined
    await this.avPlayer?.release()
  }

}