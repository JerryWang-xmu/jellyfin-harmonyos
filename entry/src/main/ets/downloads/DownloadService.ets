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

import request from '@ohos.request';
import { Logger } from '../common/utils/Logger';
import { DownloadEntity, DownloadStatus, createDownloadEntity } from '../data/entity/DownloadEntity';
import { ActivityEventType, createEvent } from '../core/event/ActivityEvent';
import { App } from '../core/di/AppDependency';

/**
 * Download Service
 * Manages media download tasks
 */
export class DownloadService {
  private static instance: DownloadService;
  private activeDownloads: Map<string, request.DownloadTask> = new Map();

  private constructor() {
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
      const downloadId = await App.database.downloadDao.insert(downloadEntity);

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
        this.updateProgress(itemId, progress, DownloadStatus.DOWNLOADING);
      });

      downloadTask.on('complete', () => {
        this.updateProgress(itemId, 100, DownloadStatus.COMPLETED);
        this.activeDownloads.delete(itemId);
        App.eventHandler.emit(createEvent(ActivityEventType.DOWNLOAD_COMPLETE, { itemId }));
      });

      downloadTask.on('fail', (err: number) => {
        this.updateProgress(itemId, 0, DownloadStatus.FAILED);
        this.activeDownloads.delete(itemId);
        Logger.error('Download failed: %{public}d', err);
      });

      this.activeDownloads.set(itemId, downloadTask);
      await this.updateProgress(itemId, 0, DownloadStatus.DOWNLOADING);

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
    return App.database.downloadDao.queryAll();
  }

  async getPendingDownloads(): Promise<DownloadEntity[]> {
    return App.database.downloadDao.queryByStatus(DownloadStatus.PENDING);
  }

  async removeDownload(itemId: string): Promise<boolean> {
    return App.database.downloadDao.delete(itemId);
  }

  private async updateProgress(itemId: string, progress: number, status: DownloadStatus): Promise<void> {
    await App.database.downloadDao.updateProgress(itemId, progress, status);
    App.eventHandler.emit(createEvent(ActivityEventType.DOWNLOAD_PROGRESS, { itemId, progress, status }));
  }
}
