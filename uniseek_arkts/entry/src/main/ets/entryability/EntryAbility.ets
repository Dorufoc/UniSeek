import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import mediaQuery from '@ohos.mediaquery';
import { ApiClient } from '../services/ApiClient';
import { AuthService } from '../services/AuthService';
import { UserSession } from '../services/UserSession';
import { AppBootstrapPolicy } from '../common/AppBootstrapPolicy';
import { ChatWebSocketService } from '../services/ChatWebSocketService';
import { BreakpointResolver, WindowBreakpoint } from '../common/Responsive';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  // 媒体查询监听器引用，用于在 Ability 销毁时统一注销
  private mqListeners: mediaQuery.MediaQueryListener[] = [];
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    ApiClient.initialize(this.context)
    ApiClient.restoreConfiguration()
    AuthService.restoreCachedSession()
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    ChatWebSocketService.getInstance().disconnect()
    this.clearMqListeners();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    const initialPage: string = AppBootstrapPolicy.resolveInitialPage(ApiClient.hasToken(), UserSession.role)
    windowStage.loadContent(initialPage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      // 注册窗口宽度媒体查询，实时同步当前断点到 AppStorage
      const win = windowStage.getMainWindowSync();
      const uiContext = win.getUIContext();
      const mq = uiContext.getMediaQuery();
      const rect = win.getWindowProperties().windowRect;
      AppStorage.setOrCreate<WindowBreakpoint>('breakpoint', BreakpointResolver.resolve(rect.width));

      const updateBreakpoint = (): void => {
        const currentRect = win.getWindowProperties().windowRect;
        AppStorage.setOrCreate<WindowBreakpoint>('breakpoint', BreakpointResolver.resolve(currentRect.width));
      };

      const compactListener = mq.matchMediaSync('(width < 600vp)');
      if (compactListener) {
        compactListener.on('change', updateBreakpoint);
        this.mqListeners.push(compactListener);
      }

      const mediumListener = mq.matchMediaSync('(width < 840vp)');
      if (mediumListener) {
        mediumListener.on('change', updateBreakpoint);
        this.mqListeners.push(mediumListener);
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    this.clearMqListeners();
  }

  private clearMqListeners(): void {
    for (const listener of this.mqListeners) {
      listener.off('change');
    }
    this.mqListeners = [];
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
