import { AppLog } from '../common/utils/Logger';
import { App } from '../core/di/AppDependency';
import { Constants } from '../common/constants/Constants';

@Entry
@Component
struct SettingsPage {
  @State serverName: string = 'Not Connected';
  @State userName: string = 'Not logged in';
  @State themeMode: number = 0; // 0: System, 1: Light, 2: Dark
  @State playbackQuality: string = 'Auto';

  aboutToAppear() {
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    // Load current server info from App preferences
    if (App.isInitialized) {
      const hostname = App.currentServer?.hostname;
      if (hostname) {
        this.serverName = hostname;
      }

      // Load current user info
      const user = App.currentUser;
      if (user) {
        this.userName = user.userId;
      }
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('Settings')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')

      List() {
        // Server Section
        ListItemGroup({ header: this.SectionHeader('Server') }) {
          ListItem() {
            this.SettingItem('Server', this.serverName, () => {
              // Navigate to server settings
            })
          }

          ListItem() {
            this.SettingItem('User', this.userName, () => {
              // Navigate to user settings
            })
          }
        }

        // Playback Section
        ListItemGroup({ header: this.SectionHeader('Playback') }) {
          ListItem() {
            this.SettingItem('Default Quality', this.playbackQuality, () => {
              // Show quality selection dialog
            })
          }

          ListItem() {
            this.SettingItem('Auto-play next episode', 'On', () => {
              // Toggle auto-play
            })
          }
        }

        // Appearance Section
        ListItemGroup({ header: this.SectionHeader('Appearance') }) {
          ListItem() {
            this.SettingItem('Theme', this.getThemeName(), () => {
              // Show theme selection dialog
            })
          }
        }

        // About Section
        ListItemGroup({ header: this.SectionHeader('About') }) {
          ListItem() {
            this.SettingItem('Version', Constants.APP_INFO_VERSION, () => {})
          }

          ListItem() {
            this.SettingItem('Open Source Licenses', '', () => {
              // Show licenses
            })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#f5f5f5')

      // Logout Button
      Row() {
        Button('Sign Out')
          .width('85%')
          .height(50)
          .backgroundColor('#FF4444')
          .onClick(() => {
            this.signOut();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor('#666666')
      .padding({ left: 16, top: 16, bottom: 8 })
  }

  @Builder
  SettingItem(title: string, value: string, onClick: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#333333')

        if (value) {
          Text(value)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(20)
        .fontColor('#999999')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .onClick(onClick)
  }

  private getThemeName(): string {
    switch (this.themeMode) {
      case 1: return 'Light';
      case 2: return 'Dark';
      default: return 'System';
    }
  }

  private async signOut(): Promise<void> {
    try {
      // Clear user session
      if (App.isInitialized) {
        await App.clear();
      }

      AppLog.i('User signed out');
      // Navigate to connect page
    } catch (err) {
      AppLog.e('Sign out error: %{public}s', JSON.stringify(err));
    }
  }
}

export default SettingsPage;
