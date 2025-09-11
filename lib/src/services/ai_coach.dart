import 'dart:math';
import '../models/game_state.dart';
import '../models/play_call.dart';
import 'package:pocket_gm_generator/pocket_gm_generator.dart';

/// AI service responsible for making intelligent play calls for CPU teams.
/// 
/// This service analyzes the current game situation and makes play calls
/// based on coaching staff ratings, down and distance, field position,
/// score differential, and time remaining.
class AICoach {
  final Random _random = Random();

  /// Makes an offensive play call based on the game situation and coaching staff.
  /// 
  /// The AI considers:
  /// - Down and distance
  /// - Field position
  /// - Score differential
  /// - Time remaining
  /// - Coach ratings (affects decision quality and tendencies)
  PlayCall makeOffensivePlayCall(GameState gameState, Team team) {
    final teamStaff = team.staff!;
    final headCoach = teamStaff.headCoach;
    final offensiveCoordinator = teamStaff.offensiveCoordinator;

    // Special teams situations
    if (_shouldPunt(gameState, headCoach)) {
      return PlayCall.specialTeams(SpecialTeamsPlay.punt);
    }

    if (_shouldAttemptFieldGoal(gameState, headCoach)) {
      return PlayCall.specialTeams(SpecialTeamsPlay.kickFG);
    }

    // Determine offensive play call
    return _selectOffensivePlay(gameState, headCoach, offensiveCoordinator, team);
  }

  /// Legacy method for backward compatibility - accepts TeamStaff
  @Deprecated('Use makeOffensivePlayCall(GameState, Team) instead')
  PlayCall makeOffensivePlayCallLegacy(GameState gameState, TeamStaff teamStaff) {
    // For legacy support, create a minimal team object or handle differently
    // This method should be phased out as callers migrate to the new signature
    final headCoach = teamStaff.headCoach;
    final offensiveCoordinator = teamStaff.offensiveCoordinator;

    // Special teams situations
    if (_shouldPunt(gameState, headCoach)) {
      return PlayCall.specialTeams(SpecialTeamsPlay.punt);
    }

    if (_shouldAttemptFieldGoal(gameState, headCoach)) {
      return PlayCall.specialTeams(SpecialTeamsPlay.kickFG);
    }

    // Return basic play call without player data
    return _selectOffensivePlayLegacy(gameState, headCoach, offensiveCoordinator);
  }

  /// Makes a defensive play call based on the game situation and coaching staff.
  /// 
  /// The AI considers:
  /// - Down and distance
  /// - Offensive tendencies and field position
  /// - Score differential and game situation
  /// - Defensive coordinator ratings and tendencies
  PlayCall makeDefensivePlayCall(GameState gameState, Team team) {
    final teamStaff = team.staff!;
    final headCoach = teamStaff.headCoach;
    final defensiveCoordinator = teamStaff.defensiveCoordinator;

    return _selectDefensivePlay(gameState, headCoach, defensiveCoordinator, team);
  }

  /// Legacy method for backward compatibility - accepts TeamStaff
  @Deprecated('Use makeDefensivePlayCall(GameState, Team) instead')
  PlayCall makeDefensivePlayCallLegacy(GameState gameState, TeamStaff teamStaff) {
    final headCoach = teamStaff.headCoach;
    final defensiveCoordinator = teamStaff.defensiveCoordinator;

    return _selectDefensivePlayLegacy(gameState, headCoach, defensiveCoordinator);
  }

  /// Legacy method for backward compatibility - defaults to offensive play calling
  PlayCall makePlayCall(GameState gameState, TeamStaff teamStaff) {
    return makeOffensivePlayCallLegacy(gameState, teamStaff);
  }

