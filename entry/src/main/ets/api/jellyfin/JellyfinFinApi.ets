import { ActiveInfo,
  FinAuthResult,
  FinPublicSystemInfo,
  ServerType } from "@ohpg/fin-core";
import { ClientInfo, DeviceInfo } from "@ohpg/network";
import { BaseItemDto, BaseItemKind, BaseItemPerson, CollectionType, ImageType,
  ItemFilter, ItemSortBy, MediaType, PlaybackInfoResponse, SortOrder,
  UserItemDataDto, Jellyfin } from "@ohpg/jellyfin";
import { FinMusicApi } from "../FinMusicApi";
import { uri } from "@kit.ArkTS";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/5/30 12:00
 * @Version V1.0
 * @Description jellyfin api for music
 */
export class JellyfinFinApi implements FinMusicApi {

  private readonly context: Context

  private activeInfo?: ActiveInfo

  private jellyfin: Jellyfin

  private jellyfinTmp: Jellyfin

  constructor(context: Context, clientInfo: ClientInfo, deviceInfo: DeviceInfo) {
    this.context = context
    this.jellyfin = new Jellyfin(clientInfo, deviceInfo)
    this.jellyfinTmp = new Jellyfin(clientInfo, deviceInfo)
  }

  getApiType(): ServerType {
    return ServerType.JELLYFIN
  }

  updateAddress(address: string): void {
    this.jellyfin.selectServer({address: address})
  }

  updateActiveInfo(activeInfo: ActiveInfo): void {
    this.activeInfo = activeInfo
    this.jellyfin.selectServer({address: activeInfo.addressInfo.address})
    this.jellyfin.selectUser({id: activeInfo.userInfo.userId, token: activeInfo.userInfo.accessToken})
  }

  async getPublicSystemInfo(url: string, name?: string): Promise<FinPublicSystemInfo> {
    this.jellyfinTmp.selectServer({address: url})
    let info = await this.jellyfinTmp.getSystemApi().getPublicSystemInfo()
    return {Id: info.Id, ServerName: name || info.ServerName, Version: info.Version, StartupWizardCompleted: info.StartupWizardCompleted}
  }

  async getSystemInfo(url?: string): Promise<FinPublicSystemInfo> {
    if (url) {
      this.jellyfinTmp.selectServer({address: url})
    } else {
      this.jellyfinTmp.selectServer({address: this.activeInfo!.addressInfo.address})
    }
    this.jellyfinTmp.selectUser({id: this.activeInfo!.userInfo.userId, token: this.activeInfo!.userInfo.accessToken})
    let info = await this.jellyfinTmp.getSystemApi().getSystemInfo()
    return {Id: info.Id, ServerName: info.ServerName, Version: info.Version, StartupWizardCompleted: info.StartupWizardCompleted}
  }

  async auth(name: string, psw?: string, url?: string): Promise<FinAuthResult> {
    if (url) {
      this.jellyfinTmp.selectServer({address: url})
    } else {
      this.jellyfinTmp.selectServer({address: this.activeInfo!.addressInfo.address})
    }
    let authResult = await this.jellyfinTmp.getUserApi().authenticateUserByName({Username: name, Pw: psw})
    return { UserName: authResult.User?.Name
      , UserId: authResult.User?.Id
      , AccessToken: authResult.AccessToken}
  }

