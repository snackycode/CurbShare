import 'package:flutter/material.dart';

class BottomNavVisibilityProvider with ChangeNotifier {
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  void toggleVisibility() {
    _isVisible = !_isVisible;
    notifyListeners();
  }
  void setNoVisibility(){
    _isVisible = false;
    notifyListeners();
  }
  void setYesVisibility(){
    _isVisible = true;
    notifyListeners();
  }
}