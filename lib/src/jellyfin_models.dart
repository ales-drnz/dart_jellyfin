// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Plain immutable DTOs for the Jellyfin API.
///
/// Modelled directly on the OpenAPI spec at
/// <https://api.jellyfin.org/openapi/jellyfin-openapi-stable.json> but
/// hand-rolled so the package stays codegen-free. Fields are added on
/// demand — `JellyfinItem.raw` keeps the full server payload around for
/// anything not yet lifted onto a typed property.
///
/// The admin, metadata, live TV and account answers keep the decoded body
/// in `raw` too. Their field names follow the Jellyfin 12.4 API document,
/// and their shapes were checked against a 12.4 server.
library;

export 'models/jellyfin_account_models.dart';
export 'models/jellyfin_browse_models.dart';
export 'models/jellyfin_config_models.dart';
export 'models/jellyfin_item_models.dart';
export 'models/jellyfin_live_tv_models.dart';
export 'models/jellyfin_lyrics_models.dart';
export 'models/jellyfin_metadata_models.dart';
export 'models/jellyfin_playback_models.dart';
export 'models/jellyfin_plugin_models.dart';
export 'models/jellyfin_query_result.dart';
export 'models/jellyfin_session_models.dart';
export 'models/jellyfin_storage_models.dart';
export 'models/jellyfin_system_models.dart';
export 'models/jellyfin_user_models.dart';
