import 'package:flutter/material.dart';
import 'package:music_app/constants.dart';

class TextFieldList extends StatelessWidget {
  final List<TextEditingController> list;
  final Function(TextEditingController, String) addToList;
  final Function(int, String) removeAfterIndex;
  final String labelText;
  final String listType;
  final double width;
  const TextFieldList(
      {super.key,
      required this.list,
      required this.addToList,
      required this.removeAfterIndex,
      required this.labelText,
      required this.listType,
      required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: listFieldHeight * list.length,
      width: width,
      child: ListView.builder(
          shrinkWrap: true, // Avoid ListView taking infinite height
          physics:
              const NeverScrollableScrollPhysics(), // Disable scroll inside the parent scroll view

          itemCount: list.length,
          itemBuilder: (context, index) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: TextField(
                controller: list[index],
                onChanged: (text) {
                  // Add a new TextField if the current one is populated and it's the last one
                  print("text not empty: " + text.isNotEmpty.toString());
                  if (text.isNotEmpty) {
                    if (index == list.length - 1) {
                      addToList(TextEditingController(), listType);
                    }
                  } else {
                    bool foundText = false;
                    for (int i = list.length - 1; i >= index; i--) {
                      if (list[i].text.isNotEmpty) {
                        removeAfterIndex(i, listType);
                        foundText = true;
                        break;
                      }
                    }
                    print("foundText: $foundText");
                    print("index: $index");
                    if (!foundText) {
                      removeAfterIndex(index, listType);
                    }
                  }
                },
                decoration: InputDecoration(
                  labelText: "$labelText ${index + 1}",
                  border: OutlineInputBorder(),
                ),
              ),
            );
          }),
    );
  }
}
