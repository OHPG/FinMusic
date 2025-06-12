import { avSession } from "@kit.AVSessionKit"
import { AudioPlayer } from "./AudioPlayer"
import { AudioQueue } from "./AudioQueue"
import { media } from "@kit.MediaKit"
import { wantAgent } from "@kit.AbilityKit"
import { backgroundTaskManager } from "@kit.BackgroundTasksKit"
import { Repository } from "../data/Repository"
import { UserItemDataDto } from "@ohpg/jellyfin"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 17:07
 * @Version V1.0
 * @Description
 */
export class AudioSession {

  private readonly context: Context

  private readonly player: AudioPlayer

  private readonly queue: AudioQueue

  private session?: avSession.AVSession

  private sessionControl?: avSession.AVSessionController

  private inLongTimeTask = false

  private state: media.AVPlayerState = 'idle'

  private progress: number = 0

  private favourite = false

  private readonly repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  constructor(context: Context, queue: AudioQueue, player: AudioPlayer) {
    this.context = context
    this.queue = queue
    this.player = player
    this.player.onStateChange((state)=> {
      this.state = state
      this.updateState()
    })
    this.player.onProgressChange((progress) => {
      this.progress = progress
      this.updateState()
    })
    this.player.onError((error) => {

    })
  }

  public async getSession(): Promise<avSession.AVSession> {
    if (!this.session) {
      this.session = await avSession.createAVSession(this.context, "FinMusic", 'audio')
      this.session.on('play', () => {
        this.player.start()
      })
      this.session.on('pause', () => {
        this.player.pause()
      })
      this.session.on('stop', () => {
        this.player.stop()
      })
      this.session.on('playNext', () => {
        this.playNext()
      })
      this.session.on('playPrevious', () => {
        this.playPre()
      })
      this.session.on('seek', (time) => {
        this.player.seek(time)
      })
      this.session.on('setLoopMode', (mode) => {
        this.switchMode(mode)
      })
      this.session.on('toggleFavorite', (assetId) => {
        this.toggleFavourite(assetId)
      })
    }
    return this.session
  }

  private async playNext(): Promise<void> {
    let item = this.queue.getNext()
    if (item) {
      return this.playFromAssetId(item.id)
    }
  }

  private async playPre(): Promise<void> {
    let item = this.queue.getPre()
    if (item) {
      return this.playFromAssetId(item.id)
    }
  }

  switchMode(mode: avSession.LoopMode) {
    let curMode = mode + 1
    if (curMode >= avSession.LoopMode.LOOP_MODE_CUSTOM) {
      curMode = avSession.LoopMode.LOOP_MODE_SEQUENCE
    }
    this.queue.setMode(curMode)
    if (this.player.getState() !== 'playing') {
      this.updateState()
    }
  }

  public async getSessionControl(): Promise<avSession.AVSessionController> {
    if (!this.sessionControl) {
      let session = await this.getSession()
      this.sessionControl = await session.getController()
      this.sessionControl.on('sessionDestroy', () => {
        this.sessionControl = undefined
        this.session = undefined
      })
    }
    return this.sessionControl
  }

  public async playFromAssetId(id: string): Promise<void> {
    let item = this.queue.getCurrent()
    if (item?.id === id) {
      // media not change
      if (!this.player.isPrepared()) {
        await this.player.prepare()
      }
    } else {
      this.queue.setCurrentItem(id)
      item = this.queue.getCurrent()
      if (!item) {
        return
      }
      this.favourite = item.extra.UserData?.IsFavorite ? true : false
      let session = await this.getSession()
      await session.activate()
      await session.setAVMetadata({
        assetId: item.id,
        title: item.name,
        album: item.extra.Album,
        artist: item.extra.AlbumArtist,
        mediaImage: item.art,
        skipIntervals: avSession.SkipIntervals.SECONDS_10,
        duration: item.extra.RunTimeTicks ? item.extra.RunTimeTicks / 10000 : undefined
      })
      // 重制
      let pre = this.player.getData()
      if (item.id !== pre?.id) {
        await this.player.reset()
        await this.player.setData(item)
      }
      await this.player.prepare()
    }
    await this.player.start()
  }

  private async toggleFavourite(id: string): Promise<void> {
    let userItemDto: UserItemDataDto
    if (this.favourite) {
      userItemDto = await this.repository.unmarkFavorite(id)
    } else {
      userItemDto = await this.repository.markFavorite(id)
    }
    let target = this.queue.getItemById(id)
    let current = this.queue.getCurrent()
    if (target) {
      target.extra.UserData = userItemDto
      if (target.id === current?.id) {
        this.favourite = userItemDto.IsFavorite ? true : false
        if (this.player.getState() !== 'playing') {
          await this.updateState()
        }
      }
    }
  }

  private async updateState() {
    let session = await this.getSession()
    let playState = avSession.PlaybackState.PLAYBACK_STATE_INITIAL
    switch (this.state) {
      case 'prepared':
        playState = avSession.PlaybackState.PLAYBACK_STATE_PREPARE
        break
      case 'playing':
        playState = avSession.PlaybackState.PLAYBACK_STATE_PLAY
        break
      case 'paused':
        playState = avSession.PlaybackState.PLAYBACK_STATE_PAUSE
        break
      case 'completed':
        playState = avSession.PlaybackState.PLAYBACK_STATE_COMPLETED
        break
      case 'stopped':
        playState = avSession.PlaybackState.PLAYBACK_STATE_STOP
        break
      case 'error':
        playState = avSession.PlaybackState.PLAYBACK_STATE_ERROR
        break
    }
    if (this.state === 'playing') {
      this.startContinuousTask()
    } else {
      this.stopContinuousTask()
    }
    let avState: avSession.AVPlaybackState = {
      state: playState,
      isFavorite: this.favourite,
      loopMode: this.queue.getMode(),
      position: {
        elapsedTime: this.progress,
        updateTime:  new Date().getTime()
      },
      duration: this.player.getDuration()
    }
    await session.setAVPlaybackState(avState)
    if (playState === avSession.PlaybackState.PLAYBACK_STATE_COMPLETED) {
      if (this.queue.getMode() === avSession.LoopMode.LOOP_MODE_SINGLE) {
        this.player.start()
      } else {
        this.playNext()
      }
    }
  }

  /**
   * Start a long-time task.
   */
  async startContinuousTask(): Promise<void> {
    if (this.inLongTimeTask) {
      return
    }
    console.info("AudioSession", 'start background.');
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.applicationInfo.name,
          abilityName: 'EntryAbility'
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    let tmpWantAgent = await wantAgent.getWantAgent(wantAgentInfo);
    console.info("AudioSession", 'start background agent ready.');
    let session = await this.getSession()
    console.info("AudioSession", 'start background session ready.');
    // Sets the application page that can be invoked when a playback control card is clicked.
    session.setLaunchAbility(tmpWantAgent);
    await backgroundTaskManager.startBackgroundRunning(this.context,
      backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, tmpWantAgent);
    this.inLongTimeTask = true
    console.info("AudioSession", 'start background finish.');
  }

  /**
   * Close a long-time task.
   */
  async stopContinuousTask(): Promise<void> {
    if (!this.inLongTimeTask) {
      return
    }
    console.info("AudioSession", 'stop background.');
    await backgroundTaskManager.stopBackgroundRunning(this.context)
    this.inLongTimeTask = false
    console.info("AudioSession", 'stop background end.');
  }

  public release() {
    this.player.offError()
    this.player.offProgressChange()
    this.player.offStateChange()
    this.session?.destroy()
    this.session = undefined
    this.sessionControl = undefined
  }

}