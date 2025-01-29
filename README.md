[![Pub Version](https://img.shields.io/pub/v/on_upgrade)](https://pub.dev/packages/on_upgrade)
[![codecov](https://codecov.io/gh/Boehrsi/on_upgrade/branch/main/graph/badge.svg?token=7XPRP9UMLF)](https://codecov.io/gh/Boehrsi/on_upgrade)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/Boehrsi/on_upgrade/main.yml)](https://github.com/Boehrsi/on_upgrade/actions)
[![GitHub](https://img.shields.io/github/license/boehrsi/on_upgrade)](https://github.com/Boehrsi/on_upgrade/blob/main/LICENSE)
[![likes](https://img.shields.io/pub/likes/on_upgrade)](https://pub.dev/packages/on_upgrade/score)
[![pub downloads](https://img.shields.io/pub/dm/on_upgrade)](https://pub.dev/packages/on_upgrade/score)
[![pub points](https://img.shields.io/pub/points/on_upgrade)](https://pub.dev/packages/on_upgrade/score)

# OnUpgrade

A simple upgrade checker plugin, to e.g. migrate data between app upgrades or to display a change log with new features to your users.

<a href="https://idx.google.com/import?url=https://github.com/Boehrsi/on_upgrade">
  <picture>
    <source
      media="(prefers-color-scheme: dark)"
      srcset="https://cdn.idx.dev/btn/open_dark_32.svg">
    <source
      media="(prefers-color-scheme: light)"
      srcset="https://cdn.idx.dev/btn/open_light_32.svg">
    <img
      height="32"
      alt="Open in IDX"
      src="https://cdn.idx.dev/btn/open_purple_32.svg">
  </picture>
</a>

## Features

- Contains a default implementation using the shared preferences of the platform to persist the last known version
- Minimal effort to check if an app upgrade is given and to update the persisted value
- Possibility to implement custom getters and setters for the persisted version (e.g. if the last known app version is already available via a database)
- Helper to easily execute all fitting / relevant upgrades

## Usage

### Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  on_upgrade: ^1.2.0
```

More information on [pub.dev](https://pub.dev/packages/on_upgrade).

### Examples

For full examples please see the [example app](https://github.com/Boehrsi/on_upgrade/blob/main/example/lib/main.dart).

### Default Implementation

```dart
final onUpgrade = OnUpgrade();
final isNewVersion = await onUpgrade.isNewVersion();
if (isNewVersion.state == UpgradeState.upgrade) {
  myDataMigrationOrNewFeatureDialog(isNewVersion.currentVersion!);
  await onUpgrade.updateLastVersion();
}

void myDataMigrationOrNewFeatureDialog(String version) {
  ...
}
```

#### Execute managed / multiple upgrades

```dart
final upgrades = {
  '1.0.0': myDataMigrationOrNewFeatureDialogForVersion1,
  '1.5.0': myDataMigrationOrNewFeatureDialogForVersion15
};

final onMultipleUpgrade = OnUpgrade();
final isNewVersionMultiple = await onMultipleUpgrade.isNewVersion();
if (isNewVersionMultiple.state == UpgradeState.upgrade) {
  await isNewVersionMultiple.executeUpgrades(upgrades);
  await onMultipleUpgrade.updateLastVersion();
}

Future<void> myDataMigrationOrNewFeatureDialogForVersion1() async {
  // Upgrade method can be async
}

void myDataMigrationOrNewFeatureDialogForVersion15() {
  // Upgrade method can be sync
}
```

### Custom Implementation

```dart
Future<String> customVersionGetter() async {
    // Your implementation. Load the last known version.
    // Must return an empty string if no initial version is known (on the first app start, before updateLastVersion() was called the first time).
}

Future<bool> customVersionSetter([String? version]) async {
    // Your implementation. Update the last known version.
    // Perform the upgrade check before calling this function.
}

final onUpgradeCustom = OnUpgrade(customVersionUpdate: customVersionSetter, customVersionLookup: customVersionGetter);
final isCustomNewVersion = await onUpgradeCustom.isNewVersion();
if (isCustomNewVersion.state == UpgradeState.upgrade) {
  myDataMigrationOrNewFeatureDialog(isCustomNewVersion.currentVersion!);
  await onUpgrade.updateLastVersion();
}

void myDataMigrationOrNewFeatureDialog(String version) {
  ...
}
```

## How to contribute

If you are interested in contributing, please have a look into the [contribution guide](https://github.com/Boehrsi/on_upgrade/blob/main/CONTRIBUTING.md). Every idea, bug report or line of code is heavily appreciated.