  /// Determines if the team should punt based on game situation and coaching.
  bool _shouldPunt(GameState gameState, HeadCoach headCoach) {
    // Only consider punting on 4th down
    if (gameState.down != 4) return false;

    // Very long 4th downs should almost always be punts
    if (gameState.yardsToGo > 8) {
      // Better coaches might be slightly more aggressive
      final aggressivenessBonus = (headCoach.gameManagement - 50) / 100;
      final baseChance = 0.85;
      final puntChance = baseChance - (aggressivenessBonus * 0.1);
      return _random.nextDouble() < puntChance;
    }

    // Medium distance 4th downs (4-8 yards)
    if (gameState.yardsToGo >= 4) {
      // Consider field position and score situation
      final inOwnTerritory = gameState.yardLine < 50;
      final basePuntChance = inOwnTerritory ? 0.7 : 0.4;
      
      // Adjust based on coach's game management
      final managementFactor = headCoach.gameManagement / 100.0;
      final adjustedChance = basePuntChance * managementFactor;
      
      return _random.nextDouble() < adjustedChance;
    }

    // Short 4th downs (1-3 yards) - more aggressive
    final inRedZone = gameState.yardLine > 80;
    if (inRedZone) {
      // Almost never punt in red zone
      return false;
    }

    // Consider going for it based on coach aggressiveness
    final conservativeChance = 0.5 - (headCoach.gameManagement - 50) / 200.0;
    return _random.nextDouble() < conservativeChance;
  }

  /// Determines if the team should attempt a field goal.
  bool _shouldAttemptFieldGoal(GameState gameState, HeadCoach headCoach) {
    // Only on 4th down in field goal range
    if (gameState.down != 4) return false;

    final distanceToGoal = 100 - gameState.yardLine;
    final fieldGoalDistance = distanceToGoal + 17; // Add 17 for end zone depth and snap

    // Very long field goals (55+ yards) - rarely attempted
    if (fieldGoalDistance > 55) {
      final desperation = _isDesperationSituation(gameState);
      return desperation && _random.nextDouble() < 0.2;
    }

    // Long field goals (45-55 yards)
    if (fieldGoalDistance > 45) {
      final confidence = headCoach.gameManagement / 100.0;
      return _random.nextDouble() < (0.6 * confidence);
    }

    // Medium range (30-45 yards) - usually attempted
    if (fieldGoalDistance > 30) {
      return _random.nextDouble() < 0.85;
    }

    // Short field goals (under 30 yards) - almost always attempted
    return _random.nextDouble() < 0.95;
  }

  /// Selects an offensive play based on situation and coordinator preferences.
  PlayCall _selectOffensivePlay(
    GameState gameState,
    HeadCoach headCoach,
    OffensiveCoordinator offensiveCoordinator,
    Team team,
  ) {
    // Determine base play type preference
    final passingPreference = offensiveCoordinator.passingOffense / 100.0;
    final rushingPreference = offensiveCoordinator.rushingOffense / 100.0;
    
    // Situational factors
    final isShortYardage = gameState.yardsToGo <= 3;
    final isLongYardage = gameState.yardsToGo > 7;
    final isRedZone = gameState.yardLine > 80;
    final isDesperationTime = _isDesperationSituation(gameState);

    // Calculate play type probability
    double passChance = 0.5; // Base 50/50

    // Adjust based on coordinator strengths
    final coordinatorBias = (passingPreference - rushingPreference) * 0.3;
    passChance += coordinatorBias;

    // Situational adjustments
    if (isShortYardage) {
      passChance -= 0.2; // Favor running in short yardage
    }
    
    if (isLongYardage) {
      passChance += 0.25; // Favor passing in long yardage
    }
    
    if (isRedZone) {
      passChance += 0.1; // Slightly favor passing in red zone
    }
    
    if (isDesperationTime) {
      passChance += 0.4; // Heavily favor passing when time is short
    }

    // Make the decision
    PlayCall baseCall;
    if (_random.nextDouble() < passChance) {
      baseCall = _selectPassPlay(gameState, offensiveCoordinator);
    } else {
      baseCall = _selectRunPlay(gameState, offensiveCoordinator);
    }

    // Populate player and coaching data
    return _populatePlayCallData(baseCall, team);
  }

