import 'package:flutter/material.dart';
import 'package:hacki/models/search_params.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';

class PostedByFilterChip extends StatelessWidget {
  const PostedByFilterChip({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final PostedByFilter? filter;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (_) async {
        final String? username = await onChipTapped(context);
        if (username == filter?.author) {
          return;
        }
        onChanged(username);
      },
      selected: filter != null,
      label: '''posted by ${filter?.author ?? ''}'''.trimRight(),
    );
  }

  Future<String?> onChipTapped(BuildContext context) async {
    final TextEditingController usernameController = TextEditingController();

    if (filter?.author != null) {
      usernameController.text = filter!.author;
    }

    final String? username = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.pt18,
              ),
              child: TextField(
                controller: usernameController,
                cursorColor: Palette.orange,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'Username',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Palette.orange),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: Dimens.pt16,
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Dimens.pt12,
              ),
              child: ButtonBar(
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, filter?.author),
                    child: const Text(
                      'Cancel',
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text(
                      'Clear',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final String text = usernameController.text.trim();
                      Navigator.pop(context, text.isEmpty ? null : text);
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Palette.deepOrange),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Palette.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    return username;
  }
}
