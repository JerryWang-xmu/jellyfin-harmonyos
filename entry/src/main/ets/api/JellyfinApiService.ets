/**
 * JellyfinApiService - Jellyfin REST API 客户端
 * 使用 @ohos.net.http 实现完整的 Jellyfin API 调用
 *
 * Batch 2 网络层实现
 */

import http from '@ohos.net.http';
import { ApiClientConfig } from './ApiClientController';

export class JellyfinApiService {
  private config: ApiClientConfig;

  constructor(config: ApiClientConfig) {
    this.config = config;
  }

  /**
   * 构建 Authorization Header
   * 格式：MediaBrowser Client="{appName}", Device="{deviceName}", DeviceId="{deviceId}",
   *       Version="{appVersion}"[, Token="{token}"]
   */
  buildAuthHeader(withToken: boolean = true): string {
    let header = `MediaBrowser Client="${this.config.appName}", ` +
      `Device="${this.config.deviceName}", ` +
      `DeviceId="${this.config.deviceId}", ` +
      `Version="${this.config.appVersion}"`;
    if (withToken && this.config.accessToken) {
      header += `, Token="${this.config.accessToken}"`;
    }
    return header;
  }

  // ===== 通用 HTTP 请求方法 =====

  /**
   * GET 请求
   */
  private async get<T>(path: string, withAuth: boolean = true): Promise<T> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        `${this.config.baseUrl}${path}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json',
            'Authorization': this.buildAuthHeader(withAuth)
          },
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 10000,
          readTimeout: 30000
        }
      );
      if (response.responseCode >= 400) {
        throw new Error(`HTTP ${response.responseCode}: GET ${path}`);
      }
      return JSON.parse(response.result as string) as T;
    } catch (e) {
      throw new Error(JSON.stringify(e));
    } finally {
      httpRequest.destroy(); // 必须释放，防止内存泄漏
    }
  }

  /**
   * POST 请求
   */
  private async post<T>(path: string, body?: object, withAuth: boolean = true): Promise<T> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        `${this.config.baseUrl}${path}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': this.buildAuthHeader(withAuth)
          },
          extraData: body ? JSON.stringify(body) : '',
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 10000,
          readTimeout: 30000
        }
      );
      if (response.responseCode >= 400) {
        throw new Error(`HTTP ${response.responseCode}: POST ${path}`);
      }
      if (!response.result || response.result === '') { const emptyObj: Object = new Object(); return emptyObj as T; }
      return JSON.parse(response.result as string) as T;
    } catch (e) {
      throw new Error(JSON.stringify(e));
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * DELETE 请求
   */
  private async delete<T>(path: string): Promise<T> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        `${this.config.baseUrl}${path}`,
        {
          method: http.RequestMethod.DELETE,
          header: {
            'Content-Type': 'application/json',
            'Authorization': this.buildAuthHeader()
          },
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 10000,
          readTimeout: 30000
        }
      );
      if (response.responseCode >= 400) {
        throw new Error(`HTTP ${response.responseCode}: DELETE ${path}`);
      }
      if (!response.result || response.result === '') { const emptyObj: Object = new Object(); return emptyObj as T; }
      return JSON.parse(response.result as string) as T;
    } catch (e) {
      throw new Error(JSON.stringify(e));
    } finally {
      httpRequest.destroy();
    }
  }

  // ===== 服务器信息 =====

  /**
   * 获取服务器公开信息（无需认证）
   */
  async getPublicSystemInfo(): Promise<PublicSystemInfo> {
    return this.get<PublicSystemInfo>('/System/Info/Public', false);
  }

  // ===== 认证 =====

  /**
   * 用户名/密码登录
   */
  async authenticateByName(username: string, password: string): Promise<AuthenticationResult> {
    const body: AuthByNameBody = { Username: username, Pw: password };
    return this.post<AuthenticationResult>('/Users/AuthenticateByName', body, false);
  }

  /**
   * 发起 QuickConnect 请求
   */
  async quickConnectInitiate(): Promise<QuickConnectResult> {
    return this.post<QuickConnectResult>('/QuickConnect/Initiate', undefined, true);
  }

  /**
   * 查询 QuickConnect 状态（客户端轮询）
   */
  async quickConnectConnect(secret: string): Promise<QuickConnectResult> {
    return this.get<QuickConnectResult>(
      `/QuickConnect/Connect?secret=${encodeURIComponent(secret)}`,
      true
    );
  }

  /**
   * 使用 QuickConnect Secret 完成认证
   */
  async authenticateWithQuickConnect(secret: string): Promise<AuthenticationResult> {
    const body: QuickConnectAuthBody = { Secret: secret };
    return this.post<AuthenticationResult>('/Users/AuthenticateWithQuickConnect', body, false);
  }

  /**
   * 登出当前会话
   */
  async logout(): Promise<void> {
    await this.post<void>('/Sessions/Logout');
  }

  // ===== 用户 =====

  /**
   * 获取当前登录用户信息
   */
  async getCurrentUser(): Promise<UserDto> {
    return this.get<UserDto>('/Users/Me');
  }

  /**
   * 获取用户媒体库列表
   */
  async getUserViews(userId: string): Promise<ItemsResult<MediaItem>> {
    return this.get<ItemsResult<MediaItem>>(`/Users/${userId}/Views`);
  }

  /**
   * 获取媒体项列表
   */
  async getItems(userId: string, params: GetItemsParams): Promise<ItemsResult<MediaItem>> {
    const query = buildQueryString(params as ESObject);
    return this.get<ItemsResult<MediaItem>>(`/Users/${userId}/Items?${query}`);
  }

  /**
   * 获取单个媒体项
   */
  async getItem(userId: string, itemId: string): Promise<MediaItem> {
    return this.get<MediaItem>(`/Users/${userId}/Items/${itemId}`);
  }

  /**
   * 获取继续观看列表
   */
  async getResumeItems(userId: string, params?: object): Promise<ItemsResult<MediaItem>> {
    const query = params ? buildQueryString(params as ESObject) : '';
    return this.get<ItemsResult<MediaItem>>(
      `/Users/${userId}/Items/Resume${query ? '?' + query : ''}`
    );
  }

  /**
   * 获取 NextUp（下一集）列表
   */
  async getNextUp(userId: string, params?: object): Promise<ItemsResult<MediaItem>> {
    const query = params ? buildQueryString(params as ESObject) : '';
    return this.get<ItemsResult<MediaItem>>(
      `/Shows/NextUp?userId=${userId}${query ? '&' + query : ''}`
    );
  }

  // ===== 播放信息 =====

  /**
   * 获取播放信息（包含转码/直链决策）
   */
  async getPlaybackInfo(itemId: string, body: PlaybackInfoRequestBody): Promise<PlaybackInfoResponse> {
    return this.post<PlaybackInfoResponse>(`/Items/${itemId}/PlaybackInfo`, body);
  }

  /**
   * 上报播放开始
   */
  async reportPlaybackStart(info: PlaybackProgressReport): Promise<void> {
    await this.post<void>('/Sessions/Playing', info);
  }

  /**
   * 上报播放进度
   */
  async reportPlaybackProgress(info: PlaybackProgressReport): Promise<void> {
    await this.post<void>('/Sessions/Playing/Progress', info);
  }

  /**
   * 上报播放停止
   */
  async reportPlaybackStopped(info: PlaybackStopReport): Promise<void> {
    await this.post<void>('/Sessions/Playing/Stopped', info);
  }

  /**
   * 标记媒体项为已播放
   */
  async markItemPlayed(userId: string, itemId: string): Promise<UserItemData> {
    return this.post<UserItemData>(`/Users/${userId}/PlayedItems/${itemId}`);
  }

  /**
   * 停止活跃的转码任务
   */
  async stopActiveEncoding(deviceId: string, playSessionId: string): Promise<void> {
    await this.delete<void>(
      `/Videos/ActiveEncodings?deviceId=${encodeURIComponent(deviceId)}&playSessionId=${encodeURIComponent(playSessionId)}`
    );
  }

  // ===== 收藏 =====

  /**
   * 设置/取消收藏
   */
  async setFavorite(userId: string, itemId: string, favorite: boolean): Promise<UserItemData> {
    if (favorite) {
      return this.post<UserItemData>(`/Users/${userId}/FavoriteItems/${itemId}`);
    } else {
      return this.delete<UserItemData>(`/Users/${userId}/FavoriteItems/${itemId}`);
    }
  }

  // ===== 图片 URL（纯拼接，无 HTTP 请求）=====

  /**
   * 构建图片 URL
   * 格式：{baseUrl}/Items/{itemId}/Images/{imageType}?tag={tag}&maxWidth={w}&quality=90
   */
  buildImageUrl(
    itemId: string,
    imageType: 'Primary' | 'Thumb' | 'Backdrop',
    tag: string,
    maxWidth?: number
  ): string {
    let url = `${this.config.baseUrl}/Items/${itemId}/Images/${imageType}?tag=${encodeURIComponent(tag)}&quality=90`;
    if (maxWidth) {
      url += `&maxWidth=${maxWidth}`;
    }
    return url;
  }

  // ===== 媒体片段 =====

  /**
   * 获取媒体片段信息（片头/片尾等），失败时静默返回空数组
   */
  async getMediaSegments(itemId: string): Promise<MediaSegment[]> {
    try {
      const result = await this.get<MediaSegmentResult>(`/Shows/${itemId}/MediaSegments`);
      return result.Items ?? [];
    } catch {
      return [];
    }
  }
}

