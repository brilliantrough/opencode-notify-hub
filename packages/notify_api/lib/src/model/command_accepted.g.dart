// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_accepted.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CommandAcceptedStatusEnum _$commandAcceptedStatusEnum_accepted =
    const CommandAcceptedStatusEnum._('accepted');

CommandAcceptedStatusEnum _$commandAcceptedStatusEnumValueOf(String name) {
  switch (name) {
    case 'accepted':
      return _$commandAcceptedStatusEnum_accepted;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CommandAcceptedStatusEnum> _$commandAcceptedStatusEnumValues =
    BuiltSet<CommandAcceptedStatusEnum>(const <CommandAcceptedStatusEnum>[
      _$commandAcceptedStatusEnum_accepted,
    ]);

Serializer<CommandAcceptedStatusEnum> _$commandAcceptedStatusEnumSerializer =
    _$CommandAcceptedStatusEnumSerializer();

class _$CommandAcceptedStatusEnumSerializer
    implements PrimitiveSerializer<CommandAcceptedStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'accepted': 'accepted',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'accepted': 'accepted',
  };

  @override
  final Iterable<Type> types = const <Type>[CommandAcceptedStatusEnum];
  @override
  final String wireName = 'CommandAcceptedStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    CommandAcceptedStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CommandAcceptedStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CommandAcceptedStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CommandAccepted extends CommandAccepted {
  @override
  final String commandId;
  @override
  final CommandAcceptedStatusEnum status;

  factory _$CommandAccepted([void Function(CommandAcceptedBuilder)? updates]) =>
      (CommandAcceptedBuilder()..update(updates))._build();

  _$CommandAccepted._({required this.commandId, required this.status})
    : super._();
  @override
  CommandAccepted rebuild(void Function(CommandAcceptedBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandAcceptedBuilder toBuilder() => CommandAcceptedBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandAccepted &&
        commandId == other.commandId &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CommandAccepted')
          ..add('commandId', commandId)
          ..add('status', status))
        .toString();
  }
}

class CommandAcceptedBuilder
    implements Builder<CommandAccepted, CommandAcceptedBuilder> {
  _$CommandAccepted? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  CommandAcceptedStatusEnum? _status;
  CommandAcceptedStatusEnum? get status => _$this._status;
  set status(CommandAcceptedStatusEnum? status) => _$this._status = status;

  CommandAcceptedBuilder() {
    CommandAccepted._defaults(this);
  }

  CommandAcceptedBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandAccepted other) {
    _$v = other as _$CommandAccepted;
  }

  @override
  void update(void Function(CommandAcceptedBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CommandAccepted build() => _build();

  _$CommandAccepted _build() {
    final _$result =
        _$v ??
        _$CommandAccepted._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'CommandAccepted',
            'commandId',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'CommandAccepted',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
