import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';
import 'package:hacki/utils/log_util.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  static const String routeName = 'logs';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: LogUtil.exportLogAsStrings(),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Theme.of(context).canvasColor.withValues(
                  alpha: 0.6,
                ),
            elevation: Dimens.zero,
            actions: <Widget>[
              if (snapshot.data != null)
                IconButton(
                  onPressed: () {
                    final String data = snapshot.data!.reduce(
                      (
                        String lhs,
                        String rhs,
                      ) =>
                          lhs + rhs,
                    );
                    Clipboard.setData(ClipboardData(text: data))
                        .whenComplete(HapticFeedbackUtil.selection);
                    context.showSnackBar(content: 'Log copied.');
                  },
                  icon: const Icon(Icons.copy),
                ),
            ],
          ),
          body: Scrollbar(
            child: ListView(
              children: <Widget>[
                if (kDebugMode) ...<Widget>[
                  SizedBoxes.pt48,
                  const Text(
                    '''Logs won't show up here in debug mode.\nYou can modify `LogUtil.logOutput()` to enable it.''',
                    textAlign: TextAlign.center,
                  ),
                ] else
                  ...?snapshot.data?.map(Text.new),
              ],
            ),
          ),
        );
      },
    );
  }
}
