//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:notify_api/src/date_serializer.dart';
import 'package:notify_api/src/model/date.dart';

import 'package:notify_api/src/model/create_ingest_key_body.dart';
import 'package:notify_api/src/model/create_ingest_key_response.dart';
import 'package:notify_api/src/model/device.dart';
import 'package:notify_api/src/model/device_list_response_inner.dart';
import 'package:notify_api/src/model/email_body.dart';
import 'package:notify_api/src/model/error_response.dart';
import 'package:notify_api/src/model/error_response_error.dart';
import 'package:notify_api/src/model/event_ingest_response.dart';
import 'package:notify_api/src/model/health_status.dart';
import 'package:notify_api/src/model/ingest_key_list_response_inner.dart';
import 'package:notify_api/src/model/login_body.dart';
import 'package:notify_api/src/model/notify_event.dart';
import 'package:notify_api/src/model/notify_event_one_of.dart';
import 'package:notify_api/src/model/notify_event_one_of1.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of1.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of1_permission.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of2.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of2_provider_action.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of_questions_inner.dart';
import 'package:notify_api/src/model/notify_event_one_of1_payload_one_of_questions_inner_options_inner.dart';
import 'package:notify_api/src/model/notify_event_one_of2.dart';
import 'package:notify_api/src/model/notify_event_one_of2_payload.dart';
import 'package:notify_api/src/model/notify_event_one_of3.dart';
import 'package:notify_api/src/model/notify_event_one_of3_payload.dart';
import 'package:notify_api/src/model/notify_event_one_of_payload.dart';
import 'package:notify_api/src/model/notify_event_one_of_session.dart';
import 'package:notify_api/src/model/notify_event_one_of_source.dart';
import 'package:notify_api/src/model/patch_device_body.dart';
import 'package:notify_api/src/model/refresh_body.dart';
import 'package:notify_api/src/model/register_body.dart';
import 'package:notify_api/src/model/register_device_body.dart';
import 'package:notify_api/src/model/reset_password_body.dart';
import 'package:notify_api/src/model/token_pair.dart';
import 'package:notify_api/src/model/verify_email_body.dart';
import 'package:notify_api/src/model/ws_server_message.dart';
import 'package:notify_api/src/model/ws_server_message_event.dart';

part 'serializers.g.dart';

@SerializersFor([
  CreateIngestKeyBody,
  CreateIngestKeyResponse,
  Device,
  DeviceListResponseInner,
  EmailBody,
  ErrorResponse,
  ErrorResponseError,
  EventIngestResponse,
  HealthStatus,
  IngestKeyListResponseInner,
  LoginBody,
  NotifyEvent,
  NotifyEventOneOf,
  NotifyEventOneOf1,
  NotifyEventOneOf1Payload,
  NotifyEventOneOf1PayloadOneOf,
  NotifyEventOneOf1PayloadOneOf1,
  NotifyEventOneOf1PayloadOneOf1Permission,
  NotifyEventOneOf1PayloadOneOf2,
  NotifyEventOneOf1PayloadOneOf2ProviderAction,
  NotifyEventOneOf1PayloadOneOfQuestionsInner,
  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner,
  NotifyEventOneOf2,
  NotifyEventOneOf2Payload,
  NotifyEventOneOf3,
  NotifyEventOneOf3Payload,
  NotifyEventOneOfPayload,
  NotifyEventOneOfSession,
  NotifyEventOneOfSource,
  PatchDeviceBody,
  RefreshBody,
  RegisterBody,
  RegisterDeviceBody,
  ResetPasswordBody,
  TokenPair,
  VerifyEmailBody,
  WsServerMessage,
  WsServerMessageEvent,
])
Serializers serializers =
    (_$serializers.toBuilder()
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(DeviceListResponseInner)]),
            () => ListBuilder<DeviceListResponseInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(IngestKeyListResponseInner)]),
            () => ListBuilder<IngestKeyListResponseInner>(),
          )
          ..add(const OneOfSerializer())
          ..add(const AnyOfSerializer())
          ..add(const DateSerializer())
          ..add(Iso8601DateTimeSerializer()))
        .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