  /// Populates a PlayCall with player and coaching data from the team.
  PlayCall _populatePlayCallData(PlayCall baseCall, Team team) {
    final teamStaff = team.staff!;
    final roster = team.roster;
    
    // Select key players for this play
    final quarterback = _selectQuarterback(roster);
    final primarySkillPlayer = _selectPrimarySkillPlayer(baseCall, roster);
    final primaryDefender = _selectPrimaryDefender(baseCall, roster);
    final offensiveLineRating = _calculateOffensiveLineRating(roster);
    final defensiveLineRating = _calculateDefensiveLineRating(roster);
    
    // Create PlayPlayers data
    final playPlayers = PlayPlayers(
      quarterback: quarterback,
      primarySkillPlayer: primarySkillPlayer,
      primaryDefender: primaryDefender,
      offensiveLineRating: offensiveLineRating.toDouble(),
      defensiveLineRating: defensiveLineRating.toDouble(),
    );
    
    // Create PlayCoaching data
    final playCoaching = PlayCoaching(
      offensiveCoordinator: teamStaff.offensiveCoordinator,
      defensiveCoordinator: teamStaff.defensiveCoordinator,
    );
    
    // Use the new withPlayerData method to enhance the PlayCall
    return baseCall.withPlayerData(
      players: playPlayers,
      coaching: playCoaching,
    );
  }

  /// Selects the best quarterback from the roster.
  Player? _selectQuarterback(List<Player> roster) {
    final quarterbacks = roster.where((p) => p.primaryPosition == 'QB').toList();
    if (quarterbacks.isEmpty) return null;
    
    // Sort by overall rating and return the best
    quarterbacks.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return quarterbacks.first;
  }

  /// Selects the primary skill player for this play based on play type.
  Player? _selectPrimarySkillPlayer(PlayCall playCall, List<Player> roster) {
    if (playCall.isPass) {
      // For pass plays, select best receiver
      final receivers = roster.where((p) => p.primaryPosition == 'WR' || p.primaryPosition == 'TE').toList();
      if (receivers.isEmpty) return null;
      receivers.sort((a, b) => b.overallRating.compareTo(a.overallRating));
      return receivers.first;
    } else if (playCall.isRun) {
      // For run plays, select best running back
      final runningBacks = roster.where((p) => p.primaryPosition == 'RB').toList();
      if (runningBacks.isEmpty) return null;
      runningBacks.sort((a, b) => b.overallRating.compareTo(a.overallRating));
      return runningBacks.first;
    }
    return null;
  }

  /// Selects the primary defender for this play.
  Player? _selectPrimaryDefender(PlayCall playCall, List<Player> roster) {
    if (playCall.isPass) {
      // For pass plays, select best defensive back
      final defensiveBacks = roster.where((p) => p.primaryPosition == 'CB' || p.primaryPosition == 'S').toList();
      if (defensiveBacks.isEmpty) return null;
      defensiveBacks.sort((a, b) => b.overallRating.compareTo(a.overallRating));
      return defensiveBacks.first;
    } else if (playCall.isRun) {
      // For run plays, select best linebacker
      final linebackers = roster.where((p) => p.primaryPosition == 'LB').toList();
      if (linebackers.isEmpty) return null;
      linebackers.sort((a, b) => b.overallRating.compareTo(a.overallRating));
      return linebackers.first;
    }
    return null;
  }

  /// Calculates the average rating of the offensive line.
  int _calculateOffensiveLineRating(List<Player> roster) {
    final offensiveLinemen = roster.where((p) => p.primaryPosition == 'OL').toList();
    if (offensiveLinemen.isEmpty) return 50; // Default average rating
    
    final totalRating = offensiveLinemen.fold<int>(0, (sum, player) => sum + player.overallRating);
    return totalRating ~/ offensiveLinemen.length;
  }

  /// Calculates the average rating of the defensive line.
  int _calculateDefensiveLineRating(List<Player> roster) {
    final defensiveLinemen = roster.where((p) => p.primaryPosition == 'DL').toList();
    if (defensiveLinemen.isEmpty) return 50; // Default average rating
    
    final totalRating = defensiveLinemen.fold<int>(0, (sum, player) => sum + player.overallRating);
    return totalRating ~/ defensiveLinemen.length;
  }

