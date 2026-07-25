import 'package:flutter/material.dart';

import 'entry/entry_splash_screen.dart';

class EntryFlowScreen extends StatelessWidget {
  const EntryFlowScreen({super.key, this.autoNavigate = true});

  final bool autoNavigate;

  @override
  Widget build(BuildContext context) {
    return EntrySplashScreen(autoNavigate: autoNavigate);
  }
}
