/*
 * Jellyfin for HarmonyOS
 * Copyright (C) 2020-2026 Jellyfin Contributors
 * Copyright (C) 2026 WangRuijie
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * ---
 *
 * Based on jellyfin-android by Jellyfin Contributors
 * Original repository: https://github.com/jellyfin/jellyfin-android
 * Rewritten in 'ArkTS' with modifications by WangRuijie on 2026-03-22
 */

/**
 * Jellyfin HarmonyOS - WebView 页面
 * 加载 Jellyfin Web 界面并初始化 Bridge
 */

import webview from '@ohos.web.webview';
import window from '@ohos.window';
import { BridgeManager, BridgeManagerConfig } from '../bridge/BridgeManager';
import { App, getContext } from '../core/di/AppDependency';
import { ActivityEventType, ChangeFullscreenPayload } from '../core/event/ActivityEvent';
import { AppLog } from '../common/utils/Logger';
import { NAV_DEST_CONNECT } from '../pages/NavDestinationNames';
import { PageLoadState, PageLoadStatus, FULLSCREEN_SHIM_SCRIPT } from './WebViewPageState';

export interface WebViewPageParams {
  serverUrl: string;
  serverId: number;
}

@Component
export struct WebViewPage {
  webViewParams: WebViewPageParams = { serverUrl: '', serverId: 0 };
  @Consume('navPathStack') navPathStack: NavPathStack;
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @State serverUrl: string = '';
  @State serverId: number = 0;
  @State loadState: PageLoadState = new PageLoadState();
  private fullscreenShimInjected: boolean = false;

  controller: webview.WebviewController = new webview.WebviewController();
  private bridgeManager: BridgeManager | null = null;
  private loadTimeoutId: number = -1;
  private windowObj: window.Window | null = null;
  private unsubscribeFullscreen: (() => void) | null = null;

  aboutToAppear() {
    this.serverUrl = this.webViewParams.serverUrl;
    this.serverId = this.webViewParams.serverId;
    AppLog.i('WebViewPage.aboutToAppear, url=%{public}s', this.serverUrl);
    if (!this.serverUrl) {
      AppLog.e('WebViewPage: serverUrl is empty, redirect to ConnectPage');
      try { this.navPathStack.replacePath({ name: NAV_DEST_CONNECT }); } catch { /* ignore */ }
      return;
    }

    // DNS 预解析 + Socket 预建连：在 WebView 组件创建前提前完成网络握手，
    // 首次连接 Jellyfin Server 时减少 DNS 解析 + TCP 建连延迟（约减少 ~50-200ms）
    try {
      webview.WebviewController.prepareForPageLoad(this.serverUrl, true, 2);
      AppLog.i('WebViewPage: DNS pre-connect prepared for %{public}s', this.serverUrl);
    } catch (e) {
      AppLog.e('WebViewPage: prepareForPageLoad error: %{public}s', JSON.stringify(e));
    }

    // 启动加载超时计时（10 秒）— P8: consolidated into single loadState transition
    this.loadTimeoutId = setTimeout(() => {
      if (this.loadState.isLoading()) {
        AppLog.e('WebViewPage: load timeout');
        this.loadState = PageLoadState.error('连接超时，请检查服务器地址');
      }
    }, 10000) as number;

    // 订阅全屏事件，由 WebViewPage 直接处理屏幕旋转 + 系统栏显示/隐藏
    this.unsubscribeFullscreen = App.eventHandler.subscribe(
      ActivityEventType.CHANGE_FULLSCREEN,
      (event) => {
        const p = event.payload as ChangeFullscreenPayload;
        const isFullscreen: boolean = p?.isFullscreen ?? false;
        this.handleFullscreenChange(isFullscreen);
      }
    );
  }

  aboutToDisappear() {
    AppLog.i('WebViewPage.aboutToDisappear');
    if (this.loadTimeoutId !== -1) {
      clearTimeout(this.loadTimeoutId);
      this.loadTimeoutId = -1;
    }
    this.unsubscribeFullscreen?.();
    this.unsubscribeFullscreen = null;
    this.bridgeManager?.destroy();
    this.bridgeManager = null;
  }

