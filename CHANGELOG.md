## [0.0.1] - 25-05-2026

### Added
- Initial scaffold targeting Jellyfin `v10.11.9`.
- Authentication flows: AuthenticateByName and Quick Connect.
- `MediaBrowser` `Authorization` header builder with token + device fields.
- Exception hierarchy with semantic error classification (`auth`, `notFound`, `serverError`, `parse`, `state`, `connection`, `timeout`, `badRequest`, `unknown`).
- Music endpoints: user views, items by type, playlists, image URLs, audio streaming (universal + direct + HLS), lyrics, playback reporting, search, favorites.
- Typed DTOs across the documented API surface, plus a `raw` escape hatch on every model for fields not yet promoted.