  /// Legacy method for selecting offensive plays without player data.
  PlayCall _selectOffensivePlayLegacy(
    GameState gameState,
    HeadCoach headCoach,
    OffensiveCoordinator offensiveCoordinator,
  ) {
    // Determine base play type preference
    final passingPreference = offensiveCoordinator.passingOffense / 100.0;
    final rushingPreference = offensiveCoordinator.rushingOffense / 100.0;
    
    // Situational factors
    final isShortYardage = gameState.yardsToGo <= 3;
    final isLongYardage = gameState.yardsToGo > 7;
    final isRedZone = gameState.yardLine > 80;
    final isDesperationTime = _isDesperationSituation(gameState);

    // Calculate play type probability
    double passChance = 0.5; // Base 50/50

    // Adjust based on coordinator strengths
    final coordinatorBias = (passingPreference - rushingPreference) * 0.3;
    passChance += coordinatorBias;

    // Situational adjustments
    if (isShortYardage) {
      passChance -= 0.2; // Favor running in short yardage
    }
    
    if (isLongYardage) {
      passChance += 0.25; // Favor passing in long yardage
    }
    
    if (isRedZone) {
      passChance += 0.1; // Slightly favor passing in red zone
    }
    
    if (isDesperationTime) {
      passChance += 0.4; // Heavily favor passing when time is short
    }

    // Make the decision
    if (_random.nextDouble() < passChance) {
      return _selectPassPlay(gameState, offensiveCoordinator);
    } else {
      return _selectRunPlay(gameState, offensiveCoordinator);
    }
  }

  /// Legacy method for selecting defensive plays without player data.
  PlayCall _selectDefensivePlayLegacy(
    GameState gameState,
    HeadCoach headCoach,
    DefensiveCoordinator defensiveCoordinator,
  ) {
    final rushDefenseRating = defensiveCoordinator.rushingDefense;
    final passDefenseRating = defensiveCoordinator.passingDefense;
    final playCallingRating = defensiveCoordinator.defensivePlayCalling;
    
    // Situational factors
    final isShortYardage = gameState.yardsToGo <= 3;
    final isLongYardage = gameState.yardsToGo > 7;
    final isRedZone = gameState.yardLine > 80;
    final isGoalLine = gameState.yardLine > 95;
    final isDesperationTime = _isDesperationSituation(gameState);

    // Goal line defense - stack the box heavily
    if (isGoalLine) {
      return _random.nextDouble() < 0.8
          ? PlayCall.defense(DefensivePlay.stackTheBox)
          : PlayCall.defense(DefensivePlay.defendRun);
    }

    // Short yardage situations - expect run
    if (isShortYardage && !isDesperationTime) {
      final stackChance = 0.6 + (rushDefenseRating - 50) / 200.0;
      if (_random.nextDouble() < stackChance) {
        return PlayCall.defense(DefensivePlay.stackTheBox);
      } else {
        return PlayCall.defense(DefensivePlay.defendRun);
      }
    }

    // Long yardage - expect pass
    if (isLongYardage) {
      final passDefenseChance = 0.7 + (passDefenseRating - 50) / 200.0;
      if (_random.nextDouble() < passDefenseChance) {
        return PlayCall.defense(DefensivePlay.defendPass);
      } else {
        // Sometimes blitz on long yardage
        return _random.nextDouble() < 0.4
            ? PlayCall.defense(DefensivePlay.blitz)
            : PlayCall.defense(DefensivePlay.balanced);
      }
    }

    // Desperation time defense
    if (isDesperationTime) {
      final scoreDifferential = gameState.defensiveTeamScore - gameState.possessionTeamScore;
      
      // If ahead, play prevent defense
      if (scoreDifferential > 3) {
        return PlayCall.defense(DefensivePlay.prevent);
      }
      
      // If close or behind, pressure the QB
      return _random.nextDouble() < 0.6
          ? PlayCall.defense(DefensivePlay.blitz)
          : PlayCall.defense(DefensivePlay.defendPass);
    }

    // Red zone defense
    if (isRedZone) {
      return _selectRedZoneDefense(gameState, defensiveCoordinator);
    }

    // Third down situations
    if (gameState.down == 3) {
      return _selectThirdDownDefense(gameState, defensiveCoordinator);
    }

    // Normal down and distance - use coordinator tendencies
    return _selectStandardDefense(gameState, defensiveCoordinator);
  }

