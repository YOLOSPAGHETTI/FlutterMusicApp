import 'package:flutter/material.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/pages/configure_music_page.dart';
import 'package:music_app/pages/custom_sort_page.dart';
import 'package:music_app/pages/settings_page.dart';

class MusicPlayerDrawer extends StatelessWidget {
  final MusicProvider musicProvider;

  const MusicPlayerDrawer({super.key, required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Drawer(
            backgroundColor: Theme.of(context).colorScheme.surface,
            // child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                      height: 100,
                      child: DrawerHeader(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: Center(
                            child: Text("Music Player",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 24))),
                      )),
                  ExpansionTile(
                    title: Text("Simple Sort"),
                    tilePadding: const EdgeInsets.only(left: 25.0, right: 25.0),
                    childrenPadding: const EdgeInsets.only(left: 50.0),
                    collapsedShape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    children: [
                      ListTile(
                          title: Text(sortSongs),
                          onTap: () {
                            musicProvider.setSortSingle(sortSongs);
                            return Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text(sortArtists),
                          onTap: () {
                            musicProvider.setSortSingle(sortArtists);
                            return Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text(sortAlbums),
                          onTap: () {
                            musicProvider.setSortSingle(sortAlbums);
                            return Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text(sortGenres),
                          onTap: () {
                            musicProvider.setSortSingle(sortGenres);
                            return Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text(sortYears),
                          onTap: () {
                            musicProvider.setSortSingle(sortYears);
                            return Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text(sortDecades),
                          onTap: () {
                            musicProvider.setSortSingle(sortDecades);
                            return Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text(sortDateAdded),
                          onTap: () {
                            musicProvider.setSortSingle(sortDateAdded);
                            return Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text(sortFavorites),
                          onTap: () {
                            musicProvider.setSortSingle(sortFavorites);
                            return Navigator.pop(context);
                          }),
                    ],
                  ),
                  Divider(
                    color: Colors.grey[500],
                  ),
                  ListTile(
                      title: Text("Custom Sort"),
                      contentPadding: const EdgeInsets.only(left: 25.0),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CustomSortPage()));
                      }),
                  Divider(
                    color: Colors.grey[500],
                  ),
                  ListTile(
                      title: Text(tablePlaylists),
                      contentPadding: const EdgeInsets.only(left: 25.0),
                      onTap: () {
                        musicProvider.setSortSingle(tablePlaylists);
                        return Navigator.pop(context);
                      }),
                  Divider(
                    color: Colors.grey[500],
                  ),
                  ListTile(
                      title: Text("Settings"),
                      contentPadding: const EdgeInsets.only(left: 25.0),
                      onTap: () {
                        Navigator.pop(context);

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()));
                      }),
                  Divider(
                    color: Colors.grey[500],
                  ),
                  ListTile(
                      title: Text("Resync Music"),
                      contentPadding: const EdgeInsets.only(left: 25.0),
                      onTap: () {
                        Navigator.pop(context);

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ConfigureMusicPage(
                                      firstConfigure: false,
                                    )));
                      }),
                ],
              ),
            )));
  }
}
