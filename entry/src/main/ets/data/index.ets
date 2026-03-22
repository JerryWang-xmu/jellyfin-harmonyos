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
 * Data layer exports for Jellyfin HarmonyOS app.
 * Migrated from Android Room to HarmonyOS RdbStore.
 */

// Database
export { JellyfinDatabase, DATABASE_NAME, DATABASE_VERSION, getDatabase, resetDatabase } from './database/JellyfinDatabase';

// Entities
export { ServerEntity, ServerEntityHelper } from './entity/ServerEntity';
export { UserEntity, UserEntityHelper, ServerUser } from './entity/UserEntity';
export { DownloadEntity, DownloadEntityHelper } from './entity/DownloadEntity';

// DAOs
export { ServerDao } from './dao/ServerDao';
export { UserDao } from './dao/UserDao';
export { DownloadDao } from './dao/DownloadDao';
