/// Provides the ability to check if the currently started app is an upgrade.
///
/// An upgrade is defined as the first start of a new app version, compared to the last known version.
/// All versions should follow the [Dart package versioning guidelines](https://dart.dev/tools/pub/versioning).
///
/// Can be used with the given persistence implementation (shared preferences) or with a custom implementation of the getter / setter logic
/// for the last known version. The currently running app version is always determined by the version loaded via
/// [package_info_plus](https://pub.dev/packages/package_info_plus).
library on_upgrade;

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
  final String? lastVersion;
  final String? currentVersion;
  final bool hasError;
  final Exception? error;

  UpgradeWrapper(
      {required this.state,
      this.lastVersion,
      this.currentVersion,
      this.hasError = false,
      this.error});

  /// Wraps the upgrade execution
  ///
  /// Provide a sorted (oldest to newest version) map of version strings and executable methods in [upgrades] (e.g. `<String, Function>{'0.0.9': yourFunction}`).
  /// All string / method pairs fitting into the upgrade range will be executed (minimal version exclusive, maximal version inclusive).
  /// This method is `async` to allow e.g. database operations. All upgrade methods will be executed `async` in the given order.
  ///
  /// Returns a list of executed version strings. An empty list means no upgrades were performed. A `null` value is returned if the [UpgradeWrapper] wasn't
  /// in a valid state during execution.
  Future<List<String>?> executeUpgrades(Map<String, Function> upgrades) async {
    if (state == UpgradeState.upgrade) {
      final upgradesCopy = {...upgrades};
      final lastVersion = Version.parse(this.lastVersion!);
      final currentVersion = Version.parse(this.currentVersion!);
      final range =
          VersionRange(min: lastVersion, max: currentVersion, includeMax: true);

      upgradesCopy
          .removeWhere((key, value) => !range.allows(Version.parse(key)));
      await Future.forEach(
          upgradesCopy.values, (Function upgrade) async => await upgrade());
      return upgradesCopy.keys.toList();
    } else if (state == UpgradeState.noUpgrade) {
      return <String>[];
    } else {
      return null;
    }
  }
}

/// Custom version lookup with the signature `Future<String> func() async {}`. Must return an empty string if no last version is given during initial start.
typedef VersionLookup = Future<String> Function();

/// Custom version update with the signature `Future<bool> func([String? version]) async {}`. Use `OnUpgrade().getCurrentVersionString` to get the currently running app version.
typedef VersionUpdate = Future<bool> Function([String? version]);

/// Contains the upgrade check functionality
///
/// The last know version must be set via [updateLastVersion].
///
/// Usage with default implementation:
/// ```dart
/// final onUpgrade = OnUpgrade();
/// final isNewVersion = await onUpgrade.isNewVersion();
/// if (isNewVersion.state == UpgradeState.upgrade) {
/// myDataMigrationOrNewFeatureDialog(isNewVersion.currentVersion!);
/// await onUpgrade.updateLastVersion();
/// }
/// ```
class OnUpgrade {
  static const _fallbackVersion = '0.0.0';

  /// Configures a custom key used in the shared preferences. Defaults to `on_upgrade.version`
  final String keyLastVersion;

  /// Optional last version getter. If set [keyLastVersion] isn't used and [customVersionUpdate] is required to be also set.
  final VersionLookup? customVersionLookup;

  /// Optional last version setter. If set [keyLastVersion] isn't used and [customVersionLookup] is required to be also set
  final VersionUpdate? customVersionUpdate;

  OnUpgrade(
      {this.keyLastVersion = 'on_upgrade.version',
      this.customVersionLookup,
      this.customVersionUpdate});

  /// Returns the upgrade state.
  Future<UpgradeWrapper> isNewVersion() async {
    try {
      final lastVersion = await getLastVersion();
      final currentVersion = await getCurrentVersion();
      final state = _checkNewVersion(lastVersion, currentVersion)
          ? UpgradeState.upgrade
          : UpgradeState.noUpgrade;
      return UpgradeWrapper(
          state: state,
          lastVersion: lastVersion,
          currentVersion: currentVersion);
    } on Exception catch (exception) {
      return UpgradeWrapper(
          state: UpgradeState.unknown, hasError: true, error: exception);
    }
  }

  /// Returns if the current app start is the first start overall.
  Future<bool> isInitialInstallation() async {
    final version = await _getLastVersionString();
    return version.isEmpty;
  }

  /// Returns the last known version or '0.0.0' as initial fallback value. Call [updateLastVersion] to update this value
  Future<String> getLastVersion() async {
    final version = await _getLastVersionString();
    return version.isNotEmpty ? version : _fallbackVersion;
  }

  /// Returns the currently running version
  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Sets the last know version and persists it. If called without parameter the currently running version is set.
  Future<bool> updateLastVersion([String? version]) async {
    if (customVersionUpdate != null) {
      return customVersionUpdate!(version);
    }
    version ??= await getCurrentVersion();
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(keyLastVersion, version);
  }

  Future<String> _getLastVersionString() async {
    if (customVersionLookup != null) {
      return customVersionLookup!();
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyLastVersion) ?? '';
  }

  bool _checkNewVersion(String lastVersionString, String currentVersionString) {
    if (currentVersionString.isEmpty) {
      throw const FormatException("Couldn't load currentVersion");
    }
    final lastVersion = Version.parse(lastVersionString);
    final currentVersion = Version.parse(currentVersionString);
    return lastVersion.compareTo(currentVersion) == -1;
  }
}
