import { BaseItemDto, BaseItemKind,
  BaseItemPerson,
  ImageType,
  PlaybackInfoResponse,
  UserItemDataDto} from "@ohpg/jellyfin";
import { FinRepository } from "@ohpg/fin-framework";
import { AppEventHub, AppEvents, ServerType } from "@ohpg/fin-core";
import { FinMusicApi } from "../api/FinMusicApi";
import { FinMusicApiFactory } from "../api/FinMusicApiFactory";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/11/9 11:50
 * @Version V1.0
 * @Description Repository
 */
export class Repository extends FinRepository {

  private currentLibrary?: BaseItemDto = undefined

  private availableLibrary?: Array<BaseItemDto> = undefined

  private playlistId: string | undefined

  constructor(context: Context) {
    super(context, new FinMusicApiFactory(context))
  }

  public getSupportServer(): Array<ServerType> {
    return [ServerType.JELLYFIN]
  }

  protected requireApi(): FinMusicApi {
    return super.requireApi() as FinMusicApi
  }

  protected onActiveInfoChanged(): void {
    this.currentLibrary = undefined
    this.availableLibrary = undefined
    this.playlistId = undefined
    AppStorage.setOrCreate("key_multi_source", false)
  }

  public peekLibraryList(): Array<BaseItemDto> | undefined {
    return this.availableLibrary
  }

  public getCurrentLibrary(): BaseItemDto | undefined {
    return this.currentLibrary
  }

  public setCurrentLibrary(library: BaseItemDto): void {
    this.currentLibrary = library
    AppEventHub.emit(AppEvents.EVENT_ACTIVE_INFO_CHANGED)
  }

  public async assertLibraryList(): Promise<void> {
    if (this.availableLibrary && this.availableLibrary.length > 0) {
      return
    }
    let musicLibrary = await this.requireApi().getMusicLibrary()
    if (musicLibrary && musicLibrary.length > 0) {
      this.availableLibrary = musicLibrary
      this.currentLibrary = musicLibrary[0]
      AppStorage.setOrCreate("key_multi_source", musicLibrary.length > 1)
    }
  }

  public buildImage(dto: BaseItemDto, type: ImageType): string {
    return this.requireApi().buildImage(dto, type)
  }

  public buildImageBlur(dto: BaseItemDto, type: ImageType): string | undefined {
    return this.requireApi().buildImageBlur(dto, type)
  }

  public buildPersonImage(person: BaseItemPerson, type: ImageType): string {
    return this.requireApi().buildPersonImage(person, type)
  }

  /**
   * 查询媒体库
   * @returns
   */
  public async getMediaList(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getMusicLibrary()
  }

  /**
   * 查询最近的专辑
   * @returns
   */
  public async getLatestMedia(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getLatestMedia(this.currentLibrary?.Id)
  }

  /**
   * 查询随机音频
   * @returns
   */
  public async getRandomMedia(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getRandomMedia(this.currentLibrary?.Id)
  }

  /**
   * 查询最近播放音频
   * @returns
   */
  public async getLatestAudio(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getLatestAudio(this.currentLibrary?.Id)
  }

  /**
   * 查询最多播放音频
   * @returns
   */
  public async getMostAudio(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getMostAudio(this.currentLibrary?.Id)
  }

  /**
   * 查询随机专辑
   * @returns
   */
  public async getRandomAlbum(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getRandomAlbum()
  }

  /**
   * 查询艺术家列表
   * @returns
   */
  public async getArtists(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getArtists(this.currentLibrary?.Id)
  }

  /**
   * 查询艺术家详情
   * @param id
   * @returns
   */
  public async getArtistDetail(id: string): Promise<BaseItemDto> {
    return this.requireApi().getArtistDetail(id)
  }

  /**
   * 查询艺术家专辑
   * @param id
   * @returns
   */
  public async getArtistAlbums(id: string): Promise<Array<BaseItemDto>> {
    return this.requireApi().getArtistAlbums(id)
  }

  /**
   * 查询流派列表
   * @returns
   */
  public async getGenres(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getGenres(this.currentLibrary?.Id)
  }

