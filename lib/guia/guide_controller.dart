import 'package:flutter/foundation.dart';

class HealthyGuideController extends ChangeNotifier {
  HealthyGuideController(int count) : _count = count;

  final int _count;
  int _index = 0;
  bool _active = true;

  int get index => _index;
  int get count => _count;
  bool get active => _active;
  bool get isLast => _index >= _count - 1;

  void next() {
    if (!_active) return;
    if (isLast) {
      finish();
    } else {
      _index++;
      notifyListeners();
    }
  }

  void previous() {
    if (!_active || _index == 0) return;
    _index--;
    notifyListeners();
  }

  void finish() {
    if (!_active) return;
    _active = false;
    notifyListeners();
  }
}
