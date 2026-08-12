// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_event_one_of_source.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyEventOneOfSource extends NotifyEventOneOfSource {
  @override
  final String directory;
  @override
  final String machine;
  @override
  final String project;

  factory _$NotifyEventOneOfSource([
    void Function(NotifyEventOneOfSourceBuilder)? updates,
  ]) => (NotifyEventOneOfSourceBuilder()..update(updates))._build();

  _$NotifyEventOneOfSource._({
    required this.directory,
    required this.machine,
    required this.project,
  }) : super._();
  @override
  NotifyEventOneOfSource rebuild(
    void Function(NotifyEventOneOfSourceBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyEventOneOfSourceBuilder toBuilder() =>
      NotifyEventOneOfSourceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyEventOneOfSource &&
        directory == other.directory &&
        machine == other.machine &&
        project == other.project;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, directory.hashCode);
    _$hash = $jc(_$hash, machine.hashCode);
    _$hash = $jc(_$hash, project.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyEventOneOfSource')
          ..add('directory', directory)
          ..add('machine', machine)
          ..add('project', project))
        .toString();
  }
}

class NotifyEventOneOfSourceBuilder
    implements Builder<NotifyEventOneOfSource, NotifyEventOneOfSourceBuilder> {
  _$NotifyEventOneOfSource? _$v;

  String? _directory;
  String? get directory => _$this._directory;
  set directory(String? directory) => _$this._directory = directory;

  String? _machine;
  String? get machine => _$this._machine;
  set machine(String? machine) => _$this._machine = machine;

  String? _project;
  String? get project => _$this._project;
  set project(String? project) => _$this._project = project;

  NotifyEventOneOfSourceBuilder() {
    NotifyEventOneOfSource._defaults(this);
  }

  NotifyEventOneOfSourceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _directory = $v.directory;
      _machine = $v.machine;
      _project = $v.project;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyEventOneOfSource other) {
    _$v = other as _$NotifyEventOneOfSource;
  }

  @override
  void update(void Function(NotifyEventOneOfSourceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyEventOneOfSource build() => _build();

  _$NotifyEventOneOfSource _build() {
    final _$result =
        _$v ??
        _$NotifyEventOneOfSource._(
          directory: BuiltValueNullFieldError.checkNotNull(
            directory,
            r'NotifyEventOneOfSource',
            'directory',
          ),
          machine: BuiltValueNullFieldError.checkNotNull(
            machine,
            r'NotifyEventOneOfSource',
            'machine',
          ),
          project: BuiltValueNullFieldError.checkNotNull(
            project,
            r'NotifyEventOneOfSource',
            'project',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
