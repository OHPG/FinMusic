import { media } from "@kit.MediaKit";
import { Repository } from "../data/Repository";
import { ErrorCallback } from "@ohos.base";
import { AudioItem } from "./AudioItem";
import { MediaProtocol, MediaSourceInfo } from "@ohpg/jellyfin";

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

  private avPlayer?: media.AVPlayer

  private avState: media.AVPlayerState = 'idle';

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
      console.log("VideoController: onStateChange state = " + state + ", reason = " + reason)
      this.avState = state
      if (state === 'initialized') {
        this.avPlayer?.prepare()
      }
      if (state === 'prepared') {
        console.log("VideoController: duration = " + this.avPlayer?.duration)
        this.avPlayer!.videoScaleType = media.VideoScaleType.VIDEO_SCALE_TYPE_FIT_CROP
        if (this.avSpeed !== undefined) {
          this.avPlayer?.setSpeed(this.avSpeed)
        }
        this.avPlayer?.play()
      }
      if (state === 'playing') {
        this.startTimer()
      } else {
        this.stopTimer()
      }
      this.stateChangeCallback?.(state, reason)
    })
    this.avPlayer.on('seekDone', (position) => {
      console.log("VideoController: onSeekDone position = " + position)
    })
    this.avPlayer.on('bufferingUpdate', (type, value) => {
      // console.log("VideoController: onBufferUpdate type = " + type + ", value = " + value)
    })
    this.avPlayer.on('trackChange', (index, selected) => {
      console.log("VideoController: onTrackChange index = " + index + ", selected = " + selected)
    })
    this.avPlayer.on('durationUpdate', (duration) => {
      console.log("VideoController: onDurationUpdate duration = " + duration)
    })
    this.avPlayer.on('error', (error) => {
      console.log("VideoController: onError error = " + JSON.stringify(error))
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

  private async printTrackInfo() {
    let info = await this.avPlayer?.getPlaybackInfo()
    console.log("VideoController: getPlaybackInfo = " + JSON.stringify(info) )
    let selected = await this.avPlayer!.getSelectedTracks()
    console.log("VideoController: getSelectedTracks = " + selected.join(",") )
    let tracks = await this.avPlayer!.getTrackDescription()
    tracks.forEach((info) => {
      console.log("VideoController: getTrackDescription = " + JSON.stringify(info) )
    })
  }

  private startTimer() {
    this.printTrackInfo()
    if (this.avTimer) return
    this.avTimer = setInterval(() => {
      this.progressCallback?.(this.getPosition())
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

  public async getSource(id: string, sourceInfo: MediaSourceInfo): Promise<string> {
    let url: string | undefined | null
    switch (sourceInfo.Protocol) {
      case MediaProtocol.File:
        url = await this.repository.loadStreamUrl(id, sourceInfo.Id!)
        break
      case MediaProtocol.Http:
        url = sourceInfo.Path
        break
    }
    if (url) {
      return url
    }
    throw new Error("Source not support.")
  }

  public async setData(item: AudioItem): Promise<void> {
    let sourceResult = await this.repository.loadMediaSource(item.id)
    // let url = await this.getSource(item.id, (sourceResult!.MediaSources![0])!)
    let url = await this.repository.loadStreamUrl(item.id, item.id)
    console.log("VideoController: setData data 1" )
    let avPlayer = await this.requireAvPlayer()
    console.log("VideoController: setData data 2")
    avPlayer.url = url
    console.log("VideoController: setData data 3 url = " + avPlayer.url)
  }

  public async prepare(): Promise<void> {
    let avPlayer = await this.requireAvPlayer()
    console.log("VideoController: prepare 1" )
    await avPlayer.prepare()
    console.log("VideoController: prepare 2" )
  }

  public getState(): media.AVPlayerState {
    return this.avState
  }

  public isPrepared(): boolean {
    return false
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
    await this.avPlayer?.play()
  }

  public async seek(position: number): Promise<void> {
    console.log("VideoController: seek " + position)
    this.avPlayer?.seek(position, media.SeekMode.SEEK_CLOSEST)
  }

  public async pause(): Promise<void> {
    await this.avPlayer?.pause()
  }

  public async stop(): Promise<void> {
    await this.avPlayer?.stop()
  }

  public async reset(): Promise<void> {
    await this.avPlayer?.reset()
  }

  public async release(): Promise<void> {
    this.progressCallback = undefined
    this.errorCallback = undefined
    this.stateChangeCallback = undefined
    await this.avPlayer?.release()
  }

}