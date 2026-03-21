/**
 * 服务器连接页面
 * 迁移自 jellyfin-android/connect/ConnectFragment.kt
 */

import { AppLog } from '../common/utils/Logger';
import { ServerEntityHelper } from '../data/entity/ServerEntity';
import { Constants } from '../common/constants/Constants';
import { ActivityEventType, ActivityEvents } from '../core/event/ActivityEvent';
import { ActivityEventHandler } from '../core/event/ActivityEventHandler';
import { App } from '../core/di/AppDependency';

@Entry
@Component
struct ConnectPage {
  @State serverUrl: string = '';
  @State isConnecting: boolean = false;
  @State errorMessage: string = '';
  @State recentServers: string[] = [];

  aboutToAppear() {
    this.loadRecentServers();
  }

  private async loadRecentServers(): Promise<void> {
    // TODO: Load from database when properly initialized
    this.recentServers = [];
  }

  build() {
    Column() {
      // Header
      Column() {
        Text('Jellyfin')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00a4dc')
          .margin({ bottom: 8 })

        Text('Connect to your media server')
          .fontSize(16)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ top: 60, bottom: 40 })

      // Server URL Input
      Column() {
        TextInput({ placeholder: 'Server URL (e.g., http://192.168.1.100:8096)' })
          .width('100%')
          .height(50)
          .onChange((value: string) => {
            this.serverUrl = value;
          })
          .margin({ bottom: 16 })

        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(Color.Red)
            .margin({ bottom: 16 })
        }

        Button(this.isConnecting ? 'Connecting...' : 'Connect')
          .width('100%')
          .height(50)
          .enabled(!this.isConnecting && this.serverUrl.length > 0)
          .onClick(() => {
            this.connectToServer();
          })
      }
      .width('85%')
      .padding(16)
      .backgroundColor('#ffffff')
      .borderRadius(12)

      // Recent Servers
      if (this.recentServers.length > 0) {
        Column() {
          Text('Recent Servers')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 32, bottom: 16 })

          ForEach(this.recentServers, (server: string) => {
            Row() {
              Text(server)
                .fontSize(14)
                .fontColor('#333333')
            }
            .width('85%')
            .height(50)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })
            .onClick(() => {
              this.serverUrl = server;
              this.connectToServer();
            })
          })
        }
        .width('100%')
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  private async connectToServer(): Promise<void> {
    this.isConnecting = true;
    this.errorMessage = '';

    try {
      let url = this.serverUrl.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://' + url;
      }

      // Try to connect to server
      const response = await this.testConnection(url);

      if (response) {
        // Emit connection event
        App.eventHandler.emit(
          ActivityEvents.openUrl(url)
        );

        AppLog.i('Connected to server: %{public}s', url);
        // Navigate to main page or login page
      } else {
        this.errorMessage = 'Unable to connect to server';
      }
    } catch (err) {
      this.errorMessage = 'Connection failed. Please check the URL.';
      AppLog.e('Connection error: %{public}s', JSON.stringify(err));
    } finally {
      this.isConnecting = false;
    }
  }

  private async testConnection(url: string): Promise<ServerInfo | null> {
    try {
      // This would normally use http module to make request
      // For now, return a placeholder
      AppLog.i('Testing connection to: %{public}s', url);
      const result: ServerInfo = {
        ServerName: 'Jellyfin Server',
        Version: '10.8.0'
      };
      return result;
    } catch (err) {
      return null;
    }
  }
}

interface ServerInfo {
  ServerName: string;
  Version: string;
}

export default ConnectPage;
