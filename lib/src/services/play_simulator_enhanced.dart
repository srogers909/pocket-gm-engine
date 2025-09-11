import 'dart:math' as math;
import 'dart:math';
import '../models/game_state.dart';
import '../models/play_call.dart';
import '../models/play_result.dart';
import 'package:pocket_gm_generator/pocket_gm_generator.dart';

/// Enhanced Play Simulator that uses all available player, staff, and referee attributes
/// to determine realistic play outcomes based on individual ratings and situational context.
class EnhancedPlaySimulator {
  final Random _random;

  EnhancedPlaySimulator({Random? random}) : _random = random ?? Random();

  /// Simulates a single play using comprehensive attribute-based calculations
  PlayResult simulatePlay(
    PlayCall playCall,
    GameState gameState,
    Team offense,
    Team defense,
    Referee referee,
  ) {
    // Base outcome calculation using all relevant attributes
    final baseResult = _calculateBaseOutcome(
      playCall,
      offense,
      defense,
      referee,
    );

    // Apply contextual modifiers based on game situation
    final contextualResult = _applyContextualModifiers(
      baseResult,
      gameState,
      playCall,
    );

    // Apply staff influence
    final staffModifiedResult = _applyStaffInfluence(
      contextualResult,
      offense,
      defense,
      playCall,
    );

    // Check for penalties using referee tendencies and player discipline
    final finalResult = _checkForPenalties(
      staffModifiedResult,
      offense,
      defense,
      referee,
      playCall,
    );

    return finalResult;
  }

  /// Calculates base play outcome using player attributes
  PlayResult _calculateBaseOutcome(
    PlayCall playCall,
    Team offense,
    Team defense,
    Referee referee,
  ) {
    if (playCall.isPass) {
      return _simulatePassPlay(playCall, offense, defense);
    } else if (playCall.isRun) {
      return _simulateRunPlay(playCall, offense, defense);
    } else if (playCall.specialTeamsPlay == SpecialTeamsPlay.punt) {
      return _simulatePuntPlay(offense, defense);
    } else if (playCall.specialTeamsPlay == SpecialTeamsPlay.kickFG) {
      return _simulateFieldGoalPlay(playCall, offense, defense);
    } else {
      return PlayResult(
        playType: PlayType.pass,
        yardsGained: 0,
        timeElapsed: const Duration(seconds: 5),
        description: 'Unknown play type',
      );
    }
  }

