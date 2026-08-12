// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of_session.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyEventOneOfSession extends NotifyEventOneOfSession {
  @override
  final String id;
  @override
  final String title;

  factory _$NotifyEventOneOfSession([
    void Function(NotifyEventOneOfSessionBuilder)? updates,
  ]) => (NotifyEventOneOfSessionBuilder()..update(updates))._build();

  _$NotifyEventOneOfSession._({required this.id, required this.title})
    : super._();
  @override
  NotifyEventOneOfSession rebuild(
    void Function(NotifyEventOneOfSessionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOfSessionBuilder toBuilder() =>
      NotifyEventOneOfSessionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOfSession &&
        id == other.id &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOfSession')
          ..add('id', id)
          ..add('title', title))
        .toString();
  }
}

class NotifyEventOneOfSessionBuilder
    implements
        Builder<NotifyEventOneOfSession, NotifyEventOneOfSessionBuilder> {
  _$NotifyEventOneOfSession? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  NotifyEventOneOfSessionBuilder() {
    NotifyEventOneOfSession._defaults(this);
  }

  NotifyEventOneOfSessionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOfSession other) {
    _$v = other as _$NotifyEventOneOfSession;
  }

  @override
  void update(void Function(NotifyEventOneOfSessionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOfSession build() => _build();

  _$NotifyEventOneOfSession _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOfSession._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'NotifyEventOneOfSession',
            'id',
          ),
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'NotifyEventOneOfSession',
            'title',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
