import { AlbumViewModel } from './AlbumViewModel'
import { ToolBar } from '@ohpg/fin-framework'
import { BaseItemDto, ImageType } from '@ohpg/jellyfin'
import { CommonConstants } from '../../../common/CommonConstants'
import { MediaArgs } from '../MediaArgs'
import { window } from '@kit.ArkUI'
import { Repository } from '../../../data/Repository'
import { GroupInfo } from '../../../entity/GroupInfo'
import { AppPlaybackManager } from '../../../player/AppPlaybackManager'
import { AVPlaybackManager } from '@ohpg/player'
import { BreakpointSystem } from '@ohpg/fin-core'
import { PlayerRouter } from '@ohpg/widget'
import { TrackItem } from '../../../widget/item/TrackItem'

@Entry
@Component
struct AlbumPage {

  private args: MediaArgs = this.getUIContext().getRouter().getParams() as MediaArgs

  private playbackManager: AppPlaybackManager = AppStorage.get(AVPlaybackManager.AV_PLAYER_MANAGER)!

  public readonly repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  private viewModel = new AlbumViewModel(getContext(), this.args)

  @StorageProp("currentAvoidArea") avoidArea?: window.AvoidArea = undefined

  @StorageProp(BreakpointSystem.CURRENT_WIDTH_BREAKPOINT) currentBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM

  @State group: GroupInfo | undefined = undefined

  /** 收藏状态数组，与 group.items 索引对应 */
  @State favoriteStates: boolean[] = []

  /** 是否已滚动超过头部 */
  @State headerCollapsed: boolean = false

