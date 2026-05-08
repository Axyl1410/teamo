import 'package:flutter/material.dart';

/// App-wide session bootstrap ([AuthStatus.checking]) loading placeholder.
class LinearLoadingScaffoldBody extends StatelessWidget {
  const LinearLoadingScaffoldBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}
