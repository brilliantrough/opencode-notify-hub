// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_control_client_message_one_of8_catalog.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PluginControlClientMessageOneOf8Catalog
    extends PluginControlClientMessageOneOf8Catalog {
  @override
  final bool hasMore;
  @override
  final BuiltList<PluginControlClientMessageOneOf8CatalogSessionsInner>
  sessions;

  factory _$PluginControlClientMessageOneOf8Catalog([
    void Function(PluginControlClientMessageOneOf8CatalogBuilder)? updates,
  ]) => (PluginControlClientMessageOneOf8CatalogBuilder()..update(updates))
      ._build();

  _$PluginControlClientMessageOneOf8Catalog._({
    required this.hasMore,
    required this.sessions,
  }) : super._();
  @override
  PluginControlClientMessageOneOf8Catalog rebuild(
    void Function(PluginControlClientMessageOneOf8CatalogBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PluginControlClientMessageOneOf8CatalogBuilder toBuilder() =>
      PluginControlClientMessageOneOf8CatalogBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PluginControlClientMessageOneOf8Catalog &&
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
    return (newBuiltValueToStringHelper(
            r'PluginControlClientMessageOneOf8Catalog',
          )
          ..add('hasMore', hasMore)
          ..add('sessions', sessions))
        .toString();
  }
}

class PluginControlClientMessageOneOf8CatalogBuilder
    implements
        Builder<
          PluginControlClientMessageOneOf8Catalog,
          PluginControlClientMessageOneOf8CatalogBuilder
        > {
  _$PluginControlClientMessageOneOf8Catalog? _$v;

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

  PluginControlClientMessageOneOf8CatalogBuilder() {
    PluginControlClientMessageOneOf8Catalog._defaults(this);
  }

  PluginControlClientMessageOneOf8CatalogBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hasMore = $v.hasMore;
      _sessions = $v.sessions.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PluginControlClientMessageOneOf8Catalog other) {
    _$v = other as _$PluginControlClientMessageOneOf8Catalog;
  }

  @override
  void update(
    void Function(PluginControlClientMessageOneOf8CatalogBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  PluginControlClientMessageOneOf8Catalog build() => _build();

  _$PluginControlClientMessageOneOf8Catalog _build() {
    _$PluginControlClientMessageOneOf8Catalog _$result;
    try {
      _$result =
          _$v ??
          _$PluginControlClientMessageOneOf8Catalog._(
            hasMore: BuiltValueNullFieldError.checkNotNull(
              hasMore,
              r'PluginControlClientMessageOneOf8Catalog',
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
          r'PluginControlClientMessageOneOf8Catalog',
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
