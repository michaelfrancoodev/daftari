import "package:flutter/material.dart";
import "../../theme/tokens.dart";

/// Brief, silent brand moment. Routing decides where it goes next —
/// this screen never navigates itself.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/brand/logo.png", width: 96, height: 96),
            const SizedBox(height: Gap.lg),
            const Text(
              "DAFTARI",
              style: TextStyle(
                color: AppColor.ink,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
