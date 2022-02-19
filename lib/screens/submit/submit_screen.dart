import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({Key? key}) : super(key: key);

  static const String routeName = '/submit';

  static Route route() {
    return MaterialPageRoute<SubmitScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (context) => BlocProvider(
        create: (context) => SubmitCubit(),
        child: const SubmitScreen(),
      ),
    );
  }

  @override
  _SubmitScreenState createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  final titleEditingController = TextEditingController();
  final urlEditingController = TextEditingController();
  final textEditingController = TextEditingController();

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
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SubmitStatus.submitted) {
          Navigator.pop(context);
          showSnackBar(
            content: 'Post submitted successfully.',
          );
        } else if (state.status == SubmitStatus.failure) {
          showSnackBar(
            content: 'Something went wrong...',
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).canvasColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Quit editing?'),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ).then((value) {
                  if (value ?? false) {
                    Navigator.of(context).pop();
                  }
                });
              },
            ),
            title: const Text(
              'Submit',
            ),
            actions: [
              if (state.status == SubmitStatus.submitting)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (canSubmit())
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.orange,
                  ),
                  onPressed: context.read<SubmitCubit>().onSubmitTapped,
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.grey,
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: titleEditingController,
                  cursorColor: Colors.orange,
                  autocorrect: false,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                  ),
                  onChanged: context.read<SubmitCubit>().onTitleChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  enabled: textEditingController.text.isEmpty,
                  controller: urlEditingController,
                  cursorColor: Colors.orange,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'Url',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                  ),
                  onChanged: context.read<SubmitCubit>().onUrlChanged,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('or'),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    enabled: urlEditingController.text.isEmpty,
                    controller: textEditingController,
                    cursorColor: Colors.orange,
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

  void showSnackBar({required String content}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        content,
      ),
      backgroundColor: Colors.orange,
    ));
  }
}