  /** ToolBar 背景透明度（0~1 渐变） */
  @State toolBarOpacity: number = 0

  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.loadData()
  }

  private loadData(): void {
    this.viewModel.loadData('Init')
      .then((data: Object) => {
        let info = data as GroupInfo
        this.group = info
        this.favoriteStates = (info.items ?? []).map((item: BaseItemDto) => {
          return item.UserData?.IsFavorite ?? false
        })
      })
      .catch((e: Error) => {
        console.error("FinMusic: AlbumPage loadData error: " + e.message)
      })
  }

  private getToolBarHeight(): number {
    let statusBarHeight = px2vp(this.avoidArea?.topRect.height ?? 0)
    return statusBarHeight + 56
  }

  @Builder
  phoneLayout(group: GroupInfo) {
    Column() {
      // 头部区域：深色渐变背景 + 封面横排
      Stack() {
        // 模糊背景
        Image(this.repository?.buildImage(group.group!, ImageType.Primary))
          .objectFit(ImageFit.Cover)
          .width(CommonConstants.FULL_PERCENT)
          .height(CommonConstants.FULL_PERCENT)
          .blur(60)
          .opacity(0.7)

        // 深色渐变遮罩
        Column()
          .width(CommonConstants.FULL_PERCENT)
          .height(CommonConstants.FULL_PERCENT)
          .linearGradient({
            angle: 180,
            colors: [['#4D000000', 0.0], ['#99000000', 1.0]]
          })

        // 封面 + 标题信息
        Row({ space: CommonConstants.SPACE_16 }) {
          Image(this.repository?.buildImage(group.group!, ImageType.Primary))
            .alt($r('app.media.default_cover'))
            .objectFit(ImageFit.Cover)
            .autoResize(true)
            .width(120)
            .aspectRatio(1)
            .borderRadius(8)
            .shadow(ShadowStyle.OUTER_DEFAULT_MD)

          Column({ space: CommonConstants.SPACE_8 }) {
            Text(group.group?.Name)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width(CommonConstants.FULL_PERCENT)

            Text(group.group?.AlbumArtist)
              .fontSize(14)
              .fontColor('#CCffffff')
              .maxLines(1)
              .width(CommonConstants.FULL_PERCENT)

            Row({ space: CommonConstants.SPACE_8 }) {
              Text(group.group?.ProductionYear?.toString())
                .fontSize(12)
                .fontColor('#99ffffff')
                .visibility(group.group?.ProductionYear ? Visibility.Visible : Visibility.None)

              Text(this.formatDuration(group.group?.RunTimeTicks))
                .fontSize(12)
                .fontColor('#99ffffff')
                .visibility(group.group?.RunTimeTicks ? Visibility.Visible : Visibility.None)
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width(CommonConstants.FULL_PERCENT)
        .padding({
          left: CommonConstants.SPACE_16,
          right: CommonConstants.SPACE_16,
          top: this.getToolBarHeight(),
          bottom: CommonConstants.SPACE_16
        })
        .alignItems(VerticalAlign.Center)
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(this.getToolBarHeight() + 140)

      // 操作按钮行
      Row({ space: CommonConstants.SPACE_12 }) {
        Button({ type: ButtonType.Capsule }) {
          Row({ space: CommonConstants.SPACE_8 }) {
            SymbolGlyph(this.group?.group?.UserData?.IsFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
              .fontSize(18)
              .fontColor([this.group?.group?.UserData?.IsFavorite
                ? Color.Red
                : $r('sys.color.ohos_id_color_text_primary')])
            Text($r('app.string.album_collect'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
          }
        }
        .height(36)
        .layoutWeight(1)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .onClick(() => {
          this.toggleAlbumFavorite()
        })

        Button({ type: ButtonType.Capsule }) {
          Row({ space: CommonConstants.SPACE_8 }) {
            SymbolGlyph($r('sys.symbol.shuffle'))
              .fontSize(18)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            Text($r('app.string.album_shuffle'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
          }
        }
        .height(36)
        .layoutWeight(1)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .onClick(() => {
          if (group.items && group.items.length > 0) {
            let randomIndex = Math.floor(Math.random() * group.items.length)
            this.playbackManager.playItems(group.items, group.items[randomIndex].Id!)
            PlayerRouter.push(this.getUIContext())
          }
        })
      }
      .width(CommonConstants.FULL_PERCENT)
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16,
        top: CommonConstants.SPACE_12,
        bottom: CommonConstants.SPACE_12
      })

      // 播放全部行
      Row() {
        SymbolGlyph($r('sys.symbol.play_circle_fill'))
          .fontSize(28)
          .fontColor([$r('sys.color.ohos_id_color_component_activated')])

        Text($r('app.string.album_play_all_count', (group.items?.length ?? 0).toString()))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .margin({ left: CommonConstants.SPACE_8 })

        Blank()
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(48)
      .padding({
        left: CommonConstants.SPACE_16,
        right: CommonConstants.SPACE_16
      })
      .onClick(() => {
        if (group.items && group.items.length > 0) {
          this.playbackManager.playItems(group.items, group.items[0].Id!)
          PlayerRouter.push(this.getUIContext())
        }
      })

      // 曲目列表
      this.trackListBuilder(group)
    }
    .width(CommonConstants.FULL_PERCENT)
  }

  @Builder
  tabletLayout(group: GroupInfo) {
    Stack({ alignContent: Alignment.Top }) {
      // 主体：左侧固定 + 右侧独立滚动
      Row() {
        // 左侧：封面 + 元数据 + 按钮（固定不滚动）
        Column({ space: CommonConstants.SPACE_16 }) {
          // ToolBar 高度占位，避免内容被遮挡
          Column()
            .height(this.getToolBarHeight())

          Image(this.repository?.buildImage(group.group!, ImageType.Primary))
            .alt($r('app.media.default_cover'))
            .objectFit(ImageFit.Cover)
            .autoResize(true)
            .width(260)
            .aspectRatio(1)
            .borderRadius(12)
            .shadow(ShadowStyle.OUTER_DEFAULT_LG)

          Text(group.group?.Name)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)

          Text(group.group?.AlbumArtist)
            .fontSize(15)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))

          Row({ space: CommonConstants.SPACE_8 }) {
            Text(group.group?.ProductionYear?.toString())
              .fontSize(13)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .visibility(group.group?.ProductionYear ? Visibility.Visible : Visibility.None)
            Text(this.formatDuration(group.group?.RunTimeTicks))
              .fontSize(13)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .visibility(group.group?.RunTimeTicks ? Visibility.Visible : Visibility.None)
            Text((group.items?.length ?? 0) + ' 首')
              .fontSize(13)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }

          Column({ space: CommonConstants.SPACE_12 }) {
            Button({ type: ButtonType.Capsule }) {
              Row({ space: CommonConstants.SPACE_8 }) {
                SymbolGlyph($r('sys.symbol.play_fill'))
                  .fontSize(18)
                  .fontColor([$r('sys.color.font_on_primary')])
                Text($r('app.string.album_play_all'))
                  .fontSize(15)
                  .fontColor($r('sys.color.font_on_primary'))
              }
            }
            .width(200)
            .height(38)
            .onClick(() => {
              if (group.items && group.items.length > 0) {
                this.playbackManager.playItems(group.items, group.items[0].Id!)
                PlayerRouter.push(this.getUIContext())
              }
            })

            Button({ type: ButtonType.Capsule }) {
              Row({ space: CommonConstants.SPACE_8 }) {
                SymbolGlyph($r('sys.symbol.shuffle'))
                  .fontSize(18)
                  .fontColor([$r('sys.color.ohos_id_color_text_primary')])
                Text($r('app.string.album_shuffle'))
                  .fontSize(15)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
              }
            }
            .width(200)
            .height(38)
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .onClick(() => {
              if (group.items && group.items.length > 0) {
                let randomIndex = Math.floor(Math.random() * group.items.length)
                this.playbackManager.playItems(group.items, group.items[randomIndex].Id!)
                PlayerRouter.push(this.getUIContext())
              }
            })
          }
          .margin({ top: CommonConstants.SPACE_8 })
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .width('38%')
        .height(CommonConstants.FULL_PERCENT)
        .padding({ left: CommonConstants.SPACE_16, right: CommonConstants.SPACE_16 })

        // 右侧：曲目列表（独立滚动）
        List() {
          // 播放全部行
          ListItem() {
            Row() {
              SymbolGlyph($r('sys.symbol.play_circle_fill'))
                .fontSize(28)
                .fontColor([$r('sys.color.ohos_id_color_component_activated')])

              Text($r('app.string.album_play_all_count', (group.items?.length ?? 0).toString()))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .margin({ left: CommonConstants.SPACE_8 })

              Blank()
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(48)
            .padding({ left: CommonConstants.SPACE_16, right: CommonConstants.SPACE_16 })
            .onClick(() => {
              if (group.items && group.items.length > 0) {
                this.playbackManager.playItems(group.items, group.items[0].Id!)
                PlayerRouter.push(this.getUIContext())
              }
            })
          }

          // 曲目列表
          ForEach(group.items, (item: BaseItemDto, index: number) => {
            ListItem() {
              TrackItem({
                item: item,
                isFavorite: this.favoriteStates[index],
                onPlay: () => {
                  this.playbackManager.playItems(group.items!, item.Id!)
                  PlayerRouter.push(this.getUIContext())
                },
                onFavoriteToggle: () => {
                  this.toggleFavorite(item, index)
                }
              })
            }
          })
        }
        .layoutWeight(1)
        .height(CommonConstants.FULL_PERCENT)
        .contentStartOffset(this.getToolBarHeight())
        .contentEndOffset(px2vp(this.avoidArea?.bottomRect.height))
        .edgeEffect(EdgeEffect.Fade)
        .scrollBar(BarState.Off)
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
      .alignItems(VerticalAlign.Top)

      // ToolBar：透明背景，固定显示标题和返回按钮
      ToolBar({
        title: this.args.name,
        color: $r('sys.color.font_primary'),
      })
        .backgroundColor($r('sys.color.background_primary'))
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
  }

  @Builder
  trackListBuilder(group: GroupInfo) {
    Column({ space: 0 }) {
      ForEach(group.items, (item: BaseItemDto, index: number) => {
        TrackItem({
          item: item,
          isFavorite: this.favoriteStates[index],
          onPlay: () => {
            this.playbackManager.playItems(group.items!, item.Id!)
            PlayerRouter.push(this.getUIContext())
          },
          onFavoriteToggle: () => {
            this.toggleFavorite(item, index)
          }
        })
      })
    }
    .width(CommonConstants.FULL_PERCENT)
  }

  build() {
    if (this.currentBreakpoint > WidthBreakpoint.WIDTH_SM) {
      // 平板布局：tabletLayout 内部自己处理 Stack + ToolBar
      if (this.group) {
        this.tabletLayout(this.group)
      } else {
        Column()
          .width(CommonConstants.FULL_PERCENT)
          .height(CommonConstants.FULL_PERCENT)
      }
    } else {
      // 手机布局：全局 Scroll + 渐变 ToolBar
      Stack() {
        Scroll(this.scroller) {
          Column() {
            if (this.group) {
              this.phoneLayout(this.group)
            }
          }
          .padding({ bottom: px2vp(this.avoidArea?.bottomRect.height) })
          .width(CommonConstants.FULL_PERCENT)
        }
        .align(Alignment.Top)
        .edgeEffect(EdgeEffect.Fade)
        .scrollBar(BarState.Off)
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)
        .onDidScroll(() => {
          let offset = this.scroller.currentOffset().yOffset
          let startFade = 80
          let endFade = 140
          let progress = Math.min(Math.max((offset - startFade) / (endFade - startFade), 0), 1)
          this.toolBarOpacity = progress
          let collapsed = progress >= 1
          if (collapsed !== this.headerCollapsed) {
            this.headerCollapsed = collapsed
          }
        })

        // ToolBar：滚动后切换为白底+标题
        Stack() {
          Column()
            .width(CommonConstants.FULL_PERCENT)
            .height(CommonConstants.FULL_PERCENT)
            .backgroundColor($r('sys.color.background_primary'))
            .opacity(this.toolBarOpacity)

          ToolBar({
            title: this.headerCollapsed ? this.args.name : undefined,
            color: this.headerCollapsed
              ? $r('sys.color.font_primary')
              : $r('sys.color.font_on_primary'),
          })
        }
        .width(CommonConstants.FULL_PERCENT)
        .height(this.getToolBarHeight())
      }
      .alignContent(Alignment.Top)
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
    }
  }

  private toggleAlbumFavorite(): void {
    if (!this.group?.group) return
    let isFav = this.group.group.UserData?.IsFavorite ?? false
    this.repository.toggleFavorite(this.group.group.Id!, !isFav)
      .then(() => {
        if (this.group?.group?.UserData) {
          this.group.group.UserData.IsFavorite = !isFav
        }
        // 重新赋值触发 @State 刷新
        let current = this.group!
        this.group = undefined
        this.group = current
      })
      .catch((e: Error) => {
        console.error("FinMusic: toggleAlbumFavorite error: " + e.message)
      })
  }

  private toggleFavorite(item: BaseItemDto, index: number): void {
    let isFav = this.favoriteStates[index]
    this.repository.toggleFavorite(item.Id!, !isFav)
      .then(() => {
        // 更新 @State 数组触发 UI 刷新
        let newStates = [...this.favoriteStates]
        newStates[index] = !isFav
        this.favoriteStates = newStates
      })
      .catch((e: Error) => {
        console.error("FinMusic: toggleFavorite error: " + e.message)
      })
  }

  private formatDuration(ticks?: number | null): string | undefined {
    if (!ticks) {
      return undefined
    }
    let minutes = Math.round(ticks / 600000000)
    if (minutes >= 60) {
      let hours = Math.floor(minutes / 60)
      let remainMinutes = minutes % 60
      return `${hours}h ${remainMinutes}min`
    }
    return `${minutes} min`
  }
}
