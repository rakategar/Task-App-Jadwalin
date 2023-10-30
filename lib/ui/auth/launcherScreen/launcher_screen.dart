import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todark/app/modules/home.dart';
import 'package:todark/app/modules/onboarding.dart';
import 'package:todark/constants.dart';
import 'package:todark/services/helper.dart';
import 'package:todark/ui/auth/authentication_bloc.dart';
import 'package:todark/ui/auth/welcome/welcome_screen.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({Key? key}) : super(key: key);

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthenticationBloc>().add(CheckFirstRunEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(colorPrimary),
      body: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          switch (state.authState) {
            case AuthState.firstRun:
              pushReplacement(
                  context, const OnBording()); // Ganti dengan OnBording
              break;
            case AuthState.authenticated:
              pushReplacement(context, HomePage(user: state.user!));
              break;
            case AuthState.unauthenticated:
              pushReplacement(context, const WelcomeScreen());
              break;
          }
        },
        child: const Center(
          child: CircularProgressIndicator.adaptive(
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation(Color(colorPrimary)),
          ),
        ),
      ),
    );
  }
}
