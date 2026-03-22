/*
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
 * Jellyfin HarmonyOS - 设置页面
 * 对齐接口契约 Section h SettingsPage 定义
 */

import { App } from '../core/di/AppDependency';
import { ActivityEventType } from '../core/event/ActivityEvent';
import { Constants } from '../common/constants/Constants';
import { AppLog } from '../common/utils/Logger';
import { NAV_DEST_CONNECT } from '../pages/NavDestinationNames';

@Component
export struct SettingsPage {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @State videoPlayerType: string = 'web';
  @State exoPlayerAllowSwipeGestures: boolean = true;
  @State serverName: string = '';
  @State userName: string = '';
  @State appVersion: string = Constants.APP_INFO_VERSION;

  aboutToAppear() {
    AppLog.i('SettingsPage.aboutToAppear');
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    try {
      // 加载服务器信息
      const server = await App.apiController.loadSavedServer();
      this.serverName = server?.hostname ?? '未连接';

      // 加载用户信息
      const user = App.currentUser;
      if (user) {
        this.userName = user.userId;
      }

      // 加载播放器偏好
      this.videoPlayerType = App.preferences.videoPlayerType ?? 'web';
      this.exoPlayerAllowSwipeGestures = App.preferences.exoPlayerAllowSwipeGestures ?? true;

      AppLog.i('SettingsPage: settings loaded, server=%{public}s', this.serverName);
    } catch (err) {
      AppLog.e('SettingsPage: loadSettings error: %{public}s', JSON.stringify(err));
    }
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(12)
      .fontColor('#00a4dc')
      .padding({ left: 16, top: 16, bottom: 8 })
      .width('100%')
  }

  @Builder
  SettingItem(title: string, subtitle: string, onClick: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(title)
          .fontSize(16)
          .fontColor('#ffffff')

        if (subtitle) {
          Text(subtitle)
            .fontSize(12)
            .fontColor('#b0b0b0')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(16)
        .height(16)
        .fillColor('#666666')
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .onClick(() => onClick())
  }

  @Builder
  NavigationItem(title: string, subtitle: string, onClick: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(title)
          .fontSize(16)
          .fontColor('#ffffff')

        if (subtitle) {
          Text(subtitle)
            .fontSize(12)
            .fontColor('#b0b0b0')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(16)
        .height(16)
        .fillColor('#666666')
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .onClick(() => onClick())
  }

  @Builder
  ToggleItem(title: string, value: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#ffffff')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#00a4dc')
        .onChange((isOn: boolean) => {
          onChange(isOn);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏
        Row() {
          Image($r('sys.media.ohos_ic_back'))
            .width(24)
            .height(24)
            .fillColor('#ffffff')
            .onClick(() => this.navPathStack.pop())

          Text('设置')
            .fontSize(18)
            .fontColor('#ffffff')
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })

          Blank()
        }
        .width('100%')
        .height(56 + this.topRectHeight)
        .padding({ left: 16, right: 16, top: this.topRectHeight })
        .backgroundColor('#0f0f0f')

        Scroll() {
          Column() {
            // 服务器信息
            this.SectionHeader('服务器')

            this.SettingItem('服务器地址', this.serverName, () => {
              // 只读展示，不跳转
            })

            this.NavigationItem('更改服务器', '', () => {
              App.eventHandler.emit({ type: ActivityEventType.SELECT_SERVER, payload: undefined });
            })

            Divider()
              .color('#2a2a2a')
              .margin({ left: 16 })

            // 播放器
            this.SectionHeader('播放器')

            this.ToggleItem(
              '允许手势控制（亮度/音量）',
              this.exoPlayerAllowSwipeGestures,
              (v: boolean) => {
                this.exoPlayerAllowSwipeGestures = v;
                // 通过 rawPreferences 写回，因为 AppPreferences 只暴露 getter
                App.preferences.getRawPreferences()?.putSync(
                  Constants.PREF_EXOPLAYER_ALLOW_SWIPE_GESTURES, v
                );
              }
            )

            Divider()
              .color('#2a2a2a')
              .margin({ left: 16 })

            // 关于
            this.SectionHeader('关于')

            this.SettingItem('版本', this.appVersion, () => {
              // 只读展示
            })

            Divider()
              .color('#2a2a2a')
              .margin({ left: 16 })

            // 账户
            this.SectionHeader('账户')

            Row() {
              Text('注销')
                .fontSize(16)
                .fontColor('#ff4444')
                .layoutWeight(1)
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .onClick(async () => {
              try {
                AppLog.i('SettingsPage: sign out');
                // 清除 access token 并跳回连接页
                App.apiController.config.accessToken = undefined;
                await App.clear();
                this.navPathStack.replacePath({ name: NAV_DEST_CONNECT });
              } catch (err) {
                AppLog.e('SettingsPage: sign out error: %{public}s', JSON.stringify(err));
              }
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#0f0f0f')
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.navPathStack.pop();
      return true;
    })
  }
}

export default SettingsPage;
