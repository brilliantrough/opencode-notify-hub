//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:notify_api/src/model/pending_snapshot_interactions_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pending_snapshot.g.dart';

/// PendingSnapshot
///
/// Properties:
/// * [generatedAt]
/// * [interactions]
/// * [queriedInstanceIds] - Instances the gateway actually queried for this snapshot; absent for clients that do not track query scope.
@BuiltValue()
abstract class PendingSnapshot
    implements Built<PendingSnapshot, PendingSnapshotBuilder> {
  @BuiltValueField(wireName: r'generatedAt')
  DateTime get generatedAt;

  @BuiltValueField(wireName: r'interactions')
  BuiltList<PendingSnapshotInteractionsInner> get interactions;

  /// Instances the gateway actually queried for this snapshot; absent for clients that do not track query scope.
  @BuiltValueField(wireName: r'queriedInstanceIds')
  BuiltList<String>? get queriedInstanceIds;

  PendingSnapshot._();

  factory PendingSnapshot([void updates(PendingSnapshotBuilder b)]) =
      _$PendingSnapshot;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingSnapshotBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingSnapshot> get serializer =>
      _$PendingSnapshotSerializer();
}

class _$PendingSnapshotSerializer
    implements PrimitiveSerializer<PendingSnapshot> {
  @override
  final Iterable<Type> types = const [PendingSnapshot, _$PendingSnapshot];

  @override
  final String wireName = r'PendingSnapshot';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingSnapshot object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'generatedAt';
    yield serializers.serialize(
      object.generatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'interactions';
    yield serializers.serialize(
      object.interactions,
      specifiedType: const FullType(BuiltList, [
        FullType(PendingSnapshotInteractionsInner),
      ]),
    );
    if (object.queriedInstanceIds != null) {
      yield r'queriedInstanceIds';
      yield serializers.serialize(
        object.queriedInstanceIds,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PendingSnapshot object, {
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
    required PendingSnapshotBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'generatedAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(DateTime),
                  )
                  as DateTime;
          result.generatedAt = valueDes;
          break;
        case r'interactions':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(PendingSnapshotInteractionsInner),
                    ]),
                  )
                  as BuiltList<PendingSnapshotInteractionsInner>;
          result.interactions.replace(valueDes);
          break;
        case r'queriedInstanceIds':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(String),
                    ]),
                  )
                  as BuiltList<String>;
          result.queriedInstanceIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PendingSnapshot deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingSnapshotBuilder();
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
