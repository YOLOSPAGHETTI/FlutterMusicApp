import 'package:flutter/material.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/themes/dark_mode.dart';
import 'package:music_app/themes/light_mode.dart';

class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();

  factory SettingsProvider() => _instance;

  SettingsProvider._internal();

  ThemeData _themeData = lightMode;
  bool _hideSongsWithEmptyTitle = true;
  bool _hideSongsWithEmptyArtist = true;
  bool _hideSongsWithEmptyAlbum = true;
  bool _hideSongsWithEmptyGenre = true;
  bool _hideSongsWithEmptyYear = true;
  bool _ignoreThe = true; // implemented
  bool _ignoreA = true; // implemented
  bool _viewArtistWithAlbum = true;
  bool _viewYearWithAlbum = true;
  String _songOrderType = orderChronologically;
  String _albumOrderType = orderChronologically;
  String _yearOrderType = orderChronologically;

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

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }

  void toggleSetting(String name) {
    toggleValueFromName(name);
    notifyListeners();
  }

  void toggleValueFromName(String name) {
    if (name == settingHideSongsWithEmptyTitle) {
      _hideSongsWithEmptyTitle = !_hideSongsWithEmptyTitle;
      updateBooleanSettingInDatabase(name, _hideSongsWithEmptyTitle);
    } else if (name == settingHideSongsWithEmptyArtist) {
      _hideSongsWithEmptyArtist = !_hideSongsWithEmptyArtist;
      updateBooleanSettingInDatabase(name, _hideSongsWithEmptyArtist);
    } else if (name == settingHideSongsWithEmptyAlbum) {
      _hideSongsWithEmptyAlbum = !_hideSongsWithEmptyAlbum;
      updateBooleanSettingInDatabase(name, _hideSongsWithEmptyAlbum);
    } else if (name == settingHideSongsWithEmptyGenre) {
      _hideSongsWithEmptyGenre = !_hideSongsWithEmptyGenre;
      updateBooleanSettingInDatabase(name, _hideSongsWithEmptyGenre);
    } else if (name == settingHideSongsWithEmptyYear) {
      _hideSongsWithEmptyYear = !_hideSongsWithEmptyYear;
      updateBooleanSettingInDatabase(name, _hideSongsWithEmptyYear);
    } else if (name == settingIgnoreThe) {
      _ignoreThe = !_ignoreThe;
      updateBooleanSettingInDatabase(name, _ignoreThe);
    } else if (name == settingIgnoreA) {
      _ignoreA = !_ignoreA;
      updateBooleanSettingInDatabase(name, _ignoreA);
    } else if (name == settingViewArtistWithAlbum) {
      _viewArtistWithAlbum = !_viewArtistWithAlbum;
      updateBooleanSettingInDatabase(name, _viewArtistWithAlbum);
    } else if (name == settingViewYearWithAlbum) {
      _viewYearWithAlbum = !_viewYearWithAlbum;
      updateBooleanSettingInDatabase(name, _viewYearWithAlbum);
    }
  }

  void updateBooleanSettingInDatabase(String name, bool value) {
    updateStringSettingInDatabase(name, value.toString());
  }

  void updateStringSettingInDatabase(String name, String value) async {
    DatabaseHelper db = DatabaseHelper();
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
}
