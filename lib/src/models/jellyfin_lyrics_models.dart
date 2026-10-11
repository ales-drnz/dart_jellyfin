// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// Lyrics
// ---------------------------------------------------------------------------

/// One time-aligned piece of a [JellyfinLyricLine] — usually a word of an
/// enhanced (word-by-word, "ELRC") lyric.
final class JellyfinLyricCue {
  /// Index in [JellyfinLyricLine.text] where the piece starts.
  final int position;

  /// Index in [JellyfinLyricLine.text] where the piece ends. Jellyfin
  /// 12.0 counts the space after a word into it (`"Hello world"` → cues
  /// 0–6 and 6–11), but do not rely on that: [JellyfinLyricLine.toLrcLine]
  /// slices from cue to cue, so no character is lost either way.
  final int endPosition;

  /// When the piece starts, in 100-ns ticks.
  final int startTicks;

  /// When the piece ends, in 100-ns ticks, when known.
  final int? endTicks;

  /// Builds a cue from already-parsed components.
  const JellyfinLyricCue({
    required this.position,
    required this.endPosition,
    required this.startTicks,
    this.endTicks,
  });

  /// Decodes a `{Position, EndPosition, Start, End}` cue.
  factory JellyfinLyricCue.fromJson(Map<String, Object?> json) =>
      JellyfinLyricCue(
        position: asInt(json['Position']) ?? 0,
        endPosition: asInt(json['EndPosition']) ?? 0,
        startTicks: asInt(json['Start']) ?? 0,
        endTicks: asInt(json['End']),
      );

  /// [startTicks] as a [Duration].
  Duration get start => Duration(microseconds: startTicks ~/ 10);

  /// [endTicks] as a [Duration], when known.
  Duration? get end =>
      endTicks == null ? null : Duration(microseconds: endTicks! ~/ 10);
}

/// One line of a lyric (`LyricLine`).
final class JellyfinLyricLine {
  /// Start time in 100-ns ticks; `null` for unsynced lines.
  final int? startTicks;

  /// Line text.
  final String text;

  /// Word-level timing, when the lyric is enhanced (ELRC); empty otherwise.
  final List<JellyfinLyricCue> cues;

  /// Builds a lyric line from already-parsed components.
  const JellyfinLyricLine({
    required this.text,
    this.startTicks,
    this.cues = const [],
  });

  /// Decodes a `{Start, Text, Cues}` lyrics entry.
  factory JellyfinLyricLine.fromJson(Map<String, Object?> json) =>
      JellyfinLyricLine(
        startTicks: asInt(json['Start']),
        text: asString(json['Text']) ?? '',
        cues: asObjectList(json['Cues'], JellyfinLyricCue.fromJson),
      );

  /// [startTicks] as a [Duration], or `null` for an unsynced line.
  Duration? get start =>
      startTicks == null ? null : Duration(microseconds: startTicks! ~/ 10);

  /// Convert to a single LRC line `[mm:ss.xx]text`, or just `text` if no
  /// timestamp is present.
  ///
  /// With [enhanced] and [cues], the words carry their own times in the
  /// enhanced-LRC (ELRC) syntax: `[00:12.00]<00:12.00>Hello <00:12.40>world<00:13.10>`.
  /// Each word runs from its cue to the next cue, so the spaces between
  /// words are kept (attached to the word they follow); a last tag closes
  /// the final word at its end time, when the server sent one. A line with
  /// cues but no start of its own takes the first cue's.
  String toLrcLine({bool enhanced = false}) {
    if (enhanced && cues.isNotEmpty) {
      final out = StringBuffer();
      final lineStart = startTicks ?? cues.first.startTicks;
      out.write('[${lrcTimestamp(lineStart)}]');
      var consumed = 0;
      int? lastEnd;
      for (final cue in cues) {
        final position = cue.position.clamp(0, text.length);
        // Out-of-order or overlapping cues would slice backwards: skip.
        if (position < consumed) continue;
        if (position > consumed) out.write(text.substring(consumed, position));
        out.write('<${lrcTimestamp(cue.startTicks)}>');
        consumed = position;
        lastEnd = cue.endTicks ?? lastEnd;
      }
      if (consumed < text.length) out.write(text.substring(consumed));
      if (lastEnd != null) out.write('<${lrcTimestamp(lastEnd)}>');
      return out.toString();
    }
    final ticks = startTicks;
    if (ticks == null) return text;
    return '[${lrcTimestamp(ticks)}]$text';
  }

