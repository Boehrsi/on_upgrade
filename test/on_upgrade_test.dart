import 'package:flutter_test/flutter_test.dart';
import 'package:on_upgrade/on_upgrade.dart';

import 'utils/mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Initial check', () {
    test('Is initial', () async {
      final onUpgrade = OnUpgrade();
      mockSharedPreferences(<String, Object>{});

      var result = await onUpgrade.isInitialInstallation();

      expect(result, true);
    });

    test('Is not initial', () async {
      final onUpgrade = OnUpgrade();
      mockSharedPreferences(
          <String, Object>{onUpgrade.keyLastVersion: '0.0.1'});

      var result = await onUpgrade.isInitialInstallation();

      expect(result, false);
    });
  });

  group('Upgrade check', () {
    test('Is unknown, empty current version', () async {
      final onUpgrade = OnUpgrade();
      mockSharedPreferences(
          <String, Object>{onUpgrade.keyLastVersion: '0.0.1'});
      mockPackageInfo(
          appName: 'test',
          packageName: 'package.test',
          version: '',
          buildNumber: '2');

      var result = await onUpgrade.isNewVersion();

      expect(result.state, UpgradeState.unknown);
      expect(result.hasError, true);
      expect(result.error.runtimeType, FormatException);
      expect((result.error as FormatException).message,
          "Couldn't load currentVersion");
    });

    test('Is upgrade', () async {
      final onUpgrade = OnUpgrade();
      mockSharedPreferences(
          <String, Object>{onUpgrade.keyLastVersion: '0.0.1'});
      mockPackageInfo(
          appName: 'test',
          packageName: 'package.test',
          version: '0.0.2',
          buildNumber: '2');

      var result = await onUpgrade.isNewVersion();

      expect(result.state, UpgradeState.upgrade);
    });

    test('Is no upgrade', () async {
      final onUpgrade = OnUpgrade();
      mockSharedPreferences(
          <String, Object>{onUpgrade.keyLastVersion: '0.0.1'});
      mockPackageInfo(
          appName: 'test',
          packageName: 'package.test',
          version: '0.0.1',
          buildNumber: '1');

      var result = await onUpgrade.isNewVersion();

      expect(result.state, UpgradeState.noUpgrade);
    });
  });

  group('Last version update', () {
    test('Update without value', () async {
      final onUpgrade = OnUpgrade();
      mockPackageInfo(
          appName: 'test',
          packageName: 'package.test',
          version: '0.0.1',
          buildNumber: '1');

      final result = await onUpgrade.updateLastVersion();

      expect(result, true);
    });

    test('Update with value', () async {
      final onUpgrade = OnUpgrade();

      final result = await onUpgrade.updateLastVersion('0.0.3');

      expect(result, true);
    });
  });

  test('Get last version', () async {
    final onUpgrade = OnUpgrade();
    mockSharedPreferences(<String, Object>{onUpgrade.keyLastVersion: '0.0.1'});

    var result = await onUpgrade.getLastVersion();

    expect(result, '0.0.1');
  });

  test('Get current Version', () async {
    final onUpgrade = OnUpgrade();
    mockPackageInfo(
        appName: 'test',
        packageName: 'package.test',
        version: '0.0.1',
        buildNumber: '1');

    var result = await onUpgrade.getCurrentVersion();

    expect(result, '0.0.1');
  });

  test('Custom lookup / update last version', () async {
    Future<String> lookup() async => '1.0.0';
    Future<bool> update([String? version]) async => true;
    final onUpgrade =
        OnUpgrade(customVersionLookup: lookup, customVersionUpdate: update);

    var lookupResult = await onUpgrade.getLastVersion();
    var updateResult = await onUpgrade.updateLastVersion();

    expect(lookupResult, '1.0.0');
    expect(updateResult, true);
  });

  group('Upgrade execution', () {
    const v005 = '0.0.5';
    const v009 = '0.0.9';
    const v110 = '1.1.0';
    const v119 = '1.1.9';
    const v200 = '2.0.0';
    const v300 = '3.0.0';

    final functions = {
      v009: () => {},
      v110: () => {},
      v200: () => {},
    };

    test('Execute none', () async {
      final wrapper = UpgradeWrapper(
          state: UpgradeState.upgrade, lastVersion: v200, currentVersion: v300);

      final result = await wrapper.executeUpgrades(functions);

      expect(result == null, false);
      expect(result!.isEmpty, true);
    });

    test('Execute all', () async {
      final wrapper = UpgradeWrapper(
          state: UpgradeState.upgrade, lastVersion: v005, currentVersion: v200);

      final result = await wrapper.executeUpgrades(functions);

      expect(result == null, false);
      expect(result!.length, 3);
      expect(result[0], v009);
      expect(result[1], v110);
      expect(result[2], v200);
    });

    test('Execute all async, keep order', () async {
      final asyncResult = <String>[];
      final asyncFunctions = {
        v009: () => Future.delayed(
            const Duration(seconds: 2), () => asyncResult.add(v009)),
        v110: () => Future.delayed(
            const Duration(seconds: 1), () => asyncResult.add(v110)),
        v200: () => Future.delayed(
            const Duration(seconds: 0), () => asyncResult.add(v200)),
      };

      final wrapper = UpgradeWrapper(
          state: UpgradeState.upgrade, lastVersion: v005, currentVersion: v200);

      final result = await wrapper.executeUpgrades(asyncFunctions);

      expect(result == null, false);
      expect(result!.length, 3);
      expect(asyncFunctions.length, 3);
      expect(result[0], v009);
      expect(result[0] == asyncResult[0], true);
      expect(result[1], v110);
      expect(result[1] == asyncResult[1], true);
      expect(result[2], v200);
      expect(result[2] == asyncResult[2], true);
    });

    test('Execute some', () async {
      final wrapper = UpgradeWrapper(
          state: UpgradeState.upgrade, lastVersion: v009, currentVersion: v119);

      final result = await wrapper.executeUpgrades(functions);

      expect(result == null, false);
      expect(result!.length, 1);
      expect(result[0], v110);
    });

    test('Execute none, no upgrade', () async {
      final wrapper = UpgradeWrapper(
          state: UpgradeState.noUpgrade,
          lastVersion: v009,
          currentVersion: v009);

      final result = await wrapper.executeUpgrades(functions);

      expect(result == null, false);
      expect(result!.length, 0);
    });

    test('Execute none, unknown', () async {
      final wrapper = UpgradeWrapper(state: UpgradeState.unknown);

      final result = await wrapper.executeUpgrades(functions);
      expect(result == null, true);
    });
  });

  test('Example code usable', () async {
    final onUpgrade = OnUpgrade();
    final isNewVersion = await onUpgrade.isNewVersion();
    if (isNewVersion.state == UpgradeState.upgrade) {
      myDataMigrationOrNewFeatureDialog(isNewVersion.currentVersion!);
      await onUpgrade.updateLastVersion();
    }

    final onUpgradeCustom = OnUpgrade(
        customVersionUpdate: customVersionSetter,
        customVersionLookup: customVersionGetter);
    final isCustomNewVersion = await onUpgradeCustom.isNewVersion();
    if (isCustomNewVersion.state == UpgradeState.upgrade) {
      myDataMigrationOrNewFeatureDialog(isCustomNewVersion.currentVersion!);
      await onUpgrade.updateLastVersion();
    }

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
  });
}
