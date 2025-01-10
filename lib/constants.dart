// Component Sizing
final double listTileHeight = 70;
final double listFieldHeight = 70;

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
  columnArtist,
  columnAlbum,
  columnGenre,
  columnYear,
  columnModifiedDate
];

// Settings
const String settingHideSongsWithEmptyTitle = "hideSongsWithEmptyTitle";
const String settingHideSongsWithEmptyArtist = "hideSongsWithEmptyArtist";
const String settingHideSongsWithEmptyAlbum = "hideSongsWithEmptyAlbum";
const String settingHideSongsWithEmptyGenre = "hideSongsWithEmptyGenre";
const String settingHideSongsWithEmptyYear = "hideSongsWithEmptyYear";
const String settingIgnoreThe = "ignoreThe";
const String settingIgnoreA = "ignoreA";
const String settingViewArtistWithAlbum = "viewArtistWithAlbum";
const String settingViewYearWithAlbum = "viewYearWithAlbum";
const String settingSongSortOrder = "songSortOrder";
const String settingAlbumSortOrder = "albumSortOrder";
const String settingYearSortOrder = "yearSortOrder";

// Order Types
const String orderAlphabetically = "Alphabetically";
const String orderChronolically = "Chronologically";
const String orderReverseChronolically = "Reverse Chronologically";

// DB
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
    CREATE TABLE $tableSongs (
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
    CREATE TABLE $tableArtists (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnArtist TEXT NOT NULL
    );''';

const String dropAlbums = 'DROP TABLE IF EXISTS $tableAlbums;';
const String buildAlbums = '''
    CREATE TABLE $tableAlbums (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnAlbum TEXT NOT NULL,
      $columnAlbumArtist TEXT NOT NULL,
      $columnTotalTrackCount INTEGER NOT NULL,
      $columnDuration INTEGER NOT NULL
    );''';

const String dropGenres = 'DROP TABLE IF EXISTS $tableGenres;';
const String buildGenres = '''
    CREATE TABLE $tableGenres (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnGenre TEXT NOT NULL
    );''';

const String dropSongArtists = 'DROP TABLE IF EXISTS $tableSongArtists;';
const String buildSongArtists = '''
    CREATE TABLE $tableSongArtists (
      $columnSongId INTEGER NOT NULL,
      $columnArtistId INTEGER NOT NULL,
      FOREIGN KEY ($columnSongId) REFERENCES $tableSongs($columnId),
      FOREIGN KEY ($columnArtistId) REFERENCES $tableArtists($columnId)
    );''';

const String dropSongGenres = 'DROP TABLE IF EXISTS $tableSongGenres;';
const String buildSongGenres = '''
    CREATE TABLE $tableSongGenres (
      $columnSongId INTEGER NOT NULL,
      $columnGenreId INTEGER NOT NULL,
      FOREIGN KEY ($columnSongId) REFERENCES $tableSongs($columnId),
      FOREIGN KEY ($columnGenreId) REFERENCES $tableGenres($columnId)
    );''';

const String dropPlaylists = 'DROP TABLE IF EXISTS $tablePlaylists;';
const String buildPlaylists = '''
    CREATE TABLE $tablePlaylists (
      $columnName TEXT PRIMARY KEY,
      $columnIsSorted BOOLEAN
    );''';

const String dropPlaylistSongs = 'DROP TABLE IF EXISTS $tablePlaylistSongs;';
const String buildPlaylistSongs = '''
    CREATE TABLE $tablePlaylistSongs (
      $columnSequence INTEGER NOT NULL,
      $columnPlaylistName TEXT NOT NULL,
      $columnSongId INTEGER NOT NULL,
      FOREIGN KEY ($columnPlaylistName) REFERENCES $tablePlaylists($columnName),
      FOREIGN KEY ($columnSongId) REFERENCES $tableSongs($columnId)
    );''';

const String dropPlaylistSort = 'DROP TABLE IF EXISTS $tablePlaylistSort;';
const String buildPlaylistSort = '''
    CREATE TABLE $tablePlaylistSort (
      $columnSequence INTEGER NOT NULL,
      $columnPlaylistName TEXT NOT NULL,
      $columnSortString TEXT NOT NULL,
      $columnSearchString TEXT NOT NULL,
      FOREIGN KEY ($columnPlaylistName) REFERENCES $tablePlaylists($columnName)
    );''';

const String dropBackupSort = 'DROP TABLE IF EXISTS $tableBackupSort;';
const String buildBackupSort = '''
    CREATE TABLE $tableBackupSort (
      $columnSortId INTEGER NOT NULL,
      $columnSequence INTEGER NOT NULL,
      $columnSortString TEXT NOT NULL,
      $columnSearchString TEXT NOT NULL,
      $columnListPosition INTEGER NOT NULL
    );''';

const String dropQueue = 'DROP TABLE IF EXISTS $tableQueue;';
const String buildQueue = '''
    CREATE TABLE $tableQueue (
      $columnSequence INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnSongId INTEGER NOT NULL,
      $columnPosition INTEGER NOT NULL,
      FOREIGN KEY ($columnSongId) REFERENCES $tableSongs($columnId)
    );''';

const String dropSettings = 'DROP TABLE IF EXISTS $tableSettings;';
const String buildSettings = '''
    CREATE TABLE $tableSettings (
      $columnName TEXT NOT NULL,
      $columnSetting TEXT NOT NULL
    );''';

const String dropSeparateFieldSettings =
    'DROP TABLE IF EXISTS $tableSeparateFieldSettings;';
const String buildSeparateFieldSettings = '''
    CREATE TABLE $tableSeparateFieldSettings (
      $columnField TEXT NOT NULL,
      $columnDelimiter TEXT NOT NULL
    );''';

const String dropFieldContainerSettings =
    'DROP TABLE IF EXISTS $tableFieldContainerSettings;';
const String buildFieldContainerSettings = '''
    CREATE TABLE $tableFieldContainerSettings (
      $columnField TEXT NOT NULL,
      $columnContainer TEXT NOT NULL,
      $columnIgnoreText TEXT NOT NULL
    );''';