  /**
   * 查询流派详情
   * @param id
   * @returns
   */
  public async getGenreDetail(id: string): Promise<BaseItemDto> {
    return this.requireApi().getGenreDetail(id)
  }

  /**
   * 查询流派专辑
   * @param id
   * @returns
   */
  public async getGenreAlbums(id: string): Promise<Array<BaseItemDto>> {
    return this.requireApi().getGenreAlbums(id)
  }

  /**
   * 查询曲目列表
   * @returns
   */
  public async getTracks(): Promise<Array<BaseItemDto>> {
    return this.requireApi().getTracks(this.currentLibrary?.Id)
  }

  /**
   * 查询收藏列表
   * @param includeItemTypes
   * @returns
   */
  public async loadFavourite(includeItemTypes?: Array<BaseItemKind>): Promise<Array<BaseItemDto>> {
    return this.requireApi().loadFavourite(includeItemTypes)
  }

  /**
   * 查询媒体列表
   * @param id
   * @param types
   * @param recursive
   * @returns
   */
  public async loadMediaList(id: string, types: Array<BaseItemKind>, recursive: boolean): Promise<Array<BaseItemDto>> {
    return this.requireApi().loadMediaList(id, types, recursive)
  }

  /**
   * 获取媒体数据源
   * @param id
   * @returns
   */
  public loadMediaSource(id: string): Promise<PlaybackInfoResponse> {
    return this.requireApi().loadMediaSource(id)
  }

  /**
   * 获取音频流地址
   * @param id
   * @param sourceId
   * @returns
   */
  public loadStreamUrl(id: string, sourceId: string): Promise<string> {
    return this.requireApi().loadStreamUrl(id, sourceId)
  }

  /**
   * 搜索
   * @param keyword
   * @returns
   */
  public searchMedia(keyword: string): Promise<Array<BaseItemDto>> {
    return this.requireApi().searchMedia(keyword)
  }

  /**
   * 获取媒体详情
   * @param id
   * @returns
   */
  public getItem(id: string): Promise<BaseItemDto> {
    return this.requireApi().getItem(id)
  }

  /**
   * 获取用户数据
   * @param id
   * @returns
   */
  public getUserItem(id: string): Promise<UserItemDataDto> {
    return this.requireApi().getUserItem(id)
  }

  /**
   * 播放开始
   * @param id
   * @returns
   */
  public onPlaybackStart(id: string): Promise<void> {
    return this.requireApi().onPlaybackStart(id)
  }

  /**
   * 播放进度
   * @param id
   * @param position
   * @param playing
   * @returns
   */
  public onPlaybackProgress(id: string, position: number, playing: boolean): Promise<void> {
    return this.requireApi().onPlaybackProgress(id, position, playing)
  }

  /**
   * 播放停止
   * @param id
   * @param position
   * @returns
   */
  public onPlaybackStopped(id: string, position: number): Promise<void> {
    return this.requireApi().onPlaybackStopped(id, position)
  }

  /**
   * 获取播放列表
   * @returns
   */
  public async getPlayList(): Promise<Array<BaseItemDto> | undefined> {
    let id = await this.getPlaylistIdInternal()
    if (!id) {
      return undefined
    }
    return this.requireApi().getPlayList(id)
  }

  /**
   * 设置播放列表
   * @param playList
   * @returns
   */
  public async setPlaylist(playList: Array<BaseItemDto>): Promise<void> {
    let ids = new Array<string>()
    playList.forEach((item: BaseItemDto) => {
      ids.push(item.Id!)
    })
    let clientName = "FinMusic"
    this.playlistId = await this.requireApi().setPlaylist(this.playlistId, ids, clientName)
  }

  /**
   * 获取歌词
   * @param id 音频 item id
   * @returns LyricDto JSON 或 undefined
   */
  public getLyrics(id: string): Promise<object | undefined> {
    return this.requireApi().getLyrics(id)
  }

  private async getPlaylistIdInternal(): Promise<string | undefined> {
    if (this.playlistId) {
      return this.playlistId
    }
    this.playlistId = await this.requireApi().getPlaylistId(this.currentLibrary?.Id, "FinMusic")
    return this.playlistId
  }

}