  /// Simulates passing plays using QB, receiver, and OL attributes
  PlayResult _simulatePassPlay(PlayCall playCall, Team offense, Team defense) {
    // Get key players using attribute-based selection
    final qb = _getQuarterback(offense);
    final receiver = _getBestReceiver(offense, playCall);
    final targetDefender = _getMatchingDefender(defense, receiver);

    // Get QB attributes
    final qbAccuracy = _getPlayerAttribute(qb, 'Accuracy');
    final qbArmStrength = _getPlayerAttribute(qb, 'Pass Strength');
    final qbEvasion = _getPlayerAttribute(qb, 'Evasion');

    // Get receiver attributes
    final receiverCatching = _getPlayerAttribute(receiver, 'Catching');
    final receiverRouteRunning = _getPlayerAttribute(receiver, 'Route Running');
    final receiverSpeed = _getPlayerAttribute(receiver, 'Speed');

    // Get defender attributes
    final defenderCoverage = _getPlayerAttribute(targetDefender, 'Coverage');
    final defenderSpeed = _getPlayerAttribute(targetDefender, 'Speed');

    // Calculate offensive line pass protection
    final passProtection = _calculateOffensiveLinePassBlocking(offense);

    // Calculate defensive pass rush
    final passRush = _calculateDefensivePassRush(defense);

    // Determine if QB gets pressured (sack/hurry)
    final pressureChance = math.max(0.0, (passRush - passProtection) / 100.0);
    final isPressured = _random.nextDouble() < pressureChance;

    if (isPressured) {
      // Calculate sack probability based on QB evasion
      // Base sack chance of 30% when pressured, reduced by evasion
      double sackChance = 0.3;
      
      // QB evasion reduces sack chance (higher evasion = lower sack probability)
      // Evasion of 50 = no change, 100 = -25% sack chance, 0 = +25% sack chance
      sackChance -= (qbEvasion - 50) / 200.0;
      
      // Clamp sack chance between 5% and 60%
      sackChance = sackChance.clamp(0.05, 0.60);
      
      if (_random.nextDouble() < sackChance) {
        // Sack occurs - evasion also affects sack yardage (better evasion = fewer yards lost)
        int baseSackYards = _random.nextInt(8) + 3; // 3-10 yard base sack
        final evasionReduction = ((qbEvasion - 50) / 25).round(); // Up to ±2 yards based on evasion
        final sackYards = math.max(1, baseSackYards - evasionReduction);
        
        return PlayResult(
          playType: PlayType.pass,
          yardsGained: -sackYards,
          timeElapsed: Duration(seconds: _random.nextInt(3) + 4),
          description: 'Sacked for ${sackYards} yards',
        );
      }
    }

    // Calculate completion probability based on multiple factors
    double completionChance = 0.4; // Base completion rate

    // QB accuracy influence (major factor)
    completionChance += (qbAccuracy - 50) / 100.0;

    // Receiver catching and route running
    completionChance += (receiverCatching - 50) / 150.0;
    completionChance += (receiverRouteRunning - 50) / 200.0;

    // Defender coverage (negative impact)
    completionChance -= (defenderCoverage - 50) / 150.0;

    // Speed differential (receiver vs defender)
    final speedDiff = receiverSpeed - defenderSpeed;
    completionChance += speedDiff / 300.0;

    // Apply pressure penalty if QB is hurried
    if (isPressured) {
      completionChance -= 0.15;
    }

    // Pass distance modifier based on play call
    final passDistance = _getPassDistance(playCall);
    if (passDistance > 15) {
      // Deep pass
      completionChance -= 0.2;
      completionChance +=
          (qbArmStrength - 50) / 200.0; // Arm strength matters more
    }

    // Clamp completion chance
    completionChance = completionChance.clamp(0.05, 0.95);

    // Determine if pass is completed
    final isCompleted = _random.nextDouble() < completionChance;

    if (!isCompleted) {
      return PlayResult(
        playType: PlayType.pass,
        yardsGained: 0,
        timeElapsed: Duration(seconds: _random.nextInt(3) + 3),
        description: 'Incomplete pass',
        isTurnover: false,
        isScore: false,
        isFirstDown: false,
        stopClock: true,
      );
    }

    // Calculate yards gained on completion
    int yardsGained = _calculatePassYardsGained(
      playCall,
      receiver,
      targetDefender,
    );

    // Apply YAC based on receiver speed and defender tackling
    final defenderTackling = _getPlayerAttribute(targetDefender, 'Tackling');
    final yacBonus = math.max(0, (receiverSpeed - defenderTackling) ~/ 10);
    yardsGained += yacBonus;

    // Check for touchdown
    final isTouchdown = yardsGained >= 20 && _random.nextDouble() < 0.1;
    if (isTouchdown) {
      yardsGained = math.max(yardsGained, 25);
    }

    return PlayResult(
      playType: PlayType.pass,
      yardsGained: yardsGained,
      timeElapsed: Duration(seconds: _random.nextInt(4) + 4),
      description: 'Pass completed for $yardsGained yards',
      isTurnover: false,
      isScore: isTouchdown,
      isFirstDown: yardsGained >= 10,
      stopClock: false,
    );
  }

