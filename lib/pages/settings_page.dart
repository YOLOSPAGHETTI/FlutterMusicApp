import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_app/components/info_button_popup.dart';
import 'package:music_app/components/music_player_controls.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double fontSize = 18;

  List<String> orderOptions = [
    orderAlphabetically,
    orderChronolically,
    orderReverseChronolically
  ];

  List<String> orderOptionsYear = [
    orderChronolically,
    orderReverseChronolically
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, value, child) {
      return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text("Settings",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.secondary),
          ),
          body: Container(
              /*decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12)),*/
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(25),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Dark Mode",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontSize: fontSize)),
                          CupertinoSwitch(
                              value: value.isDarkMode,
                              onChanged: (changed) => value.toggleTheme())
                        ]),
                    const SizedBox(height: 20),
                    Text("Hide Songs With Empty Fields",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: fontSize)),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.hideSongsWithEmptyTitle,
                      onChanged: (changed) =>
                          value.toggleSetting(settingHideSongsWithEmptyTitle),
                      title: Text(columnTitle),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.hideSongsWithEmptyArtist,
                      onChanged: (changed) =>
                          value.toggleSetting(settingHideSongsWithEmptyArtist),
                      title: Text(columnArtist),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.hideSongsWithEmptyAlbum,
                      onChanged: (changed) =>
                          value.toggleSetting(settingHideSongsWithEmptyAlbum),
                      title: Text(columnAlbum),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.hideSongsWithEmptyGenre,
                      onChanged: (changed) =>
                          value.toggleSetting(settingHideSongsWithEmptyGenre),
                      title: Text(columnGenre),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.hideSongsWithEmptyYear,
                      onChanged: (changed) =>
                          value.toggleSetting(settingHideSongsWithEmptyYear),
                      title: Text(columnYear),
                    ),
                    const SizedBox(height: 20),
                    Text("Ignore Text in Sort",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: fontSize)),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.ignoreThe,
                      onChanged: (changed) =>
                          value.toggleSetting(settingIgnoreThe),
                      title: Text("The"),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.ignoreA,
                      onChanged: (changed) =>
                          value.toggleSetting(settingIgnoreA),
                      title: Text("A"),
                    ),
                    const SizedBox(height: 20),
                    Text("Show In Album List",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: fontSize)),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.viewArtistWithAlbum,
                      onChanged: (changed) =>
                          value.toggleSetting(settingViewArtistWithAlbum),
                      title: Text("Artist"),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: value.viewYearWithAlbum,
                      onChanged: (changed) =>
                          value.toggleSetting(settingViewYearWithAlbum),
                      title: Text("Year"),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Text("Sort Songs",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: fontSize)),
                      InfoButtonPopup(
                          title: "Sort Songs",
                          info:
                              "Sort songs either alphabetically or (reverse)chronolically by album, then by the sequence within that album. Note: The full song list within Simple Sort will always be sorted alphabetically.")
                    ]),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: DropdownButton<String>(
                          value: value.songOrderType,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            value.songOrderType = newValue!;
                          },
                          items: orderOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                        )),
                    const SizedBox(height: 20),
                    Text("Sort Albums",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: fontSize)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: DropdownButton<String>(
                          value: value.albumOrderType,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            value.albumOrderType = newValue!;
                          },
                          items: orderOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                        )),
                    const SizedBox(height: 20),
                    Text("Sort Years",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: fontSize)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: DropdownButton<String>(
                          value: value.yearOrderType,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            value.yearOrderType = newValue!;
                          },
                          items: orderOptionsYear.map((option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                        )),
                  ],
                ),
              )),
          bottomNavigationBar:
              Consumer<MusicProvider>(builder: (context, value, child) {
            return Visibility(
              visible:
                  value.currentQueueIndex != -1 && value.fullQueue.isNotEmpty,
              child: BottomAppBar(
                color: Theme.of(context).colorScheme.primary,
                shape: CircularNotchedRectangle(), // Optional for FAB notch
                child: MusicPlayerControls(value, musicProvider: value),
              ),
            );
          }));
    });
  }
}
