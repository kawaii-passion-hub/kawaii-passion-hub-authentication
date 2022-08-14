import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';

class AuthenticationWidget extends StatelessWidget {
  const AuthenticationWidget(
      {Key? key, required this.logo, required this.googleClientId})
      : super(key: key);

  final Image logo;
  final String googleClientId;

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
        subtitleBuilder: (context, action) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child:
                Text('Welcome to FlutterFire UI! Please sign in to continue.'),
          );
        },
        footerBuilder: (context, _) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Copyright @twilker',
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
        showAuthActionSwitch: false,
        sideBuilder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: logo,
            ),
          );
        },
        headerBuilder: (context, constraints, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: logo,
            ),
          );
        },
        providerConfigs: [
          GoogleProviderConfiguration(
            clientId: googleClientId,
          ),
        ]);
  }
}
