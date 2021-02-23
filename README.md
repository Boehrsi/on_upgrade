[![Pub Version](https://img.shields.io/pub/v/on_upgrade)](https://pub.dev/packages/on_upgrade)
[![codecov](https://codecov.io/gh/Boehrsi/on_upgrade/branch/main/graph/badge.svg?token=7XPRP9UMLF)](https://codecov.io/gh/Boehrsi/on_upgrade)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/boehrsi/on_upgrade/Main)](https://github.com/Boehrsi/on_upgrade/actions)
[![GitHub](https://img.shields.io/github/license/boehrsi/on_upgrade)](https://github.com/Boehrsi/on_upgrade/blob/main/LICENSE)
[![likes](https://badges.bar/on_upgrade/likes)](https://pub.dev/packages/on_upgrade/score)
[![popularity](https://badges.bar/on_upgrade/popularity)](https://pub.dev/packages/on_upgrade/score)
[![pub points](https://badges.bar/on_upgrade/pub%20points)](https://pub.dev/packages/on_upgrade/score) 

# OnUpgrade

Local upgrade checker plugin for Flutter. Enables the developer to easily migrate data between upgrades or to show users a new features dialog.

## Features

A simple upgrade checker to migrate data between app updates or to display a change log with new features to your users.

- Contains a default implementation using the shared preferences of the platform to persist the last known version
- Minimal effort to check if an app update is given and to updated the persisted values
- Possibility to implement custom getters and setters for the persisted version interaction (e.g. if the last known app version is already available via a database)

## Usage

### Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  on_upgrade: ^0.1.1
```

More information on [pub.dev](https://pub.dev/packages/on_upgrade).

### Examples

For full examples please see the [example app](https://github.com/Boehrsi/on_upgrade/blob/main/example/lib/main.dart).

### Default Implementation

```dart
final onUpgrade = OnUpgrade();
final isNewVersion = await onUpgrade.isNewVersion();
if (isNewVersion.state == UpgradeState.upgrade) {
  await onUpgrade.updateLastVersion();
  myDataMigration(isNewVersion.currentVersion);
  myShowUserNewFeaturesDialog(isNewVersion.currentVersion);
}
```

### Custom Implementation

```dart
Future<String> _customVersionGetter() async {
    // Your implementation. Load the last known version.
    // Must return an empty string if no initial version is known (first app start, before calling updateLastVersion().
}

Future<bool> _customVersionSetter([String version]) async {
    // Your implementation. Update the last known version, after performing the upgrade check and starting all migration / information actions.
}

final onUpgradeCustom = OnUpgrade(customVersionUpdate: _customVersionSetter, customVersionLookup: _customVersionGetter);
final isNewVersion = await _onUpgradeCustom.isNewVersion();
if (isNewVersion.state == UpgradeState.upgrade) {
  await _onUpgradeCustom.updateLastVersion();
  myDataMigration(isNewVersion.currentVersion);
  myShowUserNewFeaturesDialog(isNewVersion.currentVersion);
}
```
