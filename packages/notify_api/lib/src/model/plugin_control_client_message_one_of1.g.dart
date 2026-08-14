// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlClientMessageOneOf1TypeEnum
_$pluginControlClientMessageOneOf1TypeEnum_pendingSnapshotResponse =
    const PluginControlClientMessageOneOf1TypeEnum._('pendingSnapshotResponse');

PluginControlClientMessageOneOf1TypeEnum
_$pluginControlClientMessageOneOf1TypeEnumValueOf(String name) {
  switch (name) {
    case 'pendingSnapshotResponse':
      return _$pluginControlClientMessageOneOf1TypeEnum_pendingSnapshotResponse;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlClientMessageOneOf1TypeEnum>
_$pluginControlClientMessageOneOf1TypeEnumValues =
    BuiltSet<PluginControlClientMessageOneOf1TypeEnum>(
      const <PluginControlClientMessageOneOf1TypeEnum>[
        _$pluginControlClientMessageOneOf1TypeEnum_pendingSnapshotResponse,
      ],
    );

Serializer<PluginControlClientMessageOneOf1TypeEnum>
_$pluginControlClientMessageOneOf1TypeEnumSerializer =
    _$PluginControlClientMessageOneOf1TypeEnumSerializer();

class _$PluginControlClientMessageOneOf1TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlClientMessageOneOf1TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pendingSnapshotResponse': 'pending_snapshot_response',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending_snapshot_response': 'pendingSnapshotResponse',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlClientMessageOneOf1TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlClientMessageOneOf1TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlClientMessageOneOf1TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlClientMessageOneOf1TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlClientMessageOneOf1TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlClientMessageOneOf1
    extends PluginControlClientMessageOneOf1 {
  @override
  final String instanceId;
  @override
  final BuiltList<PendingSnapshotInteractionsInner> interactions;
  @override
  final String requestId;
  @override
  final PluginControlClientMessageOneOf1TypeEnum type;

  factory _$PluginControlClientMessageOneOf1([
    void Function(PluginControlClientMessageOneOf1Builder)? updates,
  ]) => (PluginControlClientMessageOneOf1Builder()..update(updates))._build();

  _$PluginControlClientMessageOneOf1._({
    required this.instanceId,
    required this.interactions,
    required this.requestId,
    required this.type,
  }) : super._();
  @override
  PluginControlClientMessageOneOf1 rebuild(
    void Function(PluginControlClientMessageOneOf1Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf1Builder toBuilder() =>
      PluginControlClientMessageOneOf1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf1 &&
        instanceId == other.instanceId &&
        interactions == other.interactions &&
        requestId == other.requestId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, interactions.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlClientMessageOneOf1')
          ..add('instanceId', instanceId)
          ..add('interactions', interactions)
          ..add('requestId', requestId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlClientMessageOneOf1Builder
    implements
        Builder<
          PluginControlClientMessageOneOf1,
          PluginControlClientMessageOneOf1Builder
        > {
  _$PluginControlClientMessageOneOf1? _$v;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  ListBuilder<PendingSnapshotInteractionsInner>? _interactions;
  ListBuilder<PendingSnapshotInteractionsInner> get interactions =>
      _$this._interactions ??= ListBuilder<PendingSnapshotInteractionsInner>();
  set interactions(
    ListBuilder<PendingSnapshotInteractionsInner>? interactions,
  ) => _$this._interactions = interactions;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  PluginControlClientMessageOneOf1TypeEnum? _type;
  PluginControlClientMessageOneOf1TypeEnum? get type => _$this._type;
  set type(PluginControlClientMessageOneOf1TypeEnum? type) =>
      _$this._type = type;

  PluginControlClientMessageOneOf1Builder() {
    PluginControlClientMessageOneOf1._defaults(this);
  }

  PluginControlClientMessageOneOf1Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _instanceId = $v.instanceId;
      _interactions = $v.interactions.toBuilder();
      _requestId = $v.requestId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf1 other) {
    _$v = other as _$PluginControlClientMessageOneOf1;
  }

  @override
  void update(void Function(PluginControlClientMessageOneOf1Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf1 build() => _build();

  _$PluginControlClientMessageOneOf1 _build() {
    _$PluginControlClientMessageOneOf1 _$result;
    try {
      _$result =
          _$v ??
          _$PluginControlClientMessageOneOf1._(
            instanceId: BuiltValueNullFieldError.checkNotNull(
              instanceId,
              r'PluginControlClientMessageOneOf1',
              'instanceId',
            ),
            interactions: interactions.build(),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'PluginControlClientMessageOneOf1',
              'requestId',
            ),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'PluginControlClientMessageOneOf1',
              'type',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'interactions';
        interactions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PluginControlClientMessageOneOf1',
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
