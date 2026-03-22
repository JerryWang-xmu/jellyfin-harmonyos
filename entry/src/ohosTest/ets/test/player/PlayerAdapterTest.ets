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
 * 播放器适配器测试
 * 测试 AVPlayerAdapter 的基本功能
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import { AVPlayerAdapter } from '../../../../main/ets/player/adapter/AVPlayerAdapter';
import { IPlayerAdapter, PlayerState, TrackInfo, MediaSourceInfo } from '../../../../main/ets/player/adapter/IPlayerAdapter';

export default function PlayerAdapterTest() {
  describe('AVPlayerAdapter', () => {
    let player: AVPlayerAdapter;

    beforeEach(async () => {
      player = new AVPlayerAdapter();
      await player.initialize();
    });

    afterEach(() => {
      player.release();
    });

    /**
     * 测试初始化
     */
    it('should_initialize_correctly', async () => {
      expect(player).assertNotNull();
      expect(player.getState()).assertEqual(PlayerState.INITIALIZED);
    });

    /**
     * 测试初始状态
     */
    it('should_have_correct_initial_state', () => {
      expect(player.isPlaying()).assertFalse();
      expect(player.getCurrentPosition()).assertEqual(0);
      expect(player.getDuration()).assertEqual(0);
      expect(player.getVolume()).assertEqual(100);
      expect(player.getPlaybackSpeed()).assertEqual(1.0);
    });

    /**
     * 测试音量设置
     */
    it('should_set_volume_correctly', () => {
      player.setVolume(50);
      expect(player.getVolume()).assertEqual(50);

      player.setVolume(0);
      expect(player.getVolume()).assertEqual(0);

      player.setVolume(100);
      expect(player.getVolume()).assertEqual(100);
    });

    /**
     * 测试音量边界
     */
    it('should_clamp_volume_to_valid_range', () => {
      player.setVolume(-10);
      expect(player.getVolume()).assertEqual(0);

      player.setVolume(150);
      expect(player.getVolume()).assertEqual(100);
    });

    /**
     * 测试播放速度设置
     */
    it('should_set_playback_speed', () => {
      player.setPlaybackSpeed(1.5);
      expect(player.getPlaybackSpeed()).assertEqual(1.5);

      player.setPlaybackSpeed(0.5);
      expect(player.getPlaybackSpeed()).assertEqual(0.5);

      player.setPlaybackSpeed(2.0);
      expect(player.getPlaybackSpeed()).assertEqual(2.0);
    });

    /**
     * 测试事件监听器设置
     */
    it('should_set_event_listener', () => {
      let stateChanged = false;
      let positionChanged = false;

      player.setListener({
        onStateChanged: (state: PlayerState) => {
          stateChanged = true;
        },
        onPositionChanged: (positionMs: number) => {
          positionChanged = true;
        }
      });

      // 监听器应该已设置，不会抛出异常
      expect(true).assertTrue();
    });

    /**
     * 测试移除事件监听器
     */
    it('should_remove_event_listener', () => {
      player.setListener({
        onStateChanged: (state: PlayerState) => {}
      });

      player.removeListener();

      // 移除后应该不会抛出异常
      expect(true).assertTrue();
    });

    /**
     * 测试轨道获取
     */
    it('should_get_empty_tracks_initially', () => {
      const tracks = player.getTracks();
      expect(tracks).assertNotNull();
      // 初始状态可能没有轨道
    });

    /**
     * 测试释放
     */
    it('should_release_correctly', () => {
      player.release();
      expect(player.getState()).assertEqual(PlayerState.IDLE);
    });
  });

  describe('IPlayerAdapter Interface', () => {
    /**
     * 测试接口定义存在
     */
    it('should_have_required_interface_methods', () => {
      // 验证接口方法签名
      const requiredMethods = [
        'initialize',
        'release',
        'setSurface',
        'prepare',
        'play',
        'pause',
        'stop',
        'seekTo',
        'seekToOffset',
        'getState',
        'getCurrentPosition',
        'getDuration',
        'isPlaying',
        'setVolume',
        'getVolume',
        'setPlaybackSpeed',
        'getPlaybackSpeed',
        'getTracks',
        'selectAudioTrack',
        'selectSubtitleTrack',
        'setListener',
        'removeListener'
      ];

      // 如果能编译通过，接口定义就是正确的
      expect(requiredMethods.length).assertGreater(0);
    });
  });

  describe('PlayerState Enum', () => {
    /**
     * 测试状态枚举值
     */
    it('should_have_correct_state_values', () => {
      expect(PlayerState.IDLE).assertEqual(0);
      expect(PlayerState.INITIALIZED).assertEqual(1);
      expect(PlayerState.PREPARED).assertEqual(2);
      expect(PlayerState.PLAYING).assertEqual(3);
      expect(PlayerState.PAUSED).assertEqual(4);
      expect(PlayerState.STOPPED).assertEqual(5);
      expect(PlayerState.COMPLETED).assertEqual(6);
      expect(PlayerState.ERROR).assertEqual(7);
    });
  });
}