  /// Selects a specific passing play based on situation.
  PlayCall _selectPassPlay(GameState gameState, OffensiveCoordinator coordinator) {
    final playCallingRating = coordinator.playCalling;
    final isDesperationTime = _isDesperationSituation(gameState);
    final isLongYardage = gameState.yardsToGo > 7;
    final isShortYardage = gameState.yardsToGo <= 3;

    // Desperation situations
    if (isDesperationTime && gameState.yardsToGo > 15) {
      return PlayCall.pass(OffensivePassPlay.hailMary);
    }

    if (isDesperationTime) {
      // High-rated coordinators make better desperation calls
      if (playCallingRating > 70 && _random.nextDouble() < 0.6) {
        return PlayCall.pass(OffensivePassPlay.mediumPass);
      } else {
        return PlayCall.pass(OffensivePassPlay.deepPass);
      }
    }

    // Long yardage situations
    if (isLongYardage) {
      final deepChance = 0.4 + (playCallingRating - 50) / 200.0;
      if (_random.nextDouble() < deepChance) {
        return PlayCall.pass(OffensivePassPlay.deepPass);
      } else {
        return PlayCall.pass(OffensivePassPlay.mediumPass);
      }
    }

    // Short yardage situations
    if (isShortYardage) {
      // Screens and short passes
      final screenChance = 0.3;
      if (_random.nextDouble() < screenChance) {
        return _random.nextBool() 
            ? PlayCall.pass(OffensivePassPlay.wrScreen)
            : PlayCall.pass(OffensivePassPlay.rbScreen);
      } else {
        return PlayCall.pass(OffensivePassPlay.shortPass);
      }
    }

    // Normal situations - mix of medium and short passes
    final mediumChance = 0.4 + (playCallingRating - 50) / 250.0;
    if (_random.nextDouble() < mediumChance) {
      return PlayCall.pass(OffensivePassPlay.mediumPass);
    } else {
      return PlayCall.pass(OffensivePassPlay.shortPass);
    }
  }

  /// Selects a specific running play based on situation.
  PlayCall _selectRunPlay(GameState gameState, OffensiveCoordinator coordinator) {
    final playCallingRating = coordinator.playCalling;
    final rushingRating = coordinator.rushingOffense;
    final isShortYardage = gameState.yardsToGo <= 3;
    final isRedZone = gameState.yardLine > 80;

    // Goal line situations - power running
    if (gameState.yardLine > 95) {
      return _random.nextDouble() < 0.7 
          ? PlayCall.run(OffensiveRunPlay.powerRun)
          : PlayCall.run(OffensiveRunPlay.qbRun);
    }

    // Short yardage situations
    if (isShortYardage) {
      // High-rated coordinators mix things up more
      if (playCallingRating > 75 && _random.nextDouble() < 0.3) {
        return PlayCall.run(OffensiveRunPlay.readOption);
      } else {
        return _random.nextDouble() < 0.6
            ? PlayCall.run(OffensiveRunPlay.powerRun)
            : PlayCall.run(OffensiveRunPlay.insideRun);
      }
    }

    // Red zone - mix of power and creativity
    if (isRedZone) {
      final creativityChance = (playCallingRating - 50) / 100.0 * 0.4;
      if (_random.nextDouble() < creativityChance) {
        return _selectCreativeRunPlay();
      } else {
        return PlayCall.run(OffensiveRunPlay.powerRun);
      }
    }

    // Normal field position - full variety
    final creativeCoordinator = playCallingRating > 65;
    final outsideChance = creativeCoordinator ? 0.4 : 0.25;
    
    final roll = _random.nextDouble();
    if (roll < 0.3) {
      return PlayCall.run(OffensiveRunPlay.insideRun);
    } else if (roll < 0.3 + outsideChance) {
      return PlayCall.run(OffensiveRunPlay.outsideRun);
    } else if (roll < 0.8) {
      return PlayCall.run(OffensiveRunPlay.powerRun);
    } else {
      return _selectCreativeRunPlay();
    }
  }

  /// Selects a creative/modern running play.
  PlayCall _selectCreativeRunPlay() {
    final plays = [
      OffensiveRunPlay.jetSweep,
      OffensiveRunPlay.readOption,
      OffensiveRunPlay.qbRun,
    ];
    return PlayCall.run(plays[_random.nextInt(plays.length)]);
  }