  /// Formats ticks as an LRC timestamp, `mm:ss.cc` (truncated, never
  /// rounded up, so a line never shows before it is sung).
  static String lrcTimestamp(int ticks) {
    final ms = ticks ~/ 10000;
    final m = (ms ~/ 60000).toString().padLeft(2, '0');
    final s = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final c = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$c';
  }
}

/// Tags of a lyric file (`LyricMetadata`).
///
/// Do not count on it: Jellyfin 12.2 answered `Metadata: {}` — every field
/// here null — for an LRC that carried `[ar:]` and `[ti:]` tags.
final class JellyfinLyricMetadata {
  /// Song artist.
  final String? artist;

  /// Album the song is on.
  final String? album;

  /// Song title.
  final String? title;

  /// Author of the lyric data.
  final String? author;

  /// Song length in 100-ns ticks.
  final int? lengthTicks;

  /// Who made the LRC file.
  final String? by;

  /// Lyric offset against the audio, in 100-ns ticks.
  final int? offsetTicks;

  /// Software that made the LRC file.
  final String? creator;

  /// Version of [creator].
  final String? version;

  /// Whether the lyric is synced, as the server judged it.
  final bool? isSynced;

  /// Builds metadata from already-parsed components.
  const JellyfinLyricMetadata({
    this.artist,
    this.album,
    this.title,
    this.author,
    this.lengthTicks,
    this.by,
    this.offsetTicks,
    this.creator,
    this.version,
    this.isSynced,
  });

  /// Decodes a `LyricMetadata` object.
  factory JellyfinLyricMetadata.fromJson(Map<String, Object?> json) =>
      JellyfinLyricMetadata(
        artist: asString(json['Artist']),
        album: asString(json['Album']),
        title: asString(json['Title']),
        author: asString(json['Author']),
        lengthTicks: asInt(json['Length']),
        by: asString(json['By']),
        offsetTicks: asInt(json['Offset']),
        creator: asString(json['Creator']),
        version: asString(json['Version']),
        isSynced: json['IsSynced'] is bool ? json['IsSynced'] as bool : null,
      );
}

/// Payload of `GET /Audio/{id}/Lyrics` (`LyricDto`).
final class JellyfinLyrics {
  /// Parsed lyric lines, in display order.
  final List<JellyfinLyricLine> lines;

  /// The lyric file's tags, when the server sent them. Often empty even
  /// when the file has tags; see [JellyfinLyricMetadata].
  final JellyfinLyricMetadata? metadata;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a lyrics payload from already-parsed components.
  const JellyfinLyrics({required this.lines, required this.raw, this.metadata});

  /// Decodes `{Lyrics: [...], Metadata: {...}}`. Tolerates missing or
  /// non-list `Lyrics`.
  factory JellyfinLyrics.fromJson(Map<String, Object?> json) {
    final meta = json['Metadata'];
    return JellyfinLyrics(
      lines: asObjectList(json['Lyrics'], JellyfinLyricLine.fromJson),
      metadata: meta is Map<String, Object?>
          ? JellyfinLyricMetadata.fromJson(meta)
          : null,
      raw: json,
    );
  }

  /// `true` when at least one line carries a timestamp.
  bool get isSynced => lines.any((l) => l.startTicks != null);

  /// `true` when at least one line carries word-level cues (ELRC).
  bool get hasCues => lines.any((l) => l.cues.isNotEmpty);

  /// Render as an LRC document, suitable for any synced-lyrics player.
  ///
  /// With [enhanced], lines with cues are written word by word in the ELRC
  /// syntax (see [JellyfinLyricLine.toLrcLine]); others stay plain LRC.
  String toLrc({bool enhanced = false}) =>
      lines.map((l) => l.toLrcLine(enhanced: enhanced)).join('\n');

  /// Render as plain text (one line per entry, timestamps dropped).
  String toPlainText() => lines.map((l) => l.text).join('\n');
}