// ===== 辅助函数 =====

/**
 * 将参数对象序列化为 URL 查询字符串（过滤 undefined/null 值）
 */
function buildQueryString(params: ESObject): string {
  let result = '';
  const keys = Object.keys(params as object);
  for (let i = 0; i < keys.length; i++) {
    const k = keys[i];
    const v: ESObject = (params as ESObject)[k] as ESObject;
    if (v !== undefined && v !== null) {
      if (result.length > 0) {
        result += '&';
      }
      result += `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`;
    }
  }
  return result;
}

// ===== 请求体类型 =====

interface AuthByNameBody {
  Username: string;
  Pw: string;
}

interface QuickConnectAuthBody {
  Secret: string;
}

interface MediaSegmentResult {
  Items: MediaSegment[];
}

// ===== 类型定义 =====

export interface PublicSystemInfo {
  ServerName: string;
  Version: string;
  Id?: string;
}

export interface AuthenticationResult {
  User: UserDto;
  AccessToken: string;
  ServerId: string;
}

export interface UserDto {
  Id: string;
  Name: string;
  ServerId: string;
  HasPassword: boolean;
}

export interface QuickConnectResult {
  Secret: string;
  Code: string;
  Authenticated: boolean;
}

export interface ItemsResult<T> {
  Items: T[];
  TotalRecordCount: number;
  StartIndex: number;
}

