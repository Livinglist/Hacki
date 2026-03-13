import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';
import 'package:hacki/utils/log_util.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  static const String routeName = 'logs';

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<String> _logs = <String>[];

  @override
  void initState() {
    super.initState();

    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final List<String> logs = await LogUtil.exportLogsAsStrings();
    if (mounted) {
      setState(() {
        _logs = logs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: Dimens.zero,
        actions: <Widget>[
          IconButton(
            onPressed: _fetchLogs,
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {
              if (_logs.isEmpty) return;
              final String data = _logs.reduce(
                (
                  String lhs,
                  String rhs,
                ) =>
                    lhs + rhs,
              );
              Clipboard.setData(ClipboardData(text: data))
                  .whenComplete(HapticFeedbackUtil.selection);
              context.showSnackBar(content: 'Logs copied.');
            },
            icon: Icon(
              Icons.copy,
              color: _logs.isEmpty
                  ? Palette.grey
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: Scrollbar(
        child: kDebugMode
            ? const Column(
                children: <Widget>[
                  SizedBoxes.pt48,
                  Text(
                    '''Logs won't show up here in debug mode.\nYou can modify `LogUtil.logOutput()` to enable it.''',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView(
                reverse: true,
                children: _logs.reversed.map(Text.new).toList(),
              ),
      ),
    );
  }
}