  /// Simulates running plays using RB, OL, and defensive attributes
  PlayResult _simulateRunPlay(PlayCall playCall, Team offense, Team defense) {
    // Get key players
    final runningBack = _getBestRunningBack(offense, playCall);

    // Get RB attributes based on play type
    final rbPower = _getPlayerAttribute(runningBack, 'Rush Power');
    final rbSpeed = _getPlayerAttribute(runningBack, 'Rush Speed');
    final rbEvasion = _getPlayerAttribute(runningBack, 'Evasion');

    // Calculate offensive line run blocking
    final runBlocking = _calculateOffensiveLineRunBlocking(offense);

    // Calculate defensive run stopping
    final runDefense = _calculateDefensiveRunStopping(defense);

    // Base yards calculation
    double expectedYards = (runBlocking - runDefense) / 20.0;
    expectedYards = math.max(-5.0, expectedYards); // Minimum -5 yards

    // Apply RB-specific modifiers based on play type
    if (playCall.description.contains('Power')) {
      expectedYards += (rbPower - 50) / 25.0;
    } else if (playCall.description.contains('Outside')) {
      expectedYards += (rbSpeed - 50) / 25.0;
    } else {
      // Inside run - balance of power and evasion
      expectedYards += (rbPower + rbEvasion - 100) / 50.0;
    }

    // Add random variance
    final variance = (_random.nextDouble() - 0.5) * 6; // ±3 yards variance
    expectedYards += variance;

    // Calculate final yards (rounded)
    int yardsGained = expectedYards.round();

    // Check for big play potential
    if (yardsGained > 5 && _random.nextDouble() < 0.15) {
      final breakawayChance = (rbSpeed + rbEvasion - 100) / 200.0;
      if (_random.nextDouble() < breakawayChance) {
        yardsGained += _random.nextInt(15) + 10; // 10-24 additional yards
      }
    }

    // Check for touchdown
    final isTouchdown = yardsGained >= 15 && _random.nextDouble() < 0.08;
    if (isTouchdown) {
      yardsGained = math.max(yardsGained, 20);
    }

    return PlayResult(
      playType: PlayType.rush,
      yardsGained: yardsGained,
      timeElapsed: Duration(seconds: _random.nextInt(3) + 5),
      description: yardsGained >= 0
          ? 'Rush for $yardsGained yards'
          : 'Rush for loss of ${yardsGained.abs()} yards',
    );
  }

  /// Simulates punt plays using punter attributes
  PlayResult _simulatePuntPlay(Team offense, Team defense) {
    final punter = _getBestPunter(offense);

    final puntPower = _getPlayerAttribute(punter, 'Punt Power');
    final puntAccuracy = _getPlayerAttribute(punter, 'Punt Accuracy');

    // Calculate punt distance
    int puntDistance = 35 + ((puntPower - 50) ~/ 2); // Base 35 + power modifier
    puntDistance += _random.nextInt(11) - 5; // ±5 yards variance
    puntDistance = puntDistance.clamp(20, 65);

    // Check for touchback
    final touchbackChance = puntDistance > 50 ? 0.3 : 0.1;
    final isTouchback = _random.nextDouble() < touchbackChance;

    if (isTouchback) {
      puntDistance = math.min(puntDistance, 55); // Touchback limits distance
    }

    // Calculate return yards (simplified)
    int returnYards = 0;
    if (!isTouchback) {
      final baseReturn = _random.nextInt(8) + 2; // 2-9 base return
      final accuracyPenalty =
          (50 - puntAccuracy) ~/ 10; // Poor accuracy = longer returns
      returnYards = math.max(0, baseReturn + accuracyPenalty);
    }

    final netYards = puntDistance - returnYards;

    return PlayResult(
      playType: PlayType.punt,
      yardsGained: netYards,
      timeElapsed: Duration(seconds: _random.nextInt(2) + 8),
      description:
          'Punt for $puntDistance yards, ${returnYards > 0 ? "returned $returnYards yards" : "no return"}',
    );
  }

