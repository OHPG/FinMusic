import { PrivacyDialog } from '@ohpg/fin-framework'
import { Repository } from '../../data/Repository'
import { AppPrefer } from '../../prefer/AppPrefer'
import { FinRouter } from '@ohpg/fin-framework'
import { AppRouter } from '../../router/AppRouter'

@Entry
@Component
struct SplashPage {

  private repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  private appPrefer: AppPrefer = AppStorage.get(AppPrefer.PREFER)!

  private privacyDialog: PrivacyDialog = new PrivacyDialog(this.getUIContext())

  aboutToAppear(): void {
    if (this.appPrefer.isPrivacyGrant()) {
      setTimeout(() => {
        this.initAndWait()
      }, 1000)
    } else {
      let resourceManager = getContext().resourceManager
      let privacyUrl = resourceManager.getStringSync($r('app.string.privacy'))
      this.privacyDialog.setAppInfo(privacyUrl)
      this.privacyDialog.setPrivacyCallback(() => {
        this.appPrefer.setPrivacyGrant()
        this.privacyDialog.dismiss(true)
        setTimeout(() => {
          this.initAndWait()
        }, 1000)
      })
      this.privacyDialog.show()
    }
  }

  build() {

    Stack() {
      Image($r('app.media.foreground'))
        .size({
          width: 100,
          height: 100
        })
    }
    .width('100%')
    .height('100%')

  }

  onBackPress(): boolean | void {
    return true
  }

  aboutToDisappear(): void {

  }

  private async initAndWait() {
    let delay = new Promise<void>((resolve) => setTimeout(resolve, 1000))
    let init = this.repository.init().catch((e: Error) => {
      console.error("FinMusic: repository init failed: " + e.message)
    })
    await Promise.all([delay, init])
    let activeInfo = this.repository.getActiveInfo()
    if (activeInfo) {
      AppRouter.goToHome(this.getUIContext())
    } else {
      FinRouter.auth(this.getUIContext(), true)
    }
  }

}