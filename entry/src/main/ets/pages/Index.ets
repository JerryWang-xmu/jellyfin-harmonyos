/**
 * Index Page
 * Splash/Loading screen that redirects to appropriate page
 */
import router from '@ohos.router';
import { Logger } from '../common/utils/Logger';
import { JellyfinDatabase } from '../data/database/JellyfinDatabase';
import { UserDao } from '../data/dao/UserDao';

@Entry
@Component
struct Index {
  @State loadingProgress: number = 0;

  aboutToAppear() {
    this.initializeApp();
  }

  private async initializeApp(): Promise<void> {
    // Simulate loading
    for (let i = 0; i <= 100; i += 10) {
      this.loadingProgress = i;
      await this.delay(100);
    }

    // Navigate to main page
    router.replaceUrl({
      url: 'pages/MainPage'
    });
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  build() {
    Column() {
      // Logo
      Column() {
        Text('Jellyfin')
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary'))

        Text('The Free Software Media System')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 8 })
      }
      .margin({ top: '30%' })

      Blank()

      // Loading Progress
      Column() {
        Progress({
          value: this.loadingProgress,
          total: 100,
          type: ProgressType.Linear
        })
          .width(200)
          .color($r('app.color.primary'))
          .margin({ bottom: 16 })

        Text('Loading...')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .margin({ bottom: '20%' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .justifyContent(FlexAlign.Center)
  }
}
