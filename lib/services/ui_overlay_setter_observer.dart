import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Class to set the system UI overlay style to edge to edge.
class UIOverlaySetterObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
          ),
        );
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        break;
      default:
        break;
    }
  }
}