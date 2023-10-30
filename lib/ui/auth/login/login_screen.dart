import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:todark/app/controller/controller.dart';
import 'package:todark/app/data/schema.dart';
import 'package:todark/app/modules/home.dart';
import 'package:todark/constants.dart';
import 'package:todark/main.dart';
import 'package:todark/services/helper.dart';
import 'package:todark/ui/auth/authentication_bloc.dart';
import 'package:todark/ui/auth/login/login_bloc.dart';
import 'package:todark/ui/auth/resetPasswordScreen/reset_password_screen.dart';
import 'package:todark/ui/loading_cubit.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State createState() {
    return _LoginScreen();
  }
}

class _LoginScreen extends State<LoginScreen> {
  final GlobalKey<FormState> _key = GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  String? email, password;

  // Buat variabel tasks
  List<Tasks> tasks = [];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (context) => LoginBloc(),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(
                color: isDarkMode(context) ? Colors.white : Colors.black),
            elevation: 0.0,
          ),
          body: MultiBlocListener(
            listeners: [
              BlocListener<AuthenticationBloc, AuthenticationState>(
                  listener: (context, state) async {
                await context.read<LoadingCubit>().hideLoading();
                if (state.authState == AuthState.authenticated) {
                  if (!mounted) return;

                  final user = FirebaseAuth.instance.currentUser;
                  final userUid = user?.uid; // Dapatkan UID pengguna, jika ada
                  final userCollection = firestore.collection('users');
                  final userDoc = await userCollection.doc(user?.uid).get();

                  if (userDoc.exists) {
                    await isar.writeTxn(() async {
                      final allTasks = await isar.tasks.where().findAll();
                      for (final task in allTasks) {
                        await isar.tasks
                            .where()
                            .filter()
                            .idEqualTo(task.id)
                            .deleteAll();
                        if (!mounted) return;
                        setState(() {
                          tasks.remove(task);
                        });
                      }
                    });

                    if (kDebugMode) {
                      print("Start fetching tasks from Firestore...");
                    }
                    final tasksCollection = firestore.collection('tasks');
                    final userTasks = await tasksCollection
                        .where('uid', isEqualTo: userUid)
                        .get();

                    isar.writeTxn(() async {
                      final newTasks = <Tasks>[];
                      for (final taskDoc in userTasks.docs) {
                        final taskData = taskDoc.data();
                        final task = Tasks(
                          description: taskData['description'],
                          taskColor: taskData['taskColor'],
                          title: taskData['title'],
                          uid: taskData['uid'],
                        );

                        await isar.tasks.put(task);
                        newTasks.add(task);
                      }
                      if (!mounted) return;
                      setState(() {
                        tasks.addAll(newTasks);
                      });

                      if (kDebugMode) {
                        for (final task in newTasks) {
                          print("Task added: ${task.title}");
                        }
                      }
                    });
                  } else {
                    await isar.writeTxn(() async {
                      final allTasks = await isar.tasks.where().findAll();
                      for (final task in allTasks) {
                        await isar.tasks
                            .where()
                            .filter()
                            .idEqualTo(task.id)
                            .deleteAll();
                        if (!mounted) return;
                        setState(() {
                          tasks.remove(task);
                        });
                      }
                    });
                    // Tindakan jika koleksi dengan UID pengguna belum ada di Firestore
                  }
                  if (kDebugMode) {
                    print("Finished fetching and adding tasks from Firestore.");
                  }
                  // ignore: use_build_context_synchronously
                  pushAndRemoveUntil(
                      context, HomePage(user: state.user!), false);
                } else {
                  if (!mounted) return;
                  showSnackBar(
                    context,
                    state.message ?? 'Couldn\'t login, Please try again.',
                  );
                }
              }),
              BlocListener<LoginBloc, LoginState>(
                listener: (context, state) async {
                  if (state is ValidLoginFields) {
                    await context.read<LoadingCubit>().showLoading(
                        context, 'Logging in, Please wait...', false);
                    if (!mounted) return;
                    context.read<AuthenticationBloc>().add(
                          LoginWithEmailAndPasswordEvent(
                            email: email!,
                            password: password!,
                          ),
                        );
                  }
                },
              ),
            ],
            child: BlocBuilder<LoginBloc, LoginState>(
              buildWhen: (old, current) =>
                  current is LoginFailureState && old != current,
              builder: (context, state) {
                if (state is LoginFailureState) {
                  _validate = AutovalidateMode.onUserInteraction;
                }
                return Form(
                  key: _key,
                  autovalidateMode: _validate,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 32.0, right: 16.0, left: 16.0),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 25.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 32.0, right: 24.0, left: 24.0),
                          child: TextFormField(
                              textAlignVertical: TextAlignVertical.center,
                              textInputAction: TextInputAction.next,
                              validator: validateEmail,
                              onSaved: (String? val) {
                                email = val;
                              },
                              style: const TextStyle(fontSize: 18.0),
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: const Color(colorPrimary),
                              decoration: getInputDecoration(
                                  hint: 'Email Address',
                                  darkMode: isDarkMode(context),
                                  errorColor:
                                      Theme.of(context).colorScheme.error)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 32.0, right: 24.0, left: 24.0),
                          child: TextFormField(
                              textAlignVertical: TextAlignVertical.center,
                              obscureText: true,
                              validator: validatePassword,
                              onSaved: (String? val) {
                                password = val;
                              },
                              onFieldSubmitted: (password) => context
                                  .read<LoginBloc>()
                                  .add(ValidateLoginFieldsEvent(_key)),
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(fontSize: 18.0),
                              cursorColor: const Color(colorPrimary),
                              decoration: getInputDecoration(
                                  hint: 'Password',
                                  darkMode: isDarkMode(context),
                                  errorColor:
                                      Theme.of(context).colorScheme.error)),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 720, minWidth: 200),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, right: 24),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () =>
                                    push(context, const ResetPasswordScreen()),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                      color: Colors.lightBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 40.0, left: 40.0, top: 40),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: Size.fromWidth(
                                  MediaQuery.of(context).size.width / 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(colorPrimary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                side: const BorderSide(
                                  color: Color(colorPrimary),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                            onPressed: () => context
                                .read<LoginBloc>()
                                .add(ValidateLoginFieldsEvent(_key)),
                          ),
                        ),
                        FutureBuilder<bool>(
                          future: apple.TheAppleSignIn.isAvailable(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator.adaptive();
                            }
                            if (!snapshot.hasData || (snapshot.data != true)) {
                              return Container();
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    right: 40.0, left: 40.0, bottom: 20),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width /
                                              1.5),
                                  child: apple.AppleSignInButton(
                                      cornerRadius: 25.0,
                                      type: apple.ButtonType.signIn,
                                      style: isDarkMode(context)
                                          ? apple.ButtonStyle.white
                                          : apple.ButtonStyle.black,
                                      onPressed: () async {
                                        await context
                                            .read<LoadingCubit>()
                                            .showLoading(
                                                context,
                                                'Logging in, Please wait...',
                                                false);
                                        if (!mounted) return;
                                        context
                                            .read<AuthenticationBloc>()
                                            .add(LoginWithAppleEvent());
                                      }),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
