// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_ingest_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EventIngestResponse extends EventIngestResponse {
  @override
  final bool deduplicated;
  @override
  final String eventId;

  factory _$EventIngestResponse([
    void Function(EventIngestResponseBuilder)? updates,
  ]) => (EventIngestResponseBuilder()..update(updates))._build();

  _$EventIngestResponse._({required this.deduplicated, required this.eventId})
    : super._();
  @override
  EventIngestResponse rebuild(
    void Function(EventIngestResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  EventIngestResponseBuilder toBuilder() =>
      EventIngestResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EventIngestResponse &&
        deduplicated == other.deduplicated &&
        eventId == other.eventId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deduplicated.hashCode);
    _$hash = $jc(_$hash, eventId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EventIngestResponse')
          ..add('deduplicated', deduplicated)
          ..add('eventId', eventId))
        .toString();
  }
}

class EventIngestResponseBuilder
    implements Builder<EventIngestResponse, EventIngestResponseBuilder> {
  _$EventIngestResponse? _$v;

  bool? _deduplicated;
  bool? get deduplicated => _$this._deduplicated;
  set deduplicated(bool? deduplicated) => _$this._deduplicated = deduplicated;

  String? _eventId;
  String? get eventId => _$this._eventId;
  set eventId(String? eventId) => _$this._eventId = eventId;

  EventIngestResponseBuilder() {
    EventIngestResponse._defaults(this);
  }

  EventIngestResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deduplicated = $v.deduplicated;
      _eventId = $v.eventId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EventIngestResponse other) {
    _$v = other as _$EventIngestResponse;
  }

  @override
  void update(void Function(EventIngestResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EventIngestResponse build() => _build();

  _$EventIngestResponse _build() {
    final _$result =
        _$v ??
        _$EventIngestResponse._(
          deduplicated: BuiltValueNullFieldError.checkNotNull(
            deduplicated,
            r'EventIngestResponse',
            'deduplicated',
          ),
          eventId: BuiltValueNullFieldError.checkNotNull(
            eventId,
            r'EventIngestResponse',
            'eventId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
