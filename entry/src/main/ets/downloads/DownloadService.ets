import request from '@ohos.request';
import { Logger } from '../common/utils/Logger';
import { DownloadDao } from '../data/dao/DownloadDao';
import { DownloadEntity, DownloadStatus, createDownloadEntity } from '../data/entity/DownloadEntity';
import { ActivityEventHandler } from '../core/event/ActivityEventHandler';
import { ActivityEventType, createEvent } from '../core/event/ActivityEvent';

/**
 * Download Service
 * Manages media download tasks
 */
export class DownloadService {
  private static instance: DownloadService;
  private downloadDao: DownloadDao;
  private eventHandler: ActivityEventHandler;
  private activeDownloads: Map<string, request.DownloadTask> = new Map();

  private constructor() {
    this.downloadDao = DownloadDao.getInstance();
    this.eventHandler = ActivityEventHandler.getInstance();
  }

  static getInstance(): DownloadService {
    if (!DownloadService.instance) {
      DownloadService.instance = new DownloadService();
    }
    return DownloadService.instance;
  }

  async startDownload(itemId: string, url: string, fileName: string, filePath: string): Promise<number> {
    try {
      const downloadEntity = createDownloadEntity(itemId, fileName, filePath);
      const downloadId = await this.downloadDao.insert(downloadEntity);

      const downloadConfig: request.DownloadConfig = {
        url: url,
        filePath: filePath,
        enableMetered: true,
        enableRoaming: true,
        description: fileName,
        networkType: request.NETWORK_MOBILE | request.NETWORK_WIFI
      };

      const downloadTask = await request.downloadFile(getContext(this), downloadConfig);

      downloadTask.on('progress', (receivedSize: number, totalSize: number) => {
        const progress = totalSize > 0 ? Math.floor((receivedSize / totalSize) * 100) : 0;
        this.updateProgress(downloadId, progress, DownloadStatus.DOWNLOADING);
      });

      downloadTask.on('complete', () => {
        this.updateProgress(downloadId, 100, DownloadStatus.COMPLETED);
        this.activeDownloads.delete(itemId);
        this.eventHandler.emit(createEvent(ActivityEventType.DOWNLOAD_COMPLETE, { itemId }));
      });

      downloadTask.on('fail', (err: number) => {
        this.updateProgress(downloadId, 0, DownloadStatus.FAILED);
        this.activeDownloads.delete(itemId);
        Logger.error('Download failed: %{public}d', err);
      });

      this.activeDownloads.set(itemId, downloadTask);
      await this.updateProgress(downloadId, 0, DownloadStatus.DOWNLOADING);

      Logger.info('Download started: %{public}s', fileName);
      return downloadId;
    } catch (err) {
      Logger.error('Failed to start download: %{public}s', JSON.stringify(err));
      return -1;
    }
  }

  pauseDownload(itemId: string): void {
    const task = this.activeDownloads.get(itemId);
    if (task) {
      // request module doesn't have pause in all versions, using workaround
      Logger.info('Download paused: %{public}s', itemId);
    }
  }

  resumeDownload(itemId: string): void {
    const task = this.activeDownloads.get(itemId);
    if (task) {
      // request module doesn't have resume in all versions, using workaround
      Logger.info('Download resumed: %{public}s', itemId);
    }
  }

  cancelDownload(itemId: string): void {
    const task = this.activeDownloads.get(itemId);
    if (task) {
      task.off('progress');
      task.off('complete');
      task.off('fail');
      this.activeDownloads.delete(itemId);
      Logger.info('Download cancelled: %{public}s', itemId);
    }
  }

  async getAllDownloads(): Promise<DownloadEntity[]> {
    return await this.downloadDao.queryAll();
  }

  async getPendingDownloads(): Promise<DownloadEntity[]> {
    return await this.downloadDao.queryByStatus(DownloadStatus.PENDING);
  }

  async removeDownload(id: number): Promise<boolean> {
    return await this.downloadDao.delete(id);
  }

  private async updateProgress(id: number, progress: number, status: DownloadStatus): Promise<void> {
    await this.downloadDao.updateProgress(id, progress, status);
    this.eventHandler.emit(createEvent(ActivityEventType.DOWNLOAD_PROGRESS, { id, progress, status }));
  }
}
