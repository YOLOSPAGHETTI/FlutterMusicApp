import 'package:music_app/models/quick_sort.dart';

class ListHistory {
  List<String> items;
  Map<String, QuickSort> quickSort;
  int startIndex = 0;
  int endIndex = 0;

  ListHistory({
    required this.items,
    required this.quickSort,
  });
}
