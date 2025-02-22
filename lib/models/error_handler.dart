import 'dart:collection';

class ErrorHandler {
  final LinkedHashSet<String> messages = LinkedHashSet();

  ErrorHandler();

  void addMessage(String message) {
    messages.add(message);
  }

  void removeMessage(String message) {
    messages.remove(message);
  }

  String getErrorMessage() {
    String errorMessage = "";
    for (String message in messages) {
      if (errorMessage.isEmpty) {
        errorMessage = message;
      } else {
        errorMessage += "\n$message";
      }
    }
    return errorMessage;
  }
}
