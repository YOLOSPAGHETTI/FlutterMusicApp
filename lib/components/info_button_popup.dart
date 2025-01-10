import 'package:flutter/material.dart';

class InfoButtonPopup extends StatelessWidget {
  final String title;
  final String info;
  const InfoButtonPopup({super.key, required this.title, required this.info});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.tertiary)),
              content: Text(info,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.tertiary)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
      icon: Icon(Icons.info),
    );
  }
}