  build() {
    NavDestination() {
      Column() {
        Stack() {
          // WebView 主体
          Web({ src: this.serverUrl, controller: this.controller })
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .fileAccess(true)
            .keyboardAvoidMode(WebKeyboardAvoidMode.RESIZE_CONTENT)
            .expandSafeArea([SafeAreaType.KEYBOARD])
            .onlineImageAccess(true)
            .mixedMode(MixedMode.All)
            .cacheMode(CacheMode.Default)
            .width('100%')
            .height('100%')
            .backgroundColor('#000000')
            .onControllerAttached(async () => {
              // 关键：Bridge 注册必须在此处，注册前 WebView 控制器尚未绑定
              await this.initBridgeManager();
            })
            .onPageBegin(() => {
              AppLog.i('WebViewPage: onPageBegin');
              this.loadState = PageLoadState.loading();
            })
            .onPageEnd(() => {
              AppLog.i('WebViewPage: onPageEnd');
              clearTimeout(this.loadTimeoutId);
              this.loadTimeoutId = -1;
              this.loadState = PageLoadState.loaded();
              this.injectFullscreenBridge();
            })
            .onErrorReceive((event) => {
              // 只处理主框架加载失败，忽略子资源（XHR/fetch）错误
              // 屏幕旋转等配置变化可能导致子资源请求中断触发此回调
              if (!event?.request?.isMainFrame()) {
                return;
              }
              const msg: string = event?.error?.getErrorInfo() ?? '加载失败';
              AppLog.e('WebViewPage: onErrorReceive (main frame): %{public}s', msg);
              clearTimeout(this.loadTimeoutId);
              this.loadTimeoutId = -1;
              this.loadState = PageLoadState.error(msg);
            })

          // 加载指示器覆盖层
          if (this.loadState.isLoading()) {
            Column() {
              LoadingProgress()
                .width(48)
                .height(48)
                .color($r('app.color.primary'))
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#000000')
          }

          if (this.loadState.hasError()) {
            Column({ space: 16 }) {
              Text('连接失败')
                .fontSize(20)
                .fontColor('#ffffff')
                .fontWeight(FontWeight.Bold)

              Text(this.loadState.getErrorMessage())
                .fontSize(14)
                .fontColor('#b0b0b0')
                .textAlign(TextAlign.Center)
                .padding({ left: 32, right: 32 })

              Button('重试')
                .width(120)
                .height(44)
                .backgroundColor('#00a4dc')
                .fontColor('#ffffff')
                .onClick(() => {
                  this.loadState = PageLoadState.loading();
                  // 重置超时计时器
                  this.loadTimeoutId = setTimeout(() => {
                    if (this.loadState.isLoading()) {
                      this.loadState = PageLoadState.error('连接超时，请检查服务器地址');
                    }
                  }, 10000) as number;
                  this.controller.loadUrl(this.serverUrl);
                })

              Button('更改服务器')
                .width(120)
                .height(44)
                .backgroundColor('#2d2d2d')
                .fontColor('#ffffff')
                .onClick(() => {
                  this.navPathStack.replacePath({ name: NAV_DEST_CONNECT });
                })
            }
            .width('100%')
            .height('100%')
            .padding(32)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#0f0f0f')
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.topRectHeight })
      .backgroundColor('#000000')
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      // 先尝试 WebView 内部返回
      try {
        if (this.controller.accessBackward()) {
          this.controller.backward();
          return true;
        }
      } catch (e) {
        AppLog.e('WebViewPage: accessBackward error: %{public}s', JSON.stringify(e));
      }
      // WebView 无历史可退 → 退出应用，避免 pop 后暴露空白根页面
      try {
        (getContext() as ESObject).terminateSelf();
      } catch (e) {
        AppLog.e('WebViewPage: terminateSelf error: %{public}s', JSON.stringify(e));
      }
      return true;
    })
  }

  /**
   * 向 WebView 注入全屏桥接 shim。
   * Jellyfin web 播放器使用浏览器原生 requestFullscreen API，不直接调用
   * NativeInterface.enableFullscreen()。此 shim 拦截 fullscreenchange 事件
   * 以及 HTMLElement.prototype.requestFullscreen，将全屏请求路由到我们的
   * 原生桥接，从而触发屏幕旋转。
   */
  /**
   * P6-MEDIUM: Fullscreen shim injected only once via guard flag.
   * Script is extracted to static constant FULLSCREEN_SHIM_SCRIPT.
   */
  private injectFullscreenBridge(): void {
    if (this.fullscreenShimInjected) {
      return;
    }
    try {
      this.controller.runJavaScript(FULLSCREEN_SHIM_SCRIPT);
      this.fullscreenShimInjected = true;
      AppLog.i('WebViewPage: fullscreen bridge shim injected');
    } catch (e) {
      AppLog.e('WebViewPage: injectFullscreenBridge error: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 处理全屏切换：旋转屏幕方向 + 控制 System Bar 显示/隐藏
   */
  private async handleFullscreenChange(isFullscreen: boolean): Promise<void> {
    try {
      if (!this.windowObj) {
        this.windowObj = await window.getLastWindow(getContext());
      }
      if (isFullscreen) {
        await this.windowObj.setWindowSystemBarEnable([]);
        await this.windowObj.setPreferredOrientation(window.Orientation.LANDSCAPE);
      } else {
        await this.windowObj.setWindowSystemBarEnable(['status', 'navigation']);
        await this.windowObj.setPreferredOrientation(window.Orientation.PORTRAIT);
      }
      AppLog.i('WebViewPage: fullscreen changed, isFullscreen=%{public}s', String(isFullscreen));
    } catch (e) {
      AppLog.e('WebViewPage: handleFullscreenChange error: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 初始化 BridgeManager（在 onControllerAttached 中调用）
   * BridgeManager.initialize() 内部的 registerJavaScriptProxies() 会调用一次
   * controller.refresh() 来激活代理，此处不再重复刷新，避免双重页面重载。
   */
  private async initBridgeManager(): Promise<void> {
    try {
      AppLog.i('WebViewPage: initializing BridgeManager...');
      const config: BridgeManagerConfig = {
        controller: this.controller,
        context: getContext(),
        eventHandler: App.eventHandler,
        preferences: App.preferences
      };
      this.bridgeManager = new BridgeManager(config);
      await this.bridgeManager.initialize();
      AppLog.i('WebViewPage: BridgeManager initialized successfully');
    } catch (err) {
      AppLog.e('WebViewPage: BridgeManager init error: %{public}s', JSON.stringify(err));
    }
  }
}
