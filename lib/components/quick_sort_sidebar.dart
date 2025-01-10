import 'package:flutter/material.dart';
import 'package:music_app/models/music_provider.dart';

class QuickSortSidebar extends StatefulWidget {
  final MusicProvider musicProvider;
  final List<String> items;
  final ScrollController scrollController;
  final double itemHeight;

  const QuickSortSidebar({
    required this.musicProvider,
    required this.items,
    required this.scrollController,
    required this.itemHeight,
    super.key,
  });

  @override
  State<QuickSortSidebar> createState() => _QuickSortSidebarState();
}

class _QuickSortSidebarState extends State<QuickSortSidebar> {
  String? selectedItem; // Track the currently selected letter

  @override
  void initState() {
    super.initState();
  }

  void quickSort(String item) {
    double position = widget.musicProvider.getPositionFromQuickSort(item);
    print("quickSort::position: $position");
    widget.scrollController.jumpTo(position);
  }

  void handleTouchUpdate(Offset localPosition) {
    // Determine the letter based on the vertical position of the touch
    final double itemHeight =
        widget.itemHeight; // Adjust to match the height of each item
    final List<String> items = widget.items;
    int index = (localPosition.dy ~/ itemHeight).clamp(0, items.length - 1);
    String newItem = items[index];

    if (newItem != selectedItem) {
      setState(() {
        selectedItem = newItem;
      });
      quickSort(newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          handleTouchUpdate(details.localPosition);
        },
        onVerticalDragStart: (details) {
          handleTouchUpdate(details.localPosition);
        },
        onVerticalDragEnd: (_) {
          setState(() {
            selectedItem = null; // Clear selection when touch ends
          });
        },
        child: SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.items.map((item) {
              final isSelected = selectedItem == item;
              return Container(
                height: widget.itemHeight - // Make this + 2 for decades?
                    2, // Match the item height in touch calculation
                color: isSelected ? Colors.grey[600] : Colors.transparent,
                child: Center(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.grey[500],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