  async markFavoriteItem(id: string): Promise<void> {
    await this.jellyfin.getUserLibraryApi().markFavoriteItem({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  async unmarkFavoriteItem(id: string): Promise<void> {
    await this.jellyfin.getUserLibraryApi().unmarkFavoriteItem({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  async markPlayedItem(id: string): Promise<void> {
    await this.jellyfin.getPlayStateApi().markPlayedItem({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  async markUnplayedItem(id: string): Promise<void> {
    await this.jellyfin.getPlayStateApi().markUnplayedItem({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  buildImage(dto: BaseItemDto, type: string): string | undefined {
    let tag: string | undefined | null = dto.ImageTags?.[type]
    let id: string | undefined | null = dto.Id
    if (!tag) {
      tag = dto.AlbumPrimaryImageTag
      id = dto.AlbumId
    }
    if (!tag) {
      return undefined
    }
    let imageUri = new uri.URI(this.activeInfo!.addressInfo.address)
    imageUri = imageUri.addEncodedSegment(`items/${id!}/Images/${type}`)
    imageUri = imageUri.addQueryValue("tag", tag)
    return imageUri.toString()
  }

  buildImageBlur(dto: BaseItemDto, type: string): string | undefined {
    let ibh = dto.ImageBlurHashes
    if (!ibh) {
      return undefined
    }
    let tag: string | undefined | null = dto.ImageTags?.[type]
    if (!tag) {
      tag = dto.AlbumPrimaryImageTag
    }
    if (tag) {
      let kv: Record<string, string> | undefined = (ibh as object)[type]
      return kv?.[tag]
    }
    return undefined
  }

  buildPersonImage(person: BaseItemPerson, type: string): string {
    let imageUri = new uri.URI(this.activeInfo!.addressInfo.address)
    imageUri = imageUri.addEncodedSegment(`items/${person.Id!}/Images/${type}`)
    return imageUri.toString()
  }

  async getItem(id: string): Promise<BaseItemDto> {
    return this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
  }

  async getMusicLibrary(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getUserViewsApi().getUserViews({
      userId: this.activeInfo!.userInfo.userId,
    })
    if (result.Items) {
      return result.Items.filter((item: BaseItemDto): boolean => item.CollectionType === CollectionType.Music)
    }
    return []
  }

  async getLatestMedia(parentId?: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getUserLibraryApi().getLatestMedia({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.MusicAlbum],
      parentId: parentId,
      limit: 12
    })
    if (result) {
      return result
    }
    return []
  }

  async getRandomMedia(parentId?: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      parentId: parentId,
      sortBy: [ItemSortBy.Random],
      includeItemTypes: [BaseItemKind.Audio],
      recursive: true,
      limit: 12
    })
    let albumArray = new Array<BaseItemDto>()
    if (result.Items) {
      albumArray = result.Items.sort((a: BaseItemDto, b: BaseItemDto): number => a.Id!.localeCompare(b.Id!))
    }
    return albumArray
  }

  async getLatestAudio(parentId?: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.Audio],
      sortBy: [ItemSortBy.DatePlayed],
      sortOrder: [SortOrder.Descending],
      parentId: parentId,
      recursive: true,
      limit: 12
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  async getMostAudio(parentId?: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.Audio],
      sortBy: [ItemSortBy.PlayCount],
      sortOrder: [SortOrder.Descending],
      parentId: parentId,
      recursive: true,
      limit: 12
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  async getRandomAlbum(): Promise<Array<BaseItemDto>> {
    let libraryArray = await this.getMusicLibrary()
    let albumArray = new Array<BaseItemDto>()
    for (const library of libraryArray) {
      let result = await this.jellyfin.getItemsApi().getItems({
        userId: this.activeInfo!.userInfo.userId,
        parentId: library.Id,
        sortBy: [ItemSortBy.Random],
        includeItemTypes: [BaseItemKind.MusicAlbum],
        recursive: true,
        limit: 12
      })
      if (result.Items) {
        for (const item of result.Items) {
          albumArray.push(item)
        }
      }
    }
    try {
      albumArray.sort((a: BaseItemDto, b: BaseItemDto): number => a.Id!.localeCompare(b.Id!))
    } catch (e) {
    }
    if (albumArray.length > 12) {
      albumArray.splice(12)
    }
    return albumArray
  }

  async getArtists(parentId?: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getArtistsApi().getArtists({
      userId: this.activeInfo!.userInfo.userId,
      sortBy: [ItemSortBy.SortName],
      sortOrder: [SortOrder.Ascending],
      parentId: parentId
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  async getArtistDetail(id: string): Promise<BaseItemDto> {
    return this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
  }

  async getArtistAlbums(id: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      artistIds: [id],
      includeItemTypes: [BaseItemKind.MusicAlbum],
      recursive: true,
      sortBy: [ItemSortBy.SortName],
      sortOrder: [SortOrder.Ascending]
    })
    if (result?.Items) {
      return result.Items
    }
    return []
  }

  async getGenres(parentId?: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getGenresApi().getGenres({
      userId: this.activeInfo!.userInfo.userId,
      sortBy: [ItemSortBy.SortName],
      sortOrder: [SortOrder.Ascending],
      parentId: parentId,
      recursive: true
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  async getGenreDetail(id: string): Promise<BaseItemDto> {
    return this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
  }

  async getGenreAlbums(id: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      genreIds: [id],
      includeItemTypes: [BaseItemKind.MusicAlbum],
      recursive: true,
      sortBy: [ItemSortBy.SortName],
      sortOrder: [SortOrder.Ascending]
    })
    if (result?.Items) {
      return result.Items
    }
    return []
  }

  async getTracks(parentId?: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.Audio],
      sortBy: [ItemSortBy.SortName],
      sortOrder: [SortOrder.Ascending],
      parentId: parentId,
      recursive: true
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  async loadFavourite(includeItemTypes?: Array<BaseItemKind>): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      filters: [ItemFilter.IsFavorite],
      includeItemTypes: includeItemTypes,
      recursive: true
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  async loadMediaList(id: string, types: Array<BaseItemKind>, recursive: boolean): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      parentId: id,
      includeItemTypes: types,
      recursive: recursive
    })
    return result.Items!
  }

  async loadMediaSource(id: string): Promise<PlaybackInfoResponse> {
    return this.jellyfin.getMediaInfoApi().getPlaybackInfo({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
  }

  async loadStreamUrl(id: string, sourceId: string): Promise<string> {
    return this.jellyfin.getAudioApi().getAudioStream({
      itemId: id,
      static: true,
      mediaSourceId: sourceId
    })
  }

  async getUserItem(id: string): Promise<UserItemDataDto> {
    return this.jellyfin.getItemsApi().getItemUserData({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

  async searchMedia(keyword: string): Promise<Array<BaseItemDto>> {
    return []
  }

  async onPlaybackStart(id: string): Promise<void> {
    await this.jellyfin.getPlayStateApi().onPlaybackStart({itemId: id})
  }

  async onPlaybackProgress(id: string, position: number, playing: boolean): Promise<void> {
    await this.jellyfin.getPlayStateApi().onPlaybackProgress({itemId: id, positionTicks: position, isPaused: !playing})
  }

  async onPlaybackStopped(id: string, position: number): Promise<void> {
    await this.jellyfin.getPlayStateApi().onPlaybackStopped({itemId: id, positionTicks: position})
  }

  async getPlaylistId(parentId?: string, clientName?: string): Promise<string | undefined> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.Playlist],
      sortBy: [ItemSortBy.PlayCount],
      sortOrder: [SortOrder.Descending],
      parentId: parentId,
      recursive: true,
      limit: 12
    })
    let item = result.Items?.find((item: BaseItemDto): boolean => {
      return item.Name === clientName
    })
    if (!item) {
      return undefined
    }
    return item.Id
  }

  async getPlayList(playlistId: string): Promise<Array<BaseItemDto> | undefined> {
    let playlistResult = await this.jellyfin.getPlaylistApi().getPlaylistItems({
      playlistId: playlistId,
      userId: this.activeInfo?.userInfo.userId
    })
    if (playlistResult?.Items) {
      return playlistResult.Items
    }
    return undefined
  }

  async setPlaylist(playlistId: string | undefined, ids: Array<string>, clientName: string): Promise<string | undefined> {
    if (!playlistId) {
      // 实时查询已有播放列表，避免重复创建
      playlistId = await this.getPlaylistId(undefined, clientName)
    }
    if (!playlistId) {
      let result = await this.jellyfin.getPlaylistApi().createPlaylist({
        name: clientName,
        ids: ids,
        userId: this.activeInfo?.userInfo?.userId,
        mediaType: MediaType.Audio
      })
      return result.Id
    } else {
      await this.jellyfin.getPlaylistApi().updatePlaylist({
        playlistId: playlistId,
        updatePlaylistDto: {
          Ids: ids
        }
      })
      return playlistId
    }
  }

  async getLyrics(id: string): Promise<object | undefined> {
    try {
      return await this.jellyfin.apiClient.get<object>({
        path: `/Audio/${id}/Lyrics`
      })
    } catch (_) {
      return undefined
    }
  }

  async toggleFavorite(id: string, favorite: boolean): Promise<void> {
    if (favorite) {
      await this.jellyfin.getUserLibraryApi().markFavoriteItem({
        itemId: id,
        userId: this.activeInfo!.userInfo.userId
      })
    } else {
      await this.jellyfin.getUserLibraryApi().unmarkFavoriteItem({
        itemId: id,
        userId: this.activeInfo!.userInfo.userId
      })
    }
  }

  async release(): Promise<void> {
    this.jellyfin.apiClient.release()
  }
}