  /// Selects a defensive play based on situation and coordinator preferences.
  PlayCall _selectDefensivePlay(
    GameState gameState,
    HeadCoach headCoach,
    DefensiveCoordinator defensiveCoordinator,
    Team team,
  ) {
    final rushDefenseRating = defensiveCoordinator.rushingDefense;
    final passDefenseRating = defensiveCoordinator.passingDefense;
    final playCallingRating = defensiveCoordinator.defensivePlayCalling;
    
    // Situational factors
    final isShortYardage = gameState.yardsToGo <= 3;
    final isLongYardage = gameState.yardsToGo > 7;
    final isRedZone = gameState.yardLine > 80;
    final isGoalLine = gameState.yardLine > 95;
    final isDesperationTime = _isDesperationSituation(gameState);
    final isProbablePassSituation = _isProbablePassSituation(gameState);

    // Goal line defense - stack the box heavily
    if (isGoalLine) {
      return _random.nextDouble() < 0.8
          ? PlayCall.defense(DefensivePlay.stackTheBox)
          : PlayCall.defense(DefensivePlay.defendRun);
    }

    // Short yardage situations - expect run
    if (isShortYardage && !isDesperationTime) {
      final stackChance = 0.6 + (rushDefenseRating - 50) / 200.0;
      if (_random.nextDouble() < stackChance) {
        return PlayCall.defense(DefensivePlay.stackTheBox);
      } else {
        return PlayCall.defense(DefensivePlay.defendRun);
      }
    }

    // Long yardage - expect pass
    if (isLongYardage) {
      final passDefenseChance = 0.7 + (passDefenseRating - 50) / 200.0;
      if (_random.nextDouble() < passDefenseChance) {
        return PlayCall.defense(DefensivePlay.defendPass);
      } else {
        // Sometimes blitz on long yardage
        return _random.nextDouble() < 0.4
            ? PlayCall.defense(DefensivePlay.blitz)
            : PlayCall.defense(DefensivePlay.balanced);
      }
    }

    // Desperation time defense
    if (isDesperationTime) {
      final scoreDifferential = gameState.defensiveTeamScore - gameState.possessionTeamScore;
      
      // If ahead, play prevent defense
      if (scoreDifferential > 3) {
        return PlayCall.defense(DefensivePlay.prevent);
      }
      
      // If close or behind, pressure the QB
      return _random.nextDouble() < 0.6
          ? PlayCall.defense(DefensivePlay.blitz)
          : PlayCall.defense(DefensivePlay.defendPass);
    }

    // Red zone defense
    if (isRedZone) {
      return _selectRedZoneDefense(gameState, defensiveCoordinator);
    }

    // Third down situations
    if (gameState.down == 3) {
      return _selectThirdDownDefense(gameState, defensiveCoordinator);
    }

    // Normal down and distance - use coordinator tendencies
    return _selectStandardDefense(gameState, defensiveCoordinator);
  }

  /// Selects red zone defensive strategy.
  PlayCall _selectRedZoneDefense(GameState gameState, DefensiveCoordinator coordinator) {
    final passDefenseRating = coordinator.passingDefense;
    final rushDefenseRating = coordinator.rushingDefense;
    final playCallingRating = coordinator.defensivePlayCalling;

    // In red zone, need to be careful about big plays
    final isShortYardage = gameState.yardsToGo <= 3;
    
    if (isShortYardage) {
      // Expect goal line run plays
      return _random.nextDouble() < 0.7
          ? PlayCall.defense(DefensivePlay.stackTheBox)
          : PlayCall.defense(DefensivePlay.defendRun);
    }

    // Medium/long yardage in red zone - balanced approach
    final strongerSuit = passDefenseRating > rushDefenseRating ? 'pass' : 'run';
    final creativityChance = (playCallingRating - 50) / 100.0 * 0.3;

    if (_random.nextDouble() < creativityChance) {
      // Creative defensive coordinator might blitz
      return PlayCall.defense(DefensivePlay.blitz);
    }

    if (strongerSuit == 'pass') {
      return PlayCall.defense(DefensivePlay.defendPass);
    } else {
      return PlayCall.defense(DefensivePlay.defendRun);
    }
  }

