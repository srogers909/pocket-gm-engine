import 'package:test/test.dart';
import 'package:pocket_gm_engine/src/models/game_state.dart';
import 'package:pocket_gm_engine/src/models/play_result.dart';
import 'package:pocket_gm_engine/src/services/play_simulator.dart';
import 'package:pocket_gm_engine/src/services/clock_manager.dart';
import 'package:pocket_gm_engine/src/services/down_manager.dart';
import 'package:pocket_gm_generator/pocket_gm_generator.dart';

void main() {
  group('Game Engine Integration', () {
    late PlaySimulator playSimulator;
    late ClockManager clockManager;
    late DownManager downManager;
    late Team homeTeam;
    late Team awayTeam;

    setUp(() {
      playSimulator = PlaySimulator();
      clockManager = ClockManager();
      downManager = DownManager();
      
      // Create simple test teams for integration tests
      homeTeam = Team(
        name: 'Test Home',
        abbreviation: 'HOM',
        primaryColor: '#000000',
        secondaryColor: '#FFFFFF',
        roster: _createTestRoster(),
        stadium: _createTestStadium(),
        fanHappiness: 80,
        wins: 0,
        losses: 0,
        city: 'Home City',
        conference: 'Test',
        division: 'Test',
        staff: _createTestStaff(),
        tier: TeamTier.average,
      );
      
      awayTeam = Team(
        name: 'Test Away',
        abbreviation: 'AWY',
        primaryColor: '#FFFFFF',
        secondaryColor: '#000000',
        roster: _createTestRoster(),
        stadium: _createTestStadium(),
        fanHappiness: 80,
        wins: 0,
        losses: 0,
        city: 'Away City',
        conference: 'Test',
        division: 'Test',
        staff: _createTestStaff(),
        tier: TeamTier.average,
      );
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
        final playResult = playSimulator.simulateRunPlay(gameState, homeTeam, awayTeam);
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
        final playResult = playSimulator.simulateRunPlay(gameState, homeTeam, awayTeam);
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
        final playResult = playSimulator.simulateRunPlay(gameState, homeTeam, awayTeam);
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
        final playResult = playSimulator.simulateRunPlay(gameState, homeTeam, awayTeam);
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
        final playResult = playSimulator.simulateRunPlay(gameState, homeTeam, awayTeam);
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
      final playResult = playSimulator.simulateRunPlay(gameState, homeTeam, awayTeam);
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
        final playResult = playSimulator.simulateRunPlay(gameState, homeTeam, awayTeam);
        
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

/// Creates a minimal test stadium for integration testing
Stadium _createTestStadium() {
  return Stadium(
    name: 'Test Stadium',
    location: 'Test City, TS',
    turfType: TurfType.grass,
    roofType: RoofType.open,
    capacity: 65000,
    yearBuilt: 2000,
    luxurySuites: 50,
    concessionsRating: 85,
    parkingRating: 80,
    homeFieldAdvantage: 5,
  );
}

/// Creates a minimal test roster with basic positions for integration testing
List<Player> _createTestRoster() {
  return [
    // QB
    Player(
      fullName: 'Test Quarterback',
      commonName: 'T. Quarterback',
      shortName: 'Quarterback',
      primaryPosition: 'QB',
      heightInches: 75,
      weightLbs: 220,
      college: 'Test University',
      birthInfo: '05/15/1998 (27 yrs) - USA 🇺🇸',
      draftYear: 2021,
      draftInfo: '2021: Rd 1, Pick 15 (Test Team)',
      overallRating: 75,
      positionRating1: 70, // Arm Strength
      positionRating2: 75, // Accuracy
      positionRating3: 65, // Mobility
      pressureResistance: 70,
      evasion: 60,
      durabilityRating: 80,
    ),
    // RB
    Player(
      fullName: 'Test Runningback',
      commonName: 'T. Runningback',
      shortName: 'Runningback',
      primaryPosition: 'RB',
      heightInches: 70,
      weightLbs: 200,
      college: 'Test University',
      birthInfo: '08/22/1999 (26 yrs) - USA 🇺🇸',
      draftYear: 2022,
      draftInfo: '2022: Rd 2, Pick 45 (Test Team)',
      overallRating: 70,
      positionRating1: 75, // Rush Power
      positionRating2: 70, // Speed
      positionRating3: 65, // Catching
      pressureResistance: 65,
      evasion: 75,
      durabilityRating: 75,
    ),
    // WR
    Player(
      fullName: 'Test Receiver',
      commonName: 'T. Receiver',
      shortName: 'Receiver',
      primaryPosition: 'WR',
      heightInches: 72,
      weightLbs: 185,
      college: 'Test University',
      birthInfo: '12/03/1997 (28 yrs) - USA 🇺🇸',
      draftYear: 2020,
      draftInfo: '2020: Rd 1, Pick 30 (Test Team)',
      overallRating: 72,
      positionRating1: 70, // Route Running
      positionRating2: 75, // Catching
      positionRating3: 80, // Speed
      pressureResistance: 60,
      evasion: 70,
      durabilityRating: 70,
    ),
    // TE
    Player(
      fullName: 'Test Tightend',
      commonName: 'T. Tightend',
      shortName: 'Tightend',
      primaryPosition: 'TE',
      heightInches: 76,
      weightLbs: 250,
      college: 'Test University',
      birthInfo: '03/18/1996 (29 yrs) - USA 🇺🇸',
      draftYear: 2019,
      draftInfo: '2019: Rd 3, Pick 78 (Test Team)',
      overallRating: 68,
      positionRating1: 65, // Blocking
      positionRating2: 70, // Catching
      positionRating3: 60, // Route Running
      pressureResistance: 70,
      evasion: 55,
      durabilityRating: 85,
    ),
    // OL (simplified - just one for testing)
    Player(
      fullName: 'Test Lineman',
      commonName: 'T. Lineman',
      shortName: 'Lineman',
      primaryPosition: 'OL',
      heightInches: 78,
      weightLbs: 310,
      college: 'Test University',
      birthInfo: '07/09/1995 (30 yrs) - USA 🇺🇸',
      draftYear: 2018,
      draftInfo: '2018: Rd 2, Pick 55 (Test Team)',
      overallRating: 65,
      positionRating1: 70, // Run Blocking
      positionRating2: 65, // Pass Blocking
      positionRating3: 60, // Strength
      pressureResistance: 80,
      evasion: 30,
      durabilityRating: 90,
    ),
    // LB
    Player(
      fullName: 'Test Linebacker',
      commonName: 'T. Linebacker',
      shortName: 'Linebacker',
      primaryPosition: 'LB',
      heightInches: 74,
      weightLbs: 240,
      college: 'Test University',
      birthInfo: '11/25/1998 (26 yrs) - USA 🇺🇸',
      draftYear: 2021,
      draftInfo: '2021: Rd 1, Pick 25 (Test Team)',
      overallRating: 70,
      positionRating1: 70, // Tackling
      positionRating2: 65, // Run Defense
      positionRating3: 60, // Coverage
      pressureResistance: 75,
      evasion: 60,
      durabilityRating: 80,
    ),
    // CB
    Player(
      fullName: 'Test Cornerback',
      commonName: 'T. Cornerback',
      shortName: 'Cornerback',
      primaryPosition: 'CB',
      heightInches: 71,
      weightLbs: 190,
      college: 'Test University',
      birthInfo: '04/12/1999 (26 yrs) - USA 🇺🇸',
      draftYear: 2022,
      draftInfo: '2022: Rd 1, Pick 18 (Test Team)',
      overallRating: 68,
      positionRating1: 70, // Coverage
      positionRating2: 65, // Speed
      positionRating3: 60, // Tackling
      pressureResistance: 65,
      evasion: 75,
      durabilityRating: 70,
    ),
    // S
    Player(
      fullName: 'Test Safety',
      commonName: 'T. Safety',
      shortName: 'Safety',
      primaryPosition: 'S',
      heightInches: 72,
      weightLbs: 205,
      college: 'Test University',
      birthInfo: '09/30/1997 (27 yrs) - USA 🇺🇸',
      draftYear: 2020,
      draftInfo: '2020: Rd 2, Pick 42 (Test Team)',
      overallRating: 69,
      positionRating1: 65, // Coverage
      positionRating2: 70, // Tackling
      positionRating3: 68, // Range
      pressureResistance: 70,
      evasion: 65,
      durabilityRating: 75,
    ),
    // DE
    Player(
      fullName: 'Test Defensive End',
      commonName: 'T. Defensive End',
      shortName: 'Defensive End',
      primaryPosition: 'DE',
      heightInches: 76,
      weightLbs: 265,
      college: 'Test University',
      birthInfo: '06/14/1996 (29 yrs) - USA 🇺🇸',
      draftYear: 2019,
      draftInfo: '2019: Rd 1, Pick 12 (Test Team)',
      overallRating: 71,
      positionRating1: 75, // Pass Rush
      positionRating2: 70, // Run Defense
      positionRating3: 65, // Strength
      pressureResistance: 80,
      evasion: 55,
      durabilityRating: 85,
    ),
    // DT
    Player(
      fullName: 'Test Defensive Tackle',
      commonName: 'T. Defensive Tackle',
      shortName: 'Defensive Tackle',
      primaryPosition: 'DT',
      heightInches: 75,
      weightLbs: 300,
      college: 'Test University',
      birthInfo: '01/08/1994 (31 yrs) - USA 🇺🇸',
      draftYear: 2017,
      draftInfo: '2017: Rd 1, Pick 8 (Test Team)',
      overallRating: 67,
      positionRating1: 65, // Pass Rush
      positionRating2: 75, // Run Defense
      positionRating3: 70, // Strength
      pressureResistance: 85,
      evasion: 40,
      durabilityRating: 88,
    ),
    // K
    Player(
      fullName: 'Test Kicker',
      commonName: 'T. Kicker',
      shortName: 'Kicker',
      primaryPosition: 'K',
      heightInches: 70,
      weightLbs: 180,
      college: 'Test University',
      birthInfo: '10/20/1995 (29 yrs) - USA 🇺🇸',
      draftYear: 2018,
      draftInfo: '2018: Rd 7, Pick 245 (Test Team)',
      overallRating: 65,
      positionRating1: 70, // Accuracy/Power
      positionRating2: 65, // Range
      positionRating3: 60, // Consistency
      pressureResistance: 60,
      evasion: 30,
      durabilityRating: 70,
    ),
    // P
    Player(
      fullName: 'Test Punter',
      commonName: 'T. Punter',
      shortName: 'Punter',
      primaryPosition: 'P',
      heightInches: 71,
      weightLbs: 185,
      college: 'Test University',
      birthInfo: '02/28/1996 (29 yrs) - USA 🇺🇸',
      draftYear: 2019,
      draftInfo: '2019: Rd 6, Pick 195 (Test Team)',
      overallRating: 63,
      positionRating1: 68, // Power/Distance
      positionRating2: 65, // Hang Time
      positionRating3: 60, // Accuracy
      pressureResistance: 55,
      evasion: 35,
      durabilityRating: 75,
    ),
  ];
}

/// Creates minimal test staff for integration testing
TeamStaff _createTestStaff() {
  return TeamStaff(
    headCoach: HeadCoach(
      fullName: 'Test HeadCoach',
      commonName: 'T. HeadCoach',
      shortName: 'HeadCoach',
      age: 45,
      yearsExperience: 10,
      overallRating: 75,
      morale: 80,
      playCalling: 68,
      gameManagement: 70,
      playerDevelopment: 72,
      motivation: 75,
    ),
    offensiveCoordinator: OffensiveCoordinator(
      fullName: 'Test OffCoordinator',
      commonName: 'T. OffCoordinator',
      shortName: 'OffCoordinator',
      age: 40,
      yearsExperience: 8,
      overallRating: 70,
      morale: 75,
      playCalling: 70,
      passingOffense: 72,
      rushingOffense: 68,
      offensiveLineExpertise: 65,
    ),
    defensiveCoordinator: DefensiveCoordinator(
      fullName: 'Test DefCoordinator',
      commonName: 'T. DefCoordinator',
      shortName: 'DefCoordinator',
      age: 42,
      yearsExperience: 9,
      overallRating: 72,
      morale: 78,
      defensivePlayCalling: 70,
      passingDefense: 70,
      rushingDefense: 75,
      defensiveLineExpertise: 68,
    ),
    teamDoctor: TeamDoctor(
      fullName: 'Test TeamDoctor',
      commonName: 'T. TeamDoctor',
      shortName: 'TeamDoctor',
      age: 50,
      yearsExperience: 15,
      overallRating: 70,
      morale: 85,
      injuryPrevention: 68,
      rehabilitationSpeed: 72,
      misdiagnosisPrevention: 70,
      staminaRecovery: 75,
    ),
    headScout: HeadScout(
      fullName: 'Test HeadScout',
      commonName: 'T. HeadScout',
      shortName: 'HeadScout',
      age: 38,
      yearsExperience: 12,
      overallRating: 68,
      morale: 80,
      collegeScouting: 65,
      proScouting: 72,
      potentialIdentification: 70,
      tradeEvaluation: 68,
    ),
  );
}
