import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/services/network_proxy_service.dart';

part 'network_proxy_state.dart';

class NetworkProxyCubit extends Cubit<NetworkProxyState> {
  NetworkProxyCubit({NetworkProxyService? networkProxyService})
    : this._(networkProxyService ?? locator.get<NetworkProxyService>());

  NetworkProxyCubit._(this._networkProxyService)
    : super(
        NetworkProxyState(
          proxy: _networkProxyService.proxy,
          isAppliedToWebViews: _networkProxyService.isAppliedToWebViews,
        ),
      );

  final NetworkProxyService _networkProxyService;

  Future<void> update(NetworkProxy proxy) async {
    await _networkProxyService.update(proxy);
    emit(
      NetworkProxyState(
        proxy: _networkProxyService.proxy,
        isAppliedToWebViews: _networkProxyService.isAppliedToWebViews,
      ),
    );
  }
}
