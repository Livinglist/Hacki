import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/settings/widgets/proxy_settings_dialog.dart';
import 'package:material_ui/material_ui.dart';

class ProxyListTile extends StatelessWidget {
  const ProxyListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkProxyCubit, NetworkProxyState>(
      builder: (BuildContext context, NetworkProxyState state) {
        return ListTile(
          title: const Text('Proxy'),
          subtitle: state.proxy.isActive ? Text(state.proxy.address) : null,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const ProxySettingsDialog(),
          ),
        );
      },
    );
  }
}
