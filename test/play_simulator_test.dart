import 'package:test/test.dart';
import '../lib/src/models/game_state.dart';
import '../lib/src/models/play_result.dart';
import '../lib/src/services/play_simulator.dart';

void main() {
  group('PlaySimulator', () {
    late PlaySimulator playSimulator;

    setUp(() {
      playSimulator = PlaySimulator();
    });

    group('simulateRunPlay', () {
      test('should return a valid PlayResult for basic run play', () {
        // Arrange
        final gameState = GameState.kickoff();

        // Act
        final result = playSimulator.simulateRunPlay(gameState);

        // Assert
        expect(result.playType, equals(PlayType.rush));
        expect(result.yardsGained, isA<int>());
        expect(result.timeElapsed, isA<Duration>());
        expect(result.timeElapsed.inSeconds, greaterThanOrEqualTo(0));
        expect(result.timeElapsed.inSeconds, lessThanOrEqualTo(45));
      });

      test('should generate realistic yards gained for run plays', () {
        // Arrange
        final gameState = GameState.kickoff();
        final results = <int>[];

        // Act - Generate multiple plays to test distribution
        for (int i = 0; i < 100; i++) {
          final result = playSimulator.simulateRunPlay(gameState);
          results.add(result.yardsGained);
        }

        // Assert - Check realistic distribution
        expect(results.any((yards) => yards >= -5), isTrue); // Some negative yards possible
        expect(results.any((yards) => yards <= 20), isTrue); // Most runs should be moderate
        expect(results.every((yards) => yards >= -10), isTrue); // No catastrophic losses
        expect(results.every((yards) => yards <= 80), isTrue); // No impossible long runs
      });

      test('should consume reasonable time for run plays', () {
        // Arrange
        final gameState = GameState.kickoff();

        // Act
        final result = playSimulator.simulateRunPlay(gameState);

        // Assert
        expect(result.timeElapsed.inSeconds, greaterThanOrEqualTo(25));
        expect(result.timeElapsed.inSeconds, lessThanOrEqualTo(45));
      });

      test('should handle goal line situations appropriately', () {
        // Arrange - Team near goal line
        final gameState = GameState(
          homeScore: 0,
          awayScore: 0,
          quarter: 1,
          gameClock: const Duration(minutes: 15),
          down: 1,
          yardsToGo: 10,
          yardLine: 5, // 5 yards from goal
          homeTeamHasPossession: true,
          gameInProgress: true,
          homeTimeouts: 3,
          awayTimeouts: 3,
        );

        // Act
        final result = playSimulator.simulateRunPlay(gameState);

        // Assert
        expect(result.playType, equals(PlayType.rush));
        // Near goal line, limited yards possible
        expect(result.yardsGained, greaterThanOrEqualTo(-5));
        expect(result.yardsGained, lessThanOrEqualTo(15));
      });

      test('should set touchdown flag when play crosses goal line', () {
        // Arrange - Team 2 yards from goal
        final gameState = GameState(
          homeScore: 0,
          awayScore: 0,
          quarter: 1,
          gameClock: const Duration(minutes: 15),
          down: 1,
          yardsToGo: 10,
          yardLine: 2, // 2 yards from goal
          homeTeamHasPossession: true,
          gameInProgress: true,
          homeTimeouts: 3,
          awayTimeouts: 3,
        );

        // Act - Run multiple times to find touchdown scenario
        bool foundTouchdown = false;
        for (int i = 0; i < 50; i++) {
          final result = playSimulator.simulateRunPlay(gameState);
          if (result.yardsGained >= 2) {
            expect(result.isScore, isTrue);
            foundTouchdown = true;
            break;
          }
        }

        // Assert - Should be possible to score from 2 yards out
        expect(foundTouchdown, isTrue);
      });

      test('should set first down flag when gaining enough yards', () {
        // Arrange - 3rd and 5
        final gameState = GameState(
          homeScore: 0,
          awayScore: 0,
          quarter: 1,
          gameClock: const Duration(minutes: 15),
          down: 3,
          yardsToGo: 5,
          yardLine: 30,
          homeTeamHasPossession: true,
          gameInProgress: true,
          homeTimeouts: 3,
          awayTimeouts: 3,
        );

        // Act - Run multiple times to find first down scenario
        bool foundFirstDown = false;
        for (int i = 0; i < 50; i++) {
          final result = playSimulator.simulateRunPlay(gameState);
          if (result.yardsGained >= 5) {
            expect(result.isFirstDown, isTrue);
            foundFirstDown = true;
            break;
          } else {
            expect(result.isFirstDown, isFalse);
          }
        }

        // Assert - Should be possible to get first down
        expect(foundFirstDown, isTrue);
      });

      test('should occasionally generate fumble turnovers', () {
        // Arrange
        final gameState = GameState.kickoff();
        bool foundTurnover = false;

        // Act - Run many plays to find occasional turnover
        for (int i = 0; i < 200; i++) {
          final result = playSimulator.simulateRunPlay(gameState);
          if (result.isTurnover) {
            expect(result.playType, equals(PlayType.rush));
            foundTurnover = true;
            break;
          }
        }

        // Assert - Turnovers should be rare but possible
        expect(foundTurnover, isTrue);
      });

      test('should not stop clock for basic run plays', () {
        // Arrange
        final gameState = GameState.kickoff();

        // Act
        final result = playSimulator.simulateRunPlay(gameState);

        // Assert - Run plays that don't go out of bounds shouldn't stop clock
        if (!result.isScore && !result.isTurnover) {
          expect(result.stopClock, isFalse);
        }
      });
    });

    group('simulatePlay', () {
      test('should delegate to simulateRunPlay for now', () {
        // Arrange
        final gameState = GameState.kickoff();

        // Act
        final result = playSimulator.simulatePlay(gameState);

        // Assert
        expect(result.playType, equals(PlayType.rush));
        expect(result.yardsGained, isA<int>());
        expect(result.timeElapsed, isA<Duration>());
      });
    });
  });
}
