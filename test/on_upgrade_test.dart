import 'package:flutter_test/flutter_test.dart';
import 'package:on_upgrade/on_upgrade.dart';

import 'utils/mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Is initial', () async {
    final onUpgrade = OnUpgrade();
    mockSharedPreferences(<String, dynamic>{});

    var result = await onUpgrade.isInitialInstallation();

    expect(result, true);
  });

  test('Is not initial', () async {
    final onUpgrade = OnUpgrade();
    mockSharedPreferences(<String, dynamic>{onUpgrade.keyLastVersion: '0.0.1'});

    var result = await onUpgrade.isInitialInstallation();

    expect(result, false);
  });

  test('Is unknown', () async {
    final onUpgrade = OnUpgrade();
    mockSharedPreferences(<String, dynamic>{onUpgrade.keyLastVersion: '0.0.1'});

    var result = await onUpgrade.isNewVersion();

    expect(result.state, UpgradeState.unknown);
    expect(result.hasError, true);
  });

  test('Is upgrade', () async {
    final onUpgrade = OnUpgrade();
    mockSharedPreferences(<String, dynamic>{onUpgrade.keyLastVersion: '0.0.1'});
    mockPackageInfo(appName: 'test', packageName: 'package.test', version: '0.0.2', buildNumber: '2');

    var result = await onUpgrade.isNewVersion();

    expect(result.state, UpgradeState.upgrade);
  });

  test('Is no upgrade', () async {
    final onUpgrade = OnUpgrade();
    mockSharedPreferences(<String, dynamic>{onUpgrade.keyLastVersion: '0.0.1'});
    mockPackageInfo(appName: 'test', packageName: 'package.test', version: '0.0.1', buildNumber: '1');

    var result = await onUpgrade.isNewVersion();

    expect(result.state, UpgradeState.noUpgrade);
  });

  test('Update last version', () async {
    final onUpgrade = OnUpgrade();

    final result = await onUpgrade.updateLastVersion('0.0.3');

    expect(result, true);
  });

  test('Get last version', () async {
    final onUpgrade = OnUpgrade();
    mockSharedPreferences(<String, dynamic>{onUpgrade.keyLastVersion: '0.0.1'});

    var result = await onUpgrade.getLastVersion();

    expect(result, '0.0.1');
  });

  test('Get current Version', () async {
    final onUpgrade = OnUpgrade();
    mockPackageInfo(appName: 'test', packageName: 'package.test', version: '0.0.1', buildNumber: '1');

    var result = await onUpgrade.getCurrentVersion();

    expect(result, '0.0.1');
  });

  test('Custom lookup / update last version', () async {
    Future<bool> update([String version]) async => true;
    Future<String> lookup() async => '1.0.0';
    final onUpgrade = OnUpgrade(customVersionLookup: lookup, customVersionUpdate: update);

    var lookupResult = await onUpgrade.getLastVersion();
    var updateResult = await onUpgrade.updateLastVersion();

    expect(lookupResult, '1.0.0');
    expect(updateResult, true);
  });
}
