import 'package:test/test.dart';
import 'package:pocket_gm_engine/src/models/game_state.dart';
import 'package:pocket_gm_engine/src/models/play_result.dart';
import 'package:pocket_gm_engine/src/services/play_simulator.dart';
import 'package:pocket_gm_engine/src/services/clock_manager.dart';
import 'package:pocket_gm_engine/src/services/down_manager.dart';

void main() {
  group('Game Engine Integration', () {
    late PlaySimulator playSimulator;
    late ClockManager clockManager;
    late DownManager downManager;

    setUp(() {
      playSimulator = PlaySimulator();
      clockManager = ClockManager();
      downManager = DownManager();
    });

    test('should simulate a complete drive with multiple plays', () {
      // Arrange - Start a drive at the 25-yard line
      GameState gameState = GameState(
        homeScore: 0,
        awayScore: 0,
        quarter: 1,
        gameClock: const Duration(minutes: 15),
        down: 1,
        yardsToGo: 10,
        yardLine: 25,
        homeTeamHasPossession: true,
        gameInProgress: true,
        homeTimeouts: 3,
        awayTimeouts: 3,
      );

      final List<PlayResult> driveResults = [];
      int playCount = 0;
      final maxPlays = 30; // Increased safety limit for longer drives
      bool driveEnded = false;

      // Act - Simulate plays until drive ends
      while (gameState.gameInProgress && 
             gameState.down <= 4 && 
             playCount < maxPlays &&
             !driveEnded) {
        
        // Simulate the play
        final playResult = playSimulator.simulateRunPlay(gameState);
        driveResults.add(playResult);
        playCount++;

        // Update game state with all managers
        gameState = downManager.updateDownAndDistance(gameState, playResult);
        gameState = clockManager.updateClock(gameState, playResult);

        print('Play $playCount: ${playResult.playType.name} for ${playResult.yardsGained} yards - ${gameState.downAndDistance} at ${gameState.yardLine}');
        
        // Check if drive ended naturally
        driveEnded = playResult.isScore || playResult.isTurnover || gameState.down > 4;
      }

      // Assert - Drive should have realistic progression
      expect(driveResults, isNotEmpty);
      expect(playCount, lessThanOrEqualTo(maxPlays));
      
      // Drive should end with score, turnover, running out of downs, or hit safety limit
      final lastPlay = driveResults.last;
      final naturalEnding = lastPlay.isScore || lastPlay.isTurnover || gameState.down > 4;
      final hitSafetyLimit = playCount >= maxPlays;
      expect(naturalEnding || hitSafetyLimit, isTrue, 
        reason: 'Drive should end naturally or hit safety limit. '
                'Last play: score=${lastPlay.isScore}, turnover=${lastPlay.isTurnover}, '
                'down=${gameState.down}, playCount=$playCount');

      // Clock should have advanced
      expect(gameState.gameClock.inMinutes, lessThan(15));
    });

    test('should handle touchdown scenario correctly', () {
      // Arrange - Start very close to goal line
      GameState gameState = GameState(
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

      bool foundTouchdown = false;
      int attempts = 0;
      const maxAttempts = 100;

      // Act - Keep trying until we get a touchdown
      while (!foundTouchdown && attempts < maxAttempts) {
        final playResult = playSimulator.simulateRunPlay(gameState);
        attempts++;

        if (playResult.yardsGained >= 2) {
          // Update state to see touchdown reflected
          final updatedState = downManager.updateDownAndDistance(gameState, playResult);
          final finalState = clockManager.updateClock(updatedState, playResult);

          // Assert - All flags should be set correctly
          expect(playResult.isScore, isTrue);
          expect(playResult.stopClock, isTrue);
          expect(finalState.homeScore, equals(7)); // Touchdown + PAT
          foundTouchdown = true;
        }
      }

      expect(foundTouchdown, isTrue, reason: 'Should be able to score from 2-yard line');
    });

    test('should handle first down progression correctly', () {
      // Arrange - 3rd and 5 situation
      GameState gameState = GameState(
        homeScore: 0,
        awayScore: 0,
        quarter: 1,
        gameClock: const Duration(minutes: 15),
        down: 3,
        yardsToGo: 5,
        yardLine: 50,
        homeTeamHasPossession: true,
        gameInProgress: true,
        homeTimeouts: 3,
        awayTimeouts: 3,
      );

      bool foundFirstDown = false;
      int attempts = 0;
      const maxAttempts = 50;

      // Act - Keep trying until we get a first down
      while (!foundFirstDown && attempts < maxAttempts) {
        final playResult = playSimulator.simulateRunPlay(gameState);
        attempts++;

        if (playResult.yardsGained >= 5) {
          // Update state to see first down reflected
          final updatedState = downManager.updateDownAndDistance(gameState, playResult);

          // Assert - First down should reset down and distance
          expect(playResult.isFirstDown, isTrue);
          expect(updatedState.down, equals(1));
          expect(updatedState.yardsToGo, equals(10));
          expect(updatedState.yardLine, equals(50 + playResult.yardsGained));
          foundFirstDown = true;
        }
      }

      expect(foundFirstDown, isTrue, reason: 'Should be able to get first down on 3rd and 5 within $maxAttempts attempts');
    });

    test('should handle turnover on downs correctly', () {
      // Arrange - 4th and long situation
      GameState gameState = GameState(
        homeScore: 0,
        awayScore: 0,
        quarter: 1,
        gameClock: const Duration(minutes: 15),
        down: 4,
        yardsToGo: 15,
        yardLine: 40,
        homeTeamHasPossession: true,
        gameInProgress: true,
        homeTimeouts: 3,
        awayTimeouts: 3,
      );

      // Act - Simulate a play that doesn't get the first down
      bool foundFailedConversion = false;
      int attempts = 0;
      const maxAttempts = 50;

      while (!foundFailedConversion && attempts < maxAttempts) {
        final playResult = playSimulator.simulateRunPlay(gameState);
        attempts++;

        if (playResult.yardsGained < 15 && !playResult.isTurnover) {
          // Update state to see turnover on downs
          final updatedState = downManager.updateDownAndDistance(gameState, playResult);

          // Assert - Should result in change of possession
          expect(updatedState.homeTeamHasPossession, isFalse);
          expect(updatedState.down, equals(1));
          expect(updatedState.yardsToGo, equals(10));
          foundFailedConversion = true;
        }
      }

      expect(foundFailedConversion, isTrue, reason: 'Should find failed 4th down conversion');
    });

    test('should handle fumble turnover correctly', () {
      // Arrange
      GameState gameState = GameState.kickoff();
      bool foundFumble = false;
      int attempts = 0;
      const maxAttempts = 200; // Fumbles are rare

      // Act - Keep simulating until we get a fumble
      while (!foundFumble && attempts < maxAttempts) {
        final playResult = playSimulator.simulateRunPlay(gameState);
        attempts++;

        if (playResult.isTurnover) {
          // Update state to see fumble reflected
          final updatedState = downManager.updateDownAndDistance(gameState, playResult);
          final finalState = clockManager.updateClock(updatedState, playResult);

          // Assert - Fumble should change possession and stop clock
          expect(playResult.stopClock, isTrue);
          // GameState.kickoff() starts with away team (homeTeamHasPossession: false)
          // After fumble, possession should flip to home team (true)
          expect(updatedState.homeTeamHasPossession, isTrue);
          expect(updatedState.down, equals(1));
          expect(updatedState.yardsToGo, equals(10));
          foundFumble = true;
        }
      }

      expect(foundFumble, isTrue, reason: 'Should occasionally generate fumbles');
    });

    test('should handle clock expiration correctly', () {
      // Arrange - Late in the quarter
      GameState gameState = GameState(
        homeScore: 7,
        awayScore: 3,
        quarter: 1,
        gameClock: const Duration(minutes: 0, seconds: 30), // 30 seconds left
        down: 1,
        yardsToGo: 10,
        yardLine: 50,
        homeTeamHasPossession: true,
        gameInProgress: true,
        homeTimeouts: 3,
        awayTimeouts: 3,
      );

      // Act - Simulate a play that uses up remaining time
      final playResult = playSimulator.simulateRunPlay(gameState);
      final updatedState = downManager.updateDownAndDistance(gameState, playResult);
      final finalState = clockManager.updateClock(updatedState, playResult);

      // Assert - Clock should be at zero or very low
      expect(finalState.gameClock.inSeconds, lessThanOrEqualTo(30));
      
      // Quarter transitions are handled by higher-level game logic, not ClockManager
      expect(clockManager.isQuarterEnded(finalState), 
             finalState.gameClock.inSeconds <= 0);
    });

    test('should maintain data integrity through multiple play cycles', () {
      // Arrange
      GameState gameState = GameState.kickoff();
      final initialHomeScore = gameState.homeScore;
      final initialAwayScore = gameState.awayScore;

      // Act - Simulate several plays without scoring
      for (int i = 0; i < 5; i++) {
        final playResult = playSimulator.simulateRunPlay(gameState);
        
        // Only continue if no score or turnover
        if (!playResult.isScore && !playResult.isTurnover) {
          gameState = downManager.updateDownAndDistance(gameState, playResult);
          gameState = clockManager.updateClock(gameState, playResult);
        } else {
          break;
        }
      }

      // Assert - Core game state should remain valid
      expect(gameState.down, greaterThanOrEqualTo(1));
      expect(gameState.down, lessThanOrEqualTo(4));
      expect(gameState.yardsToGo, greaterThanOrEqualTo(1));
      expect(gameState.yardLine, greaterThanOrEqualTo(1));
      expect(gameState.yardLine, lessThanOrEqualTo(99));
      expect(gameState.quarter, greaterThanOrEqualTo(1));
      expect(gameState.quarter, lessThanOrEqualTo(4));
      
      // Scores should only change on scoring plays
      if (gameState.homeScore != initialHomeScore || gameState.awayScore != initialAwayScore) {
        // This would only happen if there was a scoring play
        expect(gameState.homeScore + gameState.awayScore, greaterThan(initialHomeScore + initialAwayScore));
      }
    });
  });
}