  /// Simulates field goal attempts using kicker attributes
  PlayResult _simulateFieldGoalPlay(
    PlayCall playCall,
    Team offense,
    Team defense,
  ) {
    final kicker = _getBestKicker(offense);

    final legStrength = _getPlayerAttribute(kicker, 'Leg Strength');
    final accuracy = _getPlayerAttribute(kicker, 'Accuracy');
    final consistency = _getPlayerAttribute(kicker, 'Consistency');

    // Simplified field goal distance calculation
    final distance = 40; // Default field goal distance since playCall.yardsToGo doesn't exist

    // Base success rate by distance
    double successRate = 0.95; // Very close kicks
    if (distance > 30) successRate = 0.90;
    if (distance > 40) successRate = 0.85;
    if (distance > 50) successRate = 0.70;
    if (distance > 55) successRate = 0.50;

    // Apply kicker attributes
    successRate += (legStrength - 50) / 200.0; // Leg strength for distance
    successRate += (accuracy - 50) / 150.0; // Accuracy
    successRate += (consistency - 50) / 200.0; // Consistency

    // Distance penalties
    if (distance > legStrength) {
      successRate -= 0.3; // Major penalty if beyond range
    }

    successRate = successRate.clamp(0.1, 0.98);

    final isGood = _random.nextDouble() < successRate;

    return PlayResult(
      playType: PlayType.fieldGoal,
      yardsGained: 0,
      timeElapsed: Duration(seconds: _random.nextInt(2) + 4),
      description: isGood
          ? 'Field goal GOOD from $distance yards'
          : 'Field goal MISSED from $distance yards',
    );
  }

  /// Gets player attribute value by name using position mapping
  int _getPlayerAttribute(Player player, String attributeName) {
    final positionAttribs = getPositionAttributes(player.primaryPosition);
    if (positionAttribs == null) return 50; // Default if position not found

    if (positionAttribs.attribute1 == attributeName)
      return player.positionRating1;
    if (positionAttribs.attribute2 == attributeName)
      return player.positionRating2;
    if (positionAttribs.attribute3 == attributeName)
      return player.positionRating3;

    return 50; // Default if attribute not found for position
  }

  /// Calculates total offensive line pass blocking rating
  double _calculateOffensiveLinePassBlocking(Team team) {
    final oLinemen = team.roster
        .where(
          (p) => ['C', 'OG', 'G', 'OT', 'T', 'OL'].contains(p.primaryPosition),
        )
        .toList();

    if (oLinemen.isEmpty) return 50.0;

    double totalBlocking = 0;
    for (final lineman in oLinemen) {
      totalBlocking += _getPlayerAttribute(lineman, 'Pass Blocking');
    }

    return totalBlocking / oLinemen.length;
  }

  /// Calculates total offensive line run blocking rating
  double _calculateOffensiveLineRunBlocking(Team team) {
    final oLinemen = team.roster
        .where(
          (p) => ['C', 'OG', 'G', 'OT', 'T', 'OL'].contains(p.primaryPosition),
        )
        .toList();

    if (oLinemen.isEmpty) return 50.0;

    double totalBlocking = 0;
    for (final lineman in oLinemen) {
      totalBlocking += _getPlayerAttribute(lineman, 'Run Blocking');
    }

    return totalBlocking / oLinemen.length;
  }

  /// Calculates defensive pass rush rating
  double _calculateDefensivePassRush(Team team) {
    final passRushers = team.roster
        .where(
          (p) =>
              ['DE', 'DT', 'NT', 'DL', 'OLB', 'LB'].contains(p.primaryPosition),
        )
        .toList();

    if (passRushers.isEmpty) return 50.0;

    double totalRush = 0;
    for (final rusher in passRushers) {
      if (['DE', 'DT', 'NT', 'DL'].contains(rusher.primaryPosition)) {
        totalRush += _getPlayerAttribute(rusher, 'Pass Rush');
      } else {
        // Linebackers - use tackling as pass rush approximation
        totalRush += _getPlayerAttribute(rusher, 'Tackling') * 0.7;
      }
    }

    return totalRush / passRushers.length;
  }

