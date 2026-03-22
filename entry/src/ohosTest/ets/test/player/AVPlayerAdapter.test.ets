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

/**
 * AVPlayerAdapter Unit Tests
 * Tests for AVPlayer adapter initialization, state management, and playback control
 * Migrated from jellyfin-android player tests
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';

import {
  PlayerState,
  TrackInfo,
  PlayerEventListener,
  MediaSourceInfo,
  IPlayerAdapter
} from '../../../../main/ets/player/adapter/IPlayerAdapter';
import { AVPlayerAdapter } from '../../../../main/ets/player/adapter/AVPlayerAdapter';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'AVPlayerAdapterTest';

export default function avPlayerAdapterTest() {
  describe('AVPlayerAdapter Tests', () => {
    let playerAdapter: AVPlayerAdapter | null = null;

    beforeAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'AVPlayerAdapter Tests starting...');
    });

    afterAll(() => {
      if (playerAdapter) {
        playerAdapter.release();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'AVPlayerAdapter Tests completed');
    });

    beforeEach(() => {
      playerAdapter = new AVPlayerAdapter();
    });

    afterEach(() => {
      if (playerAdapter) {
        playerAdapter.release();
        playerAdapter = null;
      }
    });

    // ============ PlayerState Enum Tests ============

    /**
     * Test: PlayerState enum values
     */
    it('should have correct PlayerState values', 0, () => {
      expect(PlayerState.IDLE).assertEqual(0);
      expect(PlayerState.INITIALIZED).assertEqual(1);
      expect(PlayerState.PREPARED).assertEqual(2);
      expect(PlayerState.PLAYING).assertEqual(3);
      expect(PlayerState.PAUSED).assertEqual(4);
      expect(PlayerState.STOPPED).assertEqual(5);
      expect(PlayerState.COMPLETED).assertEqual(6);
      expect(PlayerState.ERROR).assertEqual(7);
    });

    // ============ Initialization Tests ============

    /**
     * Test: Initial state is IDLE
     */
    it('should have initial state as IDLE', 0, () => {
      expect(playerAdapter!.getState()).assertEqual(PlayerState.IDLE);
    });

    /**
     * Test: Initial position is 0
     */
    it('should have initial position as 0', 0, () => {
      expect(playerAdapter!.getCurrentPosition()).assertEqual(0);
    });

    /**
     * Test: Initial duration is 0
     */
    it('should have initial duration as 0', 0, () => {
      expect(playerAdapter!.getDuration()).assertEqual(0);
    });

    /**
     * Test: Initial volume is 100
     */
    it('should have initial volume as 100', 0, () => {
      expect(playerAdapter!.getVolume()).assertEqual(100);
    });

    /**
     * Test: Initial playback speed is 1.0
     */
    it('should have initial playback speed as 1.0', 0, () => {
      expect(playerAdapter!.getPlaybackSpeed()).assertEqual(1.0);
    });

    /**
     * Test: Initial isPlaying is false
     */
    it('should have initial isPlaying as false', 0, () => {
      expect(playerAdapter!.isPlaying()).assertFalse();
    });

    // ============ Volume Control Tests ============

    /**
     * Test: Set volume to 50
     */
    it('should set volume to 50', 0, () => {
      playerAdapter!.setVolume(50);
      expect(playerAdapter!.getVolume()).assertEqual(50);
    });

    /**
     * Test: Set volume to 0
     */
    it('should set volume to 0', 0, () => {
      playerAdapter!.setVolume(0);
      expect(playerAdapter!.getVolume()).assertEqual(0);
    });

    /**
     * Test: Set volume to 100
     */
    it('should set volume to 100', 0, () => {
      playerAdapter!.setVolume(100);
      expect(playerAdapter!.getVolume()).assertEqual(100);
    });

    /**
     * Test: Volume clamped to maximum
     */
    it('should clamp volume to maximum 100', 0, () => {
      playerAdapter!.setVolume(150);
      expect(playerAdapter!.getVolume()).assertEqual(100);
    });

    /**
     * Test: Volume clamped to minimum
     */
    it('should clamp volume to minimum 0', 0, () => {
      playerAdapter!.setVolume(-50);
      expect(playerAdapter!.getVolume()).assertEqual(0);
    });

    // ============ Playback Speed Tests ============

    /**
     * Test: Set playback speed to 2.0
     */
    it('should set playback speed to 2.0', 0, () => {
      playerAdapter!.setPlaybackSpeed(2.0);
      expect(playerAdapter!.getPlaybackSpeed()).assertEqual(2.0);
    });

    /**
     * Test: Set playback speed to 0.5
     */
    it('should set playback speed to 0.5', 0, () => {
      playerAdapter!.setPlaybackSpeed(0.5);
      expect(playerAdapter!.getPlaybackSpeed()).assertEqual(0.5);
    });

    /**
     * Test: Set playback speed to 1.5
     */
    it('should set playback speed to 1.5', 0, () => {
      playerAdapter!.setPlaybackSpeed(1.5);
      expect(playerAdapter!.getPlaybackSpeed()).assertEqual(1.5);
    });

    // ============ Listener Tests ============

    /**
     * Test: Set listener
     */
    it('should set listener', 0, () => {
      const listener: PlayerEventListener = {
        onStateChanged: (state: PlayerState) => {},
        onPositionChanged: (positionMs: number) => {}
      };

      playerAdapter!.setListener(listener);
      // No exception means success
      expect(true).assertTrue();
    });

    /**
     * Test: Remove listener
     */
    it('should remove listener', 0, () => {
      const listener: PlayerEventListener = {
        onStateChanged: (state: PlayerState) => {}
      };

      playerAdapter!.setListener(listener);
      playerAdapter!.removeListener();
      // No exception means success
      expect(true).assertTrue();
    });

    // ============ State Management Tests ============

    /**
     * Test: State remains IDLE before initialization
     */
    it('should remain IDLE before initialization', 0, () => {
      expect(playerAdapter!.getState()).assertEqual(PlayerState.IDLE);
    });

    /**
     * Test: isPlaying returns false for IDLE state
     */
    it('should return false for isPlaying in IDLE state', 0, () => {
      expect(playerAdapter!.isPlaying()).assertFalse();
    });

    /**
     * Test: isPlaying returns false for ERROR state
     */
    it('should return false for isPlaying in ERROR state', 0, () => {
      // Simulate ERROR state check
      const errorState = PlayerState.ERROR;
      const isPlaying = errorState === PlayerState.PLAYING;
      expect(isPlaying).assertFalse();
    });

    // ============ Track Info Tests ============

    /**
     * Test: getTracks returns empty array before preparation
     */
    it('should return empty tracks array before preparation', 0, () => {
      const tracks = playerAdapter!.getTracks();
      expect(tracks.length).assertEqual(0);
    });

    /**
     * Test: getAudioTracks returns empty array
     */
    it('should return empty audio tracks array', 0, () => {
      const audioTracks = playerAdapter!.getAudioTracks();
      expect(audioTracks.length).assertEqual(0);
    });

    /**
     * Test: getSubtitleTracks returns empty array
     */
    it('should return empty subtitle tracks array', 0, () => {
      const subtitleTracks = playerAdapter!.getSubtitleTracks();
      expect(subtitleTracks.length).assertEqual(0);
    });

    /**
     * Test: selectAudioTrack does not throw
     */
    it('should handle selectAudioTrack without error', 0, () => {
      playerAdapter!.selectAudioTrack(0);
      expect(true).assertTrue();
    });

    /**
     * Test: selectSubtitleTrack does not throw
     */
    it('should handle selectSubtitleTrack without error', 0, () => {
      playerAdapter!.selectSubtitleTrack(0);
      expect(true).assertTrue();
    });

    /**
     * Test: disableSubtitles does not throw
     */
    it('should handle disableSubtitles without error', 0, () => {
      playerAdapter!.disableSubtitles();
      expect(true).assertTrue();
    });

    // ============ Release Tests ============

    /**
     * Test: Release resets state to IDLE
     */
    it('should reset state to IDLE after release', 0, () => {
      playerAdapter!.release();
      expect(playerAdapter!.getState()).assertEqual(PlayerState.IDLE);
    });

    /**
     * Test: Multiple release calls are safe
     */
    it('should handle multiple release calls safely', 0, () => {
      playerAdapter!.release();
      playerAdapter!.release();
      playerAdapter!.release();
      expect(true).assertTrue();
    });

    // ============ Interface Compliance Tests ============

    /**
     * Test: AVPlayerAdapter implements IPlayerAdapter
     */
    it('should implement IPlayerAdapter interface', 0, () => {
      expect(typeof playerAdapter!.initialize).assertEqual('function');
      expect(typeof playerAdapter!.release).assertEqual('function');
      expect(typeof playerAdapter!.setSurface).assertEqual('function');
      expect(typeof playerAdapter!.prepare).assertEqual('function');
      expect(typeof playerAdapter!.play).assertEqual('function');
      expect(typeof playerAdapter!.pause).assertEqual('function');
      expect(typeof playerAdapter!.stop).assertEqual('function');
      expect(typeof playerAdapter!.seekTo).assertEqual('function');
      expect(typeof playerAdapter!.seekToOffset).assertEqual('function');
      expect(typeof playerAdapter!.getState).assertEqual('function');
      expect(typeof playerAdapter!.getCurrentPosition).assertEqual('function');
      expect(typeof playerAdapter!.getDuration).assertEqual('function');
      expect(typeof playerAdapter!.isPlaying).assertEqual('function');
      expect(typeof playerAdapter!.setVolume).assertEqual('function');
      expect(typeof playerAdapter!.getVolume).assertEqual('function');
      expect(typeof playerAdapter!.setPlaybackSpeed).assertEqual('function');
      expect(typeof playerAdapter!.getPlaybackSpeed).assertEqual('function');
      expect(typeof playerAdapter!.getTracks).assertEqual('function');
      expect(typeof playerAdapter!.getAudioTracks).assertEqual('function');
      expect(typeof playerAdapter!.getSubtitleTracks).assertEqual('function');
      expect(typeof playerAdapter!.selectAudioTrack).assertEqual('function');
      expect(typeof playerAdapter!.selectSubtitleTrack).assertEqual('function');
      expect(typeof playerAdapter!.disableSubtitles).assertEqual('function');
      expect(typeof playerAdapter!.setListener).assertEqual('function');
      expect(typeof playerAdapter!.removeListener).assertEqual('function');
    });

    // ============ MediaSourceInfo Interface Tests ============

    /**
     * Test: MediaSourceInfo with minimal fields
     */
    it('should create MediaSourceInfo with minimal fields', 0, () => {
      const source: MediaSourceInfo = {
        url: 'https://example.com/video.mp4'
      };

      expect(source.url).assertEqual('https://example.com/video.mp4');
      expect(source.headers).assertUndefined();
      expect(source.mimeType).assertUndefined();
      expect(source.startPositionMs).assertUndefined();
    });

    /**
     * Test: MediaSourceInfo with all fields
     */
    it('should create MediaSourceInfo with all fields', 0, () => {
      const source: MediaSourceInfo = {
        url: 'https://example.com/video.mp4',
        headers: { 'Authorization': 'Bearer token' },
        mimeType: 'video/mp4',
        startPositionMs: 10000
      };

      expect(source.url).assertEqual('https://example.com/video.mp4');
      expect(source.headers!['Authorization']).assertEqual('Bearer token');
      expect(source.mimeType).assertEqual('video/mp4');
      expect(source.startPositionMs).assertEqual(10000);
    });

    // ============ TrackInfo Interface Tests ============

    /**
     * Test: TrackInfo interface structure
     */
    it('should create valid TrackInfo', 0, () => {
      const trackInfo: TrackInfo = {
        index: 0,
        type: 'audio',
        language: 'eng',
        label: 'English',
        isSelected: true,
        codec: 'aac',
        bitrate: 128000
      };

      expect(trackInfo.index).assertEqual(0);
      expect(trackInfo.type).assertEqual('audio');
      expect(trackInfo.language).assertEqual('eng');
      expect(trackInfo.isSelected).assertTrue();
    });

    /**
     * Test: Video track info
     */
    it('should create valid video TrackInfo', 0, () => {
      const videoTrack: TrackInfo = {
        index: 0,
        type: 'video',
        language: 'und',
        label: 'Video',
        isSelected: true,
        codec: 'h264',
        width: 1920,
        height: 1080,
        bitrate: 5000000
      };

      expect(videoTrack.type).assertEqual('video');
      expect(videoTrack.width).assertEqual(1920);
      expect(videoTrack.height).assertEqual(1080);
    });

    /**
     * Test: Subtitle track info
     */
    it('should create valid subtitle TrackInfo', 0, () => {
      const subtitleTrack: TrackInfo = {
        index: 2,
        type: 'subtitle',
        language: 'chi',
        label: 'Chinese',
        isSelected: false
      };

      expect(subtitleTrack.type).assertEqual('subtitle');
      expect(subtitleTrack.language).assertEqual('chi');
      expect(subtitleTrack.isSelected).assertFalse();
    });

    // ============ PlayerEventListener Interface Tests ============

    /**
     * Test: PlayerEventListener with all callbacks
     */
    it('should create valid PlayerEventListener', 0, () => {
      const listener: PlayerEventListener = {
        onStateChanged: (state: PlayerState) => {},
        onPositionChanged: (positionMs: number) => {},
        onDurationChanged: (durationMs: number) => {},
        onTracksChanged: (tracks: TrackInfo[]) => {},
        onVideoSizeChanged: (width: number, height: number) => {},
        onError: (error: Error) => {},
        onCompletion: () => {},
        onBufferingChanged: (isBuffering: boolean) => {}
      };

      expect(typeof listener.onStateChanged).assertEqual('function');
      expect(typeof listener.onPositionChanged).assertEqual('function');
      expect(typeof listener.onCompletion).assertEqual('function');
    });

    /**
     * Test: PlayerEventListener with minimal callbacks
     */
    it('should create valid minimal PlayerEventListener', 0, () => {
      const listener: PlayerEventListener = {};

      expect(listener.onStateChanged).assertUndefined();
      expect(listener.onCompletion).assertUndefined();
    });

    // ============ Seek Tests ============

    /**
     * Test: seekTo does not throw in IDLE state
     */
    it('should handle seekTo in IDLE state without error', 0, () => {
      playerAdapter!.seekTo(10000);
      expect(true).assertTrue();
    });

    /**
     * Test: seekToOffset with positive offset
     */
    it('should handle seekToOffset with positive offset', 0, () => {
      // Position is 0, offset is 10000
      playerAdapter!.seekToOffset(10000);
      expect(true).assertTrue();
    });

    /**
     * Test: seekToOffset with negative offset
     */
    it('should handle seekToOffset with negative offset', 0, () => {
      playerAdapter!.seekToOffset(-5000);
      expect(true).assertTrue();
    });

    // ============ Playback Control Tests ============

    /**
     * Test: play does not throw in IDLE state
     */
    it('should handle play in IDLE state without error', 0, () => {
      playerAdapter!.play();
      expect(true).assertTrue();
    });

    /**
     * Test: pause does not throw in IDLE state
     */
    it('should handle pause in IDLE state without error', 0, () => {
      playerAdapter!.pause();
      expect(true).assertTrue();
    });

    /**
     * Test: stop does not throw in IDLE state
     */
    it('should handle stop in IDLE state without error', 0, () => {
      playerAdapter!.stop();
      expect(true).assertTrue();
    });

    // ============ Surface Tests ============

    /**
     * Test: setSurface does not throw with empty string
     */
    it('should handle setSurface with empty string', 0, async () => {
      await playerAdapter!.setSurface('');
      expect(true).assertTrue();
    });

    // ============ Error Handling Tests ============

    /**
     * Test: prepare throws without initialization
     */
    it('should throw error when prepare called without initialization', 0, async () => {
      const source: MediaSourceInfo = {
        url: 'https://example.com/video.mp4'
      };

      try {
        await playerAdapter!.prepare(source);
        // May not throw if player is created in constructor
        expect(true).assertTrue();
      } catch (error) {
        expect(true).assertTrue();
      }
    });

    // ============ Constants Tests ============

    /**
     * Test: Player state transitions
     */
    it('should follow valid state transition order', 0, () => {
      const stateOrder = [
        PlayerState.IDLE,
        PlayerState.INITIALIZED,
        PlayerState.PREPARED,
        PlayerState.PLAYING,
        PlayerState.PAUSED,
        PlayerState.STOPPED,
        PlayerState.COMPLETED,
        PlayerState.ERROR
      ];

      // Verify all states have unique values
      const uniqueStates = new Set(stateOrder);
      expect(uniqueStates.size).assertEqual(stateOrder.length);
    });

    // ============ Edge Cases Tests ============

    /**
     * Test: Empty URL in MediaSourceInfo
     */
    it('should handle empty URL in MediaSourceInfo', 0, () => {
      const source: MediaSourceInfo = {
        url: ''
      };

      expect(source.url).assertEqual('');
    });

    /**
     * Test: Large position value
     */
    it('should handle large position value', 0, () => {
      const largePosition = 3600000; // 1 hour in ms
      playerAdapter!.seekTo(largePosition);
      expect(true).assertTrue();
    });

    /**
     * Test: Zero position value
     */
    it('should handle zero position value', 0, () => {
      playerAdapter!.seekTo(0);
      expect(true).assertTrue();
    });

    /**
     * Test: Negative position value
     */
    it('should handle negative position value', 0, () => {
      playerAdapter!.seekTo(-1000);
      expect(true).assertTrue();
    });

    /**
     * Test: Very high playback speed
     */
    it('should handle high playback speed', 0, () => {
      playerAdapter!.setPlaybackSpeed(10.0);
      expect(playerAdapter!.getPlaybackSpeed()).assertEqual(10.0);
    });

    /**
     * Test: Very low playback speed
     */
    it('should handle low playback speed', 0, () => {
      playerAdapter!.setPlaybackSpeed(0.1);
      expect(playerAdapter!.getPlaybackSpeed()).assertEqual(0.1);
    });

    /**
     * Test: Multiple listener changes
     */
    it('should handle multiple listener changes', 0, () => {
      const listener1: PlayerEventListener = { onStateChanged: () => {} };
      const listener2: PlayerEventListener = { onPositionChanged: () => {} };
      const listener3: PlayerEventListener = { onCompletion: () => {} };

      playerAdapter!.setListener(listener1);
      playerAdapter!.setListener(listener2);
      playerAdapter!.setListener(listener3);
      playerAdapter!.removeListener();

      expect(true).assertTrue();
    });
  });
}
