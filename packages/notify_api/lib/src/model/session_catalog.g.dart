// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_catalog.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionCatalog extends SessionCatalog {
  @override
  final bool hasMore;
  @override
  final BuiltList<PluginControlClientMessageOneOf8CatalogSessionsInner>
  sessions;

  factory _$SessionCatalog([void Function(SessionCatalogBuilder)? updates]) =>
      (SessionCatalogBuilder()..update(updates))._build();

  _$SessionCatalog._({required this.hasMore, required this.sessions})
    : super._();
  @override
  SessionCatalog rebuild(void Function(SessionCatalogBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionCatalogBuilder toBuilder() => SessionCatalogBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionCatalog &&
        hasMore == other.hasMore &&
        sessions == other.sessions;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jc(_$hash, sessions.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SessionCatalog')
          ..add('hasMore', hasMore)
          ..add('sessions', sessions))
        .toString();
  }
}

class SessionCatalogBuilder
    implements Builder<SessionCatalog, SessionCatalogBuilder> {
  _$SessionCatalog? _$v;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  ListBuilder<PluginControlClientMessageOneOf8CatalogSessionsInner>? _sessions;
  ListBuilder<PluginControlClientMessageOneOf8CatalogSessionsInner>
  get sessions => _$this._sessions ??=
      ListBuilder<PluginControlClientMessageOneOf8CatalogSessionsInner>();
  set sessions(
    ListBuilder<PluginControlClientMessageOneOf8CatalogSessionsInner>? sessions,
  ) => _$this._sessions = sessions;

  SessionCatalogBuilder() {
    SessionCatalog._defaults(this);
  }

  SessionCatalogBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hasMore = $v.hasMore;
      _sessions = $v.sessions.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SessionCatalog other) {
    _$v = other as _$SessionCatalog;
  }

  @override
  void update(void Function(SessionCatalogBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionCatalog build() => _build();

  _$SessionCatalog _build() {
    _$SessionCatalog _$result;
    try {
      _$result =
          _$v ??
          _$SessionCatalog._(
            hasMore: BuiltValueNullFieldError.checkNotNull(
              hasMore,
              r'SessionCatalog',
              'hasMore',
            ),
            sessions: sessions.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sessions';
        sessions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SessionCatalog',
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
