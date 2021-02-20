import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void mockSharedPreferences(Map<String, dynamic> values) {
  SharedPreferences.setMockInitialValues(values);
}

void mockPackageInfo({
  @required String appName,
  @required String packageName,
  @required String version,
  @required String buildNumber,
}) {
  PackageInfo.setMockInitialValues(version: version, appName: appName, buildNumber: buildNumber, packageName: packageName);
}
