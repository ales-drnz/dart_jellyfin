// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

library;

import '../jellyfin_json.dart';

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

/// The first user the setup wizard is creating (`StartupUserDto`).
final class JellyfinStartupUser {
  /// `Name`.
  final String? name;

  /// `Password`.
  final String? password;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a startup user from already-parsed components.
  const JellyfinStartupUser({required this.raw, this.name, this.password});

  /// Decodes a `StartupUserDto`.
  factory JellyfinStartupUser.fromJson(Map<String, Object?> json) =>
      JellyfinStartupUser(
        name: asString(json['Name']),
        password: asString(json['Password']),
        raw: json,
      );
}

/// The answer to `user.forgotPassword` (`ForgotPasswordResult`).
final class JellyfinForgotPasswordResult {
  /// `ContactAdmin`, `PinCode` or `InNetworkRequired` (`Action`).
  final String? action;

  /// Where the server wrote the PIN (`PinFile`).
  final String? pinFile;

  /// `PinExpirationDate`.
  final DateTime? pinExpirationDate;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the result from already-parsed components.
  const JellyfinForgotPasswordResult({
    required this.raw,
    this.action,
    this.pinFile,
    this.pinExpirationDate,
  });

  /// Decodes a `ForgotPasswordResult`.
  factory JellyfinForgotPasswordResult.fromJson(Map<String, Object?> json) =>
      JellyfinForgotPasswordResult(
        action: asString(json['Action']),
        pinFile: asString(json['PinFile']),
        pinExpirationDate: asUtcDateTime(json['PinExpirationDate']),
        raw: json,
      );
}

/// The answer to `user.forgotPasswordPin` (`PinRedeemResult`).
final class JellyfinPinRedeemResult {
  /// `Success`.
  final bool success;

  /// The users whose password was reset (`UsersReset`).
  final List<String> usersReset;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the result from already-parsed components.
  const JellyfinPinRedeemResult({
    required this.success,
    required this.usersReset,
    required this.raw,
  });

  /// Decodes a `PinRedeemResult`.
  factory JellyfinPinRedeemResult.fromJson(Map<String, Object?> json) =>
      JellyfinPinRedeemResult(
        success: json['Success'] == true,
        usersReset: asStringList(json['UsersReset']),
        raw: json,
      );
}
