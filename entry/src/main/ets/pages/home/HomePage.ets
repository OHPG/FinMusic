import { HomeToolBar } from '../../widget/bar/HomeToolBar'
import { PlaybackBar } from '../../widget/bar/PlaybackBar'
import { AlbumPage } from './album/AlbumPage'
import { ArtistPage } from './artist/ArtistPage'
import { GenrePage } from './genre/GenrePage'
import { MainPage } from './main/MainPage'
import { AudioManager } from '../../player/AudioManager'
import { CommonConstants } from '../../common/CommonConstants'
import { window } from '@kit.ArkUI'

@Entry
@Component
struct HomePage {

  @State currentIndex: number = 0

  @StorageProp('currentAvoidArea') @Watch('onAvoidAreaChanged') currentAvoidArea?: window.AvoidArea = undefined

  private controller: TabsController = new TabsController()

  private audioManager: AudioManager = AppStorage.get(AudioManager.AUDIO_MANAGER)!

  aboutToAppear(): void {
    AppStorage.setOrCreate("playerHeight", 60)
    console.info("FinMusic: HomePage.aboutToAppear, start resumeAudioQueue")
    this.audioManager.resumeAudioQueue()
  }

  private onAvoidAreaChanged(): void {
  }

  @Builder tabBuilder(index: number, name: ResourceStr) {
    Column() {
      Text(name)
        .fontColor(this.currentIndex === index
          ? $r('sys.color.ohos_id_color_text_primary')
          : $r('sys.color.ohos_id_color_text_secondary'))
        .fontSize(15)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Regular)
        .fontFamily(this.currentIndex === index
          ? CommonConstants.HARMONY_HEITI_MEDIUM_FONT_FAMILY
          : CommonConstants.HARMONY_HEI_TI_FONT_FAMILY)
        .lineHeight(22)
        .margin({ top: 8, bottom: 8 })

      Row()
        .width(20)
        .height(3)
        .borderRadius(1.5)
        .backgroundColor($r('sys.color.ohos_id_color_activated'))
        .opacity(this.currentIndex === index ? 1 : 0)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 内容区
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
        }
        .vertical(false)
        .barMode(BarMode.Fixed)
        .barWidth('100%')
        .barHeight(42)
        .animationDuration(200)
        .onChange((index: number) => {
          this.currentIndex = index
        })
        .width('100%')
        .layoutWeight(1)
      }
      .height('100%')
      .width('100%')

      // 底部悬浮播放栏
      PlaybackBar()
        .margin({
          left: CommonConstants.SPACE_16,
          right: CommonConstants.SPACE_16,
          bottom: px2vp(this.currentAvoidArea?.bottomRect.height) || CommonConstants.SPACE_8
        })
    }
    .width('100%')
    .height('100%')
  }

  aboutToDisappear(): void {
  }

}
