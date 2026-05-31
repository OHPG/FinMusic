import { window } from '@kit.ArkUI';
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BreakpointSystem } from '@ohpg/fin-core';
import { AvoidAreaSystem } from '@ohpg/fin-core';
import { DeviceUtil } from '@ohpg/fin-framework';
import { AVPlaybackManager } from '@ohpg/player';
import { AppPlaybackManager } from '../player/AppPlaybackManager';

export default class EntryAbility extends UIAbility {

  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  private avoidAreaSystem: AvoidAreaSystem = new AvoidAreaSystem();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    let mainWindow = windowStage.getMainWindowSync()
    DeviceUtil.initWindow(mainWindow)
    mainWindow.setImmersiveModeEnabledState(true)
    this.avoidAreaSystem.register(mainWindow)
    windowStage.loadContent('pages/splash/SplashPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      this.breakpointSystem.register(mainWindow)
      // 初始化播放管理器（UIContext 此时可用）
      let uiContext = mainWindow.getUIContext()
      let playbackManager = new AppPlaybackManager(uiContext)
      AppStorage.setOrCreate(AVPlaybackManager.AV_PLAYER_MANAGER, playbackManager)
      AppStorage.setOrCreate(AppPlaybackManager.APP_PLAYBACK_MANAGER, playbackManager)
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    this.avoidAreaSystem.unregister()
    this.breakpointSystem.unregister()
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    let playbackManager = AppStorage.get<AppPlaybackManager>(AppPlaybackManager.APP_PLAYBACK_MANAGER)
    playbackManager?.release()
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

}
