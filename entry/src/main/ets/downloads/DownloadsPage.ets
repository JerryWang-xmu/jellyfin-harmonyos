/**
 * Jellyfin HarmonyOS - 下载页面
 * 展示本地下载列表，支持加载/空/列表三种状态
 */

import { App } from '../core/di/AppDependency';
import { DownloadEntity, DownloadStatus } from '../data/entity/DownloadEntity';
import { AppLog } from '../common/utils/Logger';

@Component
export struct DownloadsPage {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @State downloads: DownloadEntity[] = [];
  @State isLoading: boolean = true;
  @State isEmpty: boolean = false;

  aboutToAppear() {
    AppLog.i('DownloadsPage.aboutToAppear');
    this.loadDownloads();
  }

  private async loadDownloads(): Promise<void> {
    try {
      this.downloads = await App.database.downloadDao.queryAll();
      this.isEmpty = this.downloads.length === 0;
      AppLog.i('DownloadsPage: loaded %{public}s downloads', String(this.downloads.length));
    } catch (err) {
      AppLog.e('DownloadsPage: loadDownloads error: %{public}s', JSON.stringify(err));
      this.isEmpty = true;
    } finally {
      this.isLoading = false;
    }
  }

  @Builder
  DownloadItem(item: DownloadEntity) {
    Row({ space: 12 }) {
      // 缩略图占位
      Column()
        .width(80)
        .height(45)
        .backgroundColor('#202020')
        .borderRadius(4)

      Column({ space: 4 }) {
        Text(item.fileName || item.itemId)
          .fontSize(14)
          .fontColor('#ffffff')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(item.status)
          .fontSize(12)
          .fontColor('#b0b0b0')

        if (item.status === DownloadStatus.DOWNLOADING) {
          Progress({ value: item.progress, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(3)
            .color('#00a4dc')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
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
            .onClick(() => {
              this.navPathStack.pop();
            })

          Text('下载')
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

        // 内容区
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color('#00a4dc')
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        } else if (this.isEmpty) {
          Column({ space: 16 }) {
            Text('暂无下载')
              .fontSize(16)
              .fontColor('#b0b0b0')
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        } else {
          List() {
            ForEach(this.downloads, (item: DownloadEntity) => {
              ListItem() {
                this.DownloadItem(item)
              }
            }, (item: DownloadEntity) => item.itemId)
          }
          .layoutWeight(1)
          .width('100%')
          .divider({
            strokeWidth: 1,
            color: '#2a2a2a',
            startMargin: 16,
            endMargin: 16
          })
        }
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
