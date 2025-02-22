// Component Sizing
final double listTileHeight = 70;
final double listFieldHeight = 70;

// Lazy List
final int loadIncrement = 100;

// Data
const String undefinedTag = "<UNDEFINED>";

// Sidebars
const List<String> alphabet = [
  '#',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

// Do this dynamically from db?
const List<String> decades = [
  '192-',
  '193-',
  '194-',
  '195-',
  '196-',
  '197-',
  '198-',
  '199-',
  '200-',
  '201-',
  '202-',
];

// Containers
const String parentheses = "()";
const String brackets = "[]";
const String curlyBraces = "{}";
const List<String> containers = [parentheses, brackets, curlyBraces];

// Sort Fields
const List<String> sortFields = [
  "",
  sortArtists,
  sortAlbums,
  sortGenres,
  sortYears,
  sortDecades,
  sortDateAdded,
  sortPlaylists
];

const Map<String, String> sortToColumn = {
  sortArtists: columnArtist,
  sortAlbums: columnAlbum,
  sortGenres: columnGenre,
  sortYears: columnYear,
  sortDateAdded: columnModifiedDate,
  sortPlaylists: columnName
};

// Settings
const String settingTheme = "theme";
const String settingLightMode = "lightMode";
const String settingDarkMode = "darkMode";

const String settingHideSongsWithEmptyTitle = "hideSongsWithEmptyTitle";
const String settingHideSongsWithEmptyArtist = "hideSongsWithEmptyArtist";
const String settingHideSongsWithEmptyAlbum = "hideSongsWithEmptyAlbum";
const String settingHideSongsWithEmptyGenre = "hideSongsWithEmptyGenre";
const String settingHideSongsWithEmptyYear = "hideSongsWithEmptyYear";
const String settingIgnoreThe = "ignoreThe";
const String settingIgnoreA = "ignoreA";
const String settingViewArtistWithAlbum = "viewArtistWithAlbum";
const String settingViewYearWithAlbum = "viewYearWithAlbum";
const String settingSongOrderType = "songOrderType";
const String settingAlbumOrderType = "albumOrderType";
const String settingYearOrderType = "yearOrderType";

// Order Types
const String orderAlphabetically = "Alphabetically";
const String orderChronologically = "Chronologically";
const String orderReverseChronologically = "Reverse Chronologically";

const quickSortMinimumLimit = 5;

// Sort
const String sortSongs = "Songs";
const String sortArtists = "Artists";
const String sortAlbums = "Albums";
const String sortGenres = "Genres";
const String sortYears = "Years";
const String sortDecades = "Decades";
const String sortDateAdded = "Date Added";
const String sortFavorites = "Favorites";
const String sortPlaylists = "Playlists";

// Error Messages
const String missingPlaylistNameErrorMessage =
    "Please give the playlist a name.";
const String duplicatePlaylistNameErrorMessage =
    "A playlist with this name already exists.";

// DB
const int bulkInsertSize = 100;

// Table and column names
// Songs
const String tableSongs = 'Songs';
const String columnId = 'Id';
const String columnTitle = 'Title';
const String columnAlbum = 'Album';
const String columnArtist = 'Artist';
const String columnAlbumArtist = 'AlbumArtist';
const String columnGenre = 'Genre';
const String columnYear = 'Year';
const String columnSource = 'Source';
const String columnTrackNumber = 'TrackNumber';
const String columnTotalTrackCount = 'TotalTrackCount';
const String columnDuration = 'Duration';
const String columnModifiedDate = 'ModifiedDate';
const String columnAlbumArt = 'AlbumArt';
const String columnFavorite = 'IsFavorite';

// Artists
const String tableArtists = 'Artists';

// Albums
const String tableAlbums = 'Albums';

// Genres
const String tableGenres = 'Genres';

// SongArtists
const String tableSongArtists = 'SongArtists';
const String columnSongId = 'SongId';
const String columnArtistId = 'ArtistId';

// SongGenres
const String tableSongGenres = 'SongGenres';
const String columnGenreId = 'GenreId';

// Playlists
const String tablePlaylists = 'Playlists';
const String columnName = 'Name';
const String columnIsSorted = 'IsSorted';

// PlaylistSongs
const String tablePlaylistSongs = 'PlaylistSongs';
const String columnSequence = 'Sequence';
const String columnPlaylistName = 'PlaylistName';

// PlaylistSort
const String tablePlaylistSort = 'PlaylistSort';
const String columnSortString = 'SortString';
const String columnSearchString = 'SearchString';

// BackupSort
const String tableBackupSort = 'BackupSort';
const String columnSortId = 'SortId';
const String columnListPosition = 'ListPosition';

// Queue
const String tableQueue = 'Queue';
const String columnPosition = 'Position';

// Settings
const String tableSettings = 'Settings';
const String columnSetting = 'Setting';

const String tableSeparateFieldSettings = 'SeparateFieldSettings';
const String columnField = 'Field';
const String columnDelimiter = 'Delimiter';

const String tableFieldContainerSettings = 'FieldContainerSettings';
const String columnContainer = 'Container';
const String columnIgnoreText = 'IgnoreText';

// Building tables
const String dropSongs = 'DROP TABLE IF EXISTS $tableSongs;';
const String buildSongs = '''
    CREATE TABLE IF NOT EXISTS $tableSongs (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnTitle TEXT NOT NULL,
      $columnAlbum TEXT NOT NULL,
      $columnArtist TEXT NOT NULL,
      $columnAlbumArtist TEXT NOT NULL,
      $columnGenre TEXT NOT NULL,
      $columnYear TEXT NOT NULL,
      $columnSource TEXT NOT NULL,
      $columnTrackNumber INTEGER NOT NULL,
      $columnTotalTrackCount INTEGER NOT NULL,
      $columnDuration INTEGER NOT NULL,
      $columnModifiedDate TEXT NOT NULL,
      $columnFavorite INT(1) NOT NULL DEFAULT 0
    );''';

const String dropArtists = 'DROP TABLE IF EXISTS $tableArtists;';
const String buildArtists = '''
    CREATE TABLE IF NOT EXISTS $tableArtists (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnArtist TEXT NOT NULL
    );''';

const String dropAlbums = 'DROP TABLE IF EXISTS $tableAlbums;';
const String buildAlbums = '''
    CREATE TABLE IF NOT EXISTS $tableAlbums (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnAlbum TEXT NOT NULL,
      $columnAlbumArtist TEXT NOT NULL,
      $columnTotalTrackCount INTEGER NOT NULL,
      $columnDuration INTEGER NOT NULL
    );''';

const String dropGenres = 'DROP TABLE IF EXISTS $tableGenres;';
const String buildGenres = '''
    CREATE TABLE IF NOT EXISTS $tableGenres (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnGenre TEXT NOT NULL
    );''';

const String dropSongArtists = 'DROP TABLE IF EXISTS $tableSongArtists;';
const String buildSongArtists = '''
    CREATE TABLE IF NOT EXISTS $tableSongArtists (
      $columnSongId INTEGER NOT NULL,
      $columnArtistId INTEGER NOT NULL,
      FOREIGN KEY ($columnSongId) REFERENCES $tableSongs($columnId),
      FOREIGN KEY ($columnArtistId) REFERENCES $tableArtists($columnId)
    );''';

const String dropSongGenres = 'DROP TABLE IF EXISTS $tableSongGenres;';
const String buildSongGenres = '''
    CREATE TABLE IF NOT EXISTS $tableSongGenres (
      $columnSongId INTEGER NOT NULL,
      $columnGenreId INTEGER NOT NULL,
      FOREIGN KEY ($columnSongId) REFERENCES $tableSongs($columnId),
      FOREIGN KEY ($columnGenreId) REFERENCES $tableGenres($columnId)
    );''';

const String dropPlaylists = 'DROP TABLE IF EXISTS $tablePlaylists;';
const String buildPlaylists = '''
    CREATE TABLE IF NOT EXISTS $tablePlaylists (
      $columnName TEXT PRIMARY KEY,
      $columnIsSorted INT(1) NOT NULL DEFAULT 0
    );''';

const String dropPlaylistSongs = 'DROP TABLE IF EXISTS $tablePlaylistSongs;';
const String buildPlaylistSongs = '''
    CREATE TABLE IF NOT EXISTS $tablePlaylistSongs (
      $columnSequence INTEGER NOT NULL,
      $columnPlaylistName TEXT NOT NULL,
      $columnSongId INTEGER NOT NULL,
      FOREIGN KEY ($columnPlaylistName) REFERENCES $tablePlaylists($columnName),
      FOREIGN KEY ($columnSongId) REFERENCES $tableSongs($columnId)
    );''';

const String dropPlaylistSort = 'DROP TABLE IF EXISTS $tablePlaylistSort;';
const String buildPlaylistSort = '''
    CREATE TABLE IF NOT EXISTS $tablePlaylistSort (
      $columnSequence INTEGER NOT NULL,
      $columnPlaylistName TEXT NOT NULL,
      $columnSortString TEXT NOT NULL,
      $columnSearchString TEXT NOT NULL,
      FOREIGN KEY ($columnPlaylistName) REFERENCES $tablePlaylists($columnName)
    );''';

const String dropBackupSort = 'DROP TABLE IF EXISTS $tableBackupSort;';
const String buildBackupSort = '''
    CREATE TABLE IF NOT EXISTS $tableBackupSort (
      $columnSortId INTEGER NOT NULL,
      $columnSequence INTEGER NOT NULL,
      $columnSortString TEXT NOT NULL,
      $columnSearchString TEXT NOT NULL,
      $columnListPosition INTEGER NOT NULL
    );''';

const String dropQueue = 'DROP TABLE IF EXISTS $tableQueue;';
const String buildQueue = '''
    CREATE TABLE IF NOT EXISTS $tableQueue (
      $columnSequence INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnSongId INTEGER NOT NULL,
      $columnPosition INTEGER NOT NULL,
      FOREIGN KEY ($columnSongId) REFERENCES $tableSongs($columnId)
    );''';

const String dropSettings = 'DROP TABLE IF EXISTS $tableSettings;';
const String buildSettings = '''
    CREATE TABLE IF NOT EXISTS $tableSettings (
      $columnName TEXT NOT NULL,
      $columnSetting TEXT NOT NULL
    );''';

const String dropSeparateFieldSettings =
    'DROP TABLE IF EXISTS $tableSeparateFieldSettings;';
const String buildSeparateFieldSettings = '''
    CREATE TABLE IF NOT EXISTS $tableSeparateFieldSettings (
      $columnField TEXT NOT NULL,
      $columnDelimiter TEXT NOT NULL
    );''';

const String dropFieldContainerSettings =
    'DROP TABLE IF EXISTS $tableFieldContainerSettings;';
const String buildFieldContainerSettings = '''
    CREATE TABLE IF NOT EXISTS $tableFieldContainerSettings (
      $columnField TEXT NOT NULL,
      $columnContainer TEXT NOT NULL,
      $columnIgnoreText TEXT NOT NULL
    );''';
