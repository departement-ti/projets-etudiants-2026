import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mymeds_app/components/text_field.dart';
import 'package:mymeds_app/screens/password_reset.dart';
import 'package:mymeds_app/services/auth_service.dart';
import 'package:mymeds_app/services/biometric_auth_service.dart';
import 'package:mymeds_app/auth/main_page.dart';
import 'package:mymeds_app/components/language_constants.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key, required this.showSignUpScreen});

  final void Function()? showSignUpScreen;

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  //controllers - keep track what types
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late FocusNode focusNode_email;
  late FocusNode focusNode_pwd;

  bool isLoading = false;
  bool isLoadingGoogle = false;
  bool _isBiometricAvailable = false;

  final _secureStorage = const FlutterSecureStorage();
  final BiometricAuthService _biometricService = BiometricAuthService();

  bool _isEmail = false;
  bool _isError = false;
  String errorMsg = '';

  bool isName(String input) => RegExp('[a-zA-Z]').hasMatch(input);
  bool isEmail(String input) => RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
      .hasMatch(input);
  bool isPhone(String input) =>
      RegExp(r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$')
          .hasMatch(input);

  @override
  void initState() {
    super.initState();
    focusNode_email = FocusNode();
    focusNode_pwd = FocusNode();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('login_type');
    final lastEmail = prefs.getString('last_logged_email');

    if (lastEmail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).noSavedAccount),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (loginType == 'google') {
      final success = await _biometricService.authenticateWithBiometric();
      if (!success) return;

      try {
        UserCredential user = await AuthService().signInWithGoogle(context);

        var a = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.user!.email)
            .get();
        if (!a.exists) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(translation(context).noAccountFound),
                backgroundColor: Colors.orange,
              ),
            );
            widget.showSignUpScreen?.call();
          }
          return;
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
      } catch (e) {
        print(e);
      }
      return;
    }

    final success = await _biometricService.authenticateWithBiometric();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).biometricFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final lastPassword = await _secureStorage.read(key: 'user_password');
    if (lastPassword == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).noSavedPassword),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: lastEmail,
        password: lastPassword,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future signIn() async {
    if (_emailController.text.isEmpty) {
      // showDialog(
      //   context: context,
      //   builder: (context) {
      //     return const Alert_Dialog(
      //       isError: true,
      //       alertTitle: 'Error',
      //       errorMessage: 'Email or password can\'t be empty.',
      //       buttonText: 'Cancel',
      //     );
      //   },
      // );
      focusNode_email.requestFocus();
    } else if (_passwordController.text.isEmpty) {
      focusNode_pwd.requestFocus();
    } else {
      if (!isEmail(_emailController.text)) {
        setState(() {
          _isEmail = true;
        });
      } else {
        setState(() {
          _isEmail = false;
        });
        try {
          setState(() {
            isLoading = true;
          });
          // //loading circle
          // showDialog(
          //   context: context,
          //   builder: (context) {
          //     return const Center(
          //       child: CircularProgressIndicator(
          //         color: Color.fromRGBO(7, 82, 96, 1),
          //       ),
          //     );
          //   },
          // );

          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          // Save login info
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'last_logged_email', _emailController.text.trim());
          await prefs.setString('login_type', 'email');
          await _secureStorage.write(
              key: 'user_password', value: _passwordController.text.trim());

          // if (!mounted) {
          //   return;
          // }
          // //pop loading cicle
          // Navigator.of(context).pop();
        } on FirebaseAuthException catch (e) {
          print(e.code);
          setState(() {
            isLoading = false;
          });

          if (e.code == 'user-not-found') {
            if (mounted) {
              final goToSignUp = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(translation(context).accountNotFoundTitle),
                  content: Text(translation(context).createNewAccountPrompt),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(translation(context).cancelBtn),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(translation(context).signUpDialogBtn),
                    ),
                  ],
                ),
              );
              if (goToSignUp == true) {
                widget.showSignUpScreen?.call();
              }
            }
            return;
          }

          setState(() {
            _isError = true;
            errorMsg = getErrorMessage(e.code);
          });
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  // for memory mgt
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    focusNode_email.dispose();
    focusNode_pwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          // systemOverlayStyle: const SystemUiOverlayStyle(
          //     statusBarColor: Color.fromARGB(255, 233, 237, 237)),
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Center(
            child: GlowingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              color: const Color.fromRGBO(7, 82, 96, 1),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //logo
                    const Image(
                       image: AssetImage('lib/assets/neurocare_logo.png'),
                      height: 100,
                    ),
                    //app name
                    Text(
                       'NeuroCare',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromRGBO(7, 82, 96, 1),
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    //text
                    Text(
                      translation(context).welcomeBack,
                      style: GoogleFonts.roboto(
                        fontSize: 35,
                        color: const Color.fromARGB(255, 16, 15, 15),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    //FORM
                    FormUI(),

                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      translation(context).or,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: const Color.fromARGB(255, 67, 63, 63),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    //sign in with google buttton
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton.tonalIcon(
                        //sign in with google
                        // onPressed: () {},
                         onPressed: () async {
                          setState(() {
                            isLoadingGoogle = true;
                          });
                          try {
                            UserCredential user =
                                await AuthService().signInWithGoogle(context);
                            String? userEmail = user.user!.email;
                            print('Email : $userEmail');

                            var a = await FirebaseFirestore.instance
                                .collection('Users')
                                .doc(userEmail)
                                .get();
                            if (!a.exists) {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(translation(context).noAccountFound),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                widget.showSignUpScreen?.call();
                              }
                              return;
                            }

                            await SharedPreferences.getInstance()
                                .then((prefs) => prefs.setString('login_type', 'google'));

                            if (mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => const MainPage()),
                              );
                            }
                          } catch (e) {
                            print(e);
                          }
                          setState(() {
                            isLoadingGoogle = false;
                          });
                        },
                        style: const ButtonStyle(
                          elevation: MaterialStatePropertyAll(2),
                          shape: MaterialStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: Color.fromARGB(255, 7, 82, 96),
                          size: 20,
                        ),
                        label: !isLoadingGoogle
                            ? Text(
                                translation(context).continueWithGoogle,
                                style: GoogleFonts.roboto(
                                  fontSize: 20,
                                  color: const Color.fromARGB(255, 7, 82, 96),
                                ),
                              )
                            : const CircularProgressIndicator(
                                color: Color.fromARGB(255, 7, 82, 96),
                              ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (_isBiometricAvailable) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: _authenticateWithBiometric,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color.fromRGBO(7, 82, 96, 1),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(
                            Icons.fingerprint,
                            color: Color.fromRGBO(7, 82, 96, 1),
                            size: 24,
                          ),
                          label: Text(
                            translation(context).loginWithFingerprint,
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              color: const Color.fromRGBO(7, 82, 96, 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    //link to sign up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //text
                        Text(
                          translation(context).dontHaveAccount,
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            color: const Color.fromARGB(255, 67, 63, 63),
                          ),
                        ),
                        //sign up button
                        ElevatedButton(
                          onPressed: widget.showSignUpScreen,
                          style: ButtonStyle(
                            elevation: const MaterialStatePropertyAll(0),
                            backgroundColor: const MaterialStatePropertyAll(
                              Colors.transparent,
                            ),
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            shape: const MaterialStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            translation(context).signUpLink,
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              // color: const Color.fromARGB(255, 7, 82, 96),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget FormUI() {
    return Column(
      children: [
        //email
        Text_Field(
          label: translation(context).emailFieldLabel,
          hint: translation(context).emailFieldHint,
          isPassword: false,
          keyboard: TextInputType.emailAddress,
          txtEditController: _emailController,
          focusNode: focusNode_email,
        ),
        const SizedBox(
          height: 5,
        ),
        //text not a valid email
        Visibility(
          visible: _isEmail,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
              child: Text(
                translation(context).enterValidEmail,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: const Color.fromRGBO(255, 16, 15, 15),
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        //password
        Text_Field(
          label: translation(context).passwordFieldLabel,
          hint: translation(context).passwordFieldHint,
          isPassword: true,
          keyboard: TextInputType.visiblePassword,
          txtEditController: _passwordController,
          focusNode: focusNode_pwd,
        ),
        //forgot password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            //firebase error message
            Visibility(
              visible: _isError,
              maintainSize: false,
              maintainAnimation: true,
              maintainState: true,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: GlowingOverscrollIndicator(
                    axisDirection: AxisDirection.right,
                    color: const Color.fromRGBO(255, 16, 15, 15),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color.fromRGBO(255, 16, 15, 15),
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        Text(
                          errorMsg,
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromRGBO(255, 16, 15, 15),
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            //forgot pwd button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  //password reset screen
                  MaterialPageRoute(
                    builder: (context) {
                      return const PasswordReset();
                    },
                  ),
                );
              },
              style: ButtonStyle(
                elevation: const MaterialStatePropertyAll(0),
                backgroundColor: const MaterialStatePropertyAll(
                  Colors.transparent,
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.fromLTRB(8, 0, 8, 0),
                ),
                shape: const MaterialStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                ),
              ),
              child: Text(
                translation(context).forgotPassword,
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  // color: const Color.fromARGB(255, 7, 82, 96),
                ),
              ),
            ),
          ],
        ),

        //sign in button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: FilledButton(
            onPressed: signIn,
            style: const ButtonStyle(
              elevation: MaterialStatePropertyAll(2),
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
              ),
            ),
            child: !isLoading
                ? Text(
                    translation(context).signInBtn,
                    style: GoogleFonts.roboto(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ],
    );
  }

  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case "ERROR_EMAIL_ALREADY_IN_USE":
      case "account-exists-with-different-credential":
      case "email-already-in-use":
        return "Email already used. Go to login page.";
        break;
      case "ERROR_WRONG_PASSWORD":
      case "wrong-password":
        return "Incorrect email or password.";
        break;
      case "ERROR_USER_NOT_FOUND":
      case "user-not-found":
        return "No user found with this email.";
        break;
      case "ERROR_USER_DISABLED":
      case "user-disabled":
        return "User disabled.";
        break;
      case "ERROR_TOO_MANY_REQUESTS":
      case "operation-not-allowed":
        return "Too many requests to log into this account.";
        break;
      case "ERROR_OPERATION_NOT_ALLOWED":
      case "operation-not-allowed":
        return "Server error, please try again later.";
        break;
      case "ERROR_INVALID_EMAIL":
      case "invalid-email":
        return "Incorrect email or password.E";
        break;
      case 'network-request-failed':
        return 'Network error.';
      default:
        return "Sign in failed. Please try again.";
        break;
    }
  }
}
