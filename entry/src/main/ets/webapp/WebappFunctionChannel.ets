import { BridgeChannel } from '../bridge/BridgeChannel';
import { Logger } from '../common/utils/Logger';
import { ActivityEventHandler } from '../core/event/ActivityEventHandler';
import { ActivityEventType, createEvent } from '../core/event/ActivityEvent';

/**
 * Webapp Function Channel
 * Provides specific Jellyfin web app integration functions
 */
export class WebappFunctionChannel {
  private static instance: WebappFunctionChannel;
  private bridgeChannel: BridgeChannel;

  private constructor() {
    this.bridgeChannel = BridgeChannel.getInstance();
    this.setupEventListeners();
  }

  static getInstance(): WebappFunctionChannel {
    if (!WebappFunctionChannel.instance) {
      WebappFunctionChannel.instance = new WebappFunctionChannel();
    }
    return WebappFunctionChannel.instance;
  }

  private setupEventListeners(): void {
    const eventHandler = ActivityEventHandler.getInstance();

    // Listen for playback events and forward to webapp
    eventHandler.subscribe(ActivityEventType.PLAYBACK_START, (event) => {
      this.notifyWebapp('playbackStart', event.data);
    });

    eventHandler.subscribe(ActivityEventType.PLAYBACK_STOP, (event) => {
      this.notifyWebapp('playbackStop', event.data);
    });

    eventHandler.subscribe(ActivityEventType.PLAYBACK_PROGRESS, (event) => {
      this.notifyWebapp('playbackProgress', event.data);
    });
  }

  /**
   * Notify webapp about user login
   */
  notifyUserLogin(userId: string, userName: string): void {
    this.bridgeChannel.sendMessageToWeb('userLogin', {
      userId: userId,
      userName: userName
    });
    Logger.info('Notified webapp of user login: %{public}s', userName);
  }

  /**
   * Notify webapp about server connection
   */
  notifyServerConnected(serverUrl: string, serverName: string): void {
    this.bridgeChannel.sendMessageToWeb('serverConnected', {
      serverUrl: serverUrl,
      serverName: serverName
    });
    Logger.info('Notified webapp of server connection: %{public}s', serverName);
  }

  /**
   * Send download progress to webapp
   */
  notifyDownloadProgress(itemId: string, progress: number): void {
    this.bridgeChannel.sendMessageToWeb('downloadProgress', {
      itemId: itemId,
      progress: progress
    });
  }

  /**
   * Generic notification to webapp
   */
  notifyWebapp(eventName: string, data?: Record<string, Object>): void {
    this.bridgeChannel.sendMessageToWeb(eventName, data || {});
  }

  /**
   * Request webapp to navigate to specific page
   */
  navigateTo(route: string): void {
    this.bridgeChannel.sendMessageToWeb('navigate', { route: route });
    Logger.debug('Requested navigation to: %{public}s', route);
  }

  /**
   * Update playback state in webapp
   */
  reportPlaybackState(state: Record<string, Object>): void {
    this.bridgeChannel.sendMessageToWeb('playbackState', state);
  }
}
