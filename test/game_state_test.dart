import 'package:test/test.dart';
import 'package:pocket_gm_engine/src/models/game_state.dart';

void main() {
  group('GameState', () {
    test('should create a game state with all required fields', () {
      final gameState = GameState(
        homeScore: 14,
        awayScore: 7,
        quarter: 2,
        gameClock: Duration(minutes: 8, seconds: 30),
        down: 3,
        yardsToGo: 5,
        yardLine: 35,
        homeTeamHasPossession: true,
        homeTimeouts: 2,
        awayTimeouts: 3,
        gameInProgress: true,
      );

      expect(gameState.homeScore, equals(14));
      expect(gameState.awayScore, equals(7));
      expect(gameState.quarter, equals(2));
      expect(gameState.gameClock, equals(Duration(minutes: 8, seconds: 30)));
      expect(gameState.down, equals(3));
      expect(gameState.yardsToGo, equals(5));
      expect(gameState.yardLine, equals(35));
      expect(gameState.homeTeamHasPossession, isTrue);
      expect(gameState.homeTimeouts, equals(2));
      expect(gameState.awayTimeouts, equals(3));
      expect(gameState.gameInProgress, isTrue);
    });

    test('should create a kickoff game state with correct defaults', () {
      final gameState = GameState.kickoff();

      expect(gameState.homeScore, equals(0));
      expect(gameState.awayScore, equals(0));
      expect(gameState.quarter, equals(1));
      expect(gameState.gameClock, equals(Duration(minutes: 15)));
      expect(gameState.down, equals(1));
      expect(gameState.yardsToGo, equals(10));
      expect(gameState.yardLine, equals(25));
      expect(gameState.homeTeamHasPossession, isFalse);
      expect(gameState.homeTimeouts, equals(3));
      expect(gameState.awayTimeouts, equals(3));
      expect(gameState.gameInProgress, isTrue);
    });

    test('should create a copy with modified values', () {
      final original = GameState.kickoff();
      final modified = original.copyWith(
        homeScore: 7,
        down: 2,
        yardsToGo: 3,
        homeTeamHasPossession: true,
      );

      expect(modified.homeScore, equals(7));
      expect(modified.down, equals(2));
      expect(modified.yardsToGo, equals(3));
      expect(modified.homeTeamHasPossession, isTrue);
      
      // Unchanged values should remain the same
      expect(modified.awayScore, equals(0));
      expect(modified.quarter, equals(1));
      expect(modified.yardLine, equals(25));
    });

    test('should return correct possession team score', () {
      final homeHasPossession = GameState.kickoff().copyWith(
        homeScore: 14,
        awayScore: 7,
        homeTeamHasPossession: true,
      );
      
      final awayHasPossession = GameState.kickoff().copyWith(
        homeScore: 14,
        awayScore: 7,
        homeTeamHasPossession: false,
      );

      expect(homeHasPossession.possessionTeamScore, equals(14));
      expect(homeHasPossession.defensiveTeamScore, equals(7));
      
      expect(awayHasPossession.possessionTeamScore, equals(7));
      expect(awayHasPossession.defensiveTeamScore, equals(14));
    });

    test('should correctly identify game over state', () {
      final activeGame = GameState.kickoff();
      final finishedGame = GameState.kickoff().copyWith(gameInProgress: false);

      expect(activeGame.isGameOver, isFalse);
      expect(finishedGame.isGameOver, isTrue);
    });

    test('should correctly identify overtime', () {
      final regularGame = GameState.kickoff().copyWith(quarter: 4);
      final overtimeGame = GameState.kickoff().copyWith(quarter: 5);

      expect(regularGame.isOvertime, isFalse);
      expect(overtimeGame.isOvertime, isTrue);
    });

    group('downAndDistance', () {
      test('should format down and distance correctly for 1st down', () {
        final gameState = GameState.kickoff().copyWith(down: 1, yardsToGo: 10);
        expect(gameState.downAndDistance, equals('1st & 10 at OWN 25'));
      });

      test('should format down and distance correctly for 2nd down', () {
        final gameState = GameState.kickoff().copyWith(down: 2, yardsToGo: 7);
        expect(gameState.downAndDistance, equals('2nd & 7 at OWN 25'));
      });

      test('should format down and distance correctly for 3rd down', () {
        final gameState = GameState.kickoff().copyWith(down: 3, yardsToGo: 2);
        expect(gameState.downAndDistance, equals('3rd & 2 at OWN 25'));
      });

      test('should format down and distance correctly for 4th down', () {
        final gameState = GameState.kickoff().copyWith(down: 4, yardsToGo: 1);
        expect(gameState.downAndDistance, equals('4th & 1 at OWN 25'));
      });

      test('should handle long distance correctly', () {
        final gameState = GameState.kickoff().copyWith(down: 2, yardsToGo: 15);
        expect(gameState.downAndDistance, equals('2nd & 15 at OWN 25'));
      });
    });

    group('toString', () {
      test('should format regular quarter correctly', () {
        final gameState = GameState(
          homeScore: 21,
          awayScore: 14,
          quarter: 3,
          gameClock: Duration(minutes: 5, seconds: 30),
          down: 2,
          yardsToGo: 8,
          yardLine: 45,
          homeTeamHasPossession: false,
          homeTimeouts: 2,
          awayTimeouts: 1,
          gameInProgress: true,
        );

        final result = gameState.toString();
        expect(result, contains('21-14'));
        expect(result, contains('Q3'));
        expect(result, contains('5:30'));
        expect(result, contains('2nd & 8'));
        expect(result, contains('45'));
        expect(result, contains('AWAY possession'));
      });

      test('should format overtime correctly', () {
        final gameState = GameState.kickoff().copyWith(
          quarter: 5,
          gameClock: Duration(minutes: 10),
        );

        final result = gameState.toString();
        expect(result, contains('OT'));
        expect(result, contains('10:00'));
      });

      test('should format clock with leading zero for seconds', () {
        final gameState = GameState.kickoff().copyWith(
          gameClock: Duration(minutes: 2, seconds: 5),
        );

        final result = gameState.toString();
        expect(result, contains('2:05'));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final gameState1 = GameState.kickoff();
        final gameState2 = GameState.kickoff();

        expect(gameState1, equals(gameState2));
        expect(gameState1.hashCode, equals(gameState2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final gameState1 = GameState.kickoff();
        final gameState2 = gameState1.copyWith(homeScore: 7);

        expect(gameState1, isNot(equals(gameState2)));
        expect(gameState1.hashCode, isNot(equals(gameState2.hashCode)));
      });

      test('should be equal to itself', () {
        final gameState = GameState.kickoff();
        expect(gameState, equals(gameState));
      });
    });
  });
}
