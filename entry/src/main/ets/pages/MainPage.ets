/**
 * Jellyfin HarmonyOS - 主页面
 * 替代 Android MainActivity
 */

import { App } from '../core/di/AppDependency';
import { ActivityEventType } from '../core/event/ActivityEvent';
import { AppLog } from '../common/utils/Logger';
import { ServerState } from './ServerState';

@Entry
@Component
struct MainPage {
  @State serverState: ServerState = ServerState.Pending;
  @State message: string = 'Loading...';

  private readonly TAG: string = 'MainPage';

  aboutToAppear(): void {
    AppLog.i('MainPage aboutToAppear');
    this.initializeApp();
    this.subscribeToEvents();
  }

  aboutToDisappear(): void {
    AppLog.i('MainPage aboutToDisappear');
    App.eventHandler.unsubscribe(ActivityEventType.SELECT_SERVER, () => {});
    App.eventHandler.unsubscribe(ActivityEventType.EXIT_APP, () => {});
  }

  /**
   * 初始化应用
   */
  private async initializeApp(): Promise<void> {
    try {
      // App 应该在 EntryAbility 中已经初始化
      if (!App.isInitialized) {
        AppLog.e('App not initialized');
        this.serverState = ServerState.Unset;
        this.message = 'App initialization failed';
        return;
      }

      // 检查是否已登录
      if (App.isLoggedIn) {
        this.serverState = ServerState.Available;
        this.message = `Connected to ${App.currentServer?.hostname}`;
      } else {
        this.serverState = ServerState.Unset;
        this.message = 'Please connect to a server';
      }

      AppLog.i('Server state: %{public}s', this.serverState);
    } catch (error) {
      AppLog.e('Failed to initialize app: %{public}s', JSON.stringify(error));
      this.serverState = ServerState.Unset;
      this.message = 'Error: ' + error;
    }
  }

  /**
   * 订阅事件
   */
  private subscribeToEvents(): void {
    // 订阅服务器选择事件
    App.eventHandler.subscribe(ActivityEventType.SELECT_SERVER, (event) => {
      AppLog.i('Received SelectServer event');
      this.serverState = ServerState.Unset;
      this.message = 'Select a server to connect';
    });

    // 订阅退出应用事件
    App.eventHandler.subscribe(ActivityEventType.EXIT_APP, (event) => {
      AppLog.i('Received ExitApp event');
      // TODO: 实现退出逻辑
    });
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('Jellyfin')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#00a4dc')

      // 主内容区
      Column() {
        if (this.serverState === ServerState.Pending) {
          // 加载中
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#00a4dc')

          Text(this.message)
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 16 })

        } else if (this.serverState === ServerState.Unset) {
          // 未连接服务器
          Text(this.message)
            .fontSize(16)
            .fontColor('#666666')
            .margin({ bottom: 24 })

          Button('Connect to Server')
            .width('80%')
            .height(48)
            .fontSize(16)
            .backgroundColor('#00a4dc')
            .onClick(() => {
              // TODO: 导航到服务器连接页面
              AppLog.i('Connect to Server clicked');
            })

        } else {
          // 已连接 - 显示 WebView
          Text(this.message)
            .fontSize(16)
            .fontColor('#333333')
            .margin({ bottom: 16 })

          // TODO: 替换为 WebView 组件
          Text('WebView will be here')
            .fontSize(14)
            .fontColor('#999999')
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
