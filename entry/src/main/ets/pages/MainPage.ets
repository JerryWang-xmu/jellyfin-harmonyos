/**
 * Jellyfin HarmonyOS - 主页面（路由中枢）
 * 替代 Android MainActivity
 */

import router from '@ohos.router';
import window from '@ohos.window';
import { App } from '../core/di/AppDependency';
import { ActivityEventType } from '../core/event/ActivityEvent';
import { AppLog } from '../common/utils/Logger';
import { ServerState } from './ServerState';

@Entry
@Component
struct MainPage {
  @State serverState: ServerState = ServerState.Pending;
  private unsubscribeTokens: Array<() => void> = [];
  private windowObj: window.Window | null = null;

  aboutToAppear() {
    AppLog.i('MainPage aboutToAppear');
    this.subscribeToEvents();
    this.initializeApp();
  }

  aboutToDisappear() {
    AppLog.i('MainPage aboutToDisappear');
    this.unsubscribeTokens.forEach(fn => fn());
    this.unsubscribeTokens = [];
  }

  /**
   * 订阅事件（6 个）
   */
  private subscribeToEvents(): void {
    // 1. SELECT_SERVER：更改服务器
    const t1 = App.eventHandler.subscribe(ActivityEventType.SELECT_SERVER, () => {
      AppLog.i('MainPage: SELECT_SERVER event received');
      router.replaceUrl({ url: 'setup/ConnectPage' });
    });

    // 2. LAUNCH_NATIVE_PLAYER：启动原生播放器
    const t2 = App.eventHandler.subscribe(ActivityEventType.LAUNCH_NATIVE_PLAYER, (event) => {
      AppLog.i('MainPage: LAUNCH_NATIVE_PLAYER event received');
      router.pushUrl({
        url: 'player/ui/PlayerPage',
        params: {
          playOptions: typeof event.payload === 'string'
            ? event.payload
            : JSON.stringify(event.payload)
        }
      });
    });

    // 3. OPEN_SETTINGS：打开设置
    const t3 = App.eventHandler.subscribe(ActivityEventType.OPEN_SETTINGS, () => {
      AppLog.i('MainPage: OPEN_SETTINGS event received');
      router.pushUrl({ url: 'settings/SettingsPage' });
    });

    // 4. OPEN_DOWNLOADS：打开下载
    const t4 = App.eventHandler.subscribe(ActivityEventType.OPEN_DOWNLOADS, () => {
      AppLog.i('MainPage: OPEN_DOWNLOADS event received');
      router.pushUrl({ url: 'downloads/DownloadsPage' });
    });

    // 5. EXIT_APP：退出应用
    const t5 = App.eventHandler.subscribe(ActivityEventType.EXIT_APP, () => {
      AppLog.i('MainPage: EXIT_APP event received');
      try {
        (getContext(this) as ESObject).terminateSelf();
      } catch (e) {
        AppLog.e('MainPage: terminateSelf failed: %{public}s', JSON.stringify(e));
      }
    });

    // 6. CHANGE_FULLSCREEN：全屏控制
    const t6 = App.eventHandler.subscribe(ActivityEventType.CHANGE_FULLSCREEN, (event) => {
      AppLog.i('MainPage: CHANGE_FULLSCREEN event received');
      const payload = typeof event.payload === 'string'
        ? JSON.parse(event.payload) as Record<string, boolean>
        : event.payload as Record<string, boolean>;
      const isFullscreen: boolean = (payload as Record<string, boolean>)?.['isFullscreen'] ?? false;
      this.setFullscreen(isFullscreen);
    });

    this.unsubscribeTokens = [t1, t2, t3, t4, t5, t6];
  }

  /**
   * 初始化应用：检查已保存服务器，路由到对应页面
   */
  private async initializeApp(): Promise<void> {
    this.serverState = ServerState.Pending;
    try {
      const server = await App.apiController.loadSavedServer();
      if (server) {
        this.serverState = ServerState.Available;
        AppLog.i('MainPage: saved server found, navigate to WebViewPage');
        router.replaceUrl({
          url: 'webapp/WebViewPage',
          params: { serverUrl: server.hostname, serverId: server.id }
        });
      } else {
        this.serverState = ServerState.Unset;
        AppLog.i('MainPage: no saved server, navigate to ConnectPage');
        router.replaceUrl({ url: 'setup/ConnectPage' });
      }
    } catch (err) {
      AppLog.e('MainPage: initializeApp error: %{public}s', JSON.stringify(err));
      this.serverState = ServerState.Unset;
      router.replaceUrl({ url: 'setup/ConnectPage' });
    }
  }

  /**
   * 全屏控制
   */
  private async setFullscreen(isFullscreen: boolean): Promise<void> {
    try {
      if (!this.windowObj) {
        this.windowObj = await window.getLastWindow(getContext(this));
      }
      if (isFullscreen) {
        await this.windowObj.setWindowSystemBarEnable([]);
        await this.windowObj.setPreferredOrientation(window.Orientation.LANDSCAPE);
      } else {
        await this.windowObj.setWindowSystemBarEnable(['status', 'navigation']);
        await this.windowObj.setPreferredOrientation(window.Orientation.PORTRAIT);
      }
    } catch (e) {
      AppLog.e('MainPage: setFullscreen error: %{public}s', JSON.stringify(e));
    }
  }

  build() {
    // MainPage 本身只做路由，展示加载状态
    Column() {
      if (this.serverState === ServerState.Pending) {
        LoadingProgress()
          .width(48)
          .height(48)
          .color($r('app.color.primary'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .justifyContent(FlexAlign.Center)
  }
}
