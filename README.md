# OnUpgrade

Local upgrade checker plugin for Flutter. Enables the developer to easily migrate data between upgrades or to show users a new features dialog.

## Features

A simple upgrade checker to migrate data between app updates or to display a change log with new features to your users.

- Contains a default implementation using the shared preferences of the platform to persist the last known version
- Minimal effort to check if an app update is given and to updated the persisted values
- Possibility to implement custom getters and setters for the persisted version interaction (e.g. if the last known app version is already available via a database)

## Usage

For full examples please see the [example app](https://github.com/Boehrsi/on_upgrade/blob/main/example/lib/main.dart).

### Default implementation

```dart
final onUpgrade = OnUpgrade();
final isNewVersion = await onUpgrade.isNewVersion();
if (isNewVersion.state == UpgradeState.upgrade) {
  await onUpgrade.updateLastVersion();
  myDataMigration(isNewVersion.currentVersion);
  myShowUserNewFeaturesDialog(isNewVersion.currentVersion);
}
```

### Custom implementation

```dart
Future<String> _customVersionGetter() async {
    // Your implementation
}

Future<bool> _customVersionSetter([String version]) async {
    // Your implementation
}

final onUpgradeCustom = OnUpgrade(customVersionUpdate: _customVersionSetter, customVersionLookup: _customVersionGetter);
final isNewVersion = await _onUpgradeCustom.isNewVersion();
if (isNewVersion.state == UpgradeState.upgrade) {
  await _onUpgradeCustom.updateLastVersion();
  myDataMigration(isNewVersion.currentVersion);
  myShowUserNewFeaturesDialog(isNewVersion.currentVersion);
}
```