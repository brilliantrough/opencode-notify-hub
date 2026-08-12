import 'package:built_collection/built_collection.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/ingest_keys/ingest_keys_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notify_api/notify_api.dart';

class MockIngestKeysApi extends Mock implements IngestKeysApi {}

/// Auth controller seeded directly into a fixed state (à la devices tests).
class SeededAuthController extends AuthController {
  SeededAuthController(this._seed);

  final AuthState _seed;

  @override
  AuthState build() => _seed;
}

void main() {
  setUpAll(() {
    registerFallbackValue(CreateIngestKeyBody((b) => b.name = ''));
  });

  const authenticated = Authenticated(
    accessToken: 'access-1',
    email: 'user@example.com',
  );

  final t1 = DateTime.utc(2026, 1, 2, 10);
  final t2 = DateTime.utc(2026, 1, 3, 11);

  late MockIngestKeysApi ingestKeysApi;
  late ProviderContainer container;

  IngestKeyListResponseInner listInner({
    String id = 'key-1',
    String name = 'ci-runner',
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return IngestKeyListResponseInner(
      (b) => b
        ..id = id
        ..name = name
        ..createdAt = (createdAt ?? t1).toUtc()
        ..lastUsedAt = lastUsedAt?.toUtc(),
    );
  }

  Response<BuiltList<IngestKeyListResponseInner>> listResponse(
    List<IngestKeyListResponseInner> keys,
  ) {
    return Response<BuiltList<IngestKeyListResponseInner>>(
      data: keys.toBuiltList(),
      statusCode: 200,
      requestOptions: RequestOptions(path: '/v1/ingest-keys'),
    );
  }

  void stubList(List<IngestKeyListResponseInner> keys) {
    when(
      () => ingestKeysApi.listIngestKeys(),
    ).thenAnswer((_) async => listResponse(keys));
  }

  IngestKeysController controller() =>
      container.read(ingestKeysControllerProvider.notifier);

  Future<List<IngestKey>> keys() =>
      container.read(ingestKeysControllerProvider.future);

  ProviderContainer unauthenticatedContainer() {
    final c = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => SeededAuthController(const Unauthenticated()),
        ),
        ingestKeysApiProvider.overrideWithValue(ingestKeysApi),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    ingestKeysApi = MockIngestKeysApi();
    stubList(const []);
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => SeededAuthController(authenticated),
        ),
        ingestKeysApiProvider.overrideWithValue(ingestKeysApi),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('build', () {
    test('lists the authenticated user\'s ingest keys', () async {
      stubList([
        listInner(id: 'key-1', name: 'ci-runner', lastUsedAt: t2),
        listInner(id: 'key-2', name: 'laptop'),
      ]);

      final result = await keys();

      expect(result, [
        IngestKey(id: 'key-1', name: 'ci-runner', createdAt: t1, lastUsedAt: t2),
        IngestKey(id: 'key-2', name: 'laptop', createdAt: t1),
      ]);
      verify(() => ingestKeysApi.listIngestKeys()).called(greaterThan(0));
    });

    test('is empty and never calls the gateway when unauthenticated', () async {
      final unauthenticated = unauthenticatedContainer();

      final result = await unauthenticated.read(
        ingestKeysControllerProvider.future,
      );

      expect(result, isEmpty);
      verifyNever(() => ingestKeysApi.listIngestKeys());
    });
  });

  group('create', () {
    test('returns the one-time secret and adds a secret-free row to state',
        () async {
      when(
        () => ingestKeysApi.createIngestKey(
          createIngestKeyBody: any(named: 'createIngestKeyBody'),
        ),
      ).thenAnswer(
        (_) async => Response<CreateIngestKeyResponse>(
          data: CreateIngestKeyResponse(
            (b) => b
              ..id = 'key-9'
              ..name = 'new-key'
              ..secret = 'nk-secret-abc'
              ..createdAt = t2.toUtc(),
          ),
          statusCode: 201,
          requestOptions: RequestOptions(path: '/v1/ingest-keys'),
        ),
      );
      await keys();

      final created = await controller().create('new-key');

      // The one-time secret lives only in the method result.
      expect(created.secret, 'nk-secret-abc');
      expect(created.id, 'key-9');
      final captured =
          verify(
                () => ingestKeysApi.createIngestKey(
                  createIngestKeyBody: captureAny(named: 'createIngestKeyBody'),
                ),
              ).captured.single
              as CreateIngestKeyBody;
      expect(captured.name, 'new-key');
      // The state row carries no secret (IngestKey has no secret field).
      final current = await keys();
      expect(current, [
        IngestKey(id: 'key-9', name: 'new-key', createdAt: t2),
      ]);
    });

    test('throws StateError when unauthenticated and never calls the gateway',
        () async {
      final unauthenticated = unauthenticatedContainer();

      await expectLater(
        unauthenticated
            .read(ingestKeysControllerProvider.notifier)
            .create('x'),
        throwsStateError,
      );
      verifyNever(
        () => ingestKeysApi.createIngestKey(
          createIngestKeyBody: any(named: 'createIngestKeyBody'),
        ),
      );
    });
  });

  group('list', () {
    test('refreshes state from the gateway and returns the keys', () async {
      stubList([listInner(id: 'key-1')]);
      await keys();

      stubList([listInner(id: 'key-1'), listInner(id: 'key-3', name: 'new')]);
      final refreshed = await controller().list();

      expect(refreshed.map((k) => k.id), ['key-1', 'key-3']);
      expect((await keys()).map((k) => k.id), ['key-1', 'key-3']);
    });

    test('throws StateError when unauthenticated and never calls the gateway',
        () async {
      final unauthenticated = unauthenticatedContainer();

      await expectLater(
        unauthenticated.read(ingestKeysControllerProvider.notifier).list(),
        throwsStateError,
      );
      verifyNever(() => ingestKeysApi.listIngestKeys());
    });
  });

  group('revoke', () {
    test('calls DELETE and removes the row from state', () async {
      stubList([listInner(id: 'key-1'), listInner(id: 'key-2')]);
      when(
        () => ingestKeysApi.revokeIngestKey(id: any(named: 'id')),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/v1/ingest-keys/key-1'),
        ),
      );
      await keys();

      await controller().revoke('key-1');

      verify(() => ingestKeysApi.revokeIngestKey(id: 'key-1')).called(1);
      expect((await keys()).map((k) => k.id), ['key-2']);
    });

    test('throws StateError when unauthenticated and never calls the gateway',
        () async {
      final unauthenticated = unauthenticatedContainer();

      await expectLater(
        unauthenticated
            .read(ingestKeysControllerProvider.notifier)
            .revoke('x'),
        throwsStateError,
      );
      verifyNever(() => ingestKeysApi.revokeIngestKey(id: any(named: 'id')));
    });
  });
}
