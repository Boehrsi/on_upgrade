import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test mocks
void mockSharedPreferences(Map<String, Object> values) {
  SharedPreferences.setMockInitialValues(values);
}

void mockPackageInfo({
  required String appName,
  required String packageName,
  required String version,
  required String buildNumber,
}) {
  PackageInfo.setMockInitialValues(
    version: version,
    appName: appName,
    buildNumber: buildNumber,
    packageName: packageName,
    buildSignature: 'mock',
  );
}

// Dummy methods
void myDataMigrationOrNewFeatureDialog(String currentVersion) {}

void myDataMigrationOrNewFeatureDialogForVersion1() {}

void myDataMigrationOrNewFeatureDialogForVersion15() {}

Future<String> customVersionGetter() async {
  return '';
}

Future<bool> customVersionSetter([String? version]) async {
  return true;
}
