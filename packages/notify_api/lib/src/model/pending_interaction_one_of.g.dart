// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_interaction_one_of.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PendingInteractionOneOfKindEnum
_$pendingInteractionOneOfKindEnum_question =
    const PendingInteractionOneOfKindEnum._('question');

PendingInteractionOneOfKindEnum _$pendingInteractionOneOfKindEnumValueOf(
  String name,
) {
  switch (name) {
    case 'question':
      return _$pendingInteractionOneOfKindEnum_question;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PendingInteractionOneOfKindEnum>
_$pendingInteractionOneOfKindEnumValues =
    BuiltSet<PendingInteractionOneOfKindEnum>(
      const <PendingInteractionOneOfKindEnum>[
        _$pendingInteractionOneOfKindEnum_question,
      ],
    );

Serializer<PendingInteractionOneOfKindEnum>
_$pendingInteractionOneOfKindEnumSerializer =
    _$PendingInteractionOneOfKindEnumSerializer();

class _$PendingInteractionOneOfKindEnumSerializer
    implements PrimitiveSerializer<PendingInteractionOneOfKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'question': 'question',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'question': 'question',
  };

  @override
  final Iterable<Type> types = const <Type>[PendingInteractionOneOfKindEnum];
  @override
  final String wireName = 'PendingInteractionOneOfKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    PendingInteractionOneOfKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PendingInteractionOneOfKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PendingInteractionOneOfKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PendingInteractionOneOf extends PendingInteractionOneOf {
  @override
  final String directory;
  @override
  final String instanceId;
  @override
  final PendingInteractionOneOfKindEnum kind;
  @override
  final String machine;
  @override
  final DateTime occurredAt;
  @override
  final String project;
  @override
  final BuiltList<PendingInteractionOneOfQuestionsInner> questions;
  @override
  final String requestId;
  @override
  final String sessionId;
  @override
  final String sessionTitle;
  @override
  final PendingInteractionOneOfTool? tool;

  factory _$PendingInteractionOneOf([
    void Function(PendingInteractionOneOfBuilder)? updates,
  ]) => (PendingInteractionOneOfBuilder()..update(updates))._build();

  _$PendingInteractionOneOf._({
    required this.directory,
    required this.instanceId,
    required this.kind,
    required this.machine,
    required this.occurredAt,
    required this.project,
    required this.questions,
    required this.requestId,
    required this.sessionId,
    required this.sessionTitle,
    this.tool,
  }) : super._();
  @override
  PendingInteractionOneOf rebuild(
    void Function(PendingInteractionOneOfBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PendingInteractionOneOfBuilder toBuilder() =>
      PendingInteractionOneOfBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingInteractionOneOf &&
        directory == other.directory &&
        instanceId == other.instanceId &&
        kind == other.kind &&
        machine == other.machine &&
        occurredAt == other.occurredAt &&
        project == other.project &&
        questions == other.questions &&
        requestId == other.requestId &&
        sessionId == other.sessionId &&
        sessionTitle == other.sessionTitle &&
        tool == other.tool;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, directory.hashCode);
    _$hash = $jc(_$hash, instanceId.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, machine.hashCode);
    _$hash = $jc(_$hash, occurredAt.hashCode);
    _$hash = $jc(_$hash, project.hashCode);
    _$hash = $jc(_$hash, questions.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, sessionTitle.hashCode);
    _$hash = $jc(_$hash, tool.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PendingInteractionOneOf')
          ..add('directory', directory)
          ..add('instanceId', instanceId)
          ..add('kind', kind)
          ..add('machine', machine)
          ..add('occurredAt', occurredAt)
          ..add('project', project)
          ..add('questions', questions)
          ..add('requestId', requestId)
          ..add('sessionId', sessionId)
          ..add('sessionTitle', sessionTitle)
          ..add('tool', tool))
        .toString();
  }
}

