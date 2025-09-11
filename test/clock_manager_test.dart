import 'package:test/test.dart';
import 'package:pocket_gm_engine/src/models/game_state.dart';
import 'package:pocket_gm_engine/src/models/play_result.dart';
import 'package:pocket_gm_engine/src/services/clock_manager.dart';

void main() {
  group('ClockManager', () {
    late ClockManager clockManager;

    setUp(() {
      clockManager = ClockManager();
    });

    group('updateClock', () {
      test('should update clock when play does not stop clock', () {
        final gameState = GameState.kickoff().copyWith(
          gameClock: Duration(minutes: 10),
        );
        final playResult = PlayResult.rush(yardsGained: 5);

        final result = clockManager.updateClock(gameState, playResult);

        // Should subtract play time (6s) + delay between plays (25s) = 31s total
        expect(result.gameClock, equals(Duration(minutes: 9, seconds: 29)));
      });

      test('should update clock when play stops clock', () {
        final gameState = GameState.kickoff().copyWith(
          gameClock: Duration(minutes: 10),
        );
        final playResult = PlayResult.pass(
          yardsGained: 0,
          isComplete: false, // Incomplete pass stops clock
        );

        final result = clockManager.updateClock(gameState, playResult);

        // Should only subtract play time (8s), no delay since clock stops
        expect(result.gameClock, equals(Duration(minutes: 9, seconds: 52)));
      });

      test('should not go below zero', () {
        final gameState = GameState.kickoff().copyWith(
          gameClock: Duration(seconds: 5),
        );
        final playResult = PlayResult.rush(yardsGained: 3);

        final result = clockManager.updateClock(gameState, playResult);

        expect(result.gameClock, equals(Duration.zero));
      });

      test('should not update clock if game is over', () {
        final gameState = GameState.kickoff().copyWith(
          gameClock: Duration(minutes: 5),
          gameInProgress: false,
        );
        final playResult = PlayResult.rush(yardsGained: 5);

        final result = clockManager.updateClock(gameState, playResult);

        expect(result.gameClock, equals(Duration(minutes: 5)));
      });
    });

    group('isQuarterEnded', () {
      test('should return true when clock is at zero', () {
        final gameState = GameState.kickoff().copyWith(
          gameClock: Duration.zero,
        );

        expect(clockManager.isQuarterEnded(gameState), isTrue);
      });

      test('should return false when clock has time remaining', () {
        final gameState = GameState.kickoff().copyWith(
          gameClock: Duration(seconds: 1),
        );

        expect(clockManager.isQuarterEnded(gameState), isFalse);
      });
    });

    group('startNextQuarter', () {
      test('should start next regular quarter', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 2,
          gameClock: Duration.zero,
        );

        final result = clockManager.startNextQuarter(gameState);

        expect(result.quarter, equals(3));
        expect(result.gameClock, equals(Duration(minutes: 15)));
      });

      test('should start overtime with 10 minutes', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 4,
          gameClock: Duration.zero,
        );

        final result = clockManager.startNextQuarter(gameState);

        expect(result.quarter, equals(5));
        expect(result.gameClock, equals(Duration(minutes: 10)));
      });
    });

    group('shouldGameEnd', () {
      test('should end game after regulation if score is different', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 4,
          gameClock: Duration.zero,
          homeScore: 21,
          awayScore: 14,
        );

        expect(clockManager.shouldGameEnd(gameState), isTrue);
      });

      test('should not end game after regulation if tied', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 4,
          gameClock: Duration.zero,
          homeScore: 21,
          awayScore: 21,
        );

        expect(clockManager.shouldGameEnd(gameState), isFalse);
      });

      test('should end game in overtime if score is different', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 5,
          gameClock: Duration.zero,
          homeScore: 28,
          awayScore: 21,
        );

        expect(clockManager.shouldGameEnd(gameState), isTrue);
      });

      test('should not end game if clock still running', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 4,
          gameClock: Duration(minutes: 1),
          homeScore: 21,
          awayScore: 14,
        );

        expect(clockManager.shouldGameEnd(gameState), isFalse);
      });
    });

    group('endGame', () {
      test('should mark game as not in progress', () {
        final gameState = GameState.kickoff();

        final result = clockManager.endGame(gameState);

        expect(result.gameInProgress, isFalse);
      });
    });

    group('formatClock', () {
      test('should format minutes and seconds correctly', () {
        expect(ClockManager.formatClock(Duration(minutes: 5, seconds: 30)), equals('05:30'));
        expect(ClockManager.formatClock(Duration(minutes: 12, seconds: 5)), equals('12:05'));
        expect(ClockManager.formatClock(Duration(minutes: 0, seconds: 45)), equals('00:45'));
      });
    });

    group('getQuarterProgress', () {
      test('should return correct progress for regular quarter', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 2,
          gameClock: Duration(minutes: 7, seconds: 30), // 7.5 minutes remaining
        );

        final progress = clockManager.getQuarterProgress(gameState);

        // 15 - 7.5 = 7.5 minutes elapsed out of 15 = 0.5 progress
        expect(progress, equals(0.5));
      });

      test('should return correct progress for overtime', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 5,
          gameClock: Duration(minutes: 2, seconds: 30), // 2.5 minutes remaining
        );

        final progress = clockManager.getQuarterProgress(gameState);

        // 10 - 2.5 = 7.5 minutes elapsed out of 10 = 0.75 progress
        expect(progress, equals(0.75));
      });

      test('should return 1.0 when quarter is over', () {
        final gameState = GameState.kickoff().copyWith(
          gameClock: Duration.zero,
        );

        final progress = clockManager.getQuarterProgress(gameState);

        expect(progress, equals(1.0));
      });
    });
  });
}
