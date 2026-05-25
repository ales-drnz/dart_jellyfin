// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/ScheduledTasks` — server background tasks (library scan,
/// thumbnail generation, cleanup, …).
///
/// Wraps the `ScheduledTasks` OpenAPI tag (5 operations). Admin only.
class JellyfinScheduledTasksApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinScheduledTasksApi(this._http);

  /// `GET /ScheduledTasks` — list every task, with current state
  /// (last run, current progress, triggers).
  Future<List<Map<String, dynamic>>> list({
    bool? isHidden,
    bool? isEnabled,
  }) async {
    final qp = <String, dynamic>{};
    if (isHidden != null) qp['isHidden'] = isHidden;
    if (isEnabled != null) qp['isEnabled'] = isEnabled;
    final res = await _http.request<List<dynamic>>(
      '/ScheduledTasks',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }

  /// `GET /ScheduledTasks/{taskId}` — one task's full status.
  Future<Map<String, dynamic>> byId(String taskId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/ScheduledTasks/$taskId',
    );
    return res.data ?? const {};
  }

  /// `POST /ScheduledTasks/{taskId}/Triggers` — replace the task's
  /// triggers (cron-like schedule definitions).
  Future<void> updateTriggers({
    required String taskId,
    required List<Map<String, dynamic>> triggers,
  }) async {
    await _http.request<void>(
      '/ScheduledTasks/$taskId/Triggers',
      method: 'POST',
      data: triggers,
    );
  }

  /// `POST /ScheduledTasks/Running/{taskId}` — start the task now.
  Future<void> start(String taskId) async {
    await _http.request<void>(
      '/ScheduledTasks/Running/$taskId',
      method: 'POST',
    );
  }

  /// `DELETE /ScheduledTasks/Running/{taskId}` — stop a currently
  /// running task.
  Future<void> stop(String taskId) async {
    await _http.request<void>(
      '/ScheduledTasks/Running/$taskId',
      method: 'DELETE',
    );
  }
}
