// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:convert';

/// Decode a whole text body — a subtitle or lyric file the server streams
/// off disk — picking the codec the bytes, and failing that the response
/// header, call for.
///
/// Such a file's encoding is not fixed, so the codec is chosen in this
/// order:
///
///  1. A byte-order mark — UTF-8 (`EF BB BF`), UTF-16 LE (`FF FE`) or
///     UTF-16 BE (`FE FF`). The mark outranks the header and is consumed:
///     a leading U+FEFF would push the first cue or `[mm:ss.xx]` off the
///     start of its line.
///  2. The `charset` of [contentType], when it names a codec handled here.
///     An unknown charset, or none, falls through.
///  3. A strict UTF-8 decode, falling back to Latin-1 when it throws.
///     Decoding byte by byte — what `String.fromCharCodes` does — turned
///     every accented character of a UTF-8 file into two (`Perché` →
///     `PerchÃ©`).
///
/// A declared `charset=utf-8` the bytes contradict still degrades to
/// Latin-1 rather than throwing.
///
/// Not exported from the package barrel; the same logic serves `dart_plex`.
String decodeTextBody(List<int> bytes, {String? contentType}) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return _utf8OrLatin1(bytes.sublist(3));
  }
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return _decodeUtf16(bytes.sublist(2), littleEndian: true);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return _decodeUtf16(bytes.sublist(2), littleEndian: false);
  }

  switch (_charsetOf(contentType)) {
    case 'utf-8' || 'utf8' || 'us-ascii' || 'ascii':
      return _utf8OrLatin1(bytes);
    case 'iso-8859-1' || 'iso8859-1' || 'iso_8859-1' || 'latin1' || 'latin-1':
      return latin1.decode(bytes);
    // No BOM to say otherwise, so RFC 2781's big-endian default applies
    // to a bare `utf-16`.
    case 'utf-16' || 'utf-16be' || 'utf16be':
      return _decodeUtf16(bytes, littleEndian: false);
    case 'utf-16le' || 'utf16le':
      return _decodeUtf16(bytes, littleEndian: true);
  }

  return _utf8OrLatin1(bytes);
}

/// The lowercased `charset` parameter of a `Content-Type`, or null when
/// the header is absent, carries no charset, or leaves it empty.
String? _charsetOf(String? contentType) {
  if (contentType == null) return null;
  for (final parameter in contentType.split(';').skip(1)) {
    final equals = parameter.indexOf('=');
    if (equals < 0) continue;
    if (parameter.substring(0, equals).trim().toLowerCase() != 'charset') {
      continue;
    }
    var value = parameter.substring(equals + 1).trim().toLowerCase();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    return value.isEmpty ? null : value;
  }
  return null;
}

/// Strict UTF-8, falling back to Latin-1 on the bytes that refuse it.
/// Latin-1 accepts every byte, so this always yields a string.
String _utf8OrLatin1(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

/// Decode UTF-16 code units, [littleEndian] or not, from [bytes] that
/// have already had their BOM removed. A trailing odd byte is dropped.
String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
  final units = <int>[];
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    final first = bytes[i];
    final second = bytes[i + 1];
    units.add(littleEndian ? first | (second << 8) : (first << 8) | second);
  }
  // Surrogate pairs survive: values at or below 0xFFFF are taken as UTF-16
  // code units, so a pair recombines into the one character it encodes.
  return String.fromCharCodes(units);
}
