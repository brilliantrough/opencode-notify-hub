import 'package:client/realtime/event_deduper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventDeduper', () {
    test('capacity 0 throws ArgumentError', () {
      expect(() => EventDeduper(capacity: 0), throwsArgumentError);
    });

    test('negative capacity throws ArgumentError', () {
      expect(() => EventDeduper(capacity: -1), throwsArgumentError);
    });

    test('capacity 1 detects duplicates and evicts on each new ID', () {
      final deduper = EventDeduper(capacity: 1);

      expect(deduper.isDuplicate('a'), isFalse);
      expect(deduper.isDuplicate('a'), isTrue);
      // 'b' evicts 'a'.
      expect(deduper.isDuplicate('b'), isFalse);
      expect(deduper.isDuplicate('b'), isTrue);
      expect(deduper.isDuplicate('a'), isFalse, reason: "'a' was evicted");
    });

    test('first occurrence of an event ID is not a duplicate', () {
      final deduper = EventDeduper();

      expect(deduper.isDuplicate('evt-1'), isFalse);
    });

    test('same event ID seen twice is a duplicate the second time', () {
      final deduper = EventDeduper();

      expect(deduper.isDuplicate('evt-1'), isFalse);
      expect(deduper.isDuplicate('evt-1'), isTrue);
    });

    test('distinct event IDs are all accepted', () {
      final deduper = EventDeduper();

      for (var i = 0; i < 10; i++) {
        expect(deduper.isDuplicate('evt-$i'), isFalse);
      }
    });

    test('event ID beyond capacity evicts the oldest ID', () {
      final deduper = EventDeduper(capacity: 500);

      expect(deduper.isDuplicate('evt-oldest'), isFalse);
      for (var i = 0; i < 500; i++) {
        expect(deduper.isDuplicate('evt-$i'), isFalse);
      }

      expect(deduper.isDuplicate('evt-oldest'), isFalse);
    });

    test('eviction of the oldest ID does not affect still-present IDs', () {
      final deduper = EventDeduper(capacity: 3);

      expect(deduper.isDuplicate('a'), isFalse);
      expect(deduper.isDuplicate('b'), isFalse);
      expect(deduper.isDuplicate('c'), isFalse);
      // Fourth distinct ID evicts 'a' only. Check still-present IDs first:
      expect(deduper.isDuplicate('d'), isFalse);
      // re-checking the evicted 'a' records it again and evicts the next
      // oldest ID.
      expect(deduper.isDuplicate('b'), isTrue);
      expect(deduper.isDuplicate('c'), isTrue);
      expect(deduper.isDuplicate('d'), isTrue);
      expect(deduper.isDuplicate('a'), isFalse, reason: "'a' was evicted");
    });

    test('re-checking an existing ID does not change eviction order', () {
      final deduper = EventDeduper(capacity: 2);

      expect(deduper.isDuplicate('a'), isFalse);
      expect(deduper.isDuplicate('b'), isFalse);
      // Duplicate hit on 'a' must not refresh it: 'a' stays oldest.
      expect(deduper.isDuplicate('a'), isTrue);
      // Inserting 'c' evicts 'a' (not 'b').
      expect(deduper.isDuplicate('c'), isFalse);

      expect(deduper.isDuplicate('b'), isTrue);
      expect(deduper.isDuplicate('a'), isFalse, reason: "'a' was evicted");
    });
  });
}
