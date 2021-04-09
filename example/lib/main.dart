import 'package:flutter/material.dart';
import 'package:on_upgrade/on_upgrade.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'On Upgrade Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(title: 'On Upgrade Example'),
    );
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _onUpgrade = OnUpgrade();
  OnUpgrade _onUpgradeCustom;

  String _lastVersion;
  String _customLastVersion = '';
  String _currentVersion;
  var _multipleUpgradeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _onUpgradeCustom = OnUpgrade(
        customVersionUpdate: _customVersionSetter,
        customVersionLookup: _customVersionGetter);

    _showLastVersion();
    _showCurrentVersion();
  }

  void _showLastVersion() {
    _onUpgrade.getLastVersion().then((value) {
      setState(() {
        _lastVersion = value;
      });
    });
    _onUpgradeCustom.getLastVersion().then((value) {
      setState(() {
        _customLastVersion = value;
      });
    });
  }

  void _showCurrentVersion() {
    _onUpgrade.getCurrentVersion().then((value) {
      setState(() {
        _currentVersion = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Known version (survives app restart): $_lastVersion'),
            Text('Current version: $_currentVersion'),
            OutlinedButton(
              onPressed: _checkAndUpdateVersion,
              child: Text('Check and update version'),
            ),
            OutlinedButton(
              onPressed: _executeMultipleUpgrades,
              child: Text('Check and execute multiple upgrades'),
            ),
            Visibility(
              visible: _multipleUpgradeProgress > 0.0,
              child: LinearProgressIndicator(value: _multipleUpgradeProgress),
            ),
            OutlinedButton(
              onPressed: _resetLastVersion,
              child: Text('Reset last version'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Divider(),
            ),
            Text('Known custom version: $_customLastVersion'),
            Text('Current version: $_currentVersion'),
            OutlinedButton(
              onPressed: _checkAndUpdateCustomVersion,
              child: Text('Check and update custom version'),
            ),
            OutlinedButton(
              onPressed: _resetCustomLastVersion,
              child: Text('Reset custom last version'),
            ),
          ],
        ),
      ),
    );
  }

  // Default usage example

  Future<void> _checkAndUpdateVersion() async {
    final isNewVersion = await _onUpgrade.isNewVersion();
    if (isNewVersion.state == UpgradeState.upgrade) {
      await _onUpgrade.updateLastVersion();
      _showLastVersion();
      _showSnackbar('An upgrade was detected.');
    } else {
      _showSnackbar('No upgrade.');
    }
  }

  Future<void> _executeMultipleUpgrades() async {
    final upgrades = {
      '0.0.5': () async {
        setState(() => _multipleUpgradeProgress = 0.1);
        await Future.delayed(Duration(seconds: 2),
            () => setState(() => _multipleUpgradeProgress = 0.5));
        _showSnackbar('0.0.5 migration done');
      },
      '0.5.0': () async {
        await Future.delayed(Duration(seconds: 3),
            () => setState(() => _multipleUpgradeProgress = 1));
        _showSnackbar('0.5.0 migration done');
        await Future.delayed(Duration(seconds: 2), () {});
      },
      '1.0.0': () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('1.0.0 - Nothing new'),
            content: Text('We just added more ads!'),
          ),
        );
      },
      '2.0.0': () {
        // Shouldn't get executed
        throw AssertionError("This method shouldn't get executed");
      },
    };

    final isNewVersion = await _onUpgrade.isNewVersion();
    if (isNewVersion.state == UpgradeState.upgrade) {
      await isNewVersion.executeUpgrades(upgrades);
      await _onUpgrade.updateLastVersion();
      _showLastVersion();
    } else {
      _showSnackbar('No upgrade.');
    }
  }

  // Custom implementation example

  // Loading the last version, e.g. from the database
  Future<String> _customVersionGetter() async {
    return Future.delayed(const Duration(milliseconds: 500), () {
      return _customLastVersion;
    });
  }

  // Saving the version, e.g. to a database
  Future<bool> _customVersionSetter([String version]) async {
    return Future.delayed(const Duration(milliseconds: 500), () async {
      if (version != null) {
        _customLastVersion = version;
      } else {
        final currentVersion = await _onUpgradeCustom.getCurrentVersion();
        _customLastVersion = currentVersion;
      }
      return true;
    });
  }

  // Custom usage example

  Future<void> _checkAndUpdateCustomVersion() async {
    final isNewVersion = await _onUpgradeCustom.isNewVersion();
    if (isNewVersion.state == UpgradeState.upgrade) {
      await _onUpgradeCustom.updateLastVersion();
      _showLastVersion();
      _showSnackbar('A custom upgrade was detected.');
    } else {
      _showSnackbar('No custom upgrade.');
    }
  }

  // Helpers

  void _showSnackbar(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(content: Text(text));
    ScaffoldMessenger.of(context).showSnackBar((snackBar));
  }

  Future<void> _resetLastVersion() async {
    await _onUpgrade.updateLastVersion('');
    _showLastVersion();
    _resetMultipleProgress();
  }

  void _resetMultipleProgress() =>
      setState(() => _multipleUpgradeProgress = 0.0);

  Future<void> _resetCustomLastVersion() async {
    await _onUpgradeCustom.updateLastVersion('');
    _showLastVersion();
  }
}
