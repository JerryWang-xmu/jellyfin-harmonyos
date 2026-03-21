import webview from '@ohos.web.webview';
import { Logger } from '../common/utils/Logger';
import { BridgeChannel } from '../bridge/BridgeChannel';

const TAG: string = 'WebViewPage';

@Entry
@Component
struct WebViewPage {
  controller: webview.WebviewController = new webview.WebviewController();
  @State serverUrl: string = '';
  @State isLoading: boolean = true;
  private bridgeChannel: BridgeChannel | null = null;

  aboutToAppear() {
    this.bridgeChannel = new BridgeChannel({ controller: this.controller });
  }

  build() {
    Column() {
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
      }

      Web({ src: this.serverUrl, controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .mixedMode(MixedMode.All)
        .cacheMode(CacheMode.Default)
        .onPageBegin((event) => {
          this.isLoading = true;
          Logger.i(TAG, 'WebView page begin: %{public}s', event?.url || '');
        })
        .onPageEnd((event) => {
          this.isLoading = false;
          Logger.i(TAG, 'WebView page end: %{public}s', event?.url || '');
          this.injectNativeBridge();
        })
        .onErrorReceive((event) => {
          Logger.e(TAG, 'WebView error: %{public}s', JSON.stringify(event));
        })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  private injectNativeBridge(): void {
    const bridgeScript = `
      window.JellyfinNative = {
        sendMessage: function(handler, data) {
          return window.JellyfinBridge.postMessage(JSON.stringify({ handler: handler, data: data }));
        },
        receiveMessage: function(event, data) {
          if (window.JellyfinEvents && window.JellyfinEvents[event]) {
            window.JellyfinEvents[event](data);
          }
        }
      };
    `;
    this.controller.runJavaScript(bridgeScript);
  }
}