  /// Selects third down defensive strategy.
  PlayCall _selectThirdDownDefense(GameState gameState, DefensiveCoordinator coordinator) {
    final passDefenseRating = coordinator.passingDefense;
    final playCallingRating = coordinator.defensivePlayCalling;
    final yardsToGo = gameState.yardsToGo;

    // Third and long - almost certainly a pass
    if (yardsToGo > 7) {
      final blitzChance = 0.4 + (playCallingRating - 50) / 200.0;
      if (_random.nextDouble() < blitzChance) {
        return PlayCall.defense(DefensivePlay.blitz);
      } else {
        return PlayCall.defense(DefensivePlay.defendPass);
      }
    }

    // Third and medium (4-7 yards)
    if (yardsToGo >= 4) {
      final passChance = 0.6 + (passDefenseRating - 50) / 200.0;
      if (_random.nextDouble() < passChance) {
        return PlayCall.defense(DefensivePlay.defendPass);
      } else {
        return PlayCall.defense(DefensivePlay.balanced);
      }
    }

    // Third and short (1-3 yards) - could be run or pass
    return _random.nextDouble() < 0.5
        ? PlayCall.defense(DefensivePlay.stackTheBox)
        : PlayCall.defense(DefensivePlay.balanced);
  }

  /// Selects defensive strategy for standard down and distance.
  PlayCall _selectStandardDefense(GameState gameState, DefensiveCoordinator coordinator) {
    final passDefenseRating = coordinator.passingDefense;
    final rushDefenseRating = coordinator.rushingDefense;
    final playCallingRating = coordinator.defensivePlayCalling;

    // Determine coordinator's preferred style
    final prefersPassDefense = passDefenseRating > rushDefenseRating;
    final isAggressive = playCallingRating > 70;

    // Base probabilities for first and second down
    double balancedChance = 0.4;
    double blitzChance = isAggressive ? 0.15 : 0.08;
    double passDefenseChance = prefersPassDefense ? 0.25 : 0.15;
    double runDefenseChance = prefersPassDefense ? 0.15 : 0.25;

    // Adjust based on down
    if (gameState.down == 1) {
      // First down - expect more balance
      balancedChance += 0.1;
      blitzChance -= 0.05;
    } else if (gameState.down == 2) {
      // Second down - depends on distance
      if (gameState.yardsToGo > 5) {
        passDefenseChance += 0.1;
        runDefenseChance -= 0.05;
      } else {
        runDefenseChance += 0.1;
        passDefenseChance -= 0.05;
      }
    }

    // Make selection based on probabilities
    final roll = _random.nextDouble();
    if (roll < balancedChance) {
      return PlayCall.defense(DefensivePlay.balanced);
    } else if (roll < balancedChance + blitzChance) {
      return PlayCall.defense(DefensivePlay.blitz);
    } else if (roll < balancedChance + blitzChance + passDefenseChance) {
      return PlayCall.defense(DefensivePlay.defendPass);
    } else {
      return PlayCall.defense(DefensivePlay.defendRun);
    }
  }

  /// Determines if the current situation suggests a probable pass play.
  bool _isProbablePassSituation(GameState gameState) {
    // Long yardage situations
    if (gameState.yardsToGo > 7) return true;
    
    // Late in game when behind
    if (_isDesperationSituation(gameState)) return true;
    
    // Third and medium/long
    if (gameState.down == 3 && gameState.yardsToGo > 3) return true;
    
    return false;
  }

  /// Determines if the current situation requires desperation tactics.
  bool _isDesperationSituation(GameState gameState) {
    // Last 2 minutes of half/game with significant deficit
    final isLateInGame = gameState.gameClock.inMinutes < 2;
    final scoreDifferential = gameState.defensiveTeamScore - gameState.possessionTeamScore;
    final isBehind = scoreDifferential > 0;
    
    if (isLateInGame && isBehind) {
      // Need multiple scores
      if (scoreDifferential > 10) return true;
      // Need one score
      if (scoreDifferential > 3) return true;
    }

    return false;
  }
}
