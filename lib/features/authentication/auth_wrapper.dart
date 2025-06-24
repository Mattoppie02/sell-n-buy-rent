import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_n_buy_updated/services/auth_service.dart';
import 'package:sell_n_buy_updated/features/authentication/login_page.dart';
import 'package:sell_n_buy_updated/features/home/homepage.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return Homepage();
        }

        return LoginPage();
      },
    );
  }
}
