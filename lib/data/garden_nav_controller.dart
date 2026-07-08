import 'package:flutter/foundation.dart';

/// Lets the Calendar tab ask the Garden tab to jump to a specific date,
/// since they live as sibling tabs rather than a parent/child pair.
class GardenNavController extends ChangeNotifier {
  DateTime? _pendingDate;
  DateTime? get pendingDate => _pendingDate;

  void requestDate(DateTime date) {
    _pendingDate = date;
    notifyListeners();
  }

  void clear() {
    _pendingDate = null;
  }
}