class PendingInteractionOneOfBuilder
    implements
        Builder<PendingInteractionOneOf, PendingInteractionOneOfBuilder> {
  _$PendingInteractionOneOf? _$v;

  String? _directory;
  String? get directory => _$this._directory;
  set directory(String? directory) => _$this._directory = directory;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  PendingInteractionOneOfKindEnum? _kind;
  PendingInteractionOneOfKindEnum? get kind => _$this._kind;
  set kind(PendingInteractionOneOfKindEnum? kind) => _$this._kind = kind;

  String? _machine;
  String? get machine => _$this._machine;
  set machine(String? machine) => _$this._machine = machine;

  DateTime? _occurredAt;
  DateTime? get occurredAt => _$this._occurredAt;
  set occurredAt(DateTime? occurredAt) => _$this._occurredAt = occurredAt;

  String? _project;
  String? get project => _$this._project;
  set project(String? project) => _$this._project = project;

  ListBuilder<PendingInteractionOneOfQuestionsInner>? _questions;
  ListBuilder<PendingInteractionOneOfQuestionsInner> get questions =>
      _$this._questions ??=
          ListBuilder<PendingInteractionOneOfQuestionsInner>();
  set questions(
    ListBuilder<PendingInteractionOneOfQuestionsInner>? questions,
  ) => _$this._questions = questions;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  String? _sessionTitle;
  String? get sessionTitle => _$this._sessionTitle;
  set sessionTitle(String? sessionTitle) => _$this._sessionTitle = sessionTitle;

  PendingInteractionOneOfToolBuilder? _tool;
  PendingInteractionOneOfToolBuilder get tool =>
      _$this._tool ??= PendingInteractionOneOfToolBuilder();
  set tool(PendingInteractionOneOfToolBuilder? tool) => _$this._tool = tool;

  PendingInteractionOneOfBuilder() {
    PendingInteractionOneOf._defaults(this);
  }

  PendingInteractionOneOfBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _directory = $v.directory;
      _instanceId = $v.instanceId;
      _kind = $v.kind;
      _machine = $v.machine;
      _occurredAt = $v.occurredAt;
      _project = $v.project;
      _questions = $v.questions.toBuilder();
      _requestId = $v.requestId;
      _sessionId = $v.sessionId;
      _sessionTitle = $v.sessionTitle;
      _tool = $v.tool?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingInteractionOneOf other) {
    _$v = other as _$PendingInteractionOneOf;
  }

  @override
  void update(void Function(PendingInteractionOneOfBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PendingInteractionOneOf build() => _build();

  _$PendingInteractionOneOf _build() {
    _$PendingInteractionOneOf _$result;
    try {
      _$result =
          _$v ??
          _$PendingInteractionOneOf._(
            directory: BuiltValueNullFieldError.checkNotNull(
              directory,
              r'PendingInteractionOneOf',
              'directory',
            ),
            instanceId: BuiltValueNullFieldError.checkNotNull(
              instanceId,
              r'PendingInteractionOneOf',
              'instanceId',
            ),
            kind: BuiltValueNullFieldError.checkNotNull(
              kind,
              r'PendingInteractionOneOf',
              'kind',
            ),
            machine: BuiltValueNullFieldError.checkNotNull(
              machine,
              r'PendingInteractionOneOf',
              'machine',
            ),
            occurredAt: BuiltValueNullFieldError.checkNotNull(
              occurredAt,
              r'PendingInteractionOneOf',
              'occurredAt',
            ),
            project: BuiltValueNullFieldError.checkNotNull(
              project,
              r'PendingInteractionOneOf',
              'project',
            ),
            questions: questions.build(),
            requestId: BuiltValueNullFieldError.checkNotNull(
              requestId,
              r'PendingInteractionOneOf',
              'requestId',
            ),
            sessionId: BuiltValueNullFieldError.checkNotNull(
              sessionId,
              r'PendingInteractionOneOf',
              'sessionId',
            ),
            sessionTitle: BuiltValueNullFieldError.checkNotNull(
              sessionTitle,
              r'PendingInteractionOneOf',
              'sessionTitle',
            ),
            tool: _tool?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'questions';
        questions.build();

        _$failedField = 'tool';
        _tool?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PendingInteractionOneOf',
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
