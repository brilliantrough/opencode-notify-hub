// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_server_message_one_of7_query.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PluginControlServerMessageOneOf7Query
    extends PluginControlServerMessageOneOf7Query {
  @override
  final int? limit;
  @override
  final String? search;
  @override
  final String? sessionIds;

  factory _$PluginControlServerMessageOneOf7Query([
    void Function(PluginControlServerMessageOneOf7QueryBuilder)? updates,
  ]) => (PluginControlServerMessageOneOf7QueryBuilder()..update(updates))
      ._build();

  _$PluginControlServerMessageOneOf7Query._({
    this.limit,
    this.search,
    this.sessionIds,
  }) : super._();
  @override
  PluginControlServerMessageOneOf7Query rebuild(
    void Function(PluginControlServerMessageOneOf7QueryBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlServerMessageOneOf7QueryBuilder toBuilder() =>
      PluginControlServerMessageOneOf7QueryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlServerMessageOneOf7Query &&
        limit == other.limit &&
        search == other.search &&
        sessionIds == other.sessionIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, limit.hashCode);
    _$hash = $jc(_$hash, search.hashCode);
    _$hash = $jc(_$hash, sessionIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'PluginControlServerMessageOneOf7Query',
          )
          ..add('limit', limit)
          ..add('search', search)
          ..add('sessionIds', sessionIds))
        .toString();
  }
}

class PluginControlServerMessageOneOf7QueryBuilder
    implements
        Builder<
          PluginControlServerMessageOneOf7Query,
          PluginControlServerMessageOneOf7QueryBuilder
        > {
  _$PluginControlServerMessageOneOf7Query? _$v;

  int? _limit;
  int? get limit => _$this._limit;
  set limit(int? limit) => _$this._limit = limit;

  String? _search;
  String? get search => _$this._search;
  set search(String? search) => _$this._search = search;

  String? _sessionIds;
  String? get sessionIds => _$this._sessionIds;
  set sessionIds(String? sessionIds) => _$this._sessionIds = sessionIds;

  PluginControlServerMessageOneOf7QueryBuilder() {
    PluginControlServerMessageOneOf7Query._defaults(this);
  }

  PluginControlServerMessageOneOf7QueryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _limit = $v.limit;
      _search = $v.search;
      _sessionIds = $v.sessionIds;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlServerMessageOneOf7Query other) {
    _$v = other as _$PluginControlServerMessageOneOf7Query;
  }

  @override
  void update(
    void Function(PluginControlServerMessageOneOf7QueryBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlServerMessageOneOf7Query build() => _build();

  _$PluginControlServerMessageOneOf7Query _build() {
    final _$result =
        _$v ??
        _$PluginControlServerMessageOneOf7Query._(
          limit: limit,
          search: search,
          sessionIds: sessionIds,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
