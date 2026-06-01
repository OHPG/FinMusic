import { window } from '@kit.ArkUI'
import { CommonConstants, ToolBar } from '@ohpg/fin-framework'
import { Proxy } from '@ohpg/proxy'
import { groupAttributeModifier, itemDividerBuilder, windowAttributeModifier } from '../../style/Modifier'
import { AppPrefer } from '../../prefer/AppPrefer'

@Entry
@Component
struct CacheSettingPage {

  @StorageProp('currentAvoidArea') avoidArea?: window.AvoidArea = undefined

  private prefer: AppPrefer = AppStorage.get<AppPrefer>(AppPrefer.PREFER)!

  @State cacheEnabled: boolean = false

  @State dnsCacheEnabled: boolean = true

  @State cacheMaxSizeMB: number = AppPrefer.DEFAULT_CACHE_MAX_SIZE_MB

  @State cacheMaxCount: number = AppPrefer.DEFAULT_CACHE_MAX_COUNT

  @State currentCacheSize: string = ''

  aboutToAppear(): void {
    this.cacheEnabled = this.prefer.isCacheEnabled()
    this.dnsCacheEnabled = this.prefer.isDnsCacheEnabled()
    this.cacheMaxSizeMB = this.prefer.getCacheMaxSizeMB()
    this.cacheMaxCount = this.prefer.getCacheMaxCount()
    this.refreshCacheInfo()
  }

  private refreshCacheInfo(): void {
    let sizeBytes = Proxy.getCacheSize()
    this.currentCacheSize = this.formatSize(sizeBytes)
  }

  private formatSize(bytes: number): string {
    if (bytes <= 0) {
      return '0 B'
    }
    if (bytes < 1024) {
      return bytes + ' B'
    }
    if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(1) + ' KB'
    }
    if (bytes < 1024 * 1024 * 1024) {
      return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
    }
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB'
  }

  build() {
    Column({ space: CommonConstants.SPACE_8 }) {
      ToolBar({ title: $r('app.string.prefer_cache') })

      Scroll() {
        Column({ space: CommonConstants.SPACE_12 }) {

          // ===== Group 1: 缓存开关 =====
          Column() {
            Row() {
              Text($r('app.string.cache_enable'))
                .fontSize(16)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: $$this.cacheEnabled })
                .onChange((isOn: boolean) => {
                  this.prefer.setCacheEnabled(isOn)
                })
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({
              left: CommonConstants.SPACE_16,
              right: CommonConstants.SPACE_16
            })
          }
          .attributeModifier(groupAttributeModifier)

          // ===== Group 2: 缓存限制设置 =====
          Column() {
            // 缓存大小上限
            Row() {
              Text($r('app.string.cache_max_size'))
                .fontSize(16)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Blank()
              Text(this.cacheMaxSizeMB + ' MB')
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({
              left: CommonConstants.SPACE_16,
              right: CommonConstants.SPACE_16
            })

            Slider({
              value: this.cacheMaxSizeMB,
              min: 128,
              max: 4096,
              step: 128
            })
              .width('90%')
              .onChange((value: number) => {
                this.cacheMaxSizeMB = value
                this.prefer.setCacheMaxSizeMB(value)
              })

            itemDividerBuilder()

            // 缓存数量上限
            Row() {
              Text($r('app.string.cache_max_count'))
                .fontSize(16)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Blank()
              Text(this.cacheMaxCount.toString())
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({
              left: CommonConstants.SPACE_16,
              right: CommonConstants.SPACE_16
            })

            Slider({
              value: this.cacheMaxCount,
              min: 100,
              max: 1000,
              step: 50
            })
              .width('90%')
              .onChange((value: number) => {
                this.cacheMaxCount = value
                this.prefer.setCacheMaxCount(value)
              })
          }
          .attributeModifier(groupAttributeModifier)
          .padding({ bottom: CommonConstants.SPACE_12 })

          // ===== Group 3: DNS 缓存 =====
          Column() {
            Row() {
              Text($r('app.string.dns_cache_enable'))
                .fontSize(16)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: $$this.dnsCacheEnabled })
                .onChange((isOn: boolean) => {
                  this.prefer.setDnsCacheEnabled(isOn)
                  Proxy.setDnsCacheEnabled(isOn)
                })
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({
              left: CommonConstants.SPACE_16,
              right: CommonConstants.SPACE_16
            })

            itemDividerBuilder()

            Row() {
              Text($r('app.string.dns_cache_clear'))
                .fontSize(16)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({
              left: CommonConstants.SPACE_16,
              right: CommonConstants.SPACE_16
            })
            .onClick(() => {
              Proxy.clearDnsCache()
            })
          }
          .attributeModifier(groupAttributeModifier)

          // ===== Group 4: 当前缓存信息 =====
          Column() {
            Row() {
              Text($r('app.string.cache_current_size'))
                .fontSize(16)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Blank()
              Text(this.currentCacheSize)
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(56)
            .padding({
              left: CommonConstants.SPACE_16,
              right: CommonConstants.SPACE_16
            })
          }
          .attributeModifier(groupAttributeModifier)

          // ===== 清除缓存按钮 =====
          Button($r('app.string.cache_clear'))
            .type(ButtonType.Capsule)
            .width('90%')
            .height(44)
            .backgroundColor('#E53935')
            .fontColor(Color.White)
            .fontSize(16)
            .margin({ top: CommonConstants.SPACE_16, bottom: CommonConstants.SPACE_16 })
            .onClick(async () => {
              await Proxy.clearCache()
              this.refreshCacheInfo()
            })
        }
        .constraintSize({
          minHeight: '100%'
        })
        .padding({
          bottom: px2vp(this.avoidArea?.bottomRect.height)
        })
      }
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Fade)
      .width(CommonConstants.FULL_PERCENT)
      .height('auto')
      .layoutWeight(1)
    }
    .attributeModifier(windowAttributeModifier)
  }
}
