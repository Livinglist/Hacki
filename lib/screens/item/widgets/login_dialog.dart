import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/status.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> with ItemActionMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (state.isLoggedIn) {
          context.pop();
          showSnackBar(
            content: 'Logged in successfully! ${Constants.happyFace}',
          );
        }
      },
      builder: (BuildContext context, AuthState state) {
        return SimpleDialog(
          children: <Widget>[
            if (state.status.isLoading)
              SizedBox(
                height: Dimens.pt36,
                width: Dimens.pt36,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else if (!state.isLoggedIn) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.pt18,
                ),
                child: TextField(
                  controller: usernameController,
                  cursorColor: Theme.of(context).colorScheme.primary,
                  autocorrect: false,
                  autofillHints: const <String>[AutofillHints.username],
                  decoration: InputDecoration(
                    hintText: 'Username',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: Dimens.pt16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.pt18,
                ),
                child: TextField(
                  controller: passwordController,
                  cursorColor: Theme.of(context).colorScheme.primary,
                  obscureText: true,
                  autocorrect: false,
                  autofillHints: const <String>[AutofillHints.password],
                  decoration: InputDecoration(
                    hintText: 'Password',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: Dimens.pt16,
              ),
              if (state.status == Status.failure)
                Padding(
                  padding: const EdgeInsets.only(
                    left: Dimens.pt18,
                    right: Dimens.pt6,
                  ),
                  child: Text(
                    Constants.loginErrorMessage,
                    style: const TextStyle(
                      color: Palette.grey,
                      fontSize: TextDimens.pt12,
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      state.agreedToEULA
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: state.agreedToEULA
                          ? Theme.of(context).colorScheme.primary
                          : Palette.grey,
                    ),
                    onPressed: () =>
                        context.read<AuthBloc>().add(AuthToggleAgreeToEULA()),
                  ),
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        const TextSpan(
                          text: 'I agree to ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        WidgetSpan(
                          child: Transform.translate(
                            offset: const Offset(0, 1),
                            child: TapDownWrapper(
                              onTap: () => LinkUtil.launch(
                                Constants.endUserAgreementLink,
                                context,
                              ),
                              child: Text(
                                'End User Agreement',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: Dimens.pt12,
                ),
                child: OverflowBar(
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        context.pop();
                        context.read<AuthBloc>().add(AuthInitialize());
                      },
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (state.agreedToEULA) {
                          final String username = usernameController.text;
                          final String password = passwordController.text;
                          if (username.isNotEmpty && password.isNotEmpty) {
                            context.read<AuthBloc>().add(
                                  AuthLogin(
                                    username: username,
                                    password: password,
                                  ),
                                );
                          }
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          state.agreedToEULA
                              ? Theme.of(context).colorScheme.primary
                              : Palette.grey,
                        ),
                      ),
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
