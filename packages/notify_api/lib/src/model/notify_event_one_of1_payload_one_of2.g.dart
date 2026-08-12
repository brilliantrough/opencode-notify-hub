// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1_payload_one_of2.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf1PayloadOneOf2KindEnum
_$notifyEventOneOf1PayloadOneOf2KindEnum_providerAction =
    const NotifyEventOneOf1PayloadOneOf2KindEnum._('providerAction');

NotifyEventOneOf1PayloadOneOf2KindEnum
_$notifyEventOneOf1PayloadOneOf2KindEnumValueOf(String name) {
  switch (name) {
    case 'providerAction':
      return _$notifyEventOneOf1PayloadOneOf2KindEnum_providerAction;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf1PayloadOneOf2KindEnum>
_$notifyEventOneOf1PayloadOneOf2KindEnumValues =
    BuiltSet<NotifyEventOneOf1PayloadOneOf2KindEnum>(
      const <NotifyEventOneOf1PayloadOneOf2KindEnum>[
        _$notifyEventOneOf1PayloadOneOf2KindEnum_providerAction,
      ],
    );

Serializer<NotifyEventOneOf1PayloadOneOf2KindEnum>
_$notifyEventOneOf1PayloadOneOf2KindEnumSerializer =
    _$NotifyEventOneOf1PayloadOneOf2KindEnumSerializer();

class _$NotifyEventOneOf1PayloadOneOf2KindEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf1PayloadOneOf2KindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'providerAction': 'provider_action',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'provider_action': 'providerAction',
  };

  @override
  final Iterable<Type> types = const <Type>[
    NotifyEventOneOf1PayloadOneOf2KindEnum,
  ];
  @override
  final String wireName = 'NotifyEventOneOf1PayloadOneOf2KindEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf2KindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf1PayloadOneOf2KindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf1PayloadOneOf2KindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf1PayloadOneOf2 extends NotifyEventOneOf1PayloadOneOf2 {
  @override
  final NotifyEventOneOf1PayloadOneOf2KindEnum kind;
  @override
  final NotifyEventOneOf1PayloadOneOf2ProviderAction providerAction;
  @override
  final String requestId;

  factory _$NotifyEventOneOf1PayloadOneOf2([
    void Function(NotifyEventOneOf1PayloadOneOf2Builder)? updates,
  ]) => (NotifyEventOneOf1PayloadOneOf2Builder()..update(updates))._build();

  _$NotifyEventOneOf1PayloadOneOf2._({
    required this.kind,
    required this.providerAction,
    required this.requestId,
  }) : super._();
  @override
  NotifyEventOneOf1PayloadOneOf2 rebuild(
    void Function(NotifyEventOneOf1PayloadOneOf2Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1PayloadOneOf2Builder toBuilder() =>
      NotifyEventOneOf1PayloadOneOf2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1PayloadOneOf2 &&
        kind == other.kind &&
        providerAction == other.providerAction &&
        requestId == other.requestId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, providerAction.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf1PayloadOneOf2')
          ..add('kind', kind)
          ..add('providerAction', providerAction)
          ..add('requestId', requestId))
        .toString();
  }
}

class NotifyEventOneOf1PayloadOneOf2Builder
    implements
        Builder<
          NotifyEventOneOf1PayloadOneOf2,
          NotifyEventOneOf1PayloadOneOf2Builder
        > {
  _$NotifyEventOneOf1PayloadOneOf2? _$v;

  NotifyEventOneOf1PayloadOneOf2KindEnum? _kind;
  NotifyEventOneOf1PayloadOneOf2KindEnum? get kind => _$this._kind;
  set kind(NotifyEventOneOf1PayloadOneOf2KindEnum? kind) => _$this._kind = kind;

  NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder? _providerAction;
  NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder get providerAction =>
      _$this._providerAction ??=
          NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder();
  set providerAction(
    NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder? providerAction,
  ) => _$this._providerAction = providerAction;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  NotifyEventOneOf1PayloadOneOf2Builder() {
    NotifyEventOneOf1PayloadOneOf2._defaults(this);
  }

  NotifyEventOneOf1PayloadOneOf2Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _kind = $v.kind;
      _providerAction = $v.providerAction.toBuilder();
      _requestId = $v.requestId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1PayloadOneOf2 other) {
    _$v = other as _$NotifyEventOneOf1PayloadOneOf2;
  }

  @override
  void update(void Function(NotifyEventOneOf1PayloadOneOf2Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1PayloadOneOf2 build() => _build();

  _$NotifyEventOneOf1PayloadOneOf2 _build() {
    _$NotifyEventOneOf1PayloadOneOf2 _$result;
    try {
      _$result =
          _$v ??
          _$NotifyEventOneOf1PayloadOneOf2._(
            kind: BuiltValueNullFieldError.checkNotNull(
              kind,
              r'NotifyEventOneOf1PayloadOneOf2',
              'kind',
            ),
            providerAction: providerAction.build(),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'NotifyEventOneOf1PayloadOneOf2',
              'requestId',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'providerAction';
        providerAction.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'NotifyEventOneOf1PayloadOneOf2',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
