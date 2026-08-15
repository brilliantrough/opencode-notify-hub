// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (Serializers().toBuilder()
          ..add(AnswerQuestionBody.serializer)
          ..add(CommandOutcome.serializer)
          ..add(CommandOutcomeKindEnum.serializer)
          ..add(CommandOutcomeStatusEnum.serializer)
          ..add(CreateIngestKeyBody.serializer)
          ..add(CreateIngestKeyResponse.serializer)
          ..add(DecidePermissionBody.serializer)
          ..add(DecidePermissionBodyDecisionEnum.serializer)
          ..add(Device.serializer)
          ..add(DeviceListResponseInner.serializer)
          ..add(DeviceListResponseInnerPlatformEnum.serializer)
          ..add(DevicePlatformEnum.serializer)
          ..add(EmailBody.serializer)
          ..add(ErrorResponse.serializer)
          ..add(ErrorResponseError.serializer)
          ..add(EventIngestResponse.serializer)
          ..add(HealthStatus.serializer)
          ..add(HealthStatusStatusEnum.serializer)
          ..add(IngestKeyListResponseInner.serializer)
          ..add(InstancePresence.serializer)
          ..add(InstancePresenceStateEnum.serializer)
          ..add(LoginBody.serializer)
          ..add(NotifyEvent.serializer)
          ..add(NotifyEventOneOf.serializer)
          ..add(NotifyEventOneOf1.serializer)
          ..add(NotifyEventOneOf1Payload.serializer)
          ..add(NotifyEventOneOf1PayloadOneOf.serializer)
          ..add(NotifyEventOneOf1PayloadOneOf1.serializer)
          ..add(NotifyEventOneOf1PayloadOneOf1KindEnum.serializer)
          ..add(NotifyEventOneOf1PayloadOneOf1Permission.serializer)
          ..add(NotifyEventOneOf1PayloadOneOf2.serializer)
          ..add(NotifyEventOneOf1PayloadOneOf2KindEnum.serializer)
          ..add(NotifyEventOneOf1PayloadOneOf2ProviderAction.serializer)
          ..add(NotifyEventOneOf1PayloadOneOfKindEnum.serializer)
          ..add(NotifyEventOneOf1PayloadOneOfQuestionsInner.serializer)
          ..add(
            NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner.serializer,
          )
          ..add(NotifyEventOneOf1TypeEnum.serializer)
          ..add(NotifyEventOneOf2.serializer)
          ..add(NotifyEventOneOf2Payload.serializer)
          ..add(NotifyEventOneOf2PayloadKindEnum.serializer)
          ..add(NotifyEventOneOf2TypeEnum.serializer)
          ..add(NotifyEventOneOf3.serializer)
          ..add(NotifyEventOneOf3Payload.serializer)
          ..add(NotifyEventOneOf3PayloadOutcomeEnum.serializer)
          ..add(NotifyEventOneOf3TypeEnum.serializer)
          ..add(NotifyEventOneOfPayload.serializer)
          ..add(NotifyEventOneOfPayloadStatusEnum.serializer)
          ..add(NotifyEventOneOfSession.serializer)
          ..add(NotifyEventOneOfSource.serializer)
          ..add(NotifyEventOneOfTypeEnum.serializer)
          ..add(PatchDeviceBody.serializer)
          ..add(PendingInteraction.serializer)
          ..add(PendingInteractionOneOf.serializer)
          ..add(PendingInteractionOneOf1.serializer)
          ..add(PendingInteractionOneOf1KindEnum.serializer)
          ..add(PendingInteractionOneOfKindEnum.serializer)
          ..add(PendingInteractionOneOfQuestionsInner.serializer)
          ..add(PendingInteractionOneOfQuestionsInnerOptionsInner.serializer)
          ..add(PendingInteractionOneOfTool.serializer)
          ..add(PendingSnapshot.serializer)
          ..add(PendingSnapshotInteractionsInner.serializer)
          ..add(PermissionCommandResult.serializer)
          ..add(PermissionCommandResultStatusEnum.serializer)
          ..add(PluginControlClientMessage.serializer)
          ..add(PluginControlClientMessageOneOf.serializer)
          ..add(PluginControlClientMessageOneOf1.serializer)
          ..add(PluginControlClientMessageOneOf1TypeEnum.serializer)
          ..add(PluginControlClientMessageOneOf2.serializer)
          ..add(PluginControlClientMessageOneOf2StatusEnum.serializer)
          ..add(PluginControlClientMessageOneOf2TypeEnum.serializer)
          ..add(PluginControlClientMessageOneOf3.serializer)
          ..add(PluginControlClientMessageOneOf3StatusEnum.serializer)
          ..add(PluginControlClientMessageOneOf3TypeEnum.serializer)
          ..add(PluginControlClientMessageOneOfTypeEnum.serializer)
          ..add(PluginControlServerMessage.serializer)
          ..add(PluginControlServerMessageOneOf.serializer)
          ..add(PluginControlServerMessageOneOf1.serializer)
          ..add(PluginControlServerMessageOneOf1TypeEnum.serializer)
          ..add(PluginControlServerMessageOneOf2.serializer)
          ..add(PluginControlServerMessageOneOf2TypeEnum.serializer)
          ..add(PluginControlServerMessageOneOf3.serializer)
          ..add(PluginControlServerMessageOneOf3DecisionEnum.serializer)
          ..add(PluginControlServerMessageOneOf3TypeEnum.serializer)
          ..add(PluginControlServerMessageOneOfStateEnum.serializer)
          ..add(PluginControlServerMessageOneOfTypeEnum.serializer)
          ..add(QuestionCommandResult.serializer)
          ..add(QuestionCommandResultStatusEnum.serializer)
          ..add(RefreshBody.serializer)
          ..add(RegisterBody.serializer)
          ..add(RegisterDeviceBody.serializer)
          ..add(RegisterDeviceBodyPlatformEnum.serializer)
          ..add(ResetPasswordBody.serializer)
          ..add(TokenPair.serializer)
          ..add(VerifyEmailBody.serializer)
          ..add(WsServerMessage.serializer)
          ..add(WsServerMessageOneOf.serializer)
          ..add(WsServerMessageOneOf1.serializer)
          ..add(WsServerMessageOneOf1InstancesInner.serializer)
          ..add(WsServerMessageOneOf1InstancesInnerStateEnum.serializer)
          ..add(WsServerMessageOneOf1TypeEnum.serializer)
          ..add(WsServerMessageOneOfEvent.serializer)
          ..add(WsServerMessageOneOfTypeEnum.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => ListBuilder<BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => ListBuilder<BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(NotifyEventOneOf1PayloadOneOfQuestionsInner),
            ]),
            () => ListBuilder<NotifyEventOneOf1PayloadOneOfQuestionsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(
                NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner,
              ),
            ]),
            () =>
                ListBuilder<
                  NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner
                >(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(PendingInteractionOneOfQuestionsInner),
            ]),
            () => ListBuilder<PendingInteractionOneOfQuestionsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(PendingInteractionOneOfQuestionsInnerOptionsInner),
            ]),
            () =>
                ListBuilder<
                  PendingInteractionOneOfQuestionsInnerOptionsInner
                >(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(PendingSnapshotInteractionsInner),
            ]),
            () => ListBuilder<PendingSnapshotInteractionsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(PendingSnapshotInteractionsInner),
            ]),
            () => ListBuilder<PendingSnapshotInteractionsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(WsServerMessageOneOf1InstancesInner),
            ]),
            () => ListBuilder<WsServerMessageOneOf1InstancesInner>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
