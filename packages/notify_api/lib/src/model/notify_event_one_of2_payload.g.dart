// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of2_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotifyEventOneOf2PayloadKindEnum
_$notifyEventOneOf2PayloadKindEnum_question =
    const NotifyEventOneOf2PayloadKindEnum._('question');
const NotifyEventOneOf2PayloadKindEnum
_$notifyEventOneOf2PayloadKindEnum_permission =
    const NotifyEventOneOf2PayloadKindEnum._('permission');

NotifyEventOneOf2PayloadKindEnum _$notifyEventOneOf2PayloadKindEnumValueOf(
  String name,
) {
  switch (name) {
    case 'question':
      return _$notifyEventOneOf2PayloadKindEnum_question;
    case 'permission':
      return _$notifyEventOneOf2PayloadKindEnum_permission;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotifyEventOneOf2PayloadKindEnum>
_$notifyEventOneOf2PayloadKindEnumValues =
    BuiltSet<NotifyEventOneOf2PayloadKindEnum>(
      const <NotifyEventOneOf2PayloadKindEnum>[
        _$notifyEventOneOf2PayloadKindEnum_question,
        _$notifyEventOneOf2PayloadKindEnum_permission,
      ],
    );

Serializer<NotifyEventOneOf2PayloadKindEnum>
_$notifyEventOneOf2PayloadKindEnumSerializer =
    _$NotifyEventOneOf2PayloadKindEnumSerializer();

class _$NotifyEventOneOf2PayloadKindEnumSerializer
    implements PrimitiveSerializer<NotifyEventOneOf2PayloadKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'question': 'question',
    'permission': 'permission',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'question': 'question',
    'permission': 'permission',
  };

  @override
  final Iterable<Type> types = const <Type>[NotifyEventOneOf2PayloadKindEnum];
  @override
  final String wireName = 'NotifyEventOneOf2PayloadKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf2PayloadKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotifyEventOneOf2PayloadKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotifyEventOneOf2PayloadKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$NotifyEventOneOf2Payload extends NotifyEventOneOf2Payload {
  @override
  final NotifyEventOneOf2PayloadKindEnum kind;
  @override
  final String requestId;

  factory _$NotifyEventOneOf2Payload([
    void Function(NotifyEventOneOf2PayloadBuilder)? updates,
  ]) => (NotifyEventOneOf2PayloadBuilder()..update(updates))._build();

  _$NotifyEventOneOf2Payload._({required this.kind, required this.requestId})
    : super._();
  @override
  NotifyEventOneOf2Payload rebuild(
    void Function(NotifyEventOneOf2PayloadBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf2PayloadBuilder toBuilder() =>
      NotifyEventOneOf2PayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf2Payload &&
        kind == other.kind &&
        requestId == other.requestId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOf2Payload')
          ..add('kind', kind)
          ..add('requestId', requestId))
        .toString();
  }
}

class NotifyEventOneOf2PayloadBuilder
    implements
        Builder<NotifyEventOneOf2Payload, NotifyEventOneOf2PayloadBuilder> {
  _$NotifyEventOneOf2Payload? _$v;

  NotifyEventOneOf2PayloadKindEnum? _kind;
  NotifyEventOneOf2PayloadKindEnum? get kind => _$this._kind;
  set kind(NotifyEventOneOf2PayloadKindEnum? kind) => _$this._kind = kind;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  NotifyEventOneOf2PayloadBuilder() {
    NotifyEventOneOf2Payload._defaults(this);
  }

  NotifyEventOneOf2PayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _kind = $v.kind;
      _requestId = $v.requestId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf2Payload other) {
    _$v = other as _$NotifyEventOneOf2Payload;
  }

  @override
  void update(void Function(NotifyEventOneOf2PayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf2Payload build() => _build();

  _$NotifyEventOneOf2Payload _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOf2Payload._(
          kind: BuiltValueNullFieldError.checkNotNull(
            kind,
            r'NotifyEventOneOf2Payload',
            'kind',
          ),
          requestId: BuiltValueNullFieldError.checkNotNull(
            requestId,
            r'NotifyEventOneOf2Payload',
            'requestId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
