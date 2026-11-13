import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

const NetworkProxy _proxy = NetworkProxy(
  isEnabled: true,
  host: '10.0.0.2',
  port: 8080,
);

void main() {
  late MockNetworkProxyService service;

  setUp(() {
    service = MockNetworkProxyService();
    when(() => service.proxy).thenReturn(const NetworkProxy.none());
    when(() => service.isAppliedToWebViews).thenReturn(true);
    when(() => service.update(_proxy)).thenAnswer((_) async {
      when(() => service.proxy).thenReturn(_proxy);
    });
  });

  group('NetworkProxyCubit', () {
    test('starts with the proxy already in use', () {
      when(() => service.proxy).thenReturn(_proxy);

      expect(
        NetworkProxyCubit(networkProxyService: service).state,
        const NetworkProxyState(proxy: _proxy, isAppliedToWebViews: true),
      );
    });

    blocTest<NetworkProxyCubit, NetworkProxyState>(
      'update hands the proxy to the service and emits it',
      build: () => NetworkProxyCubit(networkProxyService: service),
      act: (NetworkProxyCubit cubit) => cubit.update(_proxy),
      expect: () => <NetworkProxyState>[
        const NetworkProxyState(proxy: _proxy, isAppliedToWebViews: true),
      ],
      verify: (_) => verify(() => service.update(_proxy)).called(1),
    );

    blocTest<NetworkProxyCubit, NetworkProxyState>(
      'tells when web views could not be put on the proxy',
      setUp: () => when(() => service.update(_proxy)).thenAnswer((_) async {
        when(() => service.proxy).thenReturn(_proxy);
        when(() => service.isAppliedToWebViews).thenReturn(false);
      }),
      build: () => NetworkProxyCubit(networkProxyService: service),
      act: (NetworkProxyCubit cubit) => cubit.update(_proxy),
      expect: () => <NetworkProxyState>[
        const NetworkProxyState(proxy: _proxy, isAppliedToWebViews: false),
      ],
    );
  });
}
