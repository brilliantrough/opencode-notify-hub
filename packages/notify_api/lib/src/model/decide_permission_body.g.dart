// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decide_permission_body.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DecidePermissionBodyDecisionEnum _$decidePermissionBodyDecisionEnum_once =
    const DecidePermissionBodyDecisionEnum._('once');
const DecidePermissionBodyDecisionEnum
_$decidePermissionBodyDecisionEnum_reject =
    const DecidePermissionBodyDecisionEnum._('reject');
const DecidePermissionBodyDecisionEnum
_$decidePermissionBodyDecisionEnum_always =
    const DecidePermissionBodyDecisionEnum._('always');

DecidePermissionBodyDecisionEnum _$decidePermissionBodyDecisionEnumValueOf(
  String name,
) {
  switch (name) {
    case 'once':
      return _$decidePermissionBodyDecisionEnum_once;
    case 'reject':
      return _$decidePermissionBodyDecisionEnum_reject;
    case 'always':
      return _$decidePermissionBodyDecisionEnum_always;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DecidePermissionBodyDecisionEnum>
_$decidePermissionBodyDecisionEnumValues =
    BuiltSet<DecidePermissionBodyDecisionEnum>(
      const <DecidePermissionBodyDecisionEnum>[
        _$decidePermissionBodyDecisionEnum_once,
        _$decidePermissionBodyDecisionEnum_reject,
        _$decidePermissionBodyDecisionEnum_always,
      ],
    );

Serializer<DecidePermissionBodyDecisionEnum>
_$decidePermissionBodyDecisionEnumSerializer =
    _$DecidePermissionBodyDecisionEnumSerializer();

class _$DecidePermissionBodyDecisionEnumSerializer
    implements PrimitiveSerializer<DecidePermissionBodyDecisionEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'once': 'once',
    'reject': 'reject',
    'always': 'always',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'once': 'once',
    'reject': 'reject',
    'always': 'always',
  };

  @override
  final Iterable<Type> types = const <Type>[DecidePermissionBodyDecisionEnum];
  @override
  final String wireName = 'DecidePermissionBodyDecisionEnum';

  @override
  Object serialize(
    Serializers serializers,
    DecidePermissionBodyDecisionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DecidePermissionBodyDecisionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DecidePermissionBodyDecisionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$DecidePermissionBody extends DecidePermissionBody {
  @override
  final String commandId;
  @override
  final DecidePermissionBodyDecisionEnum decision;

  factory _$DecidePermissionBody([
    void Function(DecidePermissionBodyBuilder)? updates,
  ]) => (DecidePermissionBodyBuilder()..update(updates))._build();

  _$DecidePermissionBody._({required this.commandId, required this.decision})
    : super._();
  @override
  DecidePermissionBody rebuild(
    void Function(DecidePermissionBodyBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DecidePermissionBodyBuilder toBuilder() =>
      DecidePermissionBodyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DecidePermissionBody &&
        commandId == other.commandId &&
        decision == other.decision;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandId.hashCode);
    _$hash = $jc(_$hash, decision.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DecidePermissionBody')
          ..add('commandId', commandId)
          ..add('decision', decision))
        .toString();
  }
}

class DecidePermissionBodyBuilder
    implements Builder<DecidePermissionBody, DecidePermissionBodyBuilder> {
  _$DecidePermissionBody? _$v;

  String? _commandId;
  String? get commandId => _$this._commandId;
  set commandId(String? commandId) => _$this._commandId = commandId;

  DecidePermissionBodyDecisionEnum? _decision;
  DecidePermissionBodyDecisionEnum? get decision => _$this._decision;
  set decision(DecidePermissionBodyDecisionEnum? decision) =>
      _$this._decision = decision;

  DecidePermissionBodyBuilder() {
    DecidePermissionBody._defaults(this);
  }

  DecidePermissionBodyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandId = $v.commandId;
      _decision = $v.decision;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DecidePermissionBody other) {
    _$v = other as _$DecidePermissionBody;
  }

  @override
  void update(void Function(DecidePermissionBodyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DecidePermissionBody build() => _build();

  _$DecidePermissionBody _build() {
    final _$result =
        _$v ??
        _$DecidePermissionBody._(
          commandId: BuiltValueNullFieldError.checkNotNull(
            commandId,
            r'DecidePermissionBody',
            'commandId',
          ),
          decision: BuiltValueNullFieldError.checkNotNull(
            decision,
            r'DecidePermissionBody',
            'decision',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
