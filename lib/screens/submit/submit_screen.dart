import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key});

  static const String routeName = 'submit';

  @override
  _SubmitScreenState createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> with ItemActionMixin {
  final TextEditingController titleEditingController = TextEditingController();
  final TextEditingController urlEditingController = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    titleEditingController.dispose();
    urlEditingController.dispose();
    textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (SubmitState previous, SubmitState current) =>
          previous.status != current.status,
      listener: (BuildContext context, SubmitState state) {
        if (state.status == Status.success) {
          context.pop();
          HapticFeedbackUtil.light();
          showSnackBar(
            content: 'Post submitted.',
          );
        } else if (state.status == Status.failure) {
          showErrorSnackBar();
        }
      },
      builder: (BuildContext context, SubmitState state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).canvasColor,
            elevation: Dimens.zero,
            leading: IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                // Don't show confirmation dialog if content is empty.
                if (state.text.isNullOrEmpty &&
                    state.url.isNullOrEmpty &&
                    state.title.isNullOrEmpty) {
                  context.pop();
                  return;
                }

                showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Quit editing?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => context.pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => context.pop(true),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: Palette.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ).then((bool? value) {
                  if (context.mounted && (value ?? false)) {
                    context.pop();
                  }
                });
              },
            ),
            title: Text(
              'Submit',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            actions: <Widget>[
              if (state.status == Status.inProgress)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimens.pt18,
                    horizontal: Dimens.pt16,
                  ),
                  child: SizedBox(
                    height: Dimens.pt20,
                    width: Dimens.pt20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (canSubmit())
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Submit?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => context.pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => context.pop(true),
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  color: Palette.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ).then((bool? value) {
                      if (context.mounted && (value ?? false)) {
                        context.read<SubmitCubit>().submit();
                      }
                    });
                  },
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Palette.grey,
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.pt12,
                ),
                child: TextField(
                  controller: titleEditingController,
                  cursorColor: Theme.of(context).colorScheme.primary,
                  autocorrect: false,
                  maxLength: 80,
                  decoration: InputDecoration(
                    hintText: 'Title',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  onChanged: context.read<SubmitCubit>().onTitleChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.pt12,
                ),
                child: TextField(
                  enabled: textEditingController.text.isEmpty,
                  controller: urlEditingController,
                  cursorColor: Theme.of(context).colorScheme.primary,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Url',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  onChanged: context.read<SubmitCubit>().onUrlChanged,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Dimens.pt12,
                ),
                child: Center(
                  child: Text('or'),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.pt12,
                  ),
                  child: TextField(
                    enabled: urlEditingController.text.isEmpty,
                    controller: textEditingController,
                    cursorColor: Theme.of(context).colorScheme.primary,
                    maxLines: 200,
                    decoration: const InputDecoration(
                      hintText: 'Text',
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: context.read<SubmitCubit>().onTextChanged,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool canSubmit() {
    return titleEditingController.text.isNotEmpty &&
        (textEditingController.text.isNotEmpty ||
            urlEditingController.text.isNotEmpty);
  }
}
