// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PluginControlServerMessageOneOf1TypeEnum
_$pluginControlServerMessageOneOf1TypeEnum_pendingSnapshotRequest =
    const PluginControlServerMessageOneOf1TypeEnum._('pendingSnapshotRequest');

PluginControlServerMessageOneOf1TypeEnum
_$pluginControlServerMessageOneOf1TypeEnumValueOf(String name) {
  switch (name) {
    case 'pendingSnapshotRequest':
      return _$pluginControlServerMessageOneOf1TypeEnum_pendingSnapshotRequest;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PluginControlServerMessageOneOf1TypeEnum>
_$pluginControlServerMessageOneOf1TypeEnumValues =
    BuiltSet<PluginControlServerMessageOneOf1TypeEnum>(
      const <PluginControlServerMessageOneOf1TypeEnum>[
        _$pluginControlServerMessageOneOf1TypeEnum_pendingSnapshotRequest,
      ],
    );

Serializer<PluginControlServerMessageOneOf1TypeEnum>
_$pluginControlServerMessageOneOf1TypeEnumSerializer =
    _$PluginControlServerMessageOneOf1TypeEnumSerializer();

class _$PluginControlServerMessageOneOf1TypeEnumSerializer
    implements PrimitiveSerializer<PluginControlServerMessageOneOf1TypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pendingSnapshotRequest': 'pending_snapshot_request',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending_snapshot_request': 'pendingSnapshotRequest',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PluginControlServerMessageOneOf1TypeEnum,
  ];
  @override
  final String wireName = 'PluginControlServerMessageOneOf1TypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PluginControlServerMessageOneOf1TypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PluginControlServerMessageOneOf1TypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PluginControlServerMessageOneOf1TypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PluginControlServerMessageOneOf1
    extends PluginControlServerMessageOneOf1 {
  @override
  final String requestId;
  @override
  final PluginControlServerMessageOneOf1TypeEnum type;

  factory _$PluginControlServerMessageOneOf1([
    void Function(PluginControlServerMessageOneOf1Builder)? updates,
  ]) => (PluginControlServerMessageOneOf1Builder()..update(updates))._build();

  _$PluginControlServerMessageOneOf1._({
    required this.requestId,
    required this.type,
  }) : super._();
  @override
  PluginControlServerMessageOneOf1 rebuild(
    void Function(PluginControlServerMessageOneOf1Builder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf1Builder toBuilder() =>
      PluginControlServerMessageOneOf1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf1 &&
        requestId == other.requestId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PluginControlServerMessageOneOf1')
          ..add('requestId', requestId)
          ..add('type', type))
        .toString();
  }
}

class PluginControlServerMessageOneOf1Builder
    implements
        Builder<
          PluginControlServerMessageOneOf1,
          PluginControlServerMessageOneOf1Builder
        > {
  _$PluginControlServerMessageOneOf1? _$v;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  PluginControlServerMessageOneOf1TypeEnum? _type;
  PluginControlServerMessageOneOf1TypeEnum? get type => _$this._type;
  set type(PluginControlServerMessageOneOf1TypeEnum? type) =>
      _$this._type = type;

  PluginControlServerMessageOneOf1Builder() {
    PluginControlServerMessageOneOf1._defaults(this);
  }

  PluginControlServerMessageOneOf1Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _requestId = $v.requestId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessageOneOf1 other) {
    _$v = other as _$PluginControlServerMessageOneOf1;
  }

  @override
  void update(void Function(PluginControlServerMessageOneOf1Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf1 build() => _build();

  _$PluginControlServerMessageOneOf1 _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessageOneOf1._(
          requestId: BuiltValueNullFieldError.checkNotNull(
            requestId,
            r'PluginControlServerMessageOneOf1',
            'requestId',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'PluginControlServerMessageOneOf1',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
