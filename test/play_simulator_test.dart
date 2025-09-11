import 'package:test/test.dart';
import 'package:pocket_gm_engine/src/models/game_state.dart';
import 'package:pocket_gm_engine/src/models/play_result.dart';
import 'package:pocket_gm_engine/src/services/play_simulator.dart';
import 'package:pocket_gm_engine/src/models/play_call.dart';
import 'package:pocket_gm_generator/pocket_gm_generator.dart';

void main() {
  group('PlaySimulator', () {
    late PlaySimulator playSimulator;
    late Team mockOffensiveTeam;
    late Team mockDefensiveTeam;

    setUp(() {
      playSimulator = PlaySimulator();
      
      // Create mock teams for testing
      final mockStadium = Stadium(
        name: 'Test Stadium',
        location: 'Test City, TS',
        turfType: TurfType.grass,
        roofType: RoofType.open,
        capacity: 65000,
        yearBuilt: 2000,
        luxurySuites: 100,
        concessionsRating: 75,
        parkingRating: 70,
        homeFieldAdvantage: 5,
      );
      
      mockOffensiveTeam = Team(
        name: 'Test Offense',
        abbreviation: 'TO',
        primaryColor: '#FF0000',
        secondaryColor: '#FFFFFF',
        roster: [], // Empty roster for basic testing
        stadium: mockStadium,
        fanHappiness: 75,
        wins: 5,
        losses: 3,
        city: 'Test City',
        conference: 'Test Conference',
        division: 'Test Division',
      );
      
      mockDefensiveTeam = Team(
        name: 'Test Defense',
        abbreviation: 'TD',
        primaryColor: '#0000FF',
        secondaryColor: '#FFFFFF',
        roster: [], // Empty roster for basic testing
        stadium: mockStadium,
        fanHappiness: 70,
        wins: 3,
        losses: 5,
        city: 'Test City 2',
        conference: 'Test Conference',
        division: 'Test Division',
      );
    });

    group('simulateRunPlay', () {
      test('should return a valid PlayResult for basic run play', () {
        // Arrange
        final gameState = GameState.kickoff();

        // Act
        final result = playSimulator.simulateRunPlay(gameState, mockOffensiveTeam, mockDefensiveTeam);

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
          final result = playSimulator.simulateRunPlay(gameState, mockOffensiveTeam, mockDefensiveTeam);
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
        final result = playSimulator.simulateRunPlay(gameState, mockOffensiveTeam, mockDefensiveTeam);

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
          yardLine: 95, // 5 yards from opponent's goal (100-5=95)
          homeTeamHasPossession: true,
          gameInProgress: true,
          homeTimeouts: 3,
          awayTimeouts: 3,
        );

        // Act
        final result = playSimulator.simulateRunPlay(gameState, mockOffensiveTeam, mockDefensiveTeam);

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
          yardLine: 98, // 2 yards from opponent's goal (100-2=98)
          homeTeamHasPossession: true,
          gameInProgress: true,
          homeTimeouts: 3,
          awayTimeouts: 3,
        );

        // Act - Run multiple times to find touchdown scenario
        bool foundTouchdown = false;
        for (int i = 0; i < 50; i++) {
          final result = playSimulator.simulateRunPlay(gameState, mockOffensiveTeam, mockDefensiveTeam);
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
          final result = playSimulator.simulateRunPlay(gameState, mockOffensiveTeam, mockDefensiveTeam);
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
        // With 2% fumble rate, 500 attempts gives >99.99% chance of finding one
        for (int i = 0; i < 500; i++) {
          final result = playSimulator.simulateRunPlay(gameState, mockOffensiveTeam, mockDefensiveTeam);
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
        final result = playSimulator.simulateRunPlay(gameState, mockOffensiveTeam, mockDefensiveTeam);

        // Assert - Run plays that don't go out of bounds shouldn't stop clock
        if (!result.isScore && !result.isTurnover) {
          expect(result.stopClock, isFalse);
        }
      });
    });

    group('simulatePlay', () {
      test('should handle run play calls correctly', () {
        // Arrange
        final gameState = GameState.kickoff();
        final playCall = PlayCall.run(OffensiveRunPlay.insideRun);
        
        // Create mock teams for testing
        final testStadium1 = Stadium(
          name: 'Test Stadium',
          location: 'Test City, TS',
          turfType: TurfType.grass,
          roofType: RoofType.open,
          capacity: 65000,
          yearBuilt: 2000,
          luxurySuites: 100,
          concessionsRating: 75,
          parkingRating: 70,
          homeFieldAdvantage: 5,
        );
        
        final testStadium2 = Stadium(
          name: 'Test Stadium 2',
          location: 'Test City 2, TS',
          turfType: TurfType.grass,
          roofType: RoofType.open,
          capacity: 65000,
          yearBuilt: 2000,
          luxurySuites: 100,
          concessionsRating: 75,
          parkingRating: 70,
          homeFieldAdvantage: 5,
        );
        
        final offensiveTeam = Team(
          name: 'Test Offense',
          abbreviation: 'TO',
          primaryColor: '#FF0000',
          secondaryColor: '#FFFFFF',
          roster: [], // Empty roster for basic testing
          stadium: testStadium1,
          fanHappiness: 75,
          wins: 5,
          losses: 3,
          city: 'Test City',
          conference: 'Test Conference',
          division: 'Test Division',
        );
        
        final defensiveTeam = Team(
          name: 'Test Defense',
          abbreviation: 'TD',
          primaryColor: '#0000FF',
          secondaryColor: '#FFFFFF',
          roster: [], // Empty roster for basic testing
          stadium: testStadium2,
          fanHappiness: 70,
          wins: 3,
          losses: 5,
          city: 'Test City 2',
          conference: 'Test Conference',
          division: 'Test Division',
        );

        // Act
        final result = playSimulator.simulatePlay(gameState, playCall, offensiveTeam, defensiveTeam);

        // Assert
        expect(result.playType, equals(PlayType.rush));
        expect(result.yardsGained, isA<int>());
        expect(result.timeElapsed, isA<Duration>());
      });
    });
  });
}
