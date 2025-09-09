import 'package:test/test.dart';
import '../lib/src/models/play_result.dart';

void main() {
  group('PlayResult', () {
    test('should create a play result with all required fields', () {
      final playResult = PlayResult(
        playType: PlayType.rush,
        yardsGained: 5,
        timeElapsed: Duration(seconds: 6),
        isTurnover: false,
        isScore: false,
        isFirstDown: false,
        stopClock: false,
        description: 'Running back up the middle',
      );

      expect(playResult.playType, equals(PlayType.rush));
      expect(playResult.yardsGained, equals(5));
      expect(playResult.timeElapsed, equals(Duration(seconds: 6)));
      expect(playResult.isTurnover, isFalse);
      expect(playResult.isScore, isFalse);
      expect(playResult.isFirstDown, isFalse);
      expect(playResult.stopClock, isFalse);
      expect(playResult.description, equals('Running back up the middle'));
    });

    test('should create a play result with default boolean values', () {
      final playResult = PlayResult(
        playType: PlayType.pass,
        yardsGained: 12,
        timeElapsed: Duration(seconds: 8),
      );

      expect(playResult.isTurnover, isFalse);
      expect(playResult.isScore, isFalse);
      expect(playResult.isFirstDown, isFalse);
      expect(playResult.stopClock, isFalse);
      expect(playResult.description, isNull);
    });

    group('factory constructors', () {
      test('should create a rush play result with defaults', () {
        final playResult = PlayResult.rush(yardsGained: 4);

        expect(playResult.playType, equals(PlayType.rush));
        expect(playResult.yardsGained, equals(4));
        expect(playResult.timeElapsed, equals(Duration(seconds: 6)));
        expect(playResult.isFirstDown, isFalse);
        expect(playResult.stopClock, isFalse);
        expect(playResult.description, isNull);
      });

      test('should create a rush play result with custom values', () {
        final playResult = PlayResult.rush(
          yardsGained: 8,
          timeElapsed: Duration(seconds: 7),
          isFirstDown: true,
          description: 'Great run up the middle',
        );

        expect(playResult.playType, equals(PlayType.rush));
        expect(playResult.yardsGained, equals(8));
        expect(playResult.timeElapsed, equals(Duration(seconds: 7)));
        expect(playResult.isFirstDown, isTrue);
        expect(playResult.stopClock, isFalse);
        expect(playResult.description, equals('Great run up the middle'));
      });

      test('should create a complete pass play result', () {
        final playResult = PlayResult.pass(
          yardsGained: 15,
          isFirstDown: true,
          isComplete: true,
        );

        expect(playResult.playType, equals(PlayType.pass));
        expect(playResult.yardsGained, equals(15));
        expect(playResult.timeElapsed, equals(Duration(seconds: 8)));
        expect(playResult.isFirstDown, isTrue);
        expect(playResult.stopClock, isFalse); // Complete passes don't stop clock
      });

      test('should create an incomplete pass play result', () {
        final playResult = PlayResult.pass(
          yardsGained: 0,
          isComplete: false,
        );

        expect(playResult.playType, equals(PlayType.pass));
        expect(playResult.yardsGained, equals(0));
        expect(playResult.stopClock, isTrue); // Incomplete passes stop clock
      });

      test('should create a turnover play result', () {
        final playResult = PlayResult.turnover(
          playType: PlayType.pass,
          yardsGained: -5,
          description: 'Interception returned for 5 yards',
        );

        expect(playResult.playType, equals(PlayType.pass));
        expect(playResult.yardsGained, equals(-5));
        expect(playResult.timeElapsed, equals(Duration(seconds: 5)));
        expect(playResult.isTurnover, isTrue);
        expect(playResult.stopClock, isTrue);
        expect(playResult.description, equals('Interception returned for 5 yards'));
      });

      test('should create a touchdown play result', () {
        final playResult = PlayResult.touchdown(
          playType: PlayType.rush,
          yardsGained: 25,
          description: 'Touchdown run!',
        );

        expect(playResult.playType, equals(PlayType.rush));
        expect(playResult.yardsGained, equals(25));
        expect(playResult.timeElapsed, equals(Duration(seconds: 10)));
        expect(playResult.isScore, isTrue);
        expect(playResult.stopClock, isTrue);
        expect(playResult.description, equals('Touchdown run!'));
      });
    });

    group('toString', () {
      test('should format basic play result correctly', () {
        final playResult = PlayResult.rush(yardsGained: 5);
        final result = playResult.toString();

        expect(result, contains('RUSH'));
        expect(result, contains('+5 yards'));
        expect(result, contains('6s'));
      });

      test('should format negative yards correctly', () {
        final playResult = PlayResult.rush(yardsGained: -2);
        final result = playResult.toString();

        expect(result, contains('-2 yards'));
      });

      test('should format play with flags correctly', () {
        final playResult = PlayResult(
          playType: PlayType.pass,
          yardsGained: 20,
          timeElapsed: Duration(seconds: 8),
          isTurnover: true,
          isScore: true,
          isFirstDown: true,
          stopClock: true,
        );

        final result = playResult.toString();
        expect(result, contains('PASS'));
        expect(result, contains('+20 yards'));
        expect(result, contains('8s'));
        expect(result, contains('[TURNOVER, SCORE, 1ST DOWN, CLOCK STOPS]'));
      });

      test('should format play with no flags correctly', () {
        final playResult = PlayResult.rush(yardsGained: 3);
        final result = playResult.toString();

        expect(result, isNot(contains('[')));
        expect(result, isNot(contains(']')));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final playResult1 = PlayResult.rush(yardsGained: 5);
        final playResult2 = PlayResult.rush(yardsGained: 5);

        expect(playResult1, equals(playResult2));
        expect(playResult1.hashCode, equals(playResult2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final playResult1 = PlayResult.rush(yardsGained: 5);
        final playResult2 = PlayResult.rush(yardsGained: 7);

        expect(playResult1, isNot(equals(playResult2)));
        expect(playResult1.hashCode, isNot(equals(playResult2.hashCode)));
      });

      test('should be equal to itself', () {
        final playResult = PlayResult.rush(yardsGained: 5);
        expect(playResult, equals(playResult));
      });
    });
  });

  group('PlayType', () {
    test('should have all expected play types', () {
      expect(PlayType.values, contains(PlayType.rush));
      expect(PlayType.values, contains(PlayType.pass));
      expect(PlayType.values, contains(PlayType.punt));
      expect(PlayType.values, contains(PlayType.fieldGoal));
      expect(PlayType.values, contains(PlayType.extraPoint));
      expect(PlayType.values, contains(PlayType.kickoff));
      expect(PlayType.values, contains(PlayType.kneel));
      expect(PlayType.values, contains(PlayType.spike));
    });

    test('should have correct enum names', () {
      expect(PlayType.rush.name, equals('rush'));
      expect(PlayType.pass.name, equals('pass'));
      expect(PlayType.punt.name, equals('punt'));
      expect(PlayType.fieldGoal.name, equals('fieldGoal'));
      expect(PlayType.extraPoint.name, equals('extraPoint'));
      expect(PlayType.kickoff.name, equals('kickoff'));
      expect(PlayType.kneel.name, equals('kneel'));
      expect(PlayType.spike.name, equals('spike'));
    });
  });
}
