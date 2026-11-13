part of 'network_proxy_cubit.dart';

class NetworkProxyState extends Equatable {
  const NetworkProxyState({
    required this.proxy,
    required this.isAppliedToWebViews,
  });

  final NetworkProxy proxy;

  /// False when the proxy is active but web views can't use it.
  final bool isAppliedToWebViews;

  @override
  List<Object?> get props => <Object?>[proxy, isAppliedToWebViews];
}
