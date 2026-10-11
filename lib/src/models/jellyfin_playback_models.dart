// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// Playback info / device profile
// ---------------------------------------------------------------------------

/// Result of `GET/POST /Items/{itemId}/PlaybackInfo`.
///
/// `mediaSources` carries the server's decision for each source: which
/// of [JellyfinMediaSource.supportsDirectPlay],
/// [JellyfinMediaSource.supportsDirectStream], or
/// [JellyfinMediaSource.supportsTranscoding] is `true`, plus a
/// [JellyfinMediaSource.transcodingUrl] when transcoding is required.
final class JellyfinPlaybackInfo {
  /// Media sources annotated with the server's per-source playback decision.
  final List<JellyfinMediaSource> mediaSources;

  /// Token to thread through `/Playing/...` reporting and stop calls.
  final String? playSessionId;

  /// Server-reported failure code, when playback can't be started.
  final String? errorCode;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a playback-info DTO from already-parsed components.
  const JellyfinPlaybackInfo({
    required this.mediaSources,
    required this.raw,
    this.playSessionId,
    this.errorCode,
  });

  /// Decodes the `PlaybackInfoResponse` envelope.
  factory JellyfinPlaybackInfo.fromJson(Map<String, Object?> json) =>
      JellyfinPlaybackInfo(
        mediaSources:
            asObjectList(json['MediaSources'], JellyfinMediaSource.fromJson),
        playSessionId: asString(json['PlaySessionId']),
        errorCode: asString(json['ErrorCode']),
        raw: json,
      );
}

/// One `DirectPlayProfile` entry of a [JellyfinDeviceProfile].
///
/// [type] is the `DlnaProfileType` selector telling the server which
/// media kind the profile applies to — one of
/// `'Audio' | 'Video' | 'Photo' | 'Subtitle' | 'Lyric'`. It is required
/// because the server only matches a source against a profile whose kind
/// matches the source; an audio source never matches a `Video` profile.
/// [container], [audioCodec], and [videoCodec] are optional, comma-
/// separated constraint lists (mirroring the spec); null entries are
/// omitted from the wire body.
final class JellyfinDirectPlayProfile {
  /// Media kind this profile applies to: `'Audio' | 'Video' | 'Photo' |
  /// 'Subtitle' | 'Lyric'`.
  final String type;

  /// Comma-separated container constraint (e.g. `'mp3'`, `'mp4,mkv'`).
  final String? container;

  /// Comma-separated audio-codec constraint (e.g. `'aac,mp3'`).
  final String? audioCodec;

  /// Comma-separated video-codec constraint (e.g. `'h264,hevc'`).
  final String? videoCodec;

  /// Builds a direct-play profile. [type] selects the media kind and is
  /// required; the codec/container constraints are optional.
  const JellyfinDirectPlayProfile({
    required this.type,
    this.container,
    this.audioCodec,
    this.videoCodec,
  });

  /// Convenience constructor for an audio direct-play profile
  /// (`type: 'Audio'`).
  const JellyfinDirectPlayProfile.audio({
    this.container,
    this.audioCodec,
  })  : type = 'Audio',
        videoCodec = null;

  /// Convenience constructor for a video direct-play profile
  /// (`type: 'Video'`).
  const JellyfinDirectPlayProfile.video({
    this.container,
    this.audioCodec,
    this.videoCodec,
  }) : type = 'Video';

  /// `DirectPlayProfile` JSON body. Null constraints are omitted.
  Map<String, Object?> toJson() => <String, Object?>{
        'Type': type,
        if (container != null) 'Container': container,
        if (audioCodec != null) 'AudioCodec': audioCodec,
        if (videoCodec != null) 'VideoCodec': videoCodec,
      };
}

/// Subset of `DeviceProfile` from the OpenAPI spec — enough to tell
/// the server "I can decode these containers, codecs, and bitrates,
/// transcode anything else".
///
/// The full DTO has ~30 sub-types (CodecProfile, ContainerProfile,
/// DirectPlayProfile, TranscodingProfile, …). For ergonomic
/// hand-rolled use we expose the high-level knobs plus an `extra`
/// escape hatch — fields you set there are merged into the JSON body
/// verbatim.
final class JellyfinDeviceProfile {
  /// Human-readable name (`'Finova'`, etc).
  final String? name;

  /// Hard upper limit on streamed bitrate. Applies to both transcoded
  /// and direct-played sources.
  final int? maxStreamingBitrate;

  /// Hard upper limit on a static (download) bitrate.
  final int? maxStaticBitrate;

  /// Music-only bitrate ceiling.
  final int? musicStreamingTranscodingBitrate;

