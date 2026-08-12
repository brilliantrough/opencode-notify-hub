//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_event_one_of1_payload_one_of2_provider_action.g.dart';

/// NotifyEventOneOf1PayloadOneOf2ProviderAction
///
/// Properties:
/// * [label]
/// * [link]
/// * [message]
/// * [provider]
/// * [title]
@BuiltValue()
abstract class NotifyEventOneOf1PayloadOneOf2ProviderAction
    implements
        Built<
          NotifyEventOneOf1PayloadOneOf2ProviderAction,
          NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder
        > {
  @BuiltValueField(wireName: r'label')
  String get label;

  @BuiltValueField(wireName: r'link')
  String? get link;

  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'title')
  String get title;

  NotifyEventOneOf1PayloadOneOf2ProviderAction._();

  factory NotifyEventOneOf1PayloadOneOf2ProviderAction([
    void updates(NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder b),
  ]) = _$NotifyEventOneOf1PayloadOneOf2ProviderAction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(
    NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder b,
  ) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyEventOneOf1PayloadOneOf2ProviderAction>
  get serializer => _$NotifyEventOneOf1PayloadOneOf2ProviderActionSerializer();
}

class _$NotifyEventOneOf1PayloadOneOf2ProviderActionSerializer
    implements
        PrimitiveSerializer<NotifyEventOneOf1PayloadOneOf2ProviderAction> {
  @override
  final Iterable<Type> types = const [
    NotifyEventOneOf1PayloadOneOf2ProviderAction,
    _$NotifyEventOneOf1PayloadOneOf2ProviderAction,
  ];

  @override
  final String wireName = r'NotifyEventOneOf1PayloadOneOf2ProviderAction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf2ProviderAction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'label';
    yield serializers.serialize(
      object.label,
      specifiedType: const FullType(String),
    );
    if (object.link != null) {
      yield r'link';
      yield serializers.serialize(
        object.link,
        specifiedType: const FullType(String),
      );
    }
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'provider';
    yield serializers.serialize(
      object.provider,
      specifiedType: const FullType(String),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyEventOneOf1PayloadOneOf2ProviderAction object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'label':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.label = valueDes;
          break;
        case r'link':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.link = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.message = valueDes;
          break;
        case r'provider':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.provider = valueDes;
          break;
        case r'title':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.title = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyEventOneOf1PayloadOneOf2ProviderAction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyEventOneOf1PayloadOneOf2ProviderActionBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
