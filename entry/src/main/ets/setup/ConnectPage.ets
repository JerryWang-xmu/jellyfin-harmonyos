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
 * 服务器连接页面
 * 迁移自 jellyfin-android/connect/ConnectFragment.kt
 *
 * UI 对齐 design/UI/首页.png 及 UI_SPEC.md Section 5.1
 */

import { AppLog } from '../common/utils/Logger';
import { App } from '../core/di/AppDependency';
import { ConnectionHelper, CheckUrlSuccess, CheckUrlError } from './ConnectionHelper';
import { NAV_DEST_WEBVIEW } from '../pages/NavDestinationNames';

interface ConnectWebViewParam {
  serverUrl: string;
  serverId: number;
}

@Component
export struct ConnectPage {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @State serverUrl: string = '';
  @State isConnecting: boolean = false;
  @State errorMessage: string = '';
  @State recentServers: string[] = [];

  aboutToAppear() {
    this.loadRecentServers();
  }

  /**
   * 从数据库加载历史服务器列表
   */
  private async loadRecentServers(): Promise<void> {
    try {
      const servers = await App.apiController.loadPreviouslyUsedServers();
      this.recentServers = servers.map(s => s.hostname);
    } catch {
      this.recentServers = [];
    }
  }

  /**
   * 连接到服务器
   * 使用 ConnectionHelper 验证 URL，验证成功后调用 apiController.setupServer 持久化
   */
  private async connectToServer(): Promise<void> {
    this.isConnecting = true;
    this.errorMessage = '';

    const result = await ConnectionHelper.checkServerUrl(this.serverUrl);

    if (result.type === 'success') {
      const successResult = result as CheckUrlSuccess;
      try {
        const serverId = await App.apiController.setupServer(successResult.url);
        // 导航到 WebViewPage
        const navParam: ConnectWebViewParam = { serverUrl: successResult.url, serverId: serverId };
        this.navPathStack.replacePath({ name: NAV_DEST_WEBVIEW, param: navParam as Object });
      } catch (err) {
        this.errorMessage = '保存服务器信息失败';
        AppLog.e('Setup server error: %{public}s', JSON.stringify(err));
      }
    } else if (result.type === 'error') {
      const errorResult = result as CheckUrlError;
      this.errorMessage = errorResult.message;
    }

    this.isConnecting = false;
  }

  /**
   * Jellyfin Logo 区域：紫蓝渐变三角形图标 + "Jellyfin" 文字
   */
  @Builder
  JellyfinLogo() {
    Row() {
      // 三角形图标（使用多边形近似：两个三角叠加形成 Jellyfin logo 造型）
      // 由于 ArkTS 无法直接绘制任意 SVG，使用 Text + Unicode 或 Canvas 近似
      // 此处使用品牌色文字配合三角符号还原 logo 视觉
      Stack() {
        // 外层大三角（紫色）
        Polygon({ width: 32, height: 32 })
          .points([{ x: 16, y: 0 }, { x: 32, y: 28 }, { x: 0, y: 28 }])
          .fill('#aa5cc3')
        // 内层小三角（蓝色，形成双三角 logo 效果）
        Polygon({ width: 20, height: 20 })
          .points([{ x: 10, y: 10 }, { x: 20, y: 28 }, { x: 0, y: 28 }])
          .fill('#0086b3')
          .offset({ x: 6, y: 2 })
      }
      .width(32)
      .height(32)
      .margin({ right: 10 })

      Text('Jellyfin')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#ffffff')
    }
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 历史服务器列表项
   */
  @Builder
  RecentServerItem(server: string) {
    Row() {
      // 地球仪图标（Unicode 替代）
      Text('\uD83C\uDF10')
        .fontSize(18)
        .margin({ right: 12 })

      Text(server)
        .fontSize(14)
        .fontColor('#ffffff')
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.serverUrl = server;
      this.connectToServer();
    })
  }

  build() {
    NavDestination() {
      Column() {
        // ===== 顶部导航栏（56vp）=====
        Row() {
          // 返回箭头
          Text('\u2190')
            .fontSize(24)
            .fontColor('#ffffff')
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.navPathStack.pop();
            })

          // Jellyfin Logo
          this.JellyfinLogo()

          Blank()
        }
        .width('100%')
        .height(56 + this.topRectHeight)
        .padding({ left: 8, right: 16, top: this.topRectHeight })
        .alignItems(VerticalAlign.Center)

        // ===== 主内容区 =====
        Column() {
          // 顶部间距
          Blank().height(32)

          // "连接到服务器" 大标题
          Text('连接到服务器')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 16 })

          // "主机" 标签
          Text('主机')
            .fontSize(14)
            .fontColor('#b0b0b0')
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 8 })

          // 深色输入框
          TextInput({
            text: this.serverUrl,
            placeholder: '192.168.1.100:8096 或 https://myserver.com'
          })
            .width('100%')
            .height(48)
            .backgroundColor('#1e1e1e')
            .borderRadius(4)
            .fontSize(16)
            .fontColor('#ffffff')
            .placeholderColor('#888888')
            .placeholderFont({ size: 16 })
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              this.serverUrl = value;
            })

          // 错误提示
          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#ff4444')
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ top: 8 })
          }

          // 间距
          Blank().height(24)

          // "连接" 主按钮（青蓝色）
          Button(this.isConnecting ? '连接中...' : '连接')
            .width('100%')
            .height(48)
            .borderRadius(4)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#ffffff')
            .backgroundColor(this.isConnecting ? '#0085b3' : '#00a4dc')
            .enabled(!this.isConnecting && this.serverUrl.trim().length > 0)
            .onClick(() => {
              this.connectToServer();
            })

          // "取消" 次要按钮（暗色，有历史服务器时显示）
          if (this.recentServers.length > 0) {
            Blank().height(8)

            Button('取消')
              .width('100%')
              .height(48)
              .borderRadius(4)
              .fontSize(16)
              .fontColor('#ffffff')
              .backgroundColor('#2d2d2d')
              .onClick(() => {
                this.navPathStack.pop();
              })
          }

          // ===== 历史服务器区 =====
          if (this.recentServers.length > 0) {
            Column() {
              // "最近使用" 标题
              Text('最近使用')
                .fontSize(14)
                .fontColor('#b0b0b0')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ top: 32, bottom: 8 })

              // 服务器列表
              ForEach(this.recentServers, (server: string) => {
                this.RecentServerItem(server)
              })
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#0f0f0f')
      .alignItems(HorizontalAlign.Start)
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.navPathStack.pop();
      return true;
    })
  }
}

export default ConnectPage;