  /// Calculates defensive run stopping rating
  double _calculateDefensiveRunStopping(Team team) {
    final runStoppers = team.roster
        .where(
          (p) => [
            'DE',
            'DT',
            'NT',
            'DL',
            'LB',
            'ILB',
            'MLB',
            'OLB',
          ].contains(p.primaryPosition),
        )
        .toList();

    if (runStoppers.isEmpty) return 50.0;

    double totalStopping = 0;
    for (final stopper in runStoppers) {
      if (['DE', 'DT', 'NT', 'DL'].contains(stopper.primaryPosition)) {
        totalStopping += _getPlayerAttribute(stopper, 'Run Defense');
      } else {
        totalStopping += _getPlayerAttribute(stopper, 'Tackling');
      }
    }

    return totalStopping / runStoppers.length;
  }

  /// Helper methods for player selection

  Player _getQuarterback(Team team) {
    return team.roster.firstWhere(
      (p) => p.primaryPosition == 'QB',
      orElse: () => team.roster.first,
    );
  }

  Player _getBestReceiver(Team team, PlayCall playCall) {
    final receivers = team.roster
        .where((p) => ['WR', 'TE'].contains(p.primaryPosition))
        .toList();
    if (receivers.isEmpty) return team.roster.first;

    // For deep passes, prioritize speed and route running
    if (playCall.description.contains('Deep')) {
      receivers.sort((a, b) {
        final aScore =
            _getPlayerAttribute(a, 'Speed') +
            _getPlayerAttribute(a, 'Route Running');
        final bScore =
            _getPlayerAttribute(b, 'Speed') +
            _getPlayerAttribute(b, 'Route Running');
        return bScore.compareTo(aScore);
      });
    } else {
      // For other passes, prioritize catching
      receivers.sort((a, b) {
        final aScore = _getPlayerAttribute(a, 'Catching');
        final bScore = _getPlayerAttribute(b, 'Catching');
        return bScore.compareTo(aScore);
      });
    }

    return receivers.first;
  }

  Player _getBestRunningBack(Team team, PlayCall playCall) {
    final runningBacks = team.roster
        .where((p) => ['RB', 'FB'].contains(p.primaryPosition))
        .toList();
    if (runningBacks.isEmpty) return team.roster.first;

    // Select based on play type
    if (playCall.description.contains('Power')) {
      runningBacks.sort(
        (a, b) => _getPlayerAttribute(
          b,
          'Rush Power',
        ).compareTo(_getPlayerAttribute(a, 'Rush Power')),
      );
    } else if (playCall.description.contains('Outside')) {
      runningBacks.sort(
        (a, b) => _getPlayerAttribute(
          b,
          'Rush Speed',
        ).compareTo(_getPlayerAttribute(a, 'Rush Speed')),
      );
    } else {
      runningBacks.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    }

    return runningBacks.first;
  }

  Player _getMatchingDefender(Team team, Player receiver) {
    final defenders = team.roster
        .where((p) => ['CB', 'S', 'FS', 'SS', 'LB'].contains(p.primaryPosition))
        .toList();
    if (defenders.isEmpty) return team.roster.first;

    // Match best coverage defender
    defenders.sort(
      (a, b) => _getPlayerAttribute(
        b,
        'Coverage',
      ).compareTo(_getPlayerAttribute(a, 'Coverage')),
    );
    return defenders.first;
  }

  Player _getBestKicker(Team team) {
    return team.roster.firstWhere(
      (p) => p.primaryPosition == 'K',
      orElse: () => team.roster.first,
    );
  }

  Player _getBestPunter(Team team) {
    return team.roster.firstWhere(
      (p) => p.primaryPosition == 'P',
      orElse: () => team.roster.first,
    );
  }

  /// Helper methods

  int _getPassDistance(PlayCall playCall) {
    if (playCall.description.contains('Deep')) return 20;
    if (playCall.description.contains('Medium')) return 12;
    return 6; // Short pass
  }

