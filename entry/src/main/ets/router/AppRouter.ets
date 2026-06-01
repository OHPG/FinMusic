import { PlayerRouter } from '@ohpg/widget'
import { MediaArgs } from '../pages/detail/MediaArgs'

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/11/19 22:32
 * @Version V1.0
 * @Description: 路由跳转，所有页面跳转都走这里，统一管理，防止参数异常。
 */
export class AppRouter {

  public static goBack(context: UIContext): void {
    context.getRouter().back()
  }

  public static goToHome(context: UIContext): void {
    context.getRouter().replaceUrl({ url: 'pages/home/HomePage' })
  }

  public static goToPlayer(context: UIContext): void {
    PlayerRouter.push(context)
  }

  public static goToSetting(context: UIContext): void {
    context.getRouter().pushUrl({ url: 'pages/setting/SettingPage' })
  }

  public static goToPlaybackSetting(context: UIContext): void {
    context.getRouter().pushUrl({ url: 'pages/setting/PlaybackSettingPage' })
  }

  public static goToCacheSetting(context: UIContext): void {
    context.getRouter().pushUrl({ url: 'pages/setting/CacheSettingPage' })
  }

  public static goToAbout(context: UIContext): void {
    context.getRouter().pushUrl({ url: 'pages/about/AboutPage' })
  }

  public static goToAlbum(context: UIContext, id: string, name: string): void {
    let args: MediaArgs = { id: id, name: name }
    context.getRouter().pushUrl({ url: 'pages/detail/album/AlbumPage', params: args })
  }

  public static goToArtist(context: UIContext, id: string, name: string): void {
    let args: MediaArgs = { id: id, name: name }
    context.getRouter().pushUrl({ url: 'pages/detail/artist/ArtistPage', params: args })
  }

  public static goToGenre(context: UIContext, id: string, name: string): void {
    let args: MediaArgs = { id: id, name: name }
    context.getRouter().pushUrl({ url: 'pages/detail/genre/GenrePage', params: args })
  }
}
