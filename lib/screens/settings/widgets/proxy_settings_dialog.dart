import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user choose the proxy every connection of the app goes through.
class ProxySettingsDialog extends StatefulWidget {
  const ProxySettingsDialog({super.key});

  @override
  State<ProxySettingsDialog> createState() => _ProxySettingsDialogState();
}

class _ProxySettingsDialogState extends State<ProxySettingsDialog> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  bool _isEnabled = false;
  bool _isSaving = false;
  String? _hostError;
  String? _portError;

  @override
  void initState() {
    super.initState();

    final NetworkProxy proxy = context.read<NetworkProxyCubit>().state.proxy;
    _isEnabled = proxy.isEnabled;
    _hostController.text = proxy.host;
    _portController.text = proxy.port?.toString() ?? '';
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: const Text('Proxy'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use Proxy'),
              value: _isEnabled,
              activeThumbColor: primaryColor,
              onChanged: (bool val) {
                HapticFeedbackUtils.light();
                setState(() {
                  _isEnabled = val;
                  _hostError = null;
                  _portError = null;
                });
              },
            ),
            TextField(
              controller: _hostController,
              cursorColor: primaryColor,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Host',
                hintText: '127.0.0.1',
                errorText: _hostError,
              ),
            ),
            SizedBoxes.pt12,
            TextField(
              controller: _portController,
              cursorColor: primaryColor,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              onSubmitted: (_) => _onSaveTapped(),
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: '8080',
                errorText: _portError,
              ),
            ),
            SizedBoxes.pt16,
            const Text(
              '''HTTP proxy for every connection Hacki makes, web views included. There is no fallback: if the proxy can't be reached, nothing loads. Links opened in a browser use the connection of that browser.''',
              style: TextStyle(color: Palette.grey, fontSize: TextDimens.pt12),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: context.pop, child: const Text('Cancel')),
        TextButton(
          onPressed: _isSaving ? null : _onSaveTapped,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _onSaveTapped() async {
    final String host = NetworkProxy.normalizeHost(_hostController.text);
    final int? port = int.tryParse(_portController.text.trim());

    if (_isEnabled) {
      final String? hostError = NetworkProxy.isValidHost(host)
          ? null
          : 'Enter a host name or an IP address.';
      final String? portError = NetworkProxy.isValidPort(port)
          ? null
          : 'Enter a port from 1 to ${NetworkProxy.maxPort}.';

      if (hostError != null || portError != null) {
        setState(() {
          _hostError = hostError;
          _portError = portError;
        });
        return;
      }
    }

    setState(() => _isSaving = true);

    final NetworkProxyCubit cubit = context.read<NetworkProxyCubit>();
    await cubit.update(
      NetworkProxy(isEnabled: _isEnabled, host: host, port: port),
    );

    if (!mounted) return;

    HapticFeedbackUtils.success();
    final NetworkProxyState state = cubit.state;
    context
      ..pop()
      ..showSnackBar(
        content: !state.proxy.isActive
            ? 'Proxy is off.'
            : state.isAppliedToWebViews
            ? 'Connections now go through ${state.proxy.address}.'
            : '''Connections now go through ${state.proxy.address}, except for web views, which can't use a proxy on this device.''',
      );
  }
}
