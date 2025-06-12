import { BaseItemDto, BaseItemKind,
  BaseItemPerson,
  CollectionType,
  ImageType,
  ItemFields,
  ItemFilter,
  ItemSortBy,
  PlaybackInfoResponse,
  SortOrder,
  UserItemDataDto} from "@ohpg/jellyfin";
import { uri } from "@kit.ArkTS";
import { FinRepository } from "@ohpg/fin-framework";
import { AppEventHub, AppEvents } from "@ohpg/fin-core";

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

  constructor(context: Context) {
    super(context, "FinMusic")
  }

  private filterItem(items?: Array<BaseItemDto> | null): Array<BaseItemDto> | undefined {
    let newItems: Array<BaseItemDto> | undefined
    items?.forEach((item) => {
      let type = item.CollectionType
      if (type == CollectionType.Music) {
        if (newItems == undefined) {
          newItems = new Array()
        }
        newItems.push(item)
      }
    }
    )
    return newItems
  }

  protected onActiveInfoChanged(): void {
    this.currentLibrary = undefined
    this.availableLibrary = undefined
    AppStorage.setOrCreate("key_multi_source", false)
  }

  public peekLibraryList(): Array<BaseItemDto> | undefined {
    return this.availableLibrary
  }

  public getCurrentLibrary(): BaseItemDto | undefined {
    return this.currentLibrary
  }

  public setCurrentLibrary(library: BaseItemDto) {
    this.currentLibrary = library
    AppEventHub.emit(AppEvents.EVENT_ACTIVE_INFO_CHANGED)
  }

  public async assertLibraryList(): Promise<void> {
    if (this.availableLibrary && this.availableLibrary.length > 0) {
      return
    }
    let musicLibrary = await this.getMusicLibrary()
    if (musicLibrary && musicLibrary.length > 0) {
      this.availableLibrary = musicLibrary
      this.currentLibrary = musicLibrary[0]
      AppStorage.setOrCreate("key_multi_source", musicLibrary.length > 1)
    }
  }

  public buildImage(dto: BaseItemDto, type: ImageType): string {
    let imageUri = new uri.URI(this.jellyfin.apiClient.getServerInfo()!.address)
    let tag: string | undefined | null = dto.ImageTags?.[type]
    let id: string | undefined | null = dto.Id
    if (!tag) {
      tag = dto.AlbumPrimaryImageTag
      id = dto.AlbumId
    }
    imageUri = imageUri.addEncodedSegment(`items/${id!}/Images/${type}`)
    if (tag) {
      imageUri = imageUri.addQueryValue("tag", tag)
    }
    return imageUri.toString()
  }

  public buildImageBlur(dto: BaseItemDto, type: ImageType): string | undefined {
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

  public buildPersonImage(person: BaseItemPerson, type: ImageType): string {
    let imageUri = new uri.URI(this.jellyfin.apiClient.getServerInfo()!.address)
    imageUri = imageUri.addEncodedSegment(`items/${person.Id!}/Images/${type}`)
    return imageUri.toString()
  }

  /**
   * 查询媒体库
   * @returns
   */
  public async getMediaList(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getUserViewsApi().getUserViews({
      userId: this.activeInfo!.userInfo.userId,
      presetViews: [CollectionType.Music]
    })
    let groups = this.filterItem(result.Items)
    if (!groups) {
      return []
    }
    return groups
  }

  /**
   * 查询最近的专辑
   * @returns
   */
  public async getLatestMedia(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getUserLibraryApi().getLatestMedia({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.MusicAlbum],
      parentId: this.currentLibrary?.Id,
      limit: 12
    })
    if (result) {
      return result
    }
    return []
  }

  /**
   * 查询随机音频
   * @returns
   */
  public async getRandomMedia(): Promise<Array<BaseItemDto>> {
    let albumArray = new Array<BaseItemDto>()
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      parentId: this.currentLibrary?.Id,
      sortBy: [ItemSortBy.Random],
      includeItemTypes:[BaseItemKind.Audio],
      recursive: true,
      limit: 12
    })
    if (result.Items) {
      albumArray = result.Items.sort((a, b) => a.Id!.localeCompare(b.Id!))
    }
    return albumArray
  }

  /**
   * 查询最近的专辑
   * @param id
   * @returns
   */
  public async getLatestAudio(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.Audio],
      sortBy: [ItemSortBy.DatePlayed],
      sortOrder: [SortOrder.Descending],
      parentId: this.currentLibrary?.Id,
      recursive: true,
      limit: 12
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  /**
   * 查询最近的专辑
   * @param id
   * @returns
   */
  public async getMostAudio(id?: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.Audio],
      sortBy: [ItemSortBy.PlayCount],
      sortOrder: [SortOrder.Descending],
      parentId: this.currentLibrary?.Id,
      recursive: true,
      limit: 12
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  private async getMusicLibrary(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getUserViewsApi().getUserViews({
      userId: this.activeInfo!.userInfo.userId,
    })
    if (result.Items) {
      return result.Items.filter((item) => item.CollectionType === CollectionType.Music)
    }
    return []
  }

  /**
   * 查询随机专辑
   * @returns
   */
  public async getRandomAlbum(): Promise<Array<BaseItemDto>> {
    // 先查询包含音乐的媒体库
    let libraryArray = await this.getMusicLibrary()
    let albumArray = new Array<BaseItemDto>()
    for (const library of libraryArray) {
      let result = await this.jellyfin.getItemsApi().getItems({
        userId: this.activeInfo!.userInfo.userId,
        parentId: library.Id,
        sortBy: [ItemSortBy.Random],
        includeItemTypes:[BaseItemKind.MusicAlbum],
        recursive: true,
        limit: 12
      })
      if (result.Items) {
        albumArray.push(...result.Items)
      }
    }
    try {
      albumArray.sort((a, b) => a.Id!.localeCompare(b.Id!))
    } catch (e) {
    }
    if (albumArray.length > 12) {
      albumArray.splice(12)
    }
    return albumArray
  }

  /**
   * 查询
   * @returns
   */
  public async loadMedia(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId
    })
    let items = this.filterItem(result.Items)
    if (items) {
      return items
    }
    return []
  }

  public async getArtists(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getArtistsApi().getArtists({
      userId: this.activeInfo!.userInfo.userId,
      sortBy: [ItemSortBy.SortName],
      sortOrder: [SortOrder.Ascending],
      parentId: this.currentLibrary?.Id
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  public async getArtistDetail(id: string): Promise<BaseItemDto> {
    return this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
  }

  public async getArtistAlbums(id: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      artistIds:[id],
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

  public async getGenres(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getGenresApi().getGenres({
      userId: this.activeInfo!.userInfo.userId,
      sortBy: [ItemSortBy.SortName],
      sortOrder: [SortOrder.Ascending],
      parentId: this.currentLibrary?.Id,
      recursive: true
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  public async getGenreDetail(id: string): Promise<BaseItemDto> {
    return this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
  }

  public async getGenreAlbums(id: string): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      genreIds:[id],
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

  public async getTracks(): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      userId: this.activeInfo!.userInfo.userId,
      includeItemTypes: [BaseItemKind.Audio],
      sortBy: [ItemSortBy.SortName],
      sortOrder: [SortOrder.Ascending],
      parentId: this.currentLibrary?.Id,
      recursive: true
    })
    if (result.Items) {
      return result.Items
    }
    return []
  }

  public async loadFavourite(includeItemTypes?: Array<BaseItemKind>): Promise<Array<BaseItemDto>> {
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

  public async loadMediaList(id: string, types: Array<BaseItemKind>
    , recursive: boolean, sortBy?: Array<ItemSortBy>, sortOrder?: Array<SortOrder>): Promise<Array<BaseItemDto>> {
    let result = await this.jellyfin.getItemsApi().getItems({
      parentId: id,
      includeItemTypes: types,
      recursive: recursive,
      sortBy: sortBy,
      sortOrder: sortOrder
    })
    return result.Items!
  }

  public loadMovie(id: string): Promise<BaseItemDto> {
    return this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
  }

  public loadShow(showId: string): Promise<BaseItemDto> {
    return this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: showId
    })
  }

  public getResumeItems(): Promise<Array<BaseItemDto>> {
    return this.jellyfin.getItemsApi().getResumeItems({
      userId: this.activeInfo!.userInfo.userId,
      limit: 8,
      includeItemTypes: [BaseItemKind.Movie, BaseItemKind.Episode]
    }).then((result) => {
      if (result.Items) {
        return result.Items
      }
      return []
    })
  }

  public getNextUp(seriesId?: string): Promise<Array<BaseItemDto>> {
    return this.jellyfin.getTvShowsApi().getNextUp({
      userId: this.activeInfo!.userInfo.userId,
      seriesId: seriesId,
      enableResumable: false,
      limit: 8
    })
      .then((result) => {
        if (result.Items) {
          return result.Items
        }
        return []
      })
  }

  public getSeasons(seriesId: string): Promise<Array<BaseItemDto>> {
    return this.jellyfin.getTvShowsApi().getSeasons({
      userId: this.activeInfo!.userInfo.userId,
      seriesId: seriesId
    }).then((result) => {
      if (result.Items) {
        return result.Items
      }
      return []
      })
}

  public getEpisodes(seriesId: string, seasonId: string): Promise<Array<BaseItemDto>> {
    return this.jellyfin.getTvShowsApi().getEpisodes({
      userId: this.activeInfo!.userInfo.userId,
      seriesId: seriesId,
      seasonId: seasonId,
      fields: [ItemFields.Overview]
    }).then((result) => {
      if (result.Items) {
        return result.Items
      }
      return []
    })
  }

  public getEpisode(episodeId: string): Promise<BaseItemDto> {
    return this.jellyfin.getUserLibraryApi().getItem({
      userId: this.activeInfo!.userInfo.userId,
      itemId: episodeId
    })
  }

  public loadMediaSource(id: string): Promise<PlaybackInfoResponse> {
    return this.jellyfin.getMediaInfoApi().getPlaybackInfo({
      userId: this.activeInfo!.userInfo.userId,
      itemId: id
    })
  }

  public loadStreamUrl(id: string, sourceId: string): Promise<string> {
    return this.jellyfin.getAudioApi().getAudioStream({
      itemId: id,
      static: true,
      mediaSourceId: sourceId
    })
  }

  public searchMedia(keyword: string): Promise<Array<BaseItemDto>> {
    return Promise.resolve([])
  }

  public getUserItem(id: string): Promise<UserItemDataDto> {
    return this.jellyfin.getItemsApi().getItemUserData({
      itemId: id,
      userId: this.activeInfo!.userInfo.userId
    })
  }

}