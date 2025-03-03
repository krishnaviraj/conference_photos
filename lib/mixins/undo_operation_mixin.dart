import 'package:flutter/material.dart';

mixin UndoOperationMixin<T extends StatefulWidget> on State<T> {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _snackBarController;
  bool _isUndoOperationPending = false;

  void showUndoSnackBar({
    required String message,
    required VoidCallback onUndo,
    required VoidCallback onDismissed,
  }) {
    // If there's a pending operation, execute its dismissal first
    if (_isUndoOperationPending) {
      _snackBarController?.close();
    }

    // Hide any existing snackbars immediately
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    _isUndoOperationPending = true;

    _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 7),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _isUndoOperationPending = false;
            onUndo();
            _snackBarController?.close();
          },
        ),
      ),
    );

    _snackBarController?.closed.then((reason) {
      if (reason != SnackBarClosedReason.action && _isUndoOperationPending) {
        onDismissed();
      }
      _isUndoOperationPending = false;
    });
  }

  @override
  void dispose() {
    _snackBarController?.close();
    super.dispose();
  }
}
 
//  The  UndoOperationMixin  is a mixin that provides a method to show a snackbar with an undo action. The mixin is used in the  TalkViewScreenState  class to show a snackbar when a photo is deleted. 
//  The  showUndoSnackBar  method takes three parameters: 
 
//  message : The message to display in the snackbar. 
//  onUndo : The callback to execute when the undo action is pressed.
//  onDismissed : The callback to execute when the snackbar is dismissed without pressing the undo action.
//  The  showUndoSnackBar  method creates a snackbar with the given message and an undo action. The snackbar is displayed for 7 seconds. If the undo action is pressed, the  onUndo  callback is executed, and the snackbar is closed. 
//  If the snackbar is dismissed without pressing the undo action, the  onDismissed  callback is executed.
//  The  dispose  method is overridden to close the snackbar when the state is disposed to prevent memory leaks.
