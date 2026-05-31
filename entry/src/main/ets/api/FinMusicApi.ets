import { FinApi } from "@ohpg/fin-framework";
import { BaseItemDto, BaseItemKind, BaseItemPerson, PlaybackInfoResponse, UserItemDataDto } from "@ohpg/jellyfin";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/5/30 12:00
 * @Version V1.0
 * @Description Music Fin Api
 */
export interface FinMusicApi extends FinApi {

  /**
   * 获取媒体详情（通用）
   * @param id
   * @returns
   */
  getItem(id: string): Promise<BaseItemDto>

  /**
   * 获取媒体库列表（音乐类型）
   * @returns
   */
  getMusicLibrary(): Promise<Array<BaseItemDto>>

  /**
   * 获取最近专辑
   * @param parentId
   * @returns
   */
  getLatestMedia(parentId?: string): Promise<Array<BaseItemDto>>

  /**
   * 获取随机音频
   * @param parentId
   * @returns
   */
  getRandomMedia(parentId?: string): Promise<Array<BaseItemDto>>

  /**
   * 获取最近播放音频
   * @param parentId
   * @returns
   */
  getLatestAudio(parentId?: string): Promise<Array<BaseItemDto>>

  /**
   * 获取最多播放音频
   * @param parentId
   * @returns
   */
  getMostAudio(parentId?: string): Promise<Array<BaseItemDto>>

  /**
   * 获取随机专辑
   * @returns
   */
  getRandomAlbum(): Promise<Array<BaseItemDto>>

  /**
   * 获取艺术家列表
   * @param parentId
   * @returns
   */
  getArtists(parentId?: string): Promise<Array<BaseItemDto>>

  /**
   * 获取艺术家详情
   * @param id
   * @returns
   */
  getArtistDetail(id: string): Promise<BaseItemDto>

  /**
   * 获取艺术家专辑
   * @param id
   * @returns
   */
  getArtistAlbums(id: string): Promise<Array<BaseItemDto>>

  /**
   * 获取流派列表
   * @param parentId
   * @returns
   */
  getGenres(parentId?: string): Promise<Array<BaseItemDto>>

  /**
   * 获取流派详情
   * @param id
   * @returns
   */
  getGenreDetail(id: string): Promise<BaseItemDto>

  /**
   * 获取流派专辑
   * @param id
   * @returns
   */
  getGenreAlbums(id: string): Promise<Array<BaseItemDto>>

  /**
   * 获取曲目列表
   * @param parentId
   * @returns
   */
  getTracks(parentId?: string): Promise<Array<BaseItemDto>>

  /**
   * 获取收藏列表
   * @param includeItemTypes
   * @returns
   */
  loadFavourite(includeItemTypes?: Array<BaseItemKind>): Promise<Array<BaseItemDto>>

  /**
   * 获取媒体列表
   * @param id
   * @param types
   * @param recursive
   * @param sortBy
   * @param sortOrder
   * @returns
   */
  loadMediaList(id: string, types: Array<BaseItemKind>, recursive: boolean): Promise<Array<BaseItemDto>>

  /**
   * 获取媒体数据源
   * @param id
   * @returns
   */
  loadMediaSource(id: string): Promise<PlaybackInfoResponse>

  /**
   * 获取音频流地址
   * @param id
   * @param sourceId
   * @returns
   */
  loadStreamUrl(id: string, sourceId: string): Promise<string>

  /**
   * 获取用户数据
   * @param id
   * @returns
   */
  getUserItem(id: string): Promise<UserItemDataDto>

  /**
   * 搜索
   * @param keyword
   * @returns
   */
  searchMedia(keyword: string): Promise<Array<BaseItemDto>>

  /**
   * 构建图片地址
   * @param dto
   * @param type
   * @returns
   */
  buildImage(dto: BaseItemDto, type: string): string

  /**
   * 构建图片模糊哈希
   * @param dto
   * @param type
   * @returns
   */
  buildImageBlur(dto: BaseItemDto, type: string): string | undefined

  /**
   * 构建人物图片地址
   * @param person
   * @param type
   * @returns
   */
  buildPersonImage(person: BaseItemPerson, type: string): string

  /**
   * 播放开始
   * @param id
   * @returns
   */
  onPlaybackStart(id: string): Promise<void>

  /**
   * 播放进度
   * @param id
   * @param position
   * @param playing
   * @returns
   */
  onPlaybackProgress(id: string, position: number, playing: boolean): Promise<void>

  /**
   * 播放停止
   * @param id
   * @param position
   * @returns
   */
  onPlaybackStopped(id: string, position: number): Promise<void>

  /**
   * 获取播放列表id
   * @param parentId
   * @param clientName
   * @returns
   */
  getPlaylistId(parentId?: string, clientName?: string): Promise<string | undefined>

  /**
   * 获取播放列表
   * @param playlistId
   * @returns
   */
  getPlayList(playlistId: string): Promise<Array<BaseItemDto> | undefined>

  /**
   * 设置播放列表
   * @param playlistId
   * @param ids
   * @param clientName
   * @returns
   */
  setPlaylist(playlistId: string | undefined, ids: Array<string>, clientName: string): Promise<string | undefined>

  /**
   * 获取歌词
   * @param id 音频 item id
   * @returns LyricDto JSON 或 undefined
   */
  getLyrics(id: string): Promise<object | undefined>

  /**
   * 切换收藏状态
   * @param id item id
   * @param favorite 是否收藏
   */
  toggleFavorite(id: string, favorite: boolean): Promise<void>

}
