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
 * Jellyfin HarmonyOS - 应用入口
 * 迁移自 jellyfin-android/JellyfinApplication.kt + MainActivity.kt
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import display from '@ohos.display';
import { BusinessError } from '@kit.BasicServicesKit';
import webview from '@ohos.web.webview';
import { App } from '../core/di/AppDependency';
import { Logger, AppLog } from '../common/utils/Logger';

const DOMAIN = 0x0000;
const TAG = 'Jellyfin';

export default class EntryAbility extends UIAbility {
  private cachedDensity: number = 0;
  private mainWindow: window.Window | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 预初始化 Web 引擎，将 WebKit 内核加载提前到 Ability 创建阶段，
    // 避免首次打开 WebView 时的冷启动白屏延迟（约减少 ~100ms）
    try {
      webview.WebviewController.initializeWebEngine();
      hilog.info(DOMAIN, TAG, '%{public}s', 'Web engine pre-initialized');
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'Web engine pre-init failed: %{public}s', JSON.stringify(err));
    }

    // 设置颜色模式
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    // 销毁依赖容器
    App.destroy();
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    const setupImmersive = (win: window.Window): void => {
      // 缓存窗口引用，用于 onWindowStageDestroy 中注销监听器
      this.mainWindow = win;

      // 缓存 density 值（会话期间不变），避免每次回调都同步调用 display API
      this.cachedDensity = display.getDefaultDisplaySync().densityPixels;

      // 1. 全屏布局：内容延伸到状态栏和导航条下方
      win.setWindowLayoutFullScreen(true).catch((e: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'setWindowLayoutFullScreen failed: %{public}s', e.message);
      });

      // 2. 状态栏 / 导航条透明 + 白色图标（适配深色背景）
      win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#FFFFFF',
        navigationBarColor: '#00000000',
        navigationBarContentColor: '#FFFFFF'
      }).catch((e: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'setWindowSystemBarProperties failed: %{public}s', e.message);
      });

      // 3. 读取安全区高度并写入 AppStorage
      const syncAvoidArea = (win2: window.Window): void => {
        const topArea = win2.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        AppStorage.setOrCreate('topRectHeight', topArea.topRect.height / this.cachedDensity);

        const bottomArea = win2.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        AppStorage.setOrCreate('bottomRectHeight', bottomArea.bottomRect.height / this.cachedDensity);
      };
      syncAvoidArea(win);

      // 4. 监听安全区变化（旋转、折叠屏等场景）
      win.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          AppStorage.setOrCreate('topRectHeight', data.area.topRect.height / this.cachedDensity);
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          AppStorage.setOrCreate('bottomRectHeight', data.area.bottomRect.height / this.cachedDensity);
        }
      });
    };

    const loadPage = (stage: window.WindowStage): void => {
      stage.loadContent('pages/AppRoot', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, TAG, 'Succeeded in loading AppRoot.');
        try {
          setupImmersive(stage.getMainWindowSync());
        } catch (e) {
          hilog.warn(DOMAIN, TAG, 'setupImmersive failed: %{public}s', JSON.stringify(e));
        }
      });
    };

    // 先初始化依赖容器，完成后再加载主页面，避免 MainPage 访问未就绪的服务
    App.initialize(this.context)
      .then(() => {
        AppLog.i('AppDependency initialized successfully');
        loadPage(windowStage);
      })
      .catch((err: Error) => {
        AppLog.e('Failed to initialize AppDependency: %{public}s', err.message);
        loadPage(windowStage);
      });
  }

  onWindowStageDestroy(): void {
    // 注销 avoidAreaChange 监听器，避免窗口销毁后回调泄漏
    if (this.mainWindow) {
      try {
        this.mainWindow.off('avoidAreaChange');
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'Failed to unregister avoidAreaChange listener: %{public}s', JSON.stringify(e));
      }
      this.mainWindow = null;
    }
    this.cachedDensity = 0;
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}