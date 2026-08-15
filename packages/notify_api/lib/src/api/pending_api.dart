//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:notify_api/src/api_util.dart';
import 'package:notify_api/src/model/answer_question_body.dart';
import 'package:notify_api/src/model/command_outcome.dart';
import 'package:notify_api/src/model/decide_permission_body.dart';
import 'package:notify_api/src/model/error_response.dart';
import 'package:notify_api/src/model/pending_snapshot.dart';
import 'package:notify_api/src/model/permission_command_result.dart';
import 'package:notify_api/src/model/question_command_result.dart';

class PendingApi {
  final Dio _dio;

  final Serializers _serializers;

  const PendingApi(this._dio, this._serializers);

  /// Submit a complete answer set for a pending OpenCode question.
  /// Validates and submits one complete ordered answer set for a pending question owned by the authenticated account and routes the command to the exact Plugin instance. The response carries the client-generated commandId and the terminal outcome; it confirms gateway routing, not that OpenCode applied the answers. Leaving the request unanswered has no OpenCode side effect and never invokes question reject.
  ///
  /// Parameters:
  /// * [instanceId] - OpenCode instance identifier.
  /// * [requestId] - OpenCode question request identifier.
  /// * [answerQuestionBody]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [QuestionCommandResult] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<QuestionCommandResult>> answerQuestion({
    required String instanceId,
    required String requestId,
    required AnswerQuestionBody answerQuestionBody,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path =
        r'/v1/pending-interactions/{instanceId}/questions/{requestId}/answer'
            .replaceAll(
              '{'
              r'instanceId'
              '}',
              encodeQueryParameter(
                _serializers,
                instanceId,
                const FullType(String),
              ).toString(),
            )
            .replaceAll(
              '{'
              r'requestId'
              '}',
              encodeQueryParameter(
                _serializers,
                requestId,
                const FullType(String),
              ).toString(),
            );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(AnswerQuestionBody);
      _bodyData = _serializers.serialize(
        answerQuestionBody,
        specifiedType: _type,
      );
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

    QuestionCommandResult? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
                  rawResponse,
                  specifiedType: const FullType(QuestionCommandResult),
                )
                as QuestionCommandResult;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<QuestionCommandResult>(
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

  /// Submit an immediate decision for a pending OpenCode permission.
  /// Validates and submits one immediate allow-once, always-allow, or reject decision for a pending permission owned by the authenticated account and routes the command to the exact Plugin instance. The response carries the client-generated commandId and the terminal outcome; it confirms gateway routing, not that OpenCode applied the decision. Leaving the request undecided has no OpenCode side effect.
  ///
  /// Parameters:
  /// * [instanceId] - OpenCode instance identifier.
  /// * [requestId] - OpenCode permission request identifier.
  /// * [decidePermissionBody]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [PermissionCommandResult] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PermissionCommandResult>> decidePermission({
    required String instanceId,
    required String requestId,
    required DecidePermissionBody decidePermissionBody,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path =
        r'/v1/pending-interactions/{instanceId}/permissions/{requestId}/decision'
            .replaceAll(
              '{'
              r'instanceId'
              '}',
              encodeQueryParameter(
                _serializers,
                instanceId,
                const FullType(String),
              ).toString(),
            )
            .replaceAll(
              '{'
              r'requestId'
              '}',
              encodeQueryParameter(
                _serializers,
                requestId,
                const FullType(String),
              ).toString(),
            );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(DecidePermissionBody);
      _bodyData = _serializers.serialize(
        decidePermissionBody,
        specifiedType: _type,
      );
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

    PermissionCommandResult? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
                  rawResponse,
                  specifiedType: const FullType(PermissionCommandResult),
                )
                as PermissionCommandResult;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PermissionCommandResult>(
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

  /// Query the body-free outcome of a client-generated command.
  /// Returns the in-memory outcome correlation for a command submitted by the authenticated account, keyed by the client-generated commandId. The outcome is body-free: it carries only correlation and status metadata, never the question answers or permission decision. A client timeout should query the same commandId to distinguish accepted, confirmed, stale, and result_unknown before resubmitting.
  ///
  /// Parameters:
  /// * [commandId] - Client-generated command identifier.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [CommandOutcome] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<CommandOutcome>> getCommandOutcome({
    required String commandId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/pending-interactions/commands/{commandId}'.replaceAll(
      '{'
      r'commandId'
      '}',
      encodeQueryParameter(
        _serializers,
        commandId,
        const FullType(String),
      ).toString(),
    );
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    CommandOutcome? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
                  rawResponse,
                  specifiedType: const FullType(CommandOutcome),
                )
                as CommandOutcome;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<CommandOutcome>(
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

  /// List the authenticated user&#39;s pending interactions.
  /// Asks every owned online compatible Plugin instance for its current OpenCode questions and permissions and returns a unified snapshot. OpenCode is authoritative; the snapshot is a projection. Conflicting, incompatible, and offline instances are not queried, and provider actions never appear here.
  ///
  /// Parameters:
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [PendingSnapshot] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PendingSnapshot>> getPendingInteractions({
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/pending-interactions';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    PendingSnapshot? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
                  rawResponse,
                  specifiedType: const FullType(PendingSnapshot),
                )
                as PendingSnapshot;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PendingSnapshot>(
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
