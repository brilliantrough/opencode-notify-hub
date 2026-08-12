// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of1_payload_one_of2_provider_action.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyEventOneOf1PayloadOneOf2ProviderAction
    extends NotifyEventOneOf1PayloadOneOf2ProviderAction {
  @override
  final String label;
  @override
  final String? link;
  @override
  final String message;
  @override
  final String provider;
  @override
  final String title;

  factory _$NotifyEventOneOf1PayloadOneOf2ProviderAction([
    void Function(NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder)? updates,
  ]) => (NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder()..update(updates))
      ._build();

  _$NotifyEventOneOf1PayloadOneOf2ProviderAction._({
    required this.label,
    this.link,
    required this.message,
    required this.provider,
    required this.title,
  }) : super._();
  @override
  NotifyEventOneOf1PayloadOneOf2ProviderAction rebuild(
    void Function(NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder toBuilder() =>
      NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOf1PayloadOneOf2ProviderAction &&
        label == other.label &&
        link == other.link &&
        message == other.message &&
        provider == other.provider &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jc(_$hash, link.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'NotifyEventOneOf1PayloadOneOf2ProviderAction',
          )
          ..add('label', label)
          ..add('link', link)
          ..add('message', message)
          ..add('provider', provider)
          ..add('title', title))
        .toString();
  }
}

class NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder
    implements
        Builder<
          NotifyEventOneOf1PayloadOneOf2ProviderAction,
          NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder
        > {
  _$NotifyEventOneOf1PayloadOneOf2ProviderAction? _$v;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  String? _link;
  String? get link => _$this._link;
  set link(String? link) => _$this._link = link;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder() {
    NotifyEventOneOf1PayloadOneOf2ProviderAction._defaults(this);
  }

  NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _label = $v.label;
      _link = $v.link;
      _message = $v.message;
      _provider = $v.provider;
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOf1PayloadOneOf2ProviderAction other) {
    _$v = other as _$NotifyEventOneOf1PayloadOneOf2ProviderAction;
  }

  @override
  void update(
    void Function(NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOf1PayloadOneOf2ProviderAction build() => _build();

  _$NotifyEventOneOf1PayloadOneOf2ProviderAction _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOf1PayloadOneOf2ProviderAction._(
          label: BuiltValueNullFieldError.checkNotNull(
            label,
            r'NotifyEventOneOf1PayloadOneOf2ProviderAction',
            'label',
          ),
          link: link,
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'NotifyEventOneOf1PayloadOneOf2ProviderAction',
            'message',
          ),
          provider: BuiltValueNullFieldError.checkNotNull(
            provider,
            r'NotifyEventOneOf1PayloadOneOf2ProviderAction',
            'provider',
          ),
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'NotifyEventOneOf1PayloadOneOf2ProviderAction',
            'title',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
