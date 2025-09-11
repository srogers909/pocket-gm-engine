import 'dart:math';
import '../models/game_state.dart';
import '../models/play_result.dart';
import '../models/play_call.dart';
import 'package:pocket_gm_generator/pocket_gm_generator.dart';

/// Service responsible for simulating individual football plays.
///
/// This class handles the simulation of different types of plays and generates
/// realistic outcomes based on game situation and statistical probabilities.
class PlaySimulator {
  final Random _random = Random();

  // Player selection helper methods

  /// Selects a quarterback from the team roster
  String? _selectQuarterback(Team team) {
    final quarterbacks = team.getPlayersByPosition('QB');
    if (quarterbacks.isEmpty) return null;

    // Sort by overall rating and pick the best available
    quarterbacks.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return quarterbacks.first.commonName;
  }

  /// Selects a running back from the team roster
  String? _selectRunningBack(Team team) {
    final runningBacks = team.getPlayersByPosition('RB');
    if (runningBacks.isEmpty) return null;

    // Sort by overall rating and pick the best available
    runningBacks.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return runningBacks.first.commonName;
  }

  /// Selects a wide receiver from the team roster
  String? _selectReceiver(Team team) {
    final receivers = team.getPlayersByPosition('WR');
    if (receivers.isEmpty) return null;

    // Add some randomness to receiver selection (top 3 receivers)
    receivers.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    final topReceivers = receivers.take(3).toList();
    return topReceivers[_random.nextInt(topReceivers.length)].commonName;
  }

  /// Selects a tight end from the team roster
  String? _selectTightEnd(Team team) {
    final tightEnds = team.getPlayersByPosition('TE');
    if (tightEnds.isEmpty) return null;

    tightEnds.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return tightEnds.first.commonName;
  }

  /// Selects a defensive player for tackles/coverage
  String? _selectDefender(Team team, {String? preferredPosition}) {
    List<Player> defenders;

    if (preferredPosition != null) {
      defenders = team.getPlayersByPosition(preferredPosition);
    } else {
      // Get a mix of defensive players
      defenders = [
        ...team.getPlayersByPosition('LB'),
        ...team.getPlayersByPosition('CB'),
        ...team.getPlayersByPosition('S'),
        ...team.getPlayersByPosition('DE'),
        ...team.getPlayersByPosition('DT'),
      ];
    }

    if (defenders.isEmpty) return null;

    // Add some randomness to defensive player selection
    defenders.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    final topDefenders = defenders.take(5).toList();
    return topDefenders[_random.nextInt(topDefenders.length)].commonName;
  }

  /// Selects additional players involved in the play
  List<String> _selectInvolvedPlayers(
    Team offensiveTeam,
    Team defensiveTeam, {
    int count = 2,
  }) {
    final involved = <String>[];

    // Add some offensive players
    final offensivePlayers = [
      ...offensiveTeam.getPlayersByPosition('OL'),
      ...offensiveTeam.getPlayersByPosition('FB'),
    ];

    // Add some defensive players
    final defensivePlayers = [
      ...defensiveTeam.getPlayersByPosition('LB'),
      ...defensiveTeam.getPlayersByPosition('DB'),
    ];

    final allPlayers = [...offensivePlayers, ...defensivePlayers];
    if (allPlayers.isEmpty) return involved;

    // Randomly select involved players
    final shuffled = List.from(allPlayers)..shuffle(_random);
    for (int i = 0; i < count && i < shuffled.length; i++) {
      involved.add(shuffled[i].commonName);
    }

    return involved;
  }

  /// Selects a kicker from the team roster
  String? _selectKicker(Team team) {
    final kickers = team.getPlayersByPosition('K');
    if (kickers.isEmpty) return null;

    // Sort by overall rating and pick the best available
    kickers.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return kickers.first.commonName;
  }

  /// Selects a punter from the team roster
  String? _selectPunter(Team team) {
    final punters = team.getPlayersByPosition('P');
    if (punters.isEmpty) return null;

    // Sort by overall rating and pick the best available
    punters.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return punters.first.commonName;
  }

  /// Selects special teams players for coverage/blocking
  List<String> _selectSpecialTeamsPlayers(
    Team offensiveTeam,
    Team defensiveTeam, {
    int count = 3,
  }) {
    final involved = <String>[];

    // Add some special teams players (mix of positions)
    final specialTeamsPlayers = [
      ...offensiveTeam.getPlayersByPosition(
        'LB',
      ), // Often play on special teams
      ...offensiveTeam.getPlayersByPosition('WR'), // Gunners on punts
      ...defensiveTeam.getPlayersByPosition('LB'),
      ...defensiveTeam.getPlayersByPosition('S'), // Special teams coverage
    ];

    if (specialTeamsPlayers.isEmpty) return involved;

    // Randomly select special teams players
    final shuffled = List.from(specialTeamsPlayers)..shuffle(_random);
    for (int i = 0; i < count && i < shuffled.length; i++) {
      involved.add(shuffled[i].commonName);
    }

    return involved;
  }

  /// Simulates a basic running play.
  ///
  /// Generates realistic yards gained, time elapsed, and play outcomes
  /// based on the current game situation. Considers factors like:
  /// - Field position (goal line situations)
  /// - Distance to first down
  /// - Random variation for realistic gameplay
  ///
  /// Returns a [PlayResult] with appropriate flags set for touchdowns,
  /// first downs, turnovers, and clock management.
  PlayResult simulateRunPlay(
    GameState gameState,
    Team offensiveTeam,
    Team defensiveTeam,
  ) {
    // Base yards gained distribution: weighted toward realistic outcomes
    int yardsGained = _generateRunYards(gameState);

    // Time elapsed: running plays typically take 25-45 seconds
    final timeElapsed = Duration(seconds: 25 + _random.nextInt(21));

    // Check for touchdown
    final distanceToGoal = 100 - gameState.yardLine;
    final isScore = yardsGained >= distanceToGoal;

    // Check for first down (if not scoring)
    final isFirstDown = !isScore && yardsGained >= gameState.yardsToGo;

    // Check for turnover (fumble) - rare but possible
    final isTurnover = _shouldFumble();

    // Clock stops for scores and turnovers, but not normal runs
    final stopClock = isScore || isTurnover;

    return PlayResult(
      playType: PlayType.rush,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed,
      isTurnover: isTurnover,
      isScore: isScore,
      isFirstDown: isFirstDown,
      stopClock: stopClock,
    );
  }

  /// Simulates any type of play based on the specific play call.
  ///
  /// Accepts a [PlayCall] to determine the type of play to simulate,
  /// then routes to the appropriate simulation method for that play type.
  /// Each play type has unique characteristics and outcome probabilities.
  PlayResult simulatePlay(
    GameState gameState,
    PlayCall playCall,
    Team offensiveTeam,
    Team defensiveTeam,
  ) {
    if (playCall.isRun) {
      return _simulateRunPlayByType(
        gameState,
        playCall.runPlay!,
        offensiveTeam,
        defensiveTeam,
        playCall,
      );
    } else if (playCall.isPass) {
      return _simulatePassPlayByType(
        gameState,
        playCall.passPlay!,
        offensiveTeam,
        defensiveTeam,
        playCall,
      );
    } else if (playCall.isSpecialTeams) {
      return _simulateSpecialTeamsPlay(
        gameState,
        playCall.specialTeamsPlay!,
        offensiveTeam,
        defensiveTeam,
      );
    }

    // Fallback to basic run if somehow no valid play type
    return simulateRunPlay(gameState, offensiveTeam, defensiveTeam);
  }

  /// Simulates a play with both offensive and defensive calls.
  ///
  /// The defensive play call modifies the outcome of the offensive play,
  /// creating realistic interactions between offensive and defensive strategies.
  /// This is the primary method for simulating plays in a full game context.
  PlayResult simulatePlayWithDefense(
    GameState gameState,
    PlayCall offensivePlay,
    PlayCall defensivePlay,
    Team offensiveTeam,
    Team defensiveTeam,
  ) {
    // First simulate the base offensive play
    PlayResult baseResult = simulatePlay(
      gameState,
      offensivePlay,
      offensiveTeam,
      defensiveTeam,
    );

    // Then apply defensive modifications
    if (defensivePlay.isDefense) {
      return _applyDefensiveModifications(
        baseResult,
        offensivePlay,
        defensivePlay.defensivePlay!,
      );
    }

    // If no defensive play provided, return base result
    return baseResult;
  }

  /// Generates realistic yards gained for a running play using player attributes.
  ///
  /// Now uses player ratings to dynamically calculate outcomes:
  /// - Primary skill player rating affects success rate
  /// - Offensive line rating affects blocking quality
  /// - Defensive line rating affects run stopping ability
  /// - Coaching ratings provide scheme bonuses
  int _generateRunYards(GameState gameState, [PlayCall? playCall]) {
    final distanceToGoal = 100 - gameState.yardLine;

    // Goal line situations: limited upside, more conservative
    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYards(playCall);
    }

