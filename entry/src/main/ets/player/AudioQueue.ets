import { AudioItem } from "./AudioItem";
import { avSession } from "@kit.AVSessionKit";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 17:08
 * @Version V1.0
 * @Description
 */
export class AudioQueue {

  private readonly context: Context

  private loopMode = avSession.LoopMode.LOOP_MODE_SEQUENCE

  private audioQueue = new Array<AudioItem>()

  private audioIndex = -1

  private queueCallback?: Callback<void>

  constructor(context: Context) {
    this.context = context
  }

  on(type: "queueChanged", callback: Callback<void>) {
    this.queueCallback = callback
  }

  off(type: "queueChanged") {
    this.queueCallback = undefined
  }

  public setCurrentItem(id: string) {
    this.audioIndex = this.audioQueue.findIndex((value) => value.id == id)
  }

  public setMode(mode: avSession.LoopMode) {
    this.loopMode = mode
  }

  public getMode(): avSession.LoopMode {
    return this.loopMode
  }

  public addItem(items: AudioItem[]) {
    this.audioQueue.push(...items)
    this.queueCallback?.()
  }

  public resetItem(items: AudioItem[]) {
    this.audioQueue.splice(0)
    this.audioQueue.push(...items)
    this.queueCallback?.()
  }

  public deleteItem(item: AudioItem) {
    let index = this.audioQueue.indexOf(item)
    if (index >= 0) {
      this.audioQueue.splice(index, 1)
    }
    this.queueCallback?.()
  }

  public deleteAll() {
    this.audioQueue.splice(0)
    this.audioIndex = -1
    this.queueCallback?.()
  }

  public getQueue(): Array<AudioItem> {
    return this.audioQueue
  }

  public getItem(index: number): AudioItem {
    return this.audioQueue[index]
  }

  public getItemById(id: string): AudioItem | undefined {
    return this.audioQueue.find((value) => value.id == id)
  }

  public getCurrent(): AudioItem | undefined {
    if (this.audioIndex < 0 || this.audioIndex >= this.audioQueue.length) {
      return undefined
    }
    return this.audioQueue[this.audioIndex]
  }

  private getRandom(): AudioItem | undefined {
    if (this.audioQueue.length > 0) {
      let index = Date.now() % this.audioQueue.length
      return this.getItem(index)
    }
    return undefined
  }

  public getPre(): AudioItem | undefined{
    if (this.loopMode === avSession.LoopMode.LOOP_MODE_SHUFFLE) {
      return this.getRandom()
    } else {
      let index = this.audioIndex - 1
      if (index < 0) {
        index = this.audioQueue.length - 1
      }
      return this.getItem(index)
    }
  }

  public getNext(): AudioItem | undefined{
    if (this.loopMode === avSession.LoopMode.LOOP_MODE_SHUFFLE) {
      return this.getRandom()
    } else {
      let index = this.audioIndex + 1
      if (index >= this.audioQueue.length) {
        index = 0
      }
      return this.getItem(index)
    }
  }

  public release() {
    this.queueCallback = undefined
  }

}