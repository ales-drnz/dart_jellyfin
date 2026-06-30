// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';

/// Image URL builders + bytes fetch.
///
/// Jellyfin's image URLs are deterministic: `/Items/{id}/Images/{type}`
/// with a `tag` parameter (the hash from `ImageTags[type]`) for cache
/// busting. Width/height are server-side resize hints — the response is
/// pre-sized JPEG, no client-side scaling needed.
class JellyfinImagesApi {
  /// Front cover / poster — the most common image type.
  static const String typePrimary = 'Primary';

  /// Clear-art / character art overlay.
  static const String typeArt = 'Art';

  /// Wide background / fanart used behind detail pages.
  static const String typeBackdrop = 'Backdrop';

  /// Horizontal text-laden banner.
  static const String typeBanner = 'Banner';

  /// Transparent logo used over the backdrop.
  static const String typeLogo = 'Logo';

  /// Small thumbnail used for menus / lists.
  static const String typeThumb = 'Thumb';

  /// Physical-disc artwork.
  static const String typeDisc = 'Disc';

  /// `format` value for BMP output (`ImageFormat.Bmp`).
  static const String formatBmp = 'Bmp';

  /// `format` value for GIF output (`ImageFormat.Gif`).
  static const String formatGif = 'Gif';

  /// `format` value for JPEG output (`ImageFormat.Jpg`).
  static const String formatJpg = 'Jpg';

  /// `format` value for PNG output (`ImageFormat.Png`).
  static const String formatPng = 'Png';

  /// `format` value for WebP output (`ImageFormat.Webp`).
  static const String formatWebp = 'Webp';

  /// `format` value for SVG output (`ImageFormat.Svg`).
  static const String formatSvg = 'Svg';

  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinImagesApi(this._http);

  /// Build a deterministic image URL.
  ///
  /// `tag` is the hash from `JellyfinItem.imageTags[type]` — required
  /// for proper cache invalidation when the artwork changes server-side.
  /// Omit it only when you don't have it; the server will still serve
  /// the current image but every CDN/cache in between can't tell when
  /// the bytes have changed.
  ///
  /// `format` is the desired output container; pass one of the
  /// [formatBmp]/[formatGif]/[formatJpg]/[formatPng]/[formatWebp]/[formatSvg]
  /// constants (server-side `ImageFormat` enum).
  ///
  /// `percentPlayed` (0–100, fractional allowed) and `unplayedCount` ask
  /// the server to bake a watched-progress bar or an unplayed-count badge
  /// directly into the rendered image.
  String url({
    required String itemId,
    String type = typePrimary,
    int? imageIndex,
    String? tag,
    int? width,
    int? height,
    int? fillWidth,
    int? fillHeight,
    int? quality,
    String? format,
    double? percentPlayed,
    int? unplayedCount,
  }) {
    final base = _http.baseUrl;
    if (base == null) {
      throw const JellyfinException(
        'No base URL — call JellyfinClient.connect() first.',
        type: JellyfinErrorType.state,
      );
    }
    final qp = <String, String>{};
    if (tag != null) qp['tag'] = tag;
    if (width != null) qp['width'] = '$width';
    if (height != null) qp['height'] = '$height';
    if (fillWidth != null) qp['fillWidth'] = '$fillWidth';
    if (fillHeight != null) qp['fillHeight'] = '$fillHeight';
    if (quality != null) qp['quality'] = '$quality';
    if (format != null) qp['format'] = format;
    if (percentPlayed != null) qp['percentPlayed'] = '$percentPlayed';
    if (unplayedCount != null) qp['unplayedCount'] = '$unplayedCount';
    final indexPart = imageIndex == null ? '' : '/$imageIndex';
    return '$base/Items/$itemId/Images/$type$indexPart${_query(qp)}';
  }