    // Normal field position: full range of possibilities
    return _generateNormalRunYards(playCall);
  }

  /// Generates yards for goal line running situations using player attributes.
  ///
  /// Goal line runs have different dynamics:
  /// - Limited big play potential
  /// - Higher chance of short gains
  /// - Possible stuffs for loss
  /// - Now considers player and coaching attributes
  int _generateGoalLineRunYards([PlayCall? playCall]) {
    // Base probability thresholds for goal line situations
    int lossThreshold = 10;
    int noGainThreshold = 40;
    int shortGainThreshold = 80;
    // Goal line has limited upside - max gain threshold stays at 100

    // Base yard ranges for goal line
    int maxLoss = 3;
    int maxNoGain = 1;
    int maxShortGain = 3;
    int maxBigGain = 6;

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get skill player rating (for RB: positionRating1 = Rush Power)
      double skillPlayerRating = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final player = players.primarySkillPlayer as Player;
        skillPlayerRating = player.positionRating1
            .toDouble(); // Rush Power rating
      }

      // Get offensive line rating (more important in goal line situations)
      double offensiveLineRating = players.offensiveLineRating;

      // Get defensive line rating (opponent strength)
      double defensiveLineRating = players.defensiveLineRating;

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.rushingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // FIXED CALCULATION: Calculate advantage relative to league average (50)
      double offensiveAdvantage =
          (skillPlayerRating + offensiveLineRating) / 2.0; // Average of ratings
      double netAdvantage =
          offensiveAdvantage - defensiveLineRating + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 3.0; // Scale to roughly -16 to +16
      advantageModifier = advantageModifier.clamp(-15.0, 15.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce bad outcomes, increase good outcomes
        lossThreshold = (lossThreshold - advantageModifier).round().clamp(
          2,
          18,
        );
        noGainThreshold = (noGainThreshold - (advantageModifier * 1.5))
            .round()
            .clamp(15, 50);
        shortGainThreshold = (shortGainThreshold - (advantageModifier / 2))
            .round()
            .clamp(70, 90);

        // Slightly increase yard potential (limited in goal line)
        maxShortGain = (maxShortGain + (advantageModifier / 5)).round().clamp(
          3,
          5,
        );
        maxBigGain = (maxBigGain + (advantageModifier / 3)).round().clamp(
          6,
          10,
        );
      } else if (advantageModifier < 0) {
        // Negative advantage: increase bad outcomes, reduce good outcomes
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + absAdvantage).round().clamp(2, 25);
        noGainThreshold = (noGainThreshold + (absAdvantage * 1.5))
            .round()
            .clamp(30, 60);
        shortGainThreshold = (shortGainThreshold + (absAdvantage / 2))
            .round()
            .clamp(75, 95);

        // Decrease yard potential
        maxLoss = (maxLoss + (absAdvantage / 5)).round().clamp(3, 6);
        maxShortGain = (maxShortGain - (absAdvantage / 5)).round().clamp(2, 3);
        maxBigGain = (maxBigGain - (absAdvantage / 3)).round().clamp(4, 6);
      }
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss
      return -1 - _random.nextInt(maxLoss); // -1 to -maxLoss yards
    } else if (roll < noGainThreshold) {
      // No gain or minimal gain
      return _random.nextInt(maxNoGain + 1); // 0 to maxNoGain yards
    } else if (roll < shortGainThreshold) {
      // Short gain
      return 2 + _random.nextInt(maxShortGain); // 2 to (2 + maxShortGain) yards
    } else {
      // Bigger gain (limited in goal line)
      return 5 + _random.nextInt(maxBigGain); // 5 to (5 + maxBigGain) yards
    }
  }

  /// Generates yards for normal field position running plays.
  ///
  /// Uses realistic NFL running statistics with player attribute modifiers:
  /// - Average run: ~4.5 yards
  /// - Distribution favors 1-8 yard gains
  /// - Occasional losses and big plays
  /// - Now considers player and coaching attributes when provided
  int _generateNormalRunYards([PlayCall? playCall]) {
    // Base probability thresholds (can be modified by player attributes)
    int lossThreshold = 8;
    int noGainThreshold = 15;
    int shortGainThreshold = 60;
    int mediumGainThreshold = 85;
    int longGainThreshold = 95;

    // Base yard ranges (can be modified by player attributes)
    int baseShortYards = 5;
    int baseMediumYards = 7;
    int baseLongYards = 13;
    int baseBreakawayYards = 55;

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get skill player rating (quarterback for QB runs, primary skill player for others)
      double skillPlayerRating = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final player = players.primarySkillPlayer as Player;
        skillPlayerRating = player.positionRating1
            .toDouble(); // Position-specific rating (e.g., Rush Power for RB)
      }

      // Get offensive line rating
      double offensiveLineRating = players.offensiveLineRating;

      // Get defensive line rating (opponent strength)
      double defensiveLineRating = players.defensiveLineRating;

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.rushingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // FIXED CALCULATION: Calculate advantage relative to league average (50)
      double offensiveAdvantage =
          (skillPlayerRating + offensiveLineRating) / 2.0; // Average of ratings
      double netAdvantage =
          offensiveAdvantage - defensiveLineRating + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 2.5; // Scale to roughly -20 to +20
      advantageModifier = advantageModifier.clamp(-20.0, 20.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce bad outcomes, increase good outcomes
        lossThreshold = (lossThreshold - (advantageModifier / 2)).round().clamp(
          1,
          15,
        );
        noGainThreshold = (noGainThreshold - advantageModifier).round().clamp(
          5,
          25,
        );
        longGainThreshold = (longGainThreshold - advantageModifier)
            .round()
            .clamp(80, 98);

        // Increase yard potential
        baseShortYards = (baseShortYards + (advantageModifier / 4))
            .round()
            .clamp(3, 8);
        baseMediumYards = (baseMediumYards + (advantageModifier / 3))
            .round()
            .clamp(5, 12);
        baseLongYards = (baseLongYards + (advantageModifier / 2)).round().clamp(
          10,
          20,
        );
        baseBreakawayYards = (baseBreakawayYards + advantageModifier)
            .round()
            .clamp(40, 80);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase bad outcomes, reduce good outcomes
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + (absAdvantage / 2)).round().clamp(
          1,
          25,
        );
        noGainThreshold = (noGainThreshold + absAdvantage).round().clamp(5, 35);
        longGainThreshold = (longGainThreshold + absAdvantage).round().clamp(
          85,
          99,
        );

        // Decrease yard potential
        baseShortYards = (baseShortYards - (absAdvantage / 4)).round().clamp(
          2,
          5,
        );
        baseMediumYards = (baseMediumYards - (absAdvantage / 3)).round().clamp(
          4,
          7,
        );
        baseLongYards = (baseLongYards - (absAdvantage / 2)).round().clamp(
          8,
          13,
        );
        baseBreakawayYards = (baseBreakawayYards - absAdvantage).round().clamp(
          30,
          55,
        );
      }
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss
      return -1 - _random.nextInt(5); // -1 to -5 yards
    } else if (roll < noGainThreshold) {
      // No gain
      return 0;
    } else if (roll < shortGainThreshold) {
      // Short gain
      return 1 + _random.nextInt(baseShortYards); // 1 to baseShortYards
    } else if (roll < mediumGainThreshold) {
      // Medium gain
      return 6 + _random.nextInt(baseMediumYards); // 6 to (6 + baseMediumYards)
    } else if (roll < longGainThreshold) {
      // Long gain
      return 13 + _random.nextInt(baseLongYards); // 13 to (13 + baseLongYards)
    } else {
      // Breakaway run
      return 26 +
          _random.nextInt(
            baseBreakawayYards,
          ); // 26 to (26 + baseBreakawayYards)
    }
  }

  /// Simulates a specific type of running play based on the play call.
  ///
  /// Different run plays have different characteristics:
  /// - Power runs: higher chance of short gains, lower big play potential
  /// - Outside runs: higher variance, more big plays or losses
  /// - QB runs: different dynamics based on mobility
  PlayResult _simulateRunPlayByType(
    GameState gameState,
    OffensiveRunPlay runPlay,
    Team offensiveTeam,
    Team defensiveTeam, [
    PlayCall? playCall,
  ]) {
    int yardsGained;
    Duration timeElapsed;
    bool isTurnover = false;

    switch (runPlay) {
      case OffensiveRunPlay.powerRun:
        yardsGained = _generatePowerRunYards(gameState, playCall);
        timeElapsed = Duration(seconds: 25 + _random.nextInt(16)); // 25-40s
        isTurnover = _shouldFumble();
        break;

      case OffensiveRunPlay.insideRun:
        yardsGained = _generateInsideRunYards(gameState, playCall);
        timeElapsed = Duration(seconds: 25 + _random.nextInt(21)); // 25-45s
        isTurnover = _shouldFumble();
        break;

      case OffensiveRunPlay.outsideRun:
        yardsGained = _generateOutsideRunYards(gameState, playCall);
        timeElapsed = Duration(seconds: 20 + _random.nextInt(26)); // 20-45s
        isTurnover = _shouldFumble();
        break;

      case OffensiveRunPlay.jetSweep:
        yardsGained = _generateJetSweepYards(gameState);
        timeElapsed = Duration(seconds: 15 + _random.nextInt(21)); // 15-35s
        isTurnover = _shouldFumble();
        break;

      case OffensiveRunPlay.readOption:
        yardsGained = _generateReadOptionYards(gameState);
        timeElapsed = Duration(seconds: 20 + _random.nextInt(21)); // 20-40s
        isTurnover = _shouldReadOptionTurnover(); // Different turnover rate
        break;

      case OffensiveRunPlay.qbRun:
        yardsGained = _generateQBRunYards(gameState);
        timeElapsed = Duration(seconds: 15 + _random.nextInt(31)); // 15-45s
        isTurnover = _shouldQBTurnover(); // QBs protect ball better
        break;
    }

    final distanceToGoal = 100 - gameState.yardLine;
    final isScore = yardsGained >= distanceToGoal;
    final isFirstDown = !isScore && yardsGained >= gameState.yardsToGo;
    final stopClock = isScore || isTurnover;

    // Select players based on run play type
    String? primaryPlayer;
    String? defender;
    List<String> involvedPlayers;

    switch (runPlay) {
      case OffensiveRunPlay.qbRun:
      case OffensiveRunPlay.readOption:
        primaryPlayer = _selectQuarterback(offensiveTeam);
        defender = _selectDefender(defensiveTeam, preferredPosition: 'LB');
        involvedPlayers = _selectInvolvedPlayers(offensiveTeam, defensiveTeam);
        break;
      default:
        primaryPlayer = _selectRunningBack(offensiveTeam);
        defender = _selectDefender(defensiveTeam, preferredPosition: 'LB');
        involvedPlayers = _selectInvolvedPlayers(offensiveTeam, defensiveTeam);
        break;
    }

    return PlayResult(
      playType: PlayType.rush,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed,
      isTurnover: isTurnover,
      isScore: isScore,
      isFirstDown: isFirstDown,
      stopClock: stopClock,
      primaryPlayer: primaryPlayer,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }

  /// Simulates a specific type of passing play based on the play call.
  ///
  /// Different pass plays have different characteristics:
  /// - Deep passes: high risk/reward, more variance
  /// - Short passes: reliable, consistent gains
  /// - Screens: potential for big gains with good blocking
  /// Now uses player and staff attributes to calculate realistic outcomes.
  PlayResult _simulatePassPlayByType(
    GameState gameState,
    OffensivePassPlay passPlay,
    Team offensiveTeam,
    Team defensiveTeam,
    PlayCall? playCall,
  ) {
    int yardsGained;
    Duration timeElapsed;
    bool isTurnover = false;
    bool stopClock = false;

    switch (passPlay) {
      case OffensivePassPlay.hailMary:
        yardsGained = _generateHailMaryYards(gameState);
        timeElapsed = Duration(seconds: 8 + _random.nextInt(8)); // 8-15s
        isTurnover = _shouldHailMaryTurnover();
        stopClock = true; // Always stops clock
        break;

      case OffensivePassPlay.deepPass:
        yardsGained = _generateDeepPassYards(gameState);
        timeElapsed = Duration(seconds: 6 + _random.nextInt(10)); // 6-15s
        isTurnover = _shouldDeepPassTurnover();
        stopClock = _shouldPassStopClock();
        break;

      case OffensivePassPlay.mediumPass:
        yardsGained = _generateMediumPassYards(gameState);
        timeElapsed = Duration(seconds: 5 + _random.nextInt(8)); // 5-12s
        isTurnover = _shouldMediumPassTurnover();
        stopClock = _shouldPassStopClock();
        break;

      case OffensivePassPlay.shortPass:
        yardsGained = _generateShortPassYards(gameState, playCall);
        timeElapsed = Duration(seconds: 4 + _random.nextInt(8)); // 4-11s
        isTurnover = _shouldShortPassTurnover();
        stopClock = _shouldPassStopClock();
        break;

      case OffensivePassPlay.wrScreen:
        yardsGained = _generateWRScreenYards(gameState);
        timeElapsed = Duration(seconds: 6 + _random.nextInt(15)); // 6-20s
        isTurnover = _shouldScreenTurnover();
        stopClock = _shouldPassStopClock();
        break;

      case OffensivePassPlay.rbScreen:
        yardsGained = _generateRBScreenYards(gameState);
        timeElapsed = Duration(seconds: 8 + _random.nextInt(17)); // 8-24s
        isTurnover = _shouldScreenTurnover();
        stopClock = _shouldPassStopClock();
        break;
    }

    final distanceToGoal = 100 - gameState.yardLine;
    final isScore = yardsGained >= distanceToGoal;
    final isFirstDown = !isScore && yardsGained >= gameState.yardsToGo;

    // Select players based on pass play type
    String? primaryPlayer;
    String? targetPlayer;
    String? defender;
    List<String> involvedPlayers;

    switch (passPlay) {
      case OffensivePassPlay.hailMary:
      case OffensivePassPlay.deepPass:
      case OffensivePassPlay.mediumPass:
      case OffensivePassPlay.shortPass:
        primaryPlayer = _selectQuarterback(offensiveTeam);
        targetPlayer = _selectReceiver(offensiveTeam);
        defender = _selectDefender(defensiveTeam, preferredPosition: 'CB');
        involvedPlayers = _selectInvolvedPlayers(offensiveTeam, defensiveTeam);
        break;
      case OffensivePassPlay.wrScreen:
        primaryPlayer = _selectQuarterback(offensiveTeam);
        targetPlayer = _selectReceiver(offensiveTeam);
        defender = _selectDefender(defensiveTeam, preferredPosition: 'LB');
        involvedPlayers = _selectInvolvedPlayers(offensiveTeam, defensiveTeam);
        break;
      case OffensivePassPlay.rbScreen:
        primaryPlayer = _selectQuarterback(offensiveTeam);
        targetPlayer = _selectRunningBack(offensiveTeam);
        defender = _selectDefender(defensiveTeam, preferredPosition: 'LB');
        involvedPlayers = _selectInvolvedPlayers(offensiveTeam, defensiveTeam);
        break;
    }

    return PlayResult(
      playType: PlayType.pass,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed,
      isTurnover: isTurnover,
      isScore: isScore,
      isFirstDown: isFirstDown,
      stopClock: stopClock || isScore || isTurnover,
      primaryPlayer: primaryPlayer,
      targetPlayer: targetPlayer,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }

  /// Simulates special teams plays (field goals and punts).
  PlayResult _simulateSpecialTeamsPlay(
    GameState gameState,
    SpecialTeamsPlay specialPlay,
    Team offensiveTeam,
    Team defensiveTeam,
  ) {
    switch (specialPlay) {
      case SpecialTeamsPlay.kickFG:
        return _simulateFieldGoal(gameState, offensiveTeam, defensiveTeam);
      case SpecialTeamsPlay.punt:
        return _simulatePunt(gameState, offensiveTeam, defensiveTeam);
    }
  }

  /// Determines if a fumble occurs on the play.
  ///
  /// Fumbles are rare events that should happen occasionally
  /// but not frequently enough to be unrealistic.
  /// NFL average: ~1 fumble per 40-50 rushes
  bool _shouldFumble() {
    // Approximately 2% chance of fumble (1 in 50)
    return _random.nextInt(50) == 0;
  }

  /// Different turnover rates for different play types
  bool _shouldReadOptionTurnover() {
    // Read option has slightly higher turnover rate due to ball handling
    return _random.nextInt(40) == 0; // ~2.5%
  }

  bool _shouldQBTurnover() {
    // QBs generally protect the ball better
    return _random.nextInt(60) == 0; // ~1.7%
  }

  bool _shouldHailMaryTurnover() {
    // Hail Mary has high interception risk
    return _random.nextInt(4) == 0; // 25%
  }

  bool _shouldDeepPassTurnover() {
    // Deep passes have higher INT risk
    return _random.nextInt(20) == 0; // 5%
  }

  bool _shouldMediumPassTurnover() {
    // Medium passes moderate INT risk
    return _random.nextInt(33) == 0; // ~3%
  }

  bool _shouldShortPassTurnover() {
    // Short passes low INT risk
    return _random.nextInt(50) == 0; // 2%
  }

  bool _shouldScreenTurnover() {
    // Screens can have fumbles but low INT risk
    return _random.nextInt(60) == 0; // ~1.7%
  }

  bool _shouldPassStopClock() {
    // ~40% of passes stop the clock (incomplete, out of bounds, etc.)
    return _random.nextInt(5) < 2;
  }

  // Running play yard generation methods

  /// Power runs emphasize short, consistent gains with low variance using player attributes
  int _generatePowerRunYards(GameState gameState, [PlayCall? playCall]) {
    final distanceToGoal = 100 - gameState.yardLine;

    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYards(playCall);
    }

    // Base probability thresholds for power runs (emphasize consistency)
    int lossThreshold = 5;
    int noGainThreshold = 15;
    int shortGainThreshold = 70; // Power runs focus on short, consistent gains
    int mediumGainThreshold = 90;
    // Power runs have limited big play potential

    // Base yard ranges for power runs
    int baseLossYards = 3;
    int baseNoGainYards = 1;
    int baseShortYards = 4; // 2-5 yards emphasis
    int baseMediumYards = 5; // 6-10 yards
    int baseLongYards = 10; // 11-20 yards

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get skill player rating
      double skillPlayerRating = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final player = players.primarySkillPlayer as Player;
        skillPlayerRating = player.positionRating1
            .toDouble(); // Position-specific rating (e.g., Rush Power for RB)
      }

      // Get offensive line rating (very important for power runs)
      double offensiveLineRating = players.offensiveLineRating;

      // Get defensive line rating (opponent strength)
      double defensiveLineRating = players.defensiveLineRating;

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.rushingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4, higher for power runs
      }

      // FIXED CALCULATION: Calculate advantage relative to league average (50)
      // Weight offensive line more heavily for power runs
      double offensiveAdvantage =
          (skillPlayerRating + (offensiveLineRating * 1.3)) /
          2.3; // Weighted average
      double netAdvantage =
          offensiveAdvantage - defensiveLineRating + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 2.8; // Scale to roughly -18 to +18
      advantageModifier = advantageModifier.clamp(-18.0, 18.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce bad outcomes, increase consistency
        lossThreshold = (lossThreshold - (advantageModifier / 3)).round().clamp(
          1,
          12,
        );
        noGainThreshold = (noGainThreshold - (advantageModifier / 2))
            .round()
            .clamp(5, 25);
        shortGainThreshold = (shortGainThreshold + (advantageModifier / 4))
            .round()
            .clamp(70, 85);

        // Increase yard potential (but keep power run characteristics)
        baseShortYards = (baseShortYards + (advantageModifier / 4))
            .round()
            .clamp(4, 7);
        baseMediumYards = (baseMediumYards + (advantageModifier / 3))
            .round()
            .clamp(5, 8);
        baseLongYards = (baseLongYards + (advantageModifier / 2)).round().clamp(
          10,
          15,
        );
      } else if (advantageModifier < 0) {
        // Negative advantage: increase bad outcomes, reduce consistency
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + (absAdvantage / 3)).round().clamp(
          1,
          20,
        );
        noGainThreshold = (noGainThreshold + (absAdvantage / 2)).round().clamp(
          5,
          30,
        );
        shortGainThreshold = (shortGainThreshold - (absAdvantage / 4))
            .round()
            .clamp(55, 70);

        // Decrease yard potential
        baseLossYards = (baseLossYards + (absAdvantage / 4)).round().clamp(
          3,
          6,
        );
        baseShortYards = (baseShortYards - (absAdvantage / 4)).round().clamp(
          2,
          4,
        );
        baseMediumYards = (baseMediumYards - (absAdvantage / 3)).round().clamp(
          3,
          5,
        );
        baseLongYards = (baseLongYards - (absAdvantage / 2)).round().clamp(
          6,
          10,
        );
      }
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss
      return -1 - _random.nextInt(baseLossYards); // -1 to -baseLossYards
    } else if (roll < noGainThreshold) {
      // No gain or minimal gain
      return _random.nextInt(baseNoGainYards + 1); // 0 to baseNoGainYards
    } else if (roll < shortGainThreshold) {
      // Short gain (power run emphasis)
      return 2 + _random.nextInt(baseShortYards); // 2 to (2 + baseShortYards)
    } else if (roll < mediumGainThreshold) {
      // Medium gain
      return 6 + _random.nextInt(baseMediumYards); // 6 to (6 + baseMediumYards)
    } else {
      // Longer gain (limited for power runs)
      return 11 + _random.nextInt(baseLongYards); // 11 to (11 + baseLongYards)
    }
  }

  /// Inside runs attack the middle, moderate variance using player attributes
  int _generateInsideRunYards(GameState gameState, [PlayCall? playCall]) {
    final distanceToGoal = 100 - gameState.yardLine;

    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYards(playCall);
    }

    // Base probability thresholds for inside runs (balanced between power and outside)
    int lossThreshold = 6;
    int noGainThreshold = 12;
    int shortGainThreshold = 65;
    int mediumGainThreshold = 87;
    int longGainThreshold = 96;

    // Base yard ranges for inside runs
    int baseLossYards = 3;
    int baseNoGainYards = 1;
    int baseShortYards = 5; // 2-6 yards
    int baseMediumYards = 6; // 7-12 yards
    int baseLongYards = 12; // 13-24 yards
    int baseBreakawayYards = 45; // 25-69 yards

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get skill player rating
      double skillPlayerRating = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final player = players.primarySkillPlayer as Player;
        skillPlayerRating = player.positionRating1
            .toDouble(); // Position-specific rating (e.g., Rush Power for RB)
      }

      // Get offensive line rating (important for inside runs)
      double offensiveLineRating = players.offensiveLineRating;

      // Get defensive line rating (opponent strength)
      double defensiveLineRating = players.defensiveLineRating;

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.rushingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // FIXED CALCULATION: Calculate advantage relative to league average (50)
      double offensiveAdvantage =
          (skillPlayerRating + offensiveLineRating) /
          2.0; // Equal weight for inside runs
      double netAdvantage =
          offensiveAdvantage - defensiveLineRating + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 2.5; // Scale to roughly -20 to +20
      advantageModifier = advantageModifier.clamp(-20.0, 20.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce bad outcomes, increase good outcomes
        lossThreshold = (lossThreshold - (advantageModifier / 3)).round().clamp(
          1,
          12,
        );
        noGainThreshold = (noGainThreshold - (advantageModifier / 2))
            .round()
            .clamp(5, 20);
        longGainThreshold = (longGainThreshold - (advantageModifier / 2))
            .round()
            .clamp(85, 98);

        // Increase yard potential
        baseShortYards = (baseShortYards + (advantageModifier / 4))
            .round()
            .clamp(5, 8);
        baseMediumYards = (baseMediumYards + (advantageModifier / 3))
            .round()
            .clamp(6, 10);
        baseLongYards = (baseLongYards + (advantageModifier / 2)).round().clamp(
          12,
          18,
        );
        baseBreakawayYards = (baseBreakawayYards + (advantageModifier / 1.5))
            .round()
            .clamp(45, 65);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase bad outcomes, reduce good outcomes
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + (absAdvantage / 3)).round().clamp(
          1,
          18,
        );
        noGainThreshold = (noGainThreshold + (absAdvantage / 2)).round().clamp(
          5,
          25,
        );
        longGainThreshold = (longGainThreshold + (absAdvantage / 2))
            .round()
            .clamp(90, 99);

        // Decrease yard potential
        baseLossYards = (baseLossYards + (absAdvantage / 4)).round().clamp(
          3,
          6,
        );
        baseShortYards = (baseShortYards - (absAdvantage / 4)).round().clamp(
          3,
          5,
        );
        baseMediumYards = (baseMediumYards - (absAdvantage / 3)).round().clamp(
          4,
          6,
        );
        baseLongYards = (baseLongYards - (absAdvantage / 2)).round().clamp(
          8,
          12,
        );
        baseBreakawayYards = (baseBreakawayYards - (absAdvantage / 1.5))
            .round()
            .clamp(30, 45);
      }
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss
      return -1 - _random.nextInt(baseLossYards); // -1 to -baseLossYards
    } else if (roll < noGainThreshold) {
      // No gain or minimal gain
      return _random.nextInt(baseNoGainYards + 1); // 0 to baseNoGainYards
    } else if (roll < shortGainThreshold) {
      // Short gain
      return 2 + _random.nextInt(baseShortYards); // 2 to (2 + baseShortYards)
    } else if (roll < mediumGainThreshold) {
      // Medium gain
      return 7 + _random.nextInt(baseMediumYards); // 7 to (7 + baseMediumYards)
    } else if (roll < longGainThreshold) {
      // Long gain
      return 13 + _random.nextInt(baseLongYards); // 13 to (13 + baseLongYards)
    } else {
      // Breakaway run
      return 25 +
          _random.nextInt(
            baseBreakawayYards,
          ); // 25 to (25 + baseBreakawayYards)
    }
  }

  /// Outside runs have higher variance - big plays or losses using player attributes
  int _generateOutsideRunYards(GameState gameState, [PlayCall? playCall]) {
    final distanceToGoal = 100 - gameState.yardLine;

    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYards(playCall);
    }

    // Base probability thresholds for outside runs (higher variance)
    int lossThreshold = 15; // Higher loss chance than inside runs
    int noGainThreshold = 25;
    int shortGainThreshold = 50;
    int mediumGainThreshold = 75;
    int longGainThreshold = 90;

    // Base yard ranges for outside runs (emphasize variance)
    int baseLossYards = 4; // -2 to -6 yards
    int baseNoGainYards = 1; // 0-1 yards
    int baseShortYards = 5; // 2-7 yards
    int baseMediumYards = 7; // 8-15 yards
    int baseLongYards = 14; // 16-30 yards
    int baseBreakawayYards = 49; // 31-80 yards

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get skill player rating (speed more important for outside runs)
      double skillPlayerRating = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final player = players.primarySkillPlayer as Player;
        skillPlayerRating = player.positionRating1
            .toDouble(); // Position-specific rating (e.g., Rush Power for RB)
      }

      // Get offensive line rating (less important for outside runs than power runs)
      double offensiveLineRating = players.offensiveLineRating;

      // Get defensive line rating (opponent edge rush strength)
      double defensiveLineRating = players.defensiveLineRating;

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.rushingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // FIXED CALCULATION: Calculate advantage relative to league average (50)
      // Weight skill player more heavily for outside runs (speed/agility)
      double offensiveAdvantage =
          ((skillPlayerRating * 1.2) + offensiveLineRating) /
          2.2; // Weighted average
      double netAdvantage =
          offensiveAdvantage - defensiveLineRating + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) /
          2.3; // Scale to roughly -22 to +22 for higher variance
      advantageModifier = advantageModifier.clamp(-22.0, 22.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce losses, increase big plays
        lossThreshold = (lossThreshold - (advantageModifier / 2)).round().clamp(
          5,
          25,
        );
        noGainThreshold = (noGainThreshold - (advantageModifier / 3))
            .round()
            .clamp(10, 35);
        longGainThreshold = (longGainThreshold - (advantageModifier / 2))
            .round()
            .clamp(75, 95);

        // Increase yard potential (especially big plays)
        baseShortYards = (baseShortYards + (advantageModifier / 5))
            .round()
            .clamp(5, 8);
        baseMediumYards = (baseMediumYards + (advantageModifier / 4))
            .round()
            .clamp(7, 12);
        baseLongYards = (baseLongYards + (advantageModifier / 3)).round().clamp(
          14,
          20,
        );
        baseBreakawayYards = (baseBreakawayYards + (advantageModifier / 2))
            .round()
            .clamp(49, 75);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase losses, reduce big plays
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + (absAdvantage / 2)).round().clamp(
          5,
          35,
        );
        noGainThreshold = (noGainThreshold + (absAdvantage / 3)).round().clamp(
          10,
          40,
        );
        longGainThreshold = (longGainThreshold + (absAdvantage / 2))
            .round()
            .clamp(85, 98);

        // Decrease yard potential
        baseLossYards = (baseLossYards + (absAdvantage / 5)).round().clamp(
          4,
          8,
        );
        baseShortYards = (baseShortYards - (absAdvantage / 5)).round().clamp(
          3,
          5,
        );
        baseMediumYards = (baseMediumYards - (absAdvantage / 4)).round().clamp(
          5,
          7,
        );
        baseLongYards = (baseLongYards - (absAdvantage / 3)).round().clamp(
          10,
          14,
        );
        baseBreakawayYards = (baseBreakawayYards - (absAdvantage / 2))
            .round()
            .clamp(30, 49);
      }
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss (higher chance for outside runs)
      return -2 -
          _random.nextInt(baseLossYards); // -2 to -(2 + baseLossYards) yards
    } else if (roll < noGainThreshold) {
      // No gain or minimal gain
      return _random.nextInt(baseNoGainYards + 1); // 0 to baseNoGainYards
    } else if (roll < shortGainThreshold) {
      // Short gain
      return 2 + _random.nextInt(baseShortYards); // 2 to (2 + baseShortYards)
    } else if (roll < mediumGainThreshold) {
      // Medium gain
      return 8 + _random.nextInt(baseMediumYards); // 8 to (8 + baseMediumYards)
    } else if (roll < longGainThreshold) {
      // Long gain
      return 16 + _random.nextInt(baseLongYards); // 16 to (16 + baseLongYards)
    } else {
      // Breakaway run (outside runs have best big play potential)
      return 31 +
          _random.nextInt(
            baseBreakawayYards,
          ); // 31 to (31 + baseBreakawayYards)
    }
  }

  /// Jet sweeps are designed for speed and misdirection
  int _generateJetSweepYards(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 10) {
      return -3 - _random.nextInt(5); // Loss if caught behind LOS
    } else if (roll < 20) {
      return _random.nextInt(3); // 0-2 yards
    } else if (roll < 45) {
      return 3 + _random.nextInt(8); // 3-10 yards
    } else if (roll < 70) {
      return 11 + _random.nextInt(10); // 11-20 yards
    } else if (roll < 85) {
      return 21 + _random.nextInt(15); // 21-35 yards
    } else {
      return 36 + _random.nextInt(45); // 36-80 yards (big play potential)
    }
  }

  /// Read option combines RB and QB potential
  int _generateReadOptionYards(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 8) {
      return -1 - _random.nextInt(4); // Loss
    } else if (roll < 18) {
      return _random.nextInt(3); // 0-2 yards
    } else if (roll < 55) {
      return 3 + _random.nextInt(6); // 3-8 yards
    } else if (roll < 80) {
      return 9 + _random.nextInt(8); // 9-16 yards
    } else if (roll < 95) {
      return 17 + _random.nextInt(13); // 17-29 yards
    } else {
      return 30 + _random.nextInt(40); // 30-69 yards
    }
  }

  /// QB runs leverage mobility and surprise
  int _generateQBRunYards(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 5) {
      return -2 - _random.nextInt(6); // Loss (sack)
    } else if (roll < 15) {
      return _random.nextInt(3); // 0-2 yards
    } else if (roll < 50) {
      return 3 + _random.nextInt(7); // 3-9 yards
    } else if (roll < 75) {
      return 10 + _random.nextInt(8); // 10-17 yards
    } else if (roll < 90) {
      return 18 + _random.nextInt(12); // 18-29 yards
    } else {
      return 30 + _random.nextInt(45); // 30-74 yards
    }
  }

  // Passing play yard generation methods

  /// Hail Mary - all or nothing deep shot
  int _generateHailMaryYards(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    final roll = _random.nextInt(100);

    if (roll < 80) {
      return 0; // Incomplete - most common outcome
    } else if (roll < 95) {
      // Caught but not for TD
      return _random.nextInt(distanceToGoal ~/ 2) + (distanceToGoal ~/ 4);
    } else {
      // Miracle catch for TD
      return distanceToGoal;
    }
  }

  /// Deep pass (20+ yards) - now uses player attributes for realistic outcomes
  int _generateDeepPassYards(GameState gameState, [PlayCall? playCall]) {
    // Base probability thresholds for deep passes
    int incompleteThreshold = 50;
    int shortDeepThreshold = 75; // 20-35 yards
    int mediumDeepThreshold = 90; // 36-50 yards
    // Long deep (51-80 yards) is remaining percentage

    // Base yard ranges for deep passes
    int baseShortDeep = 16; // 20-35 yards range
    int baseMediumDeep = 15; // 36-50 yards range
    int baseLongDeep = 30; // 51-80 yards range

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get QB accuracy rating (positionRating2 for QB = Accuracy)
      double qbAccuracy = 50.0; // Default average rating
      if (players.quarterback != null) {
        final qb = players.quarterback as Player;
        qbAccuracy = qb.positionRating2.toDouble(); // Accuracy rating
      }

      // Get WR catching rating (positionRating2 for WR = Catching)
      double wrCatching = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final wr = players.primarySkillPlayer as Player;
        wrCatching = wr.positionRating2.toDouble(); // Catching rating
      }

      // Get CB coverage rating (positionRating1 for CB = Coverage)
      double cbCoverage = 50.0; // Default average rating
      if (players.primaryDefender != null) {
        final cb = players.primaryDefender as Player;
        cbCoverage = cb.positionRating1.toDouble(); // Coverage rating
      }

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.passingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // Calculate offensive advantage (QB + WR vs CB)
      double offensiveAdvantage =
          (qbAccuracy + wrCatching) / 2.0; // Average of QB + WR
      double netAdvantage = offensiveAdvantage - cbCoverage + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 2.0; // Scale to roughly -25 to +25
      advantageModifier = advantageModifier.clamp(-25.0, 25.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce incompletions, increase success
        incompleteThreshold = (incompleteThreshold - advantageModifier)
            .round()
            .clamp(15, 70);
        shortDeepThreshold = (shortDeepThreshold - (advantageModifier / 2))
            .round()
            .clamp(65, 85);
        mediumDeepThreshold = (mediumDeepThreshold - (advantageModifier / 3))
            .round()
            .clamp(85, 95);

        // Increase yard potential
        baseShortDeep = (baseShortDeep + (advantageModifier / 5)).round().clamp(
          16,
          22,
        );
        baseMediumDeep = (baseMediumDeep + (advantageModifier / 4))
            .round()
            .clamp(15, 20);
        baseLongDeep = (baseLongDeep + (advantageModifier / 3)).round().clamp(
          30,
          40,
        );
      } else if (advantageModifier < 0) {
        // Negative advantage: increase incompletions, reduce success
        double absAdvantage = -advantageModifier;
        incompleteThreshold = (incompleteThreshold + absAdvantage)
            .round()
            .clamp(40, 80);
        shortDeepThreshold = (shortDeepThreshold + (absAdvantage / 2))
            .round()
            .clamp(70, 90);
        mediumDeepThreshold = (mediumDeepThreshold + (absAdvantage / 3))
            .round()
            .clamp(88, 98);

        // Decrease yard potential
        baseShortDeep = (baseShortDeep - (absAdvantage / 5)).round().clamp(
          10,
          16,
        );
        baseMediumDeep = (baseMediumDeep - (absAdvantage / 4)).round().clamp(
          10,
          15,
        );
        baseLongDeep = (baseLongDeep - (absAdvantage / 3)).round().clamp(
          20,
          30,
        );
      }
    }

    final roll = _random.nextInt(100);

    if (roll < incompleteThreshold) {
      return 0; // Incomplete
    } else if (roll < shortDeepThreshold) {
      return 20 + _random.nextInt(baseShortDeep); // 20-35 yards (base)
    } else if (roll < mediumDeepThreshold) {
      return 36 + _random.nextInt(baseMediumDeep); // 36-50 yards (base)
    } else {
      return 51 + _random.nextInt(baseLongDeep); // 51-80 yards (base)
    }
  }

  /// Medium pass (10-20 yards) - now uses player attributes for realistic outcomes
  int _generateMediumPassYards(GameState gameState, [PlayCall? playCall]) {
    // Base probability thresholds for medium passes
    int incompleteThreshold = 35;
    int shortMediumThreshold = 70; // 10-15 yards
    int longMediumThreshold = 90; // 16-20 yards
    // Extended medium (21-35 yards with YAC) is remaining percentage

    // Base yard ranges for medium passes
    int baseShortMedium = 6; // 10-15 yards range
    int baseLongMedium = 5; // 16-20 yards range
    int baseExtendedMedium = 15; // 21-35 yards range (YAC)

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get QB accuracy rating (positionRating2 for QB = Accuracy)
      double qbAccuracy = 50.0; // Default average rating
      if (players.quarterback != null) {
        final qb = players.quarterback as Player;
        qbAccuracy = qb.positionRating2.toDouble(); // Accuracy rating
      }

      // Get WR catching rating (positionRating2 for WR = Catching)
      double wrCatching = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final wr = players.primarySkillPlayer as Player;
        wrCatching = wr.positionRating2.toDouble(); // Catching rating
      }

      // Get LB coverage rating (positionRating3 for LB = Coverage) - medium passes often covered by LBs
      double lbCoverage = 50.0; // Default average rating
      if (players.primaryDefender != null) {
        final lb = players.primaryDefender as Player;
        lbCoverage = lb.positionRating3.toDouble(); // Coverage rating for LB
      }

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.passingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // Calculate offensive advantage (QB + WR vs LB coverage)
      double offensiveAdvantage =
          (qbAccuracy + wrCatching) / 2.0; // Average of QB + WR
      double netAdvantage = offensiveAdvantage - lbCoverage + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 2.2; // Scale to roughly -23 to +23
      advantageModifier = advantageModifier.clamp(-23.0, 23.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce incompletions, increase success and YAC
        incompleteThreshold = (incompleteThreshold - advantageModifier)
            .round()
            .clamp(10, 50);
        shortMediumThreshold = (shortMediumThreshold - (advantageModifier / 2))
            .round()
            .clamp(60, 80);
        longMediumThreshold = (longMediumThreshold - (advantageModifier / 3))
            .round()
            .clamp(85, 95);

        // Increase yard potential
        baseShortMedium = (baseShortMedium + (advantageModifier / 6))
            .round()
            .clamp(6, 9);
        baseLongMedium = (baseLongMedium + (advantageModifier / 5))
            .round()
            .clamp(5, 8);
        baseExtendedMedium = (baseExtendedMedium + (advantageModifier / 4))
            .round()
            .clamp(15, 25);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase incompletions, reduce success and YAC
        double absAdvantage = -advantageModifier;
        incompleteThreshold = (incompleteThreshold + absAdvantage)
            .round()
            .clamp(25, 70);
        shortMediumThreshold = (shortMediumThreshold + (absAdvantage / 2))
            .round()
            .clamp(65, 85);
        longMediumThreshold = (longMediumThreshold + (absAdvantage / 3))
            .round()
            .clamp(88, 98);

        // Decrease yard potential
        baseShortMedium = (baseShortMedium - (absAdvantage / 6)).round().clamp(
          3,
          6,
        );
        baseLongMedium = (baseLongMedium - (absAdvantage / 5)).round().clamp(
          3,
          5,
        );
        baseExtendedMedium = (baseExtendedMedium - (absAdvantage / 4))
            .round()
            .clamp(8, 15);
      }
    }

    final roll = _random.nextInt(100);

    if (roll < incompleteThreshold) {
      return 0; // Incomplete
    } else if (roll < shortMediumThreshold) {
      return 10 + _random.nextInt(baseShortMedium); // 10-15 yards (base)
    } else if (roll < longMediumThreshold) {
      return 16 + _random.nextInt(baseLongMedium); // 16-20 yards (base)
    } else {
      return 21 +
          _random.nextInt(baseExtendedMedium); // 21-35 yards (YAC) (base)
    }
  }

  /// Short pass (under 10 yards) - now uses player attributes for realistic outcomes
  int _generateShortPassYards(GameState gameState, [PlayCall? playCall]) {
    // Base probability thresholds for short passes
    int incompleteThreshold = 20;
    int shortThreshold = 60; // 3-7 yards
    int mediumThreshold = 85; // 8-14 yards
    // Extended short (15-34 yards with YAC) is remaining percentage

    // Base yard ranges for short passes
    int baseShortYards = 5; // 3-7 yards range
    int baseMediumYards = 7; // 8-14 yards range
    int baseExtendedYards = 20; // 15-34 yards range (YAC breakaway)

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get QB accuracy rating (positionRating2 for QB = Accuracy)
      double qbAccuracy = 50.0; // Default average rating
      if (players.quarterback != null) {
        final qb = players.quarterback as Player;
        qbAccuracy = qb.positionRating2.toDouble(); // Accuracy rating
      }

      // Get WR catching rating (positionRating2 for WR = Catching)
      double wrCatching = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final wr = players.primarySkillPlayer as Player;
        wrCatching = wr.positionRating2.toDouble(); // Catching rating
      }

      // Get LB coverage rating (positionRating3 for LB = Coverage) - short passes often covered by LBs
      double lbCoverage = 50.0; // Default average rating
      if (players.primaryDefender != null) {
        final lb = players.primaryDefender as Player;
        lbCoverage = lb.positionRating3.toDouble(); // Coverage rating for LB
      }

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.passingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // Calculate offensive advantage (QB + WR vs LB coverage)
      double offensiveAdvantage =
          (qbAccuracy + wrCatching) / 2.0; // Average of QB + WR
      double netAdvantage = offensiveAdvantage - lbCoverage + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 2.5; // Scale to roughly -20 to +20
      advantageModifier = advantageModifier.clamp(-20.0, 20.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce incompletions, increase success and YAC potential
        incompleteThreshold = (incompleteThreshold - advantageModifier)
            .round()
            .clamp(5, 35);
        shortThreshold = (shortThreshold - (advantageModifier / 2))
            .round()
            .clamp(50, 70);
        mediumThreshold = (mediumThreshold - (advantageModifier / 3))
            .round()
            .clamp(80, 90);

        // Increase yard potential (especially YAC for short passes)
        baseShortYards = (baseShortYards + (advantageModifier / 5))
            .round()
            .clamp(5, 8);
        baseMediumYards = (baseMediumYards + (advantageModifier / 4))
            .round()
            .clamp(7, 10);
        baseExtendedYards = (baseExtendedYards + (advantageModifier / 3))
            .round()
            .clamp(20, 30);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase incompletions, reduce success and YAC
        double absAdvantage = -advantageModifier;
        incompleteThreshold = (incompleteThreshold + absAdvantage)
            .round()
            .clamp(10, 50);
        shortThreshold = (shortThreshold + (absAdvantage / 2)).round().clamp(
          55,
          75,
        );
        mediumThreshold = (mediumThreshold + (absAdvantage / 3)).round().clamp(
          82,
          95,
        );

        // Decrease yard potential
        baseShortYards = (baseShortYards - (absAdvantage / 5)).round().clamp(
          3,
          5,
        );
        baseMediumYards = (baseMediumYards - (absAdvantage / 4)).round().clamp(
          4,
          7,
        );
        baseExtendedYards = (baseExtendedYards - (absAdvantage / 3))
            .round()
            .clamp(12, 20);
      }
    }

    final roll = _random.nextInt(100);

    if (roll < incompleteThreshold) {
      return 0; // Incomplete
    } else if (roll < shortThreshold) {
      return 3 + _random.nextInt(baseShortYards); // 3-7 yards (base)
    } else if (roll < mediumThreshold) {
      return 8 + _random.nextInt(baseMediumYards); // 8-14 yards (base)
    } else {
      return 15 +
          _random.nextInt(
            baseExtendedYards,
          ); // 15-34 yards (YAC breakaway) (base)
    }
  }

  /// WR Screen - relies on blocking setup, now uses player attributes for realistic outcomes
  int _generateWRScreenYards(GameState gameState, [PlayCall? playCall]) {
    // Base probability thresholds for WR screens
    int lossThreshold = 15;
    int shortThreshold = 30;
    int mediumThreshold = 60;
    int longThreshold = 80;
    // Big play (25-59 yards) is remaining percentage

    // Base yard ranges for WR screens
    int baseLossYards = 4; // -2 to -6 yards
    int baseShortYards = 4; // 0-3 yards
    int baseMediumYards = 8; // 4-11 yards
    int baseLongYards = 13; // 12-24 yards
    int baseBigPlayYards = 35; // 25-59 yards

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get QB accuracy rating (positionRating2 for QB = Accuracy) - important for screen timing
      double qbAccuracy = 50.0; // Default average rating
      if (players.quarterback != null) {
        final qb = players.quarterback as Player;
        qbAccuracy = qb.positionRating2.toDouble(); // Accuracy rating
      }

      // Get WR catching rating (positionRating2 for WR = Catching) and YAC ability
      double wrCatching = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final wr = players.primarySkillPlayer as Player;
        wrCatching = wr.positionRating2.toDouble(); // Catching rating
      }

      // Get offensive line rating (critical for screen blocking)
      double offensiveLineRating = players.offensiveLineRating;

      // Get LB coverage rating (positionRating3 for LB = Coverage) - screens often covered by LBs
      double lbCoverage = 50.0; // Default average rating
      if (players.primaryDefender != null) {
        final lb = players.primaryDefender as Player;
        lbCoverage = lb.positionRating3.toDouble(); // Coverage rating for LB
      }

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.passingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // Calculate offensive advantage (QB + WR + OL vs LB coverage) - OL very important for screens
      double offensiveAdvantage =
          (qbAccuracy + wrCatching + (offensiveLineRating * 1.2)) / 3.2; // Weighted average
      double netAdvantage = offensiveAdvantage - lbCoverage + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 2.0; // Scale to roughly -25 to +25
      advantageModifier = advantageModifier.clamp(-25.0, 25.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce losses, increase big plays
        lossThreshold = (lossThreshold - (advantageModifier / 2)).round().clamp(5, 25);
        shortThreshold = (shortThreshold - (advantageModifier / 3)).round().clamp(15, 40);
        longThreshold = (longThreshold - (advantageModifier / 3)).round().clamp(70, 90);

        // Increase yard potential (especially big plays for screens)
        baseMediumYards = (baseMediumYards + (advantageModifier / 4)).round().clamp(8, 12);
        baseLongYards = (baseLongYards + (advantageModifier / 3)).round().clamp(13, 18);
        baseBigPlayYards = (baseBigPlayYards + (advantageModifier / 2)).round().clamp(35, 50);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase losses, reduce big plays
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + (absAdvantage / 2)).round().clamp(5, 35);
        shortThreshold = (shortThreshold + (absAdvantage / 3)).round().clamp(20, 50);
        longThreshold = (longThreshold + (absAdvantage / 3)).round().clamp(75, 95);

        // Decrease yard potential
        baseLossYards = (baseLossYards + (absAdvantage / 5)).round().clamp(4, 8);
        baseMediumYards = (baseMediumYards - (absAdvantage / 4)).round().clamp(5, 8);
        baseLongYards = (baseLongYards - (absAdvantage / 3)).round().clamp(8, 13);
        baseBigPlayYards = (baseBigPlayYards - (absAdvantage / 2)).round().clamp(20, 35);
      }
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss if defense reads it
      return -2 - _random.nextInt(baseLossYards); // -2 to -(2 + baseLossYards) yards
    } else if (roll < shortThreshold) {
      // Short gain
      return _random.nextInt(baseShortYards); // 0 to baseShortYards yards
    } else if (roll < mediumThreshold) {
      // Medium gain
      return 4 + _random.nextInt(baseMediumYards); // 4 to (4 + baseMediumYards) yards
    } else if (roll < longThreshold) {
      // Long gain
      return 12 + _random.nextInt(baseLongYards); // 12 to (12 + baseLongYards) yards
    } else {
      // Big play
      return 25 + _random.nextInt(baseBigPlayYards); // 25 to (25 + baseBigPlayYards) yards
    }
  }

  /// RB Screen - similar to WR but different timing, now uses player attributes for realistic outcomes
  int _generateRBScreenYards(GameState gameState, [PlayCall? playCall]) {
    // Base probability thresholds for RB screens (slightly different from WR screens)
    int lossThreshold = 10;
    int shortThreshold = 25;
    int mediumThreshold = 65;
    int longThreshold = 85;
    // Big play (25-54 yards) is remaining percentage

    // Base yard ranges for RB screens
    int baseLossYards = 3; // -1 to -4 yards
    int baseShortYards = 5; // 0-4 yards
    int baseMediumYards = 8; // 5-12 yards
    int baseLongYards = 12; // 13-24 yards
    int baseBigPlayYards = 30; // 25-54 yards

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get QB accuracy rating (positionRating2 for QB = Accuracy) - important for screen timing
      double qbAccuracy = 50.0; // Default average rating
      if (players.quarterback != null) {
        final qb = players.quarterback as Player;
        qbAccuracy = qb.positionRating2.toDouble(); // Accuracy rating
      }

      // Get RB catching rating (positionRating3 for RB = Catching) and YAC ability
      double rbCatching = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final rb = players.primarySkillPlayer as Player;
        rbCatching = rb.positionRating3.toDouble(); // Catching rating for RB
      }

      // Get offensive line rating (critical for screen blocking)
      double offensiveLineRating = players.offensiveLineRating;

      // Get LB coverage rating (positionRating3 for LB = Coverage) - screens often covered by LBs
      double lbCoverage = 50.0; // Default average rating
      if (players.primaryDefender != null) {
        final lb = players.primaryDefender as Player;
        lbCoverage = lb.positionRating3.toDouble(); // Coverage rating for LB
      }

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach =
            playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.passingOffense / 25.0).clamp(
          0.0,
          4.0,
        ); // Scale 0-100 to 0-4
      }

      // Calculate offensive advantage (QB + RB + OL vs LB coverage) - OL very important for screens
      double offensiveAdvantage =
          (qbAccuracy + rbCatching + (offensiveLineRating * 1.3)) / 3.3; // Weighted average
      double netAdvantage = offensiveAdvantage - lbCoverage + coachingBonus;

      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier =
          (netAdvantage - 50.0) / 2.1; // Scale to roughly -24 to +24
      advantageModifier = advantageModifier.clamp(-24.0, 24.0);

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce losses, increase big plays
        lossThreshold = (lossThreshold - (advantageModifier / 2)).round().clamp(3, 18);
        shortThreshold = (shortThreshold - (advantageModifier / 3)).round().clamp(12, 35);
        longThreshold = (longThreshold - (advantageModifier / 3)).round().clamp(75, 95);

        // Increase yard potential (especially big plays for screens)
        baseMediumYards = (baseMediumYards + (advantageModifier / 5)).round().clamp(8, 12);
        baseLongYards = (baseLongYards + (advantageModifier / 4)).round().clamp(12, 17);
        baseBigPlayYards = (baseBigPlayYards + (advantageModifier / 3)).round().clamp(30, 45);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase losses, reduce big plays
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + (absAdvantage / 2)).round().clamp(3, 25);
        shortThreshold = (shortThreshold + (absAdvantage / 3)).round().clamp(15, 45);
        longThreshold = (longThreshold + (absAdvantage / 3)).round().clamp(80, 98);

        // Decrease yard potential
        baseLossYards = (baseLossYards + (absAdvantage / 6)).round().clamp(3, 6);
        baseMediumYards = (baseMediumYards - (absAdvantage / 5)).round().clamp(5, 8);
        baseLongYards = (baseLongYards - (absAdvantage / 4)).round().clamp(8, 12);
        baseBigPlayYards = (baseBigPlayYards - (absAdvantage / 3)).round().clamp(18, 30);
      }
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss
      return -1 - _random.nextInt(baseLossYards); // -1 to -(1 + baseLossYards) yards
    } else if (roll < shortThreshold) {
      // Short gain
      return _random.nextInt(baseShortYards); // 0 to baseShortYards yards
    } else if (roll < mediumThreshold) {
      // Medium gain
      return 5 + _random.nextInt(baseMediumYards); // 5 to (5 + baseMediumYards) yards
    } else if (roll < longThreshold) {
      // Long gain
      return 13 + _random.nextInt(baseLongYards); // 13 to (13 + baseLongYards) yards
    } else {
      // Big play
      return 25 + _random.nextInt(baseBigPlayYards); // 25 to (25 + baseBigPlayYards) yards
    }
  }

  /// Field goal simulation - now uses kicker attributes for realistic outcomes
  PlayResult _simulateFieldGoal(
    GameState gameState,
    Team offensiveTeam,
    Team defensiveTeam, [
    PlayCall? playCall,
  ]) {
    final distanceToGoal = 100 - gameState.yardLine;
    final kickDistance =
        distanceToGoal + 17; // Add 10 for end zone + 7 for snap

    // Base success rates by distance (can be modified by kicker attributes)
    int baseSuccessRate;
    if (kickDistance <= 30) {
      baseSuccessRate = 95; // 95% base success for short kicks
    } else if (kickDistance <= 40) {
      baseSuccessRate = 85; // 85% base success
    } else if (kickDistance <= 50) {
      baseSuccessRate = 70; // 70% base success
    } else if (kickDistance <= 60) {
      baseSuccessRate = 40; // 40% base success
    } else {
      baseSuccessRate = 20; // 20% base success for very long kicks
    }

    // Apply kicker attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get kicker accuracy rating (positionRating1 for K = Accuracy/Power)
      double kickerAccuracy = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final kicker = players.primarySkillPlayer as Player;
        kickerAccuracy = kicker.positionRating1.toDouble(); // Accuracy rating
      }

      // Use offensive coordinator for general coaching bonus (no special teams coordinator available)
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach = playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        // Use a smaller bonus since this isn't specialized special teams coaching
        coachingBonus = (coach.passingOffense / 50.0).clamp(0.0, 2.0); // Scale 0-100 to 0-2
      }

      // Calculate kicker advantage relative to league average (50)
      double kickerAdvantage = kickerAccuracy - 50.0 + coachingBonus;

      // Apply kicker modifier to success rate
      // Scale advantage to reasonable modifier (-20 to +20 percentage points)
      double successModifier = (kickerAdvantage / 2.5).clamp(-20.0, 20.0);
      
      // Apply distance penalty scaling - longer kicks are more affected by kicker skill
      double distanceScaling = 1.0;
      if (kickDistance > 50) {
        distanceScaling = 1.5; // 50% more impact for long kicks
      } else if (kickDistance > 40) {
        distanceScaling = 1.2; // 20% more impact for medium-long kicks
      }
      
      successModifier *= distanceScaling;
      
      // Apply modifier to base success rate
      int finalSuccessRate = (baseSuccessRate + successModifier).round().clamp(5, 99);
      baseSuccessRate = finalSuccessRate;
    }

    // Determine if field goal is successful
    bool isGood = _random.nextInt(100) < baseSuccessRate;

    // Small chance of blocked field goal (base rate without specialized coaching)
    double blockChance = 2.0; // Base 2% chance
    bool isBlocked = _random.nextInt(1000) < (blockChance * 10).round();
    if (isBlocked) {
      isGood = false;
    }

    // Select players for field goal attempt
    final kicker = _selectKicker(offensiveTeam);
    final defender = _selectDefender(
      defensiveTeam,
      preferredPosition: 'DT',
    ); // DTs often try to block kicks
    final involvedPlayers = _selectSpecialTeamsPlayers(
      offensiveTeam,
      defensiveTeam,
    );

    return PlayResult(
      playType: PlayType.fieldGoal,
      yardsGained: 0,
      timeElapsed: Duration(seconds: 5),
      isTurnover: false,
      isScore: isGood,
      isFirstDown: false,
      stopClock: true,
      primaryPlayer: kicker,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }

  /// Punt simulation - now uses punter attributes for realistic outcomes
  PlayResult _simulatePunt(
    GameState gameState,
    Team offensiveTeam,
    Team defensiveTeam, [
    PlayCall? playCall,
  ]) {
    final distanceToGoal = 100 - gameState.yardLine;

    // Base punt distance ranges by field position (can be modified by punter attributes)
    int basePuntYards;
    int puntVariance;
    
    if (distanceToGoal > 60) {
      basePuntYards = 50; // Base 50-yard punt
      puntVariance = 21; // ±10 yards (40-60 yards)
    } else if (distanceToGoal > 40) {
      basePuntYards = 42; // Base 42-yard punt
      puntVariance = 16; // ±8 yards (35-50 yards)
    } else {
      basePuntYards = 32; // Base 32-yard punt (shorter field)
      puntVariance = 16; // ±8 yards (25-40 yards)
    }

    // Apply punter attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;

      // Get punter power/accuracy rating (positionRating1 for P = Power/Distance)
      double punterPower = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final punter = players.primarySkillPlayer as Player;
        punterPower = punter.positionRating1.toDouble(); // Power/Distance rating
      }

      // Use offensive coordinator for general coaching bonus (no special teams coordinator available)
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach = playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        // Use a smaller bonus since this isn't specialized special teams coaching
        coachingBonus = (coach.passingOffense / 50.0).clamp(0.0, 2.0); // Scale 0-100 to 0-2
      }

      // Calculate punter advantage relative to league average (50)
      double punterAdvantage = punterPower - 50.0 + coachingBonus;

      // Apply punter modifier to punt distance
      // Scale advantage to reasonable modifier (-10 to +10 yards)
      double distanceModifier = (punterAdvantage / 5.0).clamp(-10.0, 10.0);
      
      // Apply modifier to base punt distance
      basePuntYards = (basePuntYards + distanceModifier).round().clamp(20, 70);
      
      // Better punters have more consistent punts (less variance)
      if (punterAdvantage > 0) {
        puntVariance = (puntVariance * 0.8).round(); // Reduce variance by 20%
      } else if (punterAdvantage < 0) {
        puntVariance = (puntVariance * 1.2).round(); // Increase variance by 20%
      }
    }

    // Calculate final punt distance with variance
    int puntYards = basePuntYards - (puntVariance ~/ 2) + _random.nextInt(puntVariance);

    // Ensure punt doesn't go past opponent goal line
    puntYards = puntYards.clamp(0, distanceToGoal);

    // Small chance of blocked punt (base rate without specialized coaching)
    double blockChance = 0.5; // Base 0.5% chance
    final isBlocked = _random.nextInt(200) == 0;

    // Select players for punt
    final punter = _selectPunter(offensiveTeam);
    final defender = _selectDefender(
      defensiveTeam,
      preferredPosition: 'S',
    ); // Safeties often return punts
    final involvedPlayers = _selectSpecialTeamsPlayers(
      offensiveTeam,
      defensiveTeam,
    );

    if (isBlocked) {
      // For blocked punts, select a defensive lineman as the blocker
      final blocker = _selectDefender(defensiveTeam, preferredPosition: 'DE');

      return PlayResult(
        playType: PlayType.punt,
        yardsGained: -5 - _random.nextInt(11), // Loss on blocked punt
        timeElapsed: Duration(seconds: 3),
        isTurnover: true,
        isScore: false,
        isFirstDown: false,
        stopClock: true,
        primaryPlayer: punter,
        defender: blocker,
        involvedPlayers: involvedPlayers,
      );
    }

    return PlayResult(
      playType: PlayType.punt,
      yardsGained: puntYards,
      timeElapsed: Duration(seconds: 12 + _random.nextInt(6)),
      isTurnover: true, // Change of possession
      isScore: false,
      isFirstDown: false,
      stopClock: true,
      primaryPlayer: punter,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }

  /// Applies defensive modifications to the base play result.
  ///
  /// This method implements the strategic interactions between offensive and defensive play calls.
  /// Different defensive strategies will have varying effectiveness against different offensive plays,
  /// creating realistic rock-paper-scissors style gameplay dynamics.
  PlayResult _applyDefensiveModifications(
    PlayResult baseResult,
    PlayCall offensivePlay,
    DefensivePlay defensivePlay,
  ) {
    // Start with base result values
    int modifiedYards = baseResult.yardsGained;
    bool modifiedTurnover = baseResult.isTurnover;
    Duration modifiedTime = baseResult.timeElapsed;

    // Apply defensive modifications based on defensive play vs offensive play matchups
    switch (defensivePlay) {
      case DefensivePlay.balanced:
        modifiedYards = _applyBalancedDefense(modifiedYards, offensivePlay);
        break;

      case DefensivePlay.blitz:
        final blitzResult = _applyBlitzDefense(
          modifiedYards,
          modifiedTurnover,
          offensivePlay,
        );
        modifiedYards = blitzResult.$1;
        modifiedTurnover = blitzResult.$2;
        break;

      case DefensivePlay.defendPass:
        modifiedYards = _applyPassDefense(modifiedYards, offensivePlay);
        modifiedTurnover = _applyPassDefenseTurnover(
          modifiedTurnover,
          offensivePlay,
        );
        break;

      case DefensivePlay.defendRun:
        modifiedYards = _applyRunDefense(modifiedYards, offensivePlay);
        break;

      case DefensivePlay.prevent:
        modifiedYards = _applyPreventDefense(modifiedYards, offensivePlay);
        break;

      case DefensivePlay.stackTheBox:
        modifiedYards = _applyStackTheBoxDefense(modifiedYards, offensivePlay);
        break;
    }

    // Ensure yards don't become unrealistically negative
    modifiedYards = modifiedYards.clamp(-15, modifiedYards);

    // Recalculate dependent fields based on modified yards
    final distanceToGoal =
        100 -
        (baseResult.yardsGained - modifiedYards); // Approximate field position
    final isScore = modifiedYards >= distanceToGoal && modifiedYards > 0;
    final isFirstDown =
        !isScore &&
        !modifiedTurnover &&
        modifiedYards >= 10; // Simplified first down check

    return PlayResult(
      playType: baseResult.playType,
      yardsGained: modifiedYards,
      timeElapsed: modifiedTime,
      isTurnover: modifiedTurnover,
      isScore: isScore,
      isFirstDown: isFirstDown,
      stopClock: baseResult.stopClock || isScore || modifiedTurnover,
    );
  }

  // Phase 3: Referee and Head Coach Attribute Methods

  /// Calculates penalty probability and type based on referee attributes.
  ///
  /// Uses referee tendency attributes to determine if a penalty occurs and what type.
  /// Penalty chances are modified based on play type and situation.
  (bool, String?) _calculatePenalty(
    PlayCall playCall,
    PlayType playType,
    GameState gameState,
  ) {
    // No penalty if no referee provided
    if (playCall.referee == null) {
      return (false, null);
    }

    final referee = playCall.referee as Referee;
    
    // Base penalty chances by play type (percentage)
    double basePenaltyChance;
    List<String> potentialPenalties;

    switch (playType) {
      case PlayType.rush:
        basePenaltyChance = 8.0; // 8% base chance
        potentialPenalties = [
          'Holding',
          'False Start',
          'Illegal Formation',
          'Delay of Game',
          'Unnecessary Roughness',
          'Personal Foul',
        ];
        break;
      case PlayType.pass:
        basePenaltyChance = 12.0; // 12% base chance
        potentialPenalties = [
          'Holding',
          'Pass Interference', 
          'False Start',
          'Illegal Formation',
          'Delay of Game',
          'Roughing the Passer',
          'Unnecessary Roughness',
          'Personal Foul',
        ];
        break;
      case PlayType.fieldGoal:
      case PlayType.punt:
      case PlayType.extraPoint:
      case PlayType.kickoff:
      case PlayType.kneel:
      case PlayType.spike:
        basePenaltyChance = 5.0; // 5% base chance
        potentialPenalties = [
          'Holding',
          'False Start',
          'Delay of Game',
          'Illegal Block in the Back',
          'Clipping',
          'Facemask',
        ];
        break;
    }

    // Apply situational modifiers
    double situationalModifier = 1.0;

    // Red zone increases penalty chance (more intensity)
    final distanceToGoal = 100 - gameState.yardLine;
    if (distanceToGoal <= 20) {
      situationalModifier += 0.3; // 30% increase
    }

    // Short yardage situations increase penalty chance
    if (gameState.yardsToGo <= 3) {
      situationalModifier += 0.2; // 20% increase
    }

    // Apply head coach discipline modifier if available
    if (playCall.coaching?.headCoach != null) {
      final headCoach = playCall.coaching!.headCoach as HeadCoach;
      double disciplineModifier = (headCoach.leadership - 50.0) / 100.0; // Scale -0.5 to +0.5
      situationalModifier += disciplineModifier; // Better leadership = fewer penalties
    }

    // Calculate final penalty chance
    double finalPenaltyChance = basePenaltyChance * situationalModifier;
    
    // Check if penalty occurs
    if (_random.nextInt(100) >= finalPenaltyChance) {
      return (false, null);
    }

    // Select penalty type based on referee tendencies
    String? selectedPenalty = _selectPenaltyType(referee, potentialPenalties);
    
    return (true, selectedPenalty);
  }

  /// Selects specific penalty type based on referee tendencies.
  ///
  /// Uses referee attribute values to weight penalty selection.
  String? _selectPenaltyType(Referee referee, List<String> potentialPenalties) {
    if (potentialPenalties.isEmpty) return null;

    Map<String, double> penaltyWeights = {};

    // Map penalties to referee tendency attributes
    for (String penalty in potentialPenalties) {
      double weight = 50.0; // Default weight

      switch (penalty) {
        case 'Holding':
          weight = (referee.holdingTendency + referee.offensiveHoldingTendency) / 2.0;
          break;
        case 'Pass Interference':
          weight = (referee.passInterferenceTendency + referee.defensivePassInterferenceTendency) / 2.0;
          break;
        case 'Roughing the Passer':
          weight = referee.roughingThePasserTendency.toDouble();
          break;
        case 'False Start':
          weight = referee.falseStartTendency.toDouble();
          break;
        case 'Illegal Formation':
          weight = referee.illegalFormationTendency.toDouble();
          break;
        case 'Delay of Game':
          weight = referee.delayOfGameTendency.toDouble();
          break;
        case 'Unnecessary Roughness':
          weight = referee.unnecessaryRoughnessTendency.toDouble();
          break;
        case 'Personal Foul':
          weight = referee.personalFoulTendency.toDouble();
          break;
        case 'Illegal Block in the Back':
        case 'Clipping':
          weight = referee.clippingTendency.toDouble();
          break;
        case 'Facemask':
          weight = referee.facemaskTendency.toDouble();
          break;
      }

      penaltyWeights[penalty] = weight;
    }

    // Weighted random selection
    double totalWeight = penaltyWeights.values.reduce((a, b) => a + b);
    double randomValue = _random.nextDouble() * totalWeight;
    
    double currentWeight = 0.0;
    for (MapEntry<String, double> entry in penaltyWeights.entries) {
      currentWeight += entry.value;
      if (randomValue <= currentWeight) {
        return entry.key;
      }
    }

    // Fallback to first penalty
    return potentialPenalties.first;
  }

  /// Applies head coach game management decisions.
  ///
  /// Uses head coach attributes to modify play outcomes and timing decisions.
  PlayResult _applyHeadCoachModifications(
    PlayResult baseResult,
    PlayCall playCall,
    GameState gameState,
  ) {
    // No modifications if no head coach provided
    if (playCall.coaching?.headCoach == null) {
      return baseResult;
    }

    final headCoach = playCall.coaching!.headCoach as HeadCoach;
    
    // Calculate head coach impact modifiers
    double gameManagementModifier = (headCoach.gameManagement - 50.0) / 50.0; // Scale -1.0 to +1.0
    double leadershipModifier = (headCoach.leadership - 50.0) / 50.0; // Scale -1.0 to +1.0
    double schemeModifier = (headCoach.schemeKnowledge - 50.0) / 50.0; // Scale -1.0 to +1.0

    // Apply modifications
    int modifiedYards = baseResult.yardsGained;
    Duration modifiedTime = baseResult.timeElapsed;
    bool modifiedTurnover = baseResult.isTurnover;

    // Scheme knowledge affects play execution (slight yard bonus/penalty)
    if (schemeModifier != 0.0) {
      double yardModification = schemeModifier * 0.5; // Max ±0.5 yards average
      int yardAdjustment = (yardModification + (_random.nextDouble() - 0.5)).round();
      modifiedYards += yardAdjustment;
    }

    // Leadership affects turnover rates (better leaders reduce turnovers)
    if (baseResult.isTurnover && leadershipModifier > 0.0) {
      double turnoverReduction = leadershipModifier * 0.15; // Max 15% reduction
      if (_random.nextDouble() < turnoverReduction) {
        modifiedTurnover = false; // Leadership prevents turnover
      }
    }

    // Game management affects time elapsed (better management = more efficient)
    if (gameManagementModifier != 0.0) {
      double timeModification = -gameManagementModifier * 2.0; // Better management = less time
      int timeAdjustment = timeModification.round();
      int newTimeSeconds = (modifiedTime.inSeconds + timeAdjustment).clamp(3, 60);
      modifiedTime = Duration(seconds: newTimeSeconds);
    }

    // Recalculate dependent fields
    final distanceToGoal = 100 - gameState.yardLine;
    final isScore = modifiedYards >= distanceToGoal && modifiedYards > 0;
    final isFirstDown = !isScore && !modifiedTurnover && modifiedYards >= gameState.yardsToGo;

    return PlayResult(
      playType: baseResult.playType,
      yardsGained: modifiedYards,
      timeElapsed: modifiedTime,
      isTurnover: modifiedTurnover,
      isScore: isScore,
      isFirstDown: isFirstDown,
      stopClock: baseResult.stopClock || isScore || modifiedTurnover,
      primaryPlayer: baseResult.primaryPlayer,
      targetPlayer: baseResult.targetPlayer,
      defender: baseResult.defender,
      involvedPlayers: baseResult.involvedPlayers,
    );
  }

  /// Balanced defense provides neutral modifications against all play types
  int _applyBalancedDefense(int baseYards, PlayCall offensivePlay) {
    // Balanced defense doesn't heavily favor stopping any particular play type
    // Apply small random variance (-1 to +1 yards)
    final adjustment = _random.nextInt(3) - 1; // -1, 0, or 1
    return baseYards + adjustment;
  }

  /// Blitz defense increases pressure but leaves coverage vulnerable
  (int, bool) _applyBlitzDefense(
    int baseYards,
    bool baseTurnover,
    PlayCall offensivePlay,
  ) {
    if (offensivePlay.isPass) {
      // Blitz is effective against pass plays - higher chance of sacks/pressure
      final blitzSuccess =
          _random.nextInt(100) < 30; // 30% chance of significant pressure

      if (blitzSuccess) {
        // Successful blitz - significant negative yardage and turnover chance
        final sackYards = -3 - _random.nextInt(8); // -3 to -10 yards
        final forcedTurnover = _random.nextInt(100) < 15; // 15% forced turnover
        return (sackYards, baseTurnover || forcedTurnover);
      } else {
        // Blitz picked up - offense gets more yards due to open receivers
        final extraYards = 2 + _random.nextInt(6); // +2 to +7 yards
        return (baseYards + extraYards, baseTurnover);
      }
    } else if (offensivePlay.isRun) {
      // Blitz less effective against run plays - fewer defenders in box
      final runDefense =
          _random.nextInt(100) < 40; // 40% chance blitz still helps

      if (runDefense) {
        // Some blitzers can still stop the run
        final reduction = 1 + _random.nextInt(3); // -1 to -3 yards
        return (baseYards - reduction, baseTurnover);
      } else {
        // Run finds gap left by blitzing defenders
        final extraYards = 1 + _random.nextInt(4); // +1 to +4 yards
        return (baseYards + extraYards, baseTurnover);
      }
    }

    // Special teams not affected by defensive blitz
    return (baseYards, baseTurnover);
  }

  /// Pass defense specifically targets passing plays
  int _applyPassDefense(int baseYards, PlayCall offensivePlay) {
    if (offensivePlay.isPass) {
      // Very effective against pass plays
      final passDefenseSuccess =
          _random.nextInt(100) < 60; // 60% chance of good coverage

      if (passDefenseSuccess) {
        // Good coverage reduces passing yards significantly
        final reduction = (baseYards * 0.3).round() + _random.nextInt(3);
        return baseYards - reduction;
      }
    } else if (offensivePlay.isRun) {
      // Less effective against run plays - defenders playing back
      final extraYards = 1 + _random.nextInt(4); // +1 to +4 yards
      return baseYards + extraYards;
    }

    return baseYards;
  }

  /// Pass defense increases interception chances
  bool _applyPassDefenseTurnover(bool baseTurnover, PlayCall offensivePlay) {
    if (offensivePlay.isPass && !baseTurnover) {
      // Increased interception chance with pass defense
      final intChance = _random.nextInt(100) < 8; // 8% additional INT chance
      return intChance;
    }
    return baseTurnover;
  }

  /// Run defense specifically targets running plays
  int _applyRunDefense(int baseYards, PlayCall offensivePlay) {
    if (offensivePlay.isRun) {
      // Very effective against run plays
      final runDefenseSuccess =
          _random.nextInt(100) < 70; // 70% chance of good run stop

      if (runDefenseSuccess) {
        // Good run defense significantly reduces yards
        final reduction = (baseYards * 0.4).round() + _random.nextInt(2);
        return baseYards - reduction;
      }
    } else if (offensivePlay.isPass) {
      // Less effective against pass plays - light coverage
      final extraYards = 1 + _random.nextInt(3); // +1 to +3 yards
      return baseYards + extraYards;
    }

    return baseYards;
  }

  /// Prevent defense focuses on stopping big plays
  int _applyPreventDefense(int baseYards, PlayCall offensivePlay) {
    if (baseYards > 15) {
      // Prevent defense is designed to stop big plays
      final bigPlayStop =
          _random.nextInt(100) < 75; // 75% chance to limit big plays

      if (bigPlayStop) {
        // Significantly reduce big play yardage
        final cappedYards = 8 + _random.nextInt(8); // Cap at 8-15 yards
        return cappedYards;
      }
    } else if (baseYards > 0 && baseYards <= 8) {
      // Prevent defense gives up short yardage more easily
      final extraYards = 1 + _random.nextInt(3); // +1 to +3 yards
      return baseYards + extraYards;
    }

    return baseYards;
  }

  /// Stack the box defense brings extra defenders near line of scrimmage
  int _applyStackTheBoxDefense(int baseYards, PlayCall offensivePlay) {
    if (offensivePlay.isRun) {
      // Very effective against run plays with extra defenders
      final stackSuccess =
          _random.nextInt(100) < 75; // 75% chance of good run stop

      if (stackSuccess) {
        // Excellent run defense with stacked box
        final reduction = (baseYards * 0.5).round() + _random.nextInt(3);
        return (baseYards - reduction).clamp(-5, baseYards);
      }
    } else if (offensivePlay.isPass) {
      // Vulnerable to pass plays with fewer defenders in coverage
      if (offensivePlay.passPlay == OffensivePassPlay.deepPass ||
          offensivePlay.passPlay == OffensivePassPlay.hailMary) {
        // Especially vulnerable to deep passes
        final extraYards = 3 + _random.nextInt(8); // +3 to +10 yards
        return baseYards + extraYards;
      } else {
        // Still somewhat vulnerable to other passes
        final extraYards = 1 + _random.nextInt(4); // +1 to +4 yards
        return baseYards + extraYards;
      }
    }

    return baseYards;
  }
}
