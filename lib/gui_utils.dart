import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

class GuiUtils with UiLoggy {
  /// Wrapper function to provide the most common used form of snackbar, with theming support.
  void showTextSnackbar(BuildContext? context, String message,
      {bool isError = false,
      SnackBarAction? action,
      bool removeOthers = false}) {
    if (context != null) {
      ThemeData theme = Theme.of(context);
      if (isError) {
        ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
            action: action,
            backgroundColor: theme.colorScheme.error,
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: theme.colorScheme.onError,
                ),
                const VerticalDivider(),
                Text(
                  message,
                  style: TextStyle(color: theme.colorScheme.onError),
                )
              ],
            )));
      } else {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(action: action, content: Text(message)));
      }
    } else {
      loggy.warning(
          "Asked to print text snackbar without context! Contents: $message");
    }
  }

  /// Shows a snackbar with Widget contents;
  ///
  /// Warning, colors may not properly apply to the [content] widget--you should style it yourself!
  void showWidgetSnackbar(BuildContext? context, Widget content,
      {bool isError = false,
      SnackBarAction? action,
      bool removeOthers = false}) {
    if (context != null) {
      ThemeData theme = Theme.of(context);
      if (isError) {
        ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
            action: action,
            backgroundColor: theme.colorScheme.error,
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: theme.colorScheme.onError,
                ),
                const VerticalDivider(),
                content,
              ],
            )));
      } else {
        if (removeOthers) {
          ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
        }
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(action: action, content: content));
      }
    } else {
      loggy.warning(
          "Asked to print widget snackbar without context! Contents: ${content.toStringDeep()}");
    }
  }
}