  /// Fetch image bytes. Returns null on 404 (item has no such image).
  Future<Uint8List?> fetch({
    required String itemId,
    String type = typePrimary,
    int? imageIndex,
    String? tag,
    int? fillWidth,
    int? fillHeight,
    int? quality,
  }) async {
    final builtUrl = url(
      itemId: itemId,
      type: type,
      imageIndex: imageIndex,
      tag: tag,
      fillWidth: fillWidth,
      fillHeight: fillHeight,
      quality: quality,
    );
    try {
      final res = await _http.requestBytes(builtUrl);
      final body = res.data;
      if (body == null || body.isEmpty) return null;
      return Uint8List.fromList(body);
    } on JellyfinException catch (e) {
      if (e.type == JellyfinErrorType.notFound) return null;
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Entity image URL builders (Artist / Genre / MusicGenre / Studio / Person)
  // ---------------------------------------------------------------------------

  /// `GET /Artists/{name}/Images/{imageType}/{imageIndex}` — image
  /// for an artist by name.
  String artistImageUrl({
    required String artistName,
    String type = typePrimary,
    int imageIndex = 0,
    String? tag,
    int? width,
    int? height,
    int? fillWidth,
    int? fillHeight,
    int? quality,
    String? format,
  }) =>
      _entityImageUrl(
        'Artists',
        artistName,
        type,
        imageIndex,
        tag: tag,
        width: width,
        height: height,
        fillWidth: fillWidth,
        fillHeight: fillHeight,
        quality: quality,
        format: format,
      );

  /// `GET /Genres/{name}/Images/{imageType}` (with optional index).
  String genreImageUrl({
    required String genreName,
    String type = typePrimary,
    int? imageIndex,
    String? tag,
    int? width,
    int? height,
    int? fillWidth,
    int? fillHeight,
    int? quality,
    String? format,
  }) =>
      _entityImageUrl(
        'Genres',
        genreName,
        type,
        imageIndex,
        tag: tag,
        width: width,
        height: height,
        fillWidth: fillWidth,
        fillHeight: fillHeight,
        quality: quality,
        format: format,
      );

  /// `GET /MusicGenres/{name}/Images/{imageType}` (with optional index).
  String musicGenreImageUrl({
    required String genreName,
    String type = typePrimary,
    int? imageIndex,
    String? tag,
    int? width,
    int? height,
    int? fillWidth,
    int? fillHeight,
    int? quality,
    String? format,
  }) =>
      _entityImageUrl(
        'MusicGenres',
        genreName,
        type,
        imageIndex,
        tag: tag,
        width: width,
        height: height,
        fillWidth: fillWidth,
        fillHeight: fillHeight,
        quality: quality,
        format: format,
      );

  /// `GET /Studios/{name}/Images/{imageType}` (with optional index).
  String studioImageUrl({
    required String studioName,
    String type = typePrimary,
    int? imageIndex,
    String? tag,
    int? width,
    int? height,
    int? fillWidth,
    int? fillHeight,
    int? quality,
    String? format,
  }) =>
      _entityImageUrl(
        'Studios',
        studioName,
        type,
        imageIndex,
        tag: tag,
        width: width,
        height: height,
        fillWidth: fillWidth,
        fillHeight: fillHeight,
        quality: quality,
        format: format,
      );

  /// `GET /Persons/{name}/Images/{imageType}` (with optional index).
  String personImageUrl({
    required String personName,
    String type = typePrimary,
    int? imageIndex,
    String? tag,
    int? width,
    int? height,
    int? fillWidth,
    int? fillHeight,
    int? quality,
    String? format,
  }) =>
      _entityImageUrl(
        'Persons',
        personName,
        type,
        imageIndex,
        tag: tag,
        width: width,
        height: height,
        fillWidth: fillWidth,
        fillHeight: fillHeight,
        quality: quality,
        format: format,
      );

  // ---------------------------------------------------------------------------
  // User image
  // ---------------------------------------------------------------------------

  /// `GET /UserImage` — URL for the current user's avatar (the
  /// session's userId is taken from the connection state).
  ///
  /// This operation does not resize: it serves the avatar at its stored
  /// size. The only supported query params are `tag` (cache-busting hash)
  /// and `format` — one of the
  /// [formatBmp]/[formatGif]/[formatJpg]/[formatPng]/[formatWebp]/[formatSvg]
  /// constants.
  String userImageUrl({
    String? tag,
    String? format,
  }) {
    final base = _requireBase();
    final qp = <String, String>{};
    if (tag != null) qp['tag'] = tag;
    if (format != null) qp['format'] = format;
    return '$base/UserImage${_query(qp)}';
  }

  /// `POST /UserImage` — upload the current user's avatar.
  /// [body] is the raw image bytes; [contentType] tells the server
  /// the MIME (`image/jpeg`, `image/png`). The bytes are base64-encoded
  /// on the wire — the endpoint reads the body as base64 text, not raw
  /// binary.
  Future<void> uploadUserImage({
    required Uint8List body,
    String contentType = 'image/jpeg',
  }) async {
    await _http.request<void>(
      '/UserImage',
      method: 'POST',
      data: base64.encode(body),
      extraHeaders: {'Content-Type': contentType},
    );
  }

  /// `DELETE /UserImage` — remove the current user's avatar.
  Future<void> deleteUserImage() async {
    await _http.request<void>('/UserImage', method: 'DELETE');
  }

  // ---------------------------------------------------------------------------
  // Item image management (upload / delete / reorder / list)
  // ---------------------------------------------------------------------------

  /// `GET /Items/{itemId}/Images` — list every image the item has,
  /// each entry returned as a raw map (ImageType, ImageTag, Path,
  /// Width, Height, …).
  Future<List<Map<String, dynamic>>> listItemImages(String itemId) async {
    final res = await _http.request<List<dynamic>>('/Items/$itemId/Images');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `POST /Items/{itemId}/Images/{imageType}[/{imageIndex}]` —
  /// upload a new image for the item. [body] is the raw image bytes,
  /// base64-encoded on the wire (the endpoint reads the body as base64
  /// text, not raw binary).
  Future<void> setItemImage({
    required String itemId,
    required String imageType,
    int? imageIndex,
    required Uint8List body,
    String contentType = 'image/jpeg',
  }) async {
    final path = imageIndex == null
        ? '/Items/$itemId/Images/$imageType'
        : '/Items/$itemId/Images/$imageType/$imageIndex';
    await _http.request<void>(
      path,
      method: 'POST',
      data: base64.encode(body),
      extraHeaders: {'Content-Type': contentType},
    );
  }

  /// `DELETE /Items/{itemId}/Images/{imageType}[/{imageIndex}]` —
  /// remove an item image.
  Future<void> deleteItemImage({
    required String itemId,
    required String imageType,
    int? imageIndex,
  }) async {
    final path = imageIndex == null
        ? '/Items/$itemId/Images/$imageType'
        : '/Items/$itemId/Images/$imageType/$imageIndex';
    await _http.request<void>(path, method: 'DELETE');
  }

  /// `POST /Items/{itemId}/Images/{imageType}/{imageIndex}/Index` —
  /// reorder a Backdrop or Screenshot image's index.
  Future<void> reorderItemImage({
    required String itemId,
    required String imageType,
    required int imageIndex,
    required int newIndex,
  }) async {
    await _http.request<void>(
      '/Items/$itemId/Images/$imageType/$imageIndex/Index',
      method: 'POST',
      queryParameters: {'newIndex': newIndex},
    );
  }

  // ---------------------------------------------------------------------------
  // Splashscreen (server branding)
  // ---------------------------------------------------------------------------

  /// `GET /Branding/Splashscreen` — URL for the server's splash
  /// screen image (login page background).
  ///
  /// This operation does not resize: the only supported query params are
  /// `tag` (cache-busting hash) and `format` — one of the
  /// [formatBmp]/[formatGif]/[formatJpg]/[formatPng]/[formatWebp]/[formatSvg]
  /// constants.
  String splashscreenUrl({
    String? tag,
    String? format,
  }) {
    final base = _requireBase();
    final qp = <String, String>{};
    if (tag != null) qp['tag'] = tag;
    if (format != null) qp['format'] = format;
    return '$base/Branding/Splashscreen${_query(qp)}';
  }

  /// `POST /Branding/Splashscreen` — upload a custom splash screen.
  /// Admin-only. [body] is the raw image bytes, base64-encoded on the
  /// wire (the endpoint reads the body as base64 text, not raw binary).
  Future<void> uploadSplashscreen({
    required Uint8List body,
    String contentType = 'image/jpeg',
  }) async {
    await _http.request<void>(
      '/Branding/Splashscreen',
      method: 'POST',
      data: base64.encode(body),
      extraHeaders: {'Content-Type': contentType},
    );
  }

  /// `DELETE /Branding/Splashscreen` — remove the custom splash
  /// screen and revert to the default. Admin-only.
  Future<void> deleteSplashscreen() async {
    await _http.request<void>('/Branding/Splashscreen', method: 'DELETE');
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  String _entityImageUrl(
    String entityPath,
    String name,
    String type,
    int? imageIndex, {
    String? tag,
    int? width,
    int? height,
    int? fillWidth,
    int? fillHeight,
    int? quality,
    String? format,
  }) {
    final base = _requireBase();
    final qp = <String, String>{};
    if (tag != null) qp['tag'] = tag;
    if (width != null) qp['width'] = '$width';
    if (height != null) qp['height'] = '$height';
    if (fillWidth != null) qp['fillWidth'] = '$fillWidth';
    if (fillHeight != null) qp['fillHeight'] = '$fillHeight';
    if (quality != null) qp['quality'] = '$quality';
    if (format != null) qp['format'] = format;
    final indexPart = imageIndex == null ? '' : '/$imageIndex';
    return '$base/$entityPath/${Uri.encodeComponent(name)}/Images/$type$indexPart${_query(qp)}';
  }

  String _query(Map<String, String> qp) => qp.isEmpty
      ? ''
      : '?${qp.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

  String _requireBase() {
    final base = _http.baseUrl;
    if (base == null) {
      throw const JellyfinException(
        'No base URL. Call JellyfinClient.connect() first.',
        type: JellyfinErrorType.state,
      );
    }
    return base;
  }
}