  /// Profiles the client can direct-play. Each entry names a media kind
  /// (`'Audio'`, `'Video'`, …) plus an optional container/codec
  /// constraint. The server skips transcoding when a source matches one
  /// of these AND the codecs inside are also supported. Because the kind
  /// is explicit per entry, audio sources (`flac`, `mp3`, `aac`) match
  /// `Type: 'Audio'` profiles rather than being forced down the video path.
  final List<JellyfinDirectPlayProfile> directPlayProfiles;

  /// Containers + codecs the server should re-mux into when direct
  /// play isn't possible but transcoding would be wasteful.
  final List<Map<String, Object?>> transcodingProfiles;

  /// Codec-level constraints (e.g. "h264 up to profile high@4.0").
  final List<Map<String, Object?>> codecProfiles;

  /// Container-level constraints.
  final List<Map<String, Object?>> containerProfiles;

  /// Subtitle profiles (formats the player understands and which
  /// methods — Embed/Encode/External — it prefers).
  final List<Map<String, Object?>> subtitleProfiles;

  /// Anything else not promoted to a typed field. Merged verbatim
  /// into the outgoing JSON.
  final Map<String, Object?> extra;

  /// Builds a device profile from already-parsed components.
  const JellyfinDeviceProfile({
    this.name,
    this.maxStreamingBitrate,
    this.maxStaticBitrate,
    this.musicStreamingTranscodingBitrate,
    this.directPlayProfiles = const [],
    this.transcodingProfiles = const [],
    this.codecProfiles = const [],
    this.containerProfiles = const [],
    this.subtitleProfiles = const [],
    this.extra = const {},
  });

  /// JSON body accepted by `/Items/{id}/PlaybackInfo` and friends. Empty
  /// fields are omitted; [extra] is merged in at the top level.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (name != null) 'Name': name,
      if (maxStreamingBitrate != null)
        'MaxStreamingBitrate': maxStreamingBitrate,
      if (maxStaticBitrate != null) 'MaxStaticBitrate': maxStaticBitrate,
      if (musicStreamingTranscodingBitrate != null)
        'MusicStreamingTranscodingBitrate': musicStreamingTranscodingBitrate,
      if (directPlayProfiles.isNotEmpty)
        'DirectPlayProfiles': [
          for (final profile in directPlayProfiles) profile.toJson(),
        ],
      if (transcodingProfiles.isNotEmpty)
        'TranscodingProfiles': transcodingProfiles,
      if (codecProfiles.isNotEmpty) 'CodecProfiles': codecProfiles,
      if (containerProfiles.isNotEmpty) 'ContainerProfiles': containerProfiles,
      if (subtitleProfiles.isNotEmpty) 'SubtitleProfiles': subtitleProfiles,
      ...extra,
    };
  }
}

// ---------------------------------------------------------------------------
// Media segments (`/MediaSegments/{itemId}`) — skip intro/outro/recap
// ---------------------------------------------------------------------------

/// One annotated time range on a media item: an intro, a recap, an
/// outro, a commercial, a preview, or an unknown segment. Times are
/// expressed in Jellyfin ticks (10,000 per millisecond).
final class JellyfinMediaSegment {
  /// Stable server-side segment id.
  final String? id;

  /// Id of the item this segment belongs to.
  final String? itemId;

  /// `Unknown`, `Commercial`, `Preview`, `Recap`, `Outro`, `Intro`.
  final String? type;

  /// Segment start in ticks (10_000 per millisecond).
  final int? startTicks;

  /// Segment end in ticks (10_000 per millisecond).
  final int? endTicks;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a media segment from already-parsed components.
  const JellyfinMediaSegment({
    this.id,
    this.itemId,
    this.type,
    this.startTicks,
    this.endTicks,
    this.raw = const {},
  });

  /// Segment start as a [Duration], or `null` when [startTicks] is absent.
  Duration? get start =>
      startTicks == null ? null : Duration(microseconds: startTicks! ~/ 10);

  /// Segment end as a [Duration], or `null` when [endTicks] is absent.
  Duration? get end =>
      endTicks == null ? null : Duration(microseconds: endTicks! ~/ 10);

  /// Decodes a `/MediaSegments/{itemId}` entry.
  factory JellyfinMediaSegment.fromJson(Map<String, Object?> json) =>
      JellyfinMediaSegment(
        id: asString(json['Id']),
        itemId: asString(json['ItemId']),
        type: asString(json['Type']),
        startTicks: asInt(json['StartTicks']),
        endTicks: asInt(json['EndTicks']),
        raw: json,
      );
}

/// Canonical [JellyfinMediaSegment.type] values.
abstract final class JellyfinMediaSegmentType {
  /// Unclassified segment.
  static const unknown = 'Unknown';

  /// Commercial break.
  static const commercial = 'Commercial';

  /// "Next on…" or upcoming-content preview.
  static const preview = 'Preview';

  /// Recap of previous episodes.
  static const recap = 'Recap';

  /// Closing/outro sequence.
  static const outro = 'Outro';

  /// Opening/intro sequence.
  static const intro = 'Intro';
}
