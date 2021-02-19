/// Provides the ability to check if the currently started app is an upgrade.
///
/// An upgrade is defined as the first start of a new app version, compared to the last known version.
/// All versions depend on the [Semantic Versioning](https://semver.org/) definition, implemented by [pub_semver](https://pub.dev/packages/pub_semver).
///
/// Can be used with the given persistence implementation (shared preferences) or with a custom implementation of the getter / setter logic
/// for the last known version. The currently running app version is always determined by the version loaded via
/// [package_info_plus](https://pub.dev/packages/package_info_plus).
library on_upgrade;

import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UpgradeState {
  upgrade,
  noUpgrade,
  unknown,
}

/// Wraps the upgrade state of the app.
///
/// If [hasError] is **false** the upgrade check was successful and [state], [lastVersion] and [currentVersion] are set accordingly.
///
/// If an error occurred [hasError] is **true**, [state] is [UpgradeState.unknown] and the error reason is returned in [error].
class UpgradeWrapper {
  final UpgradeState state;
  final Version lastVersion;
  final Version currentVersion;
  final bool hasError;
  final Exception error;

  UpgradeWrapper(
      {@required this.state,
      this.lastVersion,
      this.currentVersion,
      this.hasError = false,
      this.error});
}

/// Contains the upgrade check functionality
///
/// The last know version must be set via [updateLastVersion].
///
/// Usage with default implementation:
/// ```dart
/// final onUpgrade = OnUpgrade();
/// final isNewVersion = await onUpgrade.isNewVersion();
/// if (isNewVersion.isUpdate == UpgradeState.upgrade) {
///   await onUpgrade.updateLastVersion();
///   myDataMigration();
///   myShowUserNewFeaturesDialog();
/// }
/// ```
class OnUpgrade {
  /// Configures a custom key used in the shared preferences. Defaults to `on_upgrade.version`
  final String keyLastVersion;

  /// Optional current version getter. If set [keyLastVersion] isn't used and [customVersionUpdate] is required to be also set.
  /// Must have the signature `Future<String> func() async {}`
  final Function customVersionLookup;

  /// Optional current version setter. If set [keyLastVersion] isn't used and [customVersionLookup] is required to be also set
  /// Must have the signature `Future<bool> func([String version]) async {}`
  final Function customVersionUpdate;

  OnUpgrade(
      {this.keyLastVersion = 'on_upgrade.version',
      this.customVersionLookup,
      this.customVersionUpdate});

  /// Returns the upgrade state.
  Future<UpgradeWrapper> isNewVersion() async {
    try {
      final lastVersion = await getLastVersion();
      final currentVersion = await getCurrentVersion();
      final state = lastVersion.compareTo(currentVersion) < 0
          ? UpgradeState.upgrade
          : UpgradeState.noUpgrade;
      return UpgradeWrapper(
          state: state,
          lastVersion: lastVersion,
          currentVersion: currentVersion);
    } catch (exception) {
      return UpgradeWrapper(
          state: UpgradeState.unknown, hasError: true, error: exception);
    }
  }

  /// Returns if the current app start is the first start overall.
  Future<bool> isInitialInstallation() async {
    final lastVersion = await _getLastVersionString();
    return lastVersion.isEmpty;
  }

  /// Returns the last known version. Call [updateLastVersion] to update this value
  Future<Version> getLastVersion() async {
    final versionString = await _getLastVersionString();
    return versionString != null && versionString.isNotEmpty
        ? Version.parse(versionString)
        : Version.none;
  }

  /// Returns the currently running version
  Future<Version> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return Version.parse(packageInfo.version);
  }

  /// Returns the currently running version as [String]
  Future<String> getCurrentVersionString() async {
    return (await getCurrentVersion()).toString();
  }

  /// Sets the last know version and persists it. If called without parameter the currently running version is set.
  Future<bool> updateLastVersion([String version]) async {
    if (customVersionUpdate != null) {
      return customVersionUpdate(version);
    }
    version ??= await getCurrentVersionString();
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(keyLastVersion, version);
  }

  Future<String> _getLastVersionString() async {
    if (customVersionLookup != null) {
      return customVersionLookup();
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyLastVersion) ?? '';
  }
}
