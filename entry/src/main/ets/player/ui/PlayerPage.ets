import { AVPlayerAdapter } from '../adapter/AVPlayerAdapter';
import { IPlayerAdapter, PlayerState, PlayerEventListener } from '../adapter/IPlayerAdapter';
import { Logger } from '../../common/utils/Logger';

const TAG: string = 'PlayerPage';

class PlayerPageListener extends PlayerEventListener {
  private stateCallback: (state: PlayerState) => void;
  private positionCallback: (pos: number) => void;
  private durationCallback: (dur: number) => void;
  private errorCallback: (error: Error) => void;

  constructor(
    onState: (state: PlayerState) => void,
    onPosition: (pos: number) => void,
    onDuration: (dur: number) => void,
    onError: (error: Error) => void
  ) {
    super();
    this.stateCallback = onState;
    this.positionCallback = onPosition;
    this.durationCallback = onDuration;
    this.errorCallback = onError;
  }

  onStateChanged(state: PlayerState): void {
    this.stateCallback(state);
  }

  onPositionChanged(pos: number): void {
    this.positionCallback(pos);
  }

  onDurationChanged(dur: number): void {
    this.durationCallback(dur);
  }

  onError(error: Error): void {
    this.errorCallback(error);
  }
}

@Entry
@Component
struct PlayerPage {
  @State isPlaying: boolean = false;
  @State currentPosition: number = 0;
  @State duration: number = 0;
  @State mediaTitle: string = 'Media Title';
  private player: IPlayerAdapter | null = null;

  aboutToAppear() {
    this.initPlayer();
  }

  aboutToDisappear() {
    this.player?.stop();
  }

  private initPlayer(): void {
    this.player = new AVPlayerAdapter();

    const listener = new PlayerPageListener(
      (state: PlayerState): void => {
        this.isPlaying = (state === PlayerState.PLAYING);
      },
      (pos: number): void => {
        this.currentPosition = pos;
      },
      (dur: number): void => {
        this.duration = dur;
      },
      (error: Error): void => {
        Logger.e(TAG, 'Player error: %{public}s', error.message);
      }
    );

    this.player.setListener(listener);
  }

  build() {
    Column() {
      // Video Display Area
      Column() {
        Text('Video Player')
          .fontSize(24)
          .fontColor('#333333')
      }
      .width('100%')
      .height('60%')
      .backgroundColor('#f5f5f5')
      .justifyContent(FlexAlign.Center)

      // Media Info
      Column() {
        Text(this.mediaTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text(this.formatTime(this.currentPosition) + ' / ' + this.formatTime(this.duration))
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 8 })
      }
      .padding(16)

      // Controls
      Row() {
        Button('Previous')
          .fontSize(14)
          .onClick(() => {
            // TODO: Previous track
          })

        Button(this.isPlaying ? 'Pause' : 'Play')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16, right: 16 })
          .onClick(() => {
            if (this.isPlaying) {
              this.player?.pause();
            } else {
              this.player?.play();
            }
          })

        Button('Next')
          .fontSize(14)
          .onClick(() => {
            // TODO: Next track
          })
      }
      .padding(16)

      // Progress Slider
      Slider({
        value: this.currentPosition,
        min: 0,
        max: this.duration > 0 ? this.duration : 100
      })
        .width('90%')
        .onChange((value: number) => {
          this.player?.seekTo(value);
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  private formatTime(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const secs = seconds % 60;
    const mins = minutes % 60;

    if (hours > 0) {
      return hours.toString().padStart(2, '0') + ':' +
             mins.toString().padStart(2, '0') + ':' +
             secs.toString().padStart(2, '0');
    } else {
      return mins.toString().padStart(2, '0') + ':' +
             secs.toString().padStart(2, '0');
    }
  }
}

export default PlayerPage;
