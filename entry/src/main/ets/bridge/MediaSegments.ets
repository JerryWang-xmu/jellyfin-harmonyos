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
 * Jellyfin HarmonyOS - MediaSegments 桥接接口
 * 媒体段处理桥接，支持跳过片头片尾等功能
 * 迁移自 jellyfin-android/bridge/MediaSegments.kt
 */

import { Logger } from '../common/utils/Logger';

/**
 * 媒体段类型
 */
export enum MediaSegmentType {
  INTRO = 'Intro',
  OUTRO = 'Outro',
  PREVIEW = 'Preview',
  RECAP = 'Recap',
  COMMERCIAL = 'Commercial',
  UNKNOWN = 'Unknown'
}

/**
 * 媒体段动作
 */
export enum MediaSegmentAction {
  NONE = 'none',
  ASK_TO_SKIP = 'ask_to_skip',
  SKIP = 'skip'
}

/**
 * 媒体段信息
 */
export interface MediaSegment {
  id: string;
  itemId: string;
  type: MediaSegmentType;
  startTicks: number;
  endTicks: number;
}

/**
 * 支持的媒体段类型
 */
export const SUPPORTED_SEGMENT_TYPES: MediaSegmentType[] = [
  MediaSegmentType.INTRO,
  MediaSegmentType.OUTRO,
  MediaSegmentType.PREVIEW,
  MediaSegmentType.RECAP,
  MediaSegmentType.COMMERCIAL
];

/**
 * 媒体段仓储接口
 */
export interface MediaSegmentRepository {
  setDefaultSegmentTypeAction(type: MediaSegmentType, action: MediaSegmentAction): void;
  getDefaultSegmentTypeAction(type: MediaSegmentType): MediaSegmentAction;
  getSegments(itemId: string): Promise<MediaSegment[]>;
}

/**
 * 默认媒体段仓储实现
 */
export class DefaultMediaSegmentRepository implements MediaSegmentRepository {
  private static readonly TAG: string = 'MediaSegmentRepository';

  private segmentTypeActions: Map<MediaSegmentType, MediaSegmentAction> = new Map();

  constructor() {
    // 默认配置
    this.segmentTypeActions.set(MediaSegmentType.INTRO, MediaSegmentAction.ASK_TO_SKIP);
    this.segmentTypeActions.set(MediaSegmentType.OUTRO, MediaSegmentAction.ASK_TO_SKIP);
    this.segmentTypeActions.set(MediaSegmentType.PREVIEW, MediaSegmentAction.NONE);
    this.segmentTypeActions.set(MediaSegmentType.RECAP, MediaSegmentAction.NONE);
    this.segmentTypeActions.set(MediaSegmentType.COMMERCIAL, MediaSegmentAction.SKIP);
  }

  setDefaultSegmentTypeAction(type: MediaSegmentType, action: MediaSegmentAction): void {
    this.segmentTypeActions.set(type, action);
    Logger.d(DefaultMediaSegmentRepository.TAG,
      'Set segment type action: type=%{public}s, action=%{public}s', type, action);
  }

  getDefaultSegmentTypeAction(type: MediaSegmentType): MediaSegmentAction {
    return this.segmentTypeActions.get(type) ?? MediaSegmentAction.NONE;
  }

  async getSegments(itemId: string): Promise<MediaSegment[]> {
    // 实际实现应该从服务器获取
    Logger.d(DefaultMediaSegmentRepository.TAG, 'Get segments for item: %{public}s', itemId);
    return [];
  }
}

/**
 * MediaSegments 桥接类
 * 提供给 JavaScript 调用的媒体段接口
 */
export class MediaSegments {
  private static readonly TAG: string = 'MediaSegments';

  private mediaSegmentRepository: MediaSegmentRepository;

  constructor(mediaSegmentRepository?: MediaSegmentRepository) {
    this.mediaSegmentRepository = mediaSegmentRepository ?? new DefaultMediaSegmentRepository();
    Logger.i(MediaSegments.TAG, 'MediaSegments created');
  }

  // ============ JavaScript 可调用方法 ============

  /**
   * 设置媒体段类型的默认动作
   * @param typeString 媒体段类型字符串
   * @param actionString 动作字符串
   */
  setSegmentTypeAction(typeString: string, actionString: string): void {
    Logger.d(MediaSegments.TAG, 'setSegmentTypeAction: type=%{public}s, action=%{public}s',
      typeString, actionString);

    try {
      const type = this.parseSegmentType(typeString);
      const action = this.parseSegmentAction(actionString);

      if (type && action !== null) {
        this.mediaSegmentRepository.setDefaultSegmentTypeAction(type, action);
      } else {
        Logger.e(MediaSegments.TAG, 'Invalid type or action');
      }
    } catch (error) {
      Logger.e(MediaSegments.TAG, 'setSegmentTypeAction error: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 获取支持的媒体段类型
   * @returns JSON 格式的类型数组
   */
  getSupportedSegmentTypes(): string {
    Logger.d(MediaSegments.TAG, 'getSupportedSegmentTypes called');
    return JSON.stringify(SUPPORTED_SEGMENT_TYPES);
  }

  // ============ 辅助方法 ============

  /**
   * 解析媒体段类型
   */
  private parseSegmentType(typeString: string): MediaSegmentType | null {
    const normalizedType = typeString.toLowerCase();

    switch (normalizedType) {
      case 'intro':
        return MediaSegmentType.INTRO;
      case 'outro':
        return MediaSegmentType.OUTRO;
      case 'preview':
        return MediaSegmentType.PREVIEW;
      case 'recap':
        return MediaSegmentType.RECAP;
      case 'commercial':
        return MediaSegmentType.COMMERCIAL;
      default:
        Logger.w(MediaSegments.TAG, 'Unknown segment type: %{public}s', typeString);
        return null;
    }
  }

  /**
   * 解析媒体段动作
   */
  private parseSegmentAction(actionString: string): MediaSegmentAction | null {
    const normalizedAction = actionString.toLowerCase();

    switch (normalizedAction) {
      case 'none':
        return MediaSegmentAction.NONE;
      case 'ask_to_skip':
        return MediaSegmentAction.ASK_TO_SKIP;
      case 'skip':
        return MediaSegmentAction.SKIP;
      default:
        Logger.w(MediaSegments.TAG, 'Unknown segment action: %{public}s', actionString);
        return null;
    }
  }

  /**
   * 获取媒体段动作
   */
  getSegmentTypeAction(type: MediaSegmentType): MediaSegmentAction {
    return this.mediaSegmentRepository.getDefaultSegmentTypeAction(type);
  }

  /**
   * 获取媒体段
   */
  async getSegments(itemId: string): Promise<MediaSegment[]> {
    return this.mediaSegmentRepository.getSegments(itemId);
  }
}

/**
 * MediaSegments 代理对象
 */
export interface MediaSegmentsProxy {
  setSegmentTypeAction: (typeString: string, actionString: string) => void;
  getSupportedSegmentTypes: () => string;
}

/**
 * 创建 MediaSegments 代理
 */
export function createMediaSegmentsProxy(mediaSegments: MediaSegments): MediaSegmentsProxy {
  return {
    setSegmentTypeAction: (typeString: string, actionString: string): void =>
      mediaSegments.setSegmentTypeAction(typeString, actionString),
    getSupportedSegmentTypes: (): string =>
      mediaSegments.getSupportedSegmentTypes()
  };
}