  int _calculatePassYardsGained(
    PlayCall playCall,
    Player receiver,
    Player defender,
  ) {
    final baseYards = _getPassDistance(playCall);
    final variance = _random.nextInt(8) - 4; // ±4 yards
    return math.max(1, baseYards + variance);
  }

  /// Apply contextual modifiers based on game situation
  PlayResult _applyContextualModifiers(
    PlayResult result,
    GameState gameState,
    PlayCall playCall,
  ) {
    // Add game situation logic here if needed
    return result;
  }

  /// Apply staff influence to play results
  PlayResult _applyStaffInfluence(
    PlayResult result,
    Team offense,
    Team defense,
    PlayCall playCall,
  ) {
    // Get coordinators
    final offCoordinator = offense.staff?.offensiveCoordinator;
    final defCoordinator = defense.staff?.defensiveCoordinator;

    if (offCoordinator != null &&
        result.playType != PlayType.punt &&
        result.playType != PlayType.fieldGoal) {
      // Apply offensive coordinator bonuses
      double bonus = 0.0;

      if (result.playType == PlayType.pass) {
        bonus =
            (offCoordinator.passingOffense + offCoordinator.playCalling - 100) /
            400.0;
      } else if (result.playType == PlayType.rush) {
        bonus =
            (offCoordinator.rushingOffense + offCoordinator.playCalling - 100) /
            400.0;
      }

      if (bonus.abs() > 0.01) {
        final yardsBonus = (bonus * 3).round(); // Small yards bonus/penalty
        final newYards = result.yardsGained + yardsBonus;

        return result.copyWith(yardsGained: newYards);
      }
    }

    return result;
  }

  /// Check for penalties using referee tendencies
  PlayResult _checkForPenalties(
    PlayResult result,
    Team offense,
    Team defense,
    Referee referee,
    PlayCall playCall,
  ) {
    // Base penalty probabilities per play
    const basePenaltyChance = 0.08; // 8% chance per play

    if (_random.nextDouble() > basePenaltyChance) {
      return result; // No penalty
    }

    // Determine penalty type based on play and referee tendencies
    final penalties = <String, double>{};

    if (result.playType == PlayType.pass) {
      penalties['holding'] = referee.holdingTendency / 100.0;
      penalties['passInterference'] = referee.passInterferenceTendency / 100.0;
      penalties['roughingThePasser'] =
          referee.roughingThePasserTendency / 100.0;
      penalties['falseStart'] = referee.falseStartTendency / 100.0;
    } else if (result.playType == PlayType.rush) {
      penalties['holding'] = referee.holdingTendency / 100.0;
      penalties['falseStart'] = referee.falseStartTendency / 100.0;
      penalties['illegalFormation'] = referee.illegalFormationTendency / 100.0;
    }

    // Select penalty type (simplified)
    if (penalties.isNotEmpty) {
      final penaltyType = penalties.keys.first; // Simplified selection

      // Apply penalty effect
      if (['holding', 'falseStart', 'illegalFormation'].contains(penaltyType)) {
        // Offensive penalties
        final penaltyYards = penaltyType == 'holding' ? 10 : 5;
        return result.copyWith(
          yardsGained: result.yardsGained - penaltyYards,
          description: '${result.description} - $penaltyType penalty',
        );
      }
    }

    return result;
  }
}

/// Extension to add copyWith method to PlayResult
extension PlayResultCopyWith on PlayResult {
  PlayResult copyWith({
    PlayType? playType,
    int? yardsGained,
    Duration? timeElapsed,
    String? description,
    bool? isTurnover,
    bool? isScore,
    bool? isFirstDown,
    bool? stopClock,
  }) {
    return PlayResult(
      playType: playType ?? this.playType,
      yardsGained: yardsGained ?? this.yardsGained,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      description: description ?? this.description,
      isTurnover: isTurnover ?? this.isTurnover,
      isScore: isScore ?? this.isScore,
      isFirstDown: isFirstDown ?? this.isFirstDown,
      stopClock: stopClock ?? this.stopClock,
    );
  }
}
