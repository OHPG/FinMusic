import { PlaybackOverlay } from '../../overlay/PlaybackOverlay'
import { HomeToolBar } from '../../widget/bar/HomeToolBar'
import { AlbumPage } from './album/AlbumPage'
import { ArtistPage } from './artist/ArtistPage'
import { GenrePage } from './genre/GenrePage'
import { MainPage } from './main/MainPage'

@Entry
@Component
struct HomePage {

  @State fontColor: string = '#182431'

  @State selectedFontColor: string = '#007DFF'

  @State currentIndex: number = 0

  private controller: TabsController = new TabsController()

  private playbackOverlay: PlaybackOverlay = new PlaybackOverlay(this.getUIContext())

  aboutToAppear(): void {
    this.playbackOverlay.attach()
  }

  @Builder tabBuilder(index: number, name: ResourceStr) {
    Column() {
      Text(name)
        .fontColor(this.currentIndex === index ? '#1698CE' : '#6B6B6B')
        .fontSize(16)
        .fontWeight(this.currentIndex === index ? 500 : 400)
        .lineHeight(22)
        .margin({ top: 6, bottom: 6 })
      Divider()
        .strokeWidth(2)
        .color('#007DFF')
        .opacity(this.currentIndex === index ? 1 : 0)
    }.width('100%')
  }

  build() {
    Column() {
      HomeToolBar({
        title: $r('app.string.app_name')
      })

      Tabs({ barPosition: BarPosition.Start, index: this.currentIndex, controller: this.controller }) {
        TabContent() {
          MainPage()
        }
        .tabBar(this.tabBuilder(0, $r('app.string.home_main')))

        TabContent() {
          AlbumPage()
        }
        .tabBar(this.tabBuilder(1, $r('app.string.home_album')))

        TabContent() {
          ArtistPage()
        }
        .tabBar(this.tabBuilder(2, $r('app.string.home_artist')))

        TabContent() {
          GenrePage()
        }
        .tabBar(this.tabBuilder(3, $r('app.string.home_genre')))

        // TabContent() {
        //   TrackPage()
        // }
        // .tabBar(this.tabBuilder(4, $r('app.string.home_track')))
      }
      .vertical(false)
      .barMode(BarMode.Fixed)
      .barWidth('100%')
      .barHeight(38)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .width('100%')
      .layoutWeight(1)
    }
    .height('100%')
    .width('100%')
  }

  aboutToDisappear(): void {
    this.playbackOverlay.detach()
  }

}


