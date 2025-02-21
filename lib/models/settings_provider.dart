import 'package:flutter/material.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/themes/dark_mode.dart';
import 'package:music_app/themes/light_mode.dart';

class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();

  factory SettingsProvider() => _instance;

  SettingsProvider._internal();

  DatabaseHelper db = DatabaseHelper();

  // Settings
  ThemeData _themeData = lightMode;
  bool _hideSongsWithEmptyTitle = true;
  bool _hideSongsWithEmptyArtist = true;
  bool _hideSongsWithEmptyAlbum = true;
  bool _hideSongsWithEmptyGenre = true;
  bool _hideSongsWithEmptyYear = true;
  bool _ignoreThe = true;
  bool _ignoreA = true;
  bool _viewArtistWithAlbum = true;
  bool _viewYearWithAlbum = true;
  String _songOrderType = orderChronologically;
  String _albumOrderType = orderChronologically;
  String _yearOrderType = orderChronologically;

  // Config Settings
  final List<String> _artistDelimiters = <String>[];
  final List<String> _genreDelimiters = <String>[];
  final Map<String, List<String>> _songIgnoreText = {};
  final Map<String, List<String>> _artistIgnoreText = {};

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;
  bool get hideSongsWithEmptyTitle => _hideSongsWithEmptyTitle;
  bool get hideSongsWithEmptyArtist => _hideSongsWithEmptyArtist;
  bool get hideSongsWithEmptyAlbum => _hideSongsWithEmptyAlbum;
  bool get hideSongsWithEmptyGenre => _hideSongsWithEmptyGenre;
  bool get hideSongsWithEmptyYear => _hideSongsWithEmptyYear;
  bool get ignoreThe => _ignoreThe;
  bool get ignoreA => _ignoreA;
  bool get viewArtistWithAlbum => _viewArtistWithAlbum;
  bool get viewYearWithAlbum => _viewYearWithAlbum;
  String get songOrderType => _songOrderType;
  String get albumOrderType => _albumOrderType;
  String get yearOrderType => _yearOrderType;

  List<String> get artistDelimiters => _artistDelimiters;
  List<String> get genreDelimiters => _genreDelimiters;
  Map<String, List<String>> get songIgnoreText => _songIgnoreText;
  Map<String, List<String>> get artistIgnoreText => _artistIgnoreText;

  set themeData(ThemeData themeData) {
    _themeData = themeData;

    notifyListeners();
  }

  set songOrderType(String songOrderType) {
    _songOrderType = songOrderType;

    notifyListeners();
  }

  set albumOrderType(String albumOrderType) {
    _albumOrderType = albumOrderType;

    notifyListeners();
  }

  set yearOrderType(String yearOrderType) {
    _yearOrderType = yearOrderType;

    notifyListeners();
  }

  void populateAllSettingsFromDatabase() async {
    String currentTheme = await getStringSettingFromDatabaseWithDefault(
        settingTheme, settingLightMode);
    if (currentTheme == settingLightMode) {
      themeData = lightMode;
    } else {
      themeData = darkMode;
    }

    _hideSongsWithEmptyArtist = await getBoolSettingFromDatabaseWithDefault(
        settingHideSongsWithEmptyArtist, _hideSongsWithEmptyArtist);

    _hideSongsWithEmptyAlbum = await getBoolSettingFromDatabaseWithDefault(
        settingHideSongsWithEmptyAlbum, _hideSongsWithEmptyAlbum);

    _hideSongsWithEmptyGenre = await getBoolSettingFromDatabaseWithDefault(
        settingHideSongsWithEmptyGenre, _hideSongsWithEmptyGenre);

    _hideSongsWithEmptyYear = await getBoolSettingFromDatabaseWithDefault(
        settingHideSongsWithEmptyYear, _hideSongsWithEmptyYear);

    _ignoreThe = await getBoolSettingFromDatabaseWithDefault(
        settingIgnoreThe, _ignoreThe);

    _ignoreA =
        await getBoolSettingFromDatabaseWithDefault(settingIgnoreA, _ignoreA);

    _viewArtistWithAlbum = await getBoolSettingFromDatabaseWithDefault(
        settingViewArtistWithAlbum, _viewArtistWithAlbum);

    _viewYearWithAlbum = await getBoolSettingFromDatabaseWithDefault(
        settingViewYearWithAlbum, _viewYearWithAlbum);

    _songOrderType = await getStringSettingFromDatabaseWithDefault(
        settingSongOrderType, _songOrderType);

    _albumOrderType = await getStringSettingFromDatabaseWithDefault(
        settingAlbumOrderType, _albumOrderType);

    _yearOrderType = await getStringSettingFromDatabaseWithDefault(
        settingYearOrderType, _yearOrderType);

    populateConfigSettingsFromDatabase();
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
      updateStringSettingInDatabase(settingTheme, settingDarkMode);
    } else {
      themeData = lightMode;
      updateStringSettingInDatabase(settingTheme, settingLightMode);
    }
  }

  void toggleSetting(String name) {
    toggleValueFromName(name);
    notifyListeners();
  }

  void toggleValueFromName(String name) {
    if (name == settingHideSongsWithEmptyTitle) {
      _hideSongsWithEmptyTitle = !_hideSongsWithEmptyTitle;
      updateBoolSettingInDatabase(name, _hideSongsWithEmptyTitle);
    } else if (name == settingHideSongsWithEmptyArtist) {
      _hideSongsWithEmptyArtist = !_hideSongsWithEmptyArtist;
      updateBoolSettingInDatabase(name, _hideSongsWithEmptyArtist);
    } else if (name == settingHideSongsWithEmptyAlbum) {
      _hideSongsWithEmptyAlbum = !_hideSongsWithEmptyAlbum;
      updateBoolSettingInDatabase(name, _hideSongsWithEmptyAlbum);
    } else if (name == settingHideSongsWithEmptyGenre) {
      _hideSongsWithEmptyGenre = !_hideSongsWithEmptyGenre;
      updateBoolSettingInDatabase(name, _hideSongsWithEmptyGenre);
    } else if (name == settingHideSongsWithEmptyYear) {
      _hideSongsWithEmptyYear = !_hideSongsWithEmptyYear;
      updateBoolSettingInDatabase(name, _hideSongsWithEmptyYear);
    } else if (name == settingIgnoreThe) {
      _ignoreThe = !_ignoreThe;
      updateBoolSettingInDatabase(name, _ignoreThe);
    } else if (name == settingIgnoreA) {
      _ignoreA = !_ignoreA;
      updateBoolSettingInDatabase(name, _ignoreA);
    } else if (name == settingViewArtistWithAlbum) {
      _viewArtistWithAlbum = !_viewArtistWithAlbum;
      updateBoolSettingInDatabase(name, _viewArtistWithAlbum);
    } else if (name == settingViewYearWithAlbum) {
      _viewYearWithAlbum = !_viewYearWithAlbum;
      updateBoolSettingInDatabase(name, _viewYearWithAlbum);
    }
  }

  void updateBoolSettingInDatabase(String name, bool value) {
    updateStringSettingInDatabase(name, value.toString());
  }

  void updateStringSettingInDatabase(String name, String value) async {
    String currentSetting = await db.easyShortQuery(
        tableSettings, columnSetting, "$columnName = ?", name);

    Map<String, String> data = {};
    data[columnSetting] = value;
    if (currentSetting.isNotEmpty) {
      db.updateSetting(name, data);
    } else {
      data[columnName] = name;
      db.insert(tableSettings, data);
    }
  }

  Future<bool> getBoolSettingFromDatabaseWithDefault(
      String name, bool def) async {
    return (await getStringSettingFromDatabaseWithDefault(
                name, def.toString()) ==
            "true"
        ? true
        : false);
  }

  Future<String> getStringSettingFromDatabaseWithDefault(
      String name, String def) async {
    String currentSetting = await db.easyShortQuery(
        tableSettings, columnSetting, "$columnName = ?", name);

    if (currentSetting.isNotEmpty) {
      return currentSetting;
    }
    return def;
  }

  void populateConfigSettings(
      List<String> artistDelimiters,
      List<String> genreDelimiters,
      Map<String, List<String>> songIgnoreText,
      Map<String, List<String>> artistIgnoreText) async {
    _artistDelimiters.clear();
    _artistDelimiters.addAll(artistDelimiters);

    _genreDelimiters.clear();
    _genreDelimiters.addAll(genreDelimiters);

    _songIgnoreText.clear();
    _songIgnoreText.addAll(songIgnoreText);

    _artistIgnoreText.clear();
    _artistIgnoreText.addAll(artistIgnoreText);

    await db.customQuery("DELETE FROM $tableSeparateFieldSettings", []);
    await db.customQuery("DELETE FROM $tableFieldContainerSettings", []);
    for (String delimiter in artistDelimiters) {
      Map<String, String> data = {};
      data[columnField] = columnArtist;
      data[columnDelimiter] = delimiter;
      await db.insert(tableSeparateFieldSettings, data);
    }

    for (String delimiter in genreDelimiters) {
      Map<String, String> data = {};
      data[columnField] = columnGenre;
      data[columnDelimiter] = delimiter;
      await db.insert(tableSeparateFieldSettings, data);
    }

    for (String container in songIgnoreText.keys) {
      List<String> ignoreTextList = songIgnoreText[container]!;
      for (String ignoreText in ignoreTextList) {
        Map<String, String> data = {};
        data[columnField] = columnTitle;
        data[columnContainer] = container;
        data[columnIgnoreText] = ignoreText;
        await db.insert(tableFieldContainerSettings, data);
      }
    }

    for (String container in artistIgnoreText.keys) {
      List<String> ignoreTextList = artistIgnoreText[container]!;
      for (String ignoreText in ignoreTextList) {
        Map<String, String> data = {};
        data[columnField] = columnArtist;
        data[columnContainer] = container;
        data[columnIgnoreText] = ignoreText;
        await db.insert(tableFieldContainerSettings, data);
      }
    }
  }

  void populateConfigSettingsFromDatabase() async {
    List<Map<String, Object?>> resultsSeparateField =
        await db.customQuery("SELECT * FROM $tableSeparateFieldSettings", []);
    List<Map<String, Object?>> resultsFieldContainer =
        await db.customQuery("SELECT * FROM $tableFieldContainerSettings", []);

    for (Map<String, Object?> row in resultsSeparateField) {
      if (row[columnField].toString() == columnArtist) {
        artistDelimiters.add(row[columnDelimiter].toString());
      } else if (row[columnField] == columnGenre) {
        genreDelimiters.add(row[columnDelimiter].toString());
      }
    }

    for (Map<String, Object?> row in resultsFieldContainer) {
      String container = row[columnContainer].toString();
      if (row[columnField].toString() == columnTitle) {
        if (!songIgnoreText.containsKey(container)) {
          songIgnoreText[container] = <String>[];
        }
        songIgnoreText[container]!.add(row[columnIgnoreText].toString());
      } else if (row[columnField].toString() == columnArtist) {
        artistIgnoreText[container]!.add(row[columnIgnoreText].toString());
      }
    }
  }
}