export interface GetItemsParams {
  parentId?: string;
  includeItemTypes?: string;
  sortBy?: string;
  sortOrder?: 'Ascending' | 'Descending';
  startIndex?: number;
  limit?: number;
  recursive?: boolean;
  fields?: string;
}

export interface MediaItem {
  id: string;
  Id?: string;           // Jellyfin API 返回大写 Id
  name?: string;
  Name?: string;
  type?: string;
  Type?: string;
  seriesName?: string;
  SeriesName?: string;
  indexNumber?: number;
  IndexNumber?: number;
  parentIndexNumber?: number;
  ParentIndexNumber?: number;
  productionYear?: number;
  ProductionYear?: number;
  overview?: string;
  Overview?: string;
  officialRating?: string;
  OfficialRating?: string;
  communityRating?: number;
  CommunityRating?: number;
  criticRating?: number;
  CriticRating?: number;
  runTimeTicks?: number;
  RunTimeTicks?: number;
  imageTags?: Record<string, string>;
  ImageTags?: Record<string, string>;
  backdropImageTags?: string[];
  BackdropImageTags?: string[];
  mediaSources?: JellyfinMediaSourceInfo[];
  MediaSources?: JellyfinMediaSourceInfo[];
  userData?: UserItemData;
  UserData?: UserItemData;
}

export interface JellyfinMediaSourceInfo {
  Id?: string;
  Name?: string;
  RunTimeTicks?: number;
  PlayMethod?: string;
  PlaySessionId?: string;
  LiveStreamId?: string;
  MediaStreams?: MediaStreamInfo[];
  DefaultAudioStreamIndex?: number;
  DefaultSubtitleStreamIndex?: number;
  TranscodingUrl?: string;
  DirectStreamUrl?: string;
  SupportsTranscoding?: boolean;
  SupportsDirectPlay?: boolean;
  SupportsDirectStream?: boolean;
}

export interface MediaStreamInfo {
  Index: number;
  Type: string;
  Codec?: string;
  Language?: string;
  DisplayTitle?: string;
  IsDefault?: boolean;
  IsForced?: boolean;
  IsExternal?: boolean;
  DeliveryUrl?: string;
}

export interface UserItemData {
  IsFavorite?: boolean;
  PlaybackPositionTicks?: number;
  Played?: boolean;
  UnplayedItemCount?: number;
  PlayedPercentage?: number;
}

export interface PlaybackInfoRequestBody {
  UserId?: string;
  MediaSourceId?: string;
  DeviceProfile?: object;
  MaxStreamingBitrate?: number;
  StartTimeTicks?: number;
  AudioStreamIndex?: number;
  SubtitleStreamIndex?: number;
  AutoOpenLiveStream?: boolean;
}

export interface PlaybackInfoResponse {
  MediaSources: JellyfinMediaSourceInfo[];
  PlaySessionId?: string;
}

export interface PlaybackProgressReport {
  ItemId: string;
  PositionTicks: number;
  IsPaused: boolean;
  IsMuted: boolean;
  VolumeLevel: number;
  PlaySessionId?: string;
  LiveStreamId?: string;
  AudioStreamIndex?: number;
  SubtitleStreamIndex?: number;
  PlayMethod?: string;
}

export interface PlaybackStopReport {
  ItemId: string;
  PositionTicks: number;
  PlaySessionId?: string;
  Failed: boolean;
}

export interface MediaSegment {
  Id: string;
  ItemId: string;
  Type: string;
  StartTicks: number;
  EndTicks: number;
}
