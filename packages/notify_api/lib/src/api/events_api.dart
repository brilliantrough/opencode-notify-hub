//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:notify_api/src/model/error_response.dart';
import 'package:notify_api/src/model/event_ingest_response.dart';
import 'package:notify_api/src/model/notify_event.dart';

class EventsApi {
  final Dio _dio;

  final Serializers _serializers;

  const EventsApi(this._dio, this._serializers);

  /// Ingest a signed notification event from the OpenCode plugin.
  /// Authenticate with &#x60;Authorization: Bearer keyId.secret&#x60; plus the X-Notify-Timestamp and X-Notify-Signature HMAC headers. Events are deduplicated per user by eventId for a short window.
  ///
  /// Parameters:
  /// * [xNotifyTimestamp] - Unix milliseconds. Requests more than 5 minutes from server time are rejected.
  /// * [xNotifySignature] - Hex HMAC-SHA256 of `${timestamp}.${rawBody}` keyed with the ingest-key secret.
  /// * [notifyEvent]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [EventIngestResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<EventIngestResponse>> ingestEvent({
    required int xNotifyTimestamp,
    required String xNotifySignature,
    required NotifyEvent notifyEvent,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/events';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-Notify-Timestamp': xNotifyTimestamp,
        r'X-Notify-Signature': xNotifySignature,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'ingestKeyAuth'},
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(NotifyEvent);
      _bodyData = _serializers.serialize(notifyEvent, specifiedType: _type);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(_dio.options, _path),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    EventIngestResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
                  rawResponse,
                  specifiedType: const FullType(EventIngestResponse),
                )
                as EventIngestResponse;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<EventIngestResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }
}
