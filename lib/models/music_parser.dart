class MusicParser {
  final String artistText;
  final String songText;
  final String genreText;

  const MusicParser(
      {required this.artistText,
      required this.songText,
      required this.genreText});

  List<String> getArtists(
      List<String> delimiters,
      List<String> songContainers,
      Map<String, List<String>> songContainerIgnore,
      List<String> artistContainers,
      Map<String, List<String>> artistContainerIgnore) {
    List<String> artists = <String>[];

    if (songText.isNotEmpty) {
      artists.addAll(getArtistsFromContainer(
          songText, delimiters, songContainers, songContainerIgnore));
      //print("getArtists::getArtistsFromContainer: $artists");
    }

    if (artistText.isNotEmpty) {
      artists.addAll(splitByDelimiters(artistText, delimiters));
      //print("getArtists::splitByDelims: $artists");
      artists.addAll(getArtistsFromContainer(
          artistText, delimiters, artistContainers, artistContainerIgnore));
    }

    return artists;
  }

  List<String> getGenres(List<String> delimiters) {
    List<String> genres = <String>[];
    if (genreText.isNotEmpty) {
      genres = splitByDelimiters(genreText, delimiters);
    }

    return genres;
  }

  List<String> splitByDelimiters(String text, List<String> delimiters) {
    List<String> items = <String>[];
    String regexString = '[';
    for (String delimiter in delimiters) {
      regexString += RegExp.escape(delimiter);
    }
    regexString += ']';
    RegExp regex = RegExp(regexString);

    items = text.split(regex).map((item) => item.trim()).toList();

    return items;
  }

  List<String> getArtistsFromContainer(String text, List<String> delimiters,
      List<String> containers, Map<String, List<String>> textIgnore) {
    List<String> artistsFromContainer = <String>[];
    List<String> artists = <String>[];

    for (String container in containers) {
      String open = RegExp.escape(container[0]);
      String close = RegExp.escape(container[1]);
      String regexString = '$open([^)]+)$close';
      RegExp regex = RegExp(regexString);

      // Find all matches
      Iterable<RegExpMatch> matches = regex.allMatches(text);
      List<String> items = matches.map((match) => match.group(1)!).toList();
      for (String item in items) {
        List<String> ignoreList = textIgnore[container]!;
        for (String ignore in ignoreList) {
          String artist = item.replaceAll(ignore, "");
          if (artist.isNotEmpty) {
            artistsFromContainer.add(artist);
          }
        }
      }
    }
    for (String artist in artistsFromContainer) {
      artists = splitByDelimiters(artist, delimiters);
    }
    return artists;
  }
}
