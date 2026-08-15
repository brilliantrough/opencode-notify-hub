// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_outcome.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CommandOutcomeKindEnum _$commandOutcomeKindEnum_question =
    const CommandOutcomeKindEnum._('question');
const CommandOutcomeKindEnum _$commandOutcomeKindEnum_permission =
    const CommandOutcomeKindEnum._('permission');

CommandOutcomeKindEnum _$commandOutcomeKindEnumValueOf(String name) {
  switch (name) {
    case 'question':
      return _$commandOutcomeKindEnum_question;
    case 'permission':
      return _$commandOutcomeKindEnum_permission;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CommandOutcomeKindEnum> _$commandOutcomeKindEnumValues =
    BuiltSet<CommandOutcomeKindEnum>(const <CommandOutcomeKindEnum>[
      _$commandOutcomeKindEnum_question,
      _$commandOutcomeKindEnum_permission,
    ]);

const CommandOutcomeStatusEnum _$commandOutcomeStatusEnum_accepted =
    const CommandOutcomeStatusEnum._('accepted');
const CommandOutcomeStatusEnum _$commandOutcomeStatusEnum_confirmed =
    const CommandOutcomeStatusEnum._('confirmed');
const CommandOutcomeStatusEnum _$commandOutcomeStatusEnum_stale =
    const CommandOutcomeStatusEnum._('stale');
const CommandOutcomeStatusEnum _$commandOutcomeStatusEnum_upstreamError =
    const CommandOutcomeStatusEnum._('upstreamError');
const CommandOutcomeStatusEnum _$commandOutcomeStatusEnum_resultUnknown =
    const CommandOutcomeStatusEnum._('resultUnknown');

CommandOutcomeStatusEnum _$commandOutcomeStatusEnumValueOf(String name) {
  switch (name) {
    case 'accepted':
      return _$commandOutcomeStatusEnum_accepted;
    case 'confirmed':
      return _$commandOutcomeStatusEnum_confirmed;
    case 'stale':
      return _$commandOutcomeStatusEnum_stale;
    case 'upstreamError':
      return _$commandOutcomeStatusEnum_upstreamError;
    case 'resultUnknown':
      return _$commandOutcomeStatusEnum_resultUnknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CommandOutcomeStatusEnum> _$commandOutcomeStatusEnumValues =
    BuiltSet<CommandOutcomeStatusEnum>(const <CommandOutcomeStatusEnum>[
      _$commandOutcomeStatusEnum_accepted,
      _$commandOutcomeStatusEnum_confirmed,
      _$commandOutcomeStatusEnum_stale,
      _$commandOutcomeStatusEnum_upstreamError,
      _$commandOutcomeStatusEnum_resultUnknown,
    ]);

Serializer<CommandOutcomeKindEnum> _$commandOutcomeKindEnumSerializer =
    _$CommandOutcomeKindEnumSerializer();
Serializer<CommandOutcomeStatusEnum> _$commandOutcomeStatusEnumSerializer =
    _$CommandOutcomeStatusEnumSerializer();

class _$CommandOutcomeKindEnumSerializer
    implements PrimitiveSerializer<CommandOutcomeKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'question': 'question',
    'permission': 'permission',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'question': 'question',
    'permission': 'permission',
  };

  @override
  final Iterable<Type> types = const <Type>[CommandOutcomeKindEnum];
  @override
  final String wireName = 'CommandOutcomeKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    CommandOutcomeKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CommandOutcomeKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CommandOutcomeKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CommandOutcomeStatusEnumSerializer
    implements PrimitiveSerializer<CommandOutcomeStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'accepted': 'accepted',
    'confirmed': 'confirmed',
    'stale': 'stale',
    'upstreamError': 'upstream_error',
    'resultUnknown': 'result_unknown',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'accepted': 'accepted',
    'confirmed': 'confirmed',
    'stale': 'stale',
    'upstream_error': 'upstreamError',
    'result_unknown': 'resultUnknown',
  };

  @override
  final Iterable<Type> types = const <Type>[CommandOutcomeStatusEnum];
  @override
  final String wireName = 'CommandOutcomeStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    CommandOutcomeStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CommandOutcomeStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CommandOutcomeStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CommandOutcome extends CommandOutcome {
  @override
  final String commandId;
  @override
  final String instanceId;
  @override
  final CommandOutcomeKindEnum kind;
  @override
  final String requestId;
  @override
  final CommandOutcomeStatusEnum status;
  @override
  final DateTime updatedAt;

  factory _$CommandOutcome([void Function(CommandOutcomeBuilder)? updates]) =>
      (CommandOutcomeBuilder()..update(updates))._build();

  _$CommandOutcome._({
    required this.commandId,
    required this.instanceId,
    required this.kind,
    required this.requestId,
    required this.status,
    required this.updatedAt,
  }) : super._();
  @override
  CommandOutcome rebuild(void Function(CommandOutcomeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandOutcomeBuilder toBuilder() => CommandOutcomeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandOutcome &&
        commandId == other.commandId &&
        instanceId == other.instanceId &&
        kind == other.kind &&
        requestId == other.requestId &&
        status == other.status &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CommandOutcome')
          ..add('commandId', commandId)
          ..add('instanceId', instanceId)
          ..add('kind', kind)
          ..add('requestId', requestId)
          ..add('status', status)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class CommandOutcomeBuilder
    implements Builder<CommandOutcome, CommandOutcomeBuilder> {
  _$CommandOutcome? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  CommandOutcomeKindEnum? _kind;
  CommandOutcomeKindEnum? get kind => _$this._kind;
  set kind(CommandOutcomeKindEnum? kind) => _$this._kind = kind;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  CommandOutcomeStatusEnum? _status;
  CommandOutcomeStatusEnum? get status => _$this._status;
  set status(CommandOutcomeStatusEnum? status) => _$this._status = status;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  CommandOutcomeBuilder() {
    CommandOutcome._defaults(this);
  }

  CommandOutcomeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _instanceId = $v.instanceId;
      _kind = $v.kind;
      _requestId = $v.requestId;
      _status = $v.status;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandOutcome other) {
    _$v = other as _$CommandOutcome;
  }

  @override
  void update(void Function(CommandOutcomeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CommandOutcome build() => _build();

  _$CommandOutcome _build() {
    final _$result =
        _$v ??
        _$CommandOutcome._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'CommandOutcome',
            'commandId',
          ),
          instanceId: BuiltValueNullFieldError.checkNotNull(
            instanceId,
            r'CommandOutcome',
            'instanceId',
          ),
          kind: BuiltValueNullFieldError.checkNotNull(
            kind,
            r'CommandOutcome',
            'kind',
          ),
          requestId: BuiltValueNullFieldError.checkNotNull(
            requestId,
            r'CommandOutcome',
            'requestId',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'CommandOutcome',
            'status',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'CommandOutcome',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
