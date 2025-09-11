import 'dart:math';
import '../models/game_state.dart';
import '../models/play_result.dart';
import '../models/play_call.dart';
import 'package:pocket_gm_generator/pocket_gm_generator.dart';

/// Improved PlaySimulator with enhanced realism based on NFL statistical analysis.
/// 
/// This version addresses three key areas identified in realism testing:
/// 1. Reduced touchdown probability and field goal accuracy to lower scoring
/// 2. Adjusted play yard gain distributions to reduce total offensive yardage
/// 3. Significantly reduced fumble and interception probabilities to match NFL turnover rates
/// 
/// Target adjustments:
/// - Average scoring: Reduce from 30.4 to ~23.5 points per team (29.4% reduction)
/// - Average yardage: Reduce from 513 to ~350 yards per team (46.6% reduction) 
/// - Average turnovers: Reduce from 7.2 to ~2.1 per game (242.9% reduction)
class PlaySimulator {
  final Random _random = Random();

  // REALISM IMPROVEMENT: Reduced turnover rates significantly
  // Old fumble rate was ~2% (1 in 50), new rate is ~0.8% (1 in 125)
  // This addresses the 242.9% higher turnover rate
  static const int _fumbleRate = 125; // Was 50, now 125 (60% reduction)
  static const int _readOptionTurnoverRate = 100; // Was 40, now 100 (60% reduction)
  static const int _qbTurnoverRate = 150; // Was 60, now 150 (60% reduction)
  
  // REALISM IMPROVEMENT: Reduced pass interception rates
  static const int _hailMaryIntRate = 6; // Was 4 (25%), now 6 (~17%)
  static const int _deepPassIntRate = 40; // Was 20 (5%), now 40 (2.5%)
  static const int _mediumPassIntRate = 66; // Was 33 (~3%), now 66 (1.5%)
  static const int _shortPassIntRate = 100; // Was 50 (2%), now 100 (1%)
  static const int _screenTurnoverRate = 150; // Was 60, now 150

  // Player selection helper methods (unchanged for brevity)
  String? _selectQuarterback(Team team) {
    final quarterbacks = team.getPlayersByPosition('QB');
    if (quarterbacks.isEmpty) return null;
    quarterbacks.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return quarterbacks.first.commonName;
  }

  String? _selectRunningBack(Team team) {
    final runningBacks = team.getPlayersByPosition('RB');
    if (runningBacks.isEmpty) return null;
    runningBacks.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return runningBacks.first.commonName;
  }

  String? _selectReceiver(Team team) {
    final receivers = team.getPlayersByPosition('WR');
    if (receivers.isEmpty) return null;
    receivers.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    final topReceivers = receivers.take(3).toList();
    return topReceivers[_random.nextInt(topReceivers.length)].commonName;
  }

  String? _selectTightEnd(Team team) {
    final tightEnds = team.getPlayersByPosition('TE');
    if (tightEnds.isEmpty) return null;
    tightEnds.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return tightEnds.first.commonName;
  }

  String? _selectDefender(Team team, {String? preferredPosition}) {
    List<Player> defenders;
    if (preferredPosition != null) {
      defenders = team.getPlayersByPosition(preferredPosition);
    } else {
      defenders = [
        ...team.getPlayersByPosition('LB'),
        ...team.getPlayersByPosition('CB'),
        ...team.getPlayersByPosition('S'),
        ...team.getPlayersByPosition('DE'),
        ...team.getPlayersByPosition('DT'),
      ];
    }
    if (defenders.isEmpty) return null;
    defenders.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    final topDefenders = defenders.take(5).toList();
    return topDefenders[_random.nextInt(topDefenders.length)].commonName;
  }

  List<String> _selectInvolvedPlayers(Team offensiveTeam, Team defensiveTeam, {int count = 2}) {
    final involved = <String>[];
    final offensivePlayers = [
      ...offensiveTeam.getPlayersByPosition('OL'),
      ...offensiveTeam.getPlayersByPosition('FB'),
    ];
    final defensivePlayers = [
      ...defensiveTeam.getPlayersByPosition('LB'),
      ...defensiveTeam.getPlayersByPosition('DB'),
    ];
    final allPlayers = [...offensivePlayers, ...defensivePlayers];
    if (allPlayers.isEmpty) return involved;
    final shuffled = List.from(allPlayers)..shuffle(_random);
    for (int i = 0; i < count && i < shuffled.length; i++) {
      involved.add(shuffled[i].commonName);
    }
    return involved;
  }

  String? _selectKicker(Team team) {
    final kickers = team.getPlayersByPosition('K');
    if (kickers.isEmpty) return null;
    kickers.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return kickers.first.commonName;
  }

  String? _selectPunter(Team team) {
    final punters = team.getPlayersByPosition('P');
    if (punters.isEmpty) return null;
    punters.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return punters.first.commonName;
  }

  List<String> _selectSpecialTeamsPlayers(Team offensiveTeam, Team defensiveTeam, {int count = 3}) {
    final involved = <String>[];
    final specialTeamsPlayers = [
      ...offensiveTeam.getPlayersByPosition('LB'),
      ...offensiveTeam.getPlayersByPosition('WR'),
      ...defensiveTeam.getPlayersByPosition('LB'),
      ...defensiveTeam.getPlayersByPosition('S'),
    ];
    if (specialTeamsPlayers.isEmpty) return involved;
    final shuffled = List.from(specialTeamsPlayers)..shuffle(_random);
    for (int i = 0; i < count && i < shuffled.length; i++) {
      involved.add(shuffled[i].commonName);
    }
    return involved;
  }

  /// Simulates a basic running play with improved realism.
  PlayResult simulateRunPlay(GameState gameState, Team offensiveTeam, Team defensiveTeam) {
    // REALISM IMPROVEMENT: Reduced yard gains to lower total yardage
    int yardsGained = _generateRunYardsImproved(gameState);
    
    final timeElapsed = Duration(seconds: 25 + _random.nextInt(21));
    final distanceToGoal = 100 - gameState.yardLine;
    final isScore = yardsGained >= distanceToGoal;
    final isFirstDown = !isScore && yardsGained >= gameState.yardsToGo;
    
    // REALISM IMPROVEMENT: Significantly reduced fumble rate
    final isTurnover = _shouldFumbleImproved();
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

  /// Main simulation method with improved realism.
  PlayResult simulatePlay(GameState gameState, PlayCall playCall, Team offensiveTeam, Team defensiveTeam) {
    if (playCall.isRun) {
      return _simulateRunPlayByTypeImproved(gameState, playCall.runPlay!, offensiveTeam, defensiveTeam);
    } else if (playCall.isPass) {
      return _simulatePassPlayByTypeImproved(gameState, playCall.passPlay!, offensiveTeam, defensiveTeam);
    } else if (playCall.isSpecialTeams) {
      return _simulateSpecialTeamsPlayImproved(gameState, playCall.specialTeamsPlay!, offensiveTeam, defensiveTeam);
    }
    return simulateRunPlay(gameState, offensiveTeam, defensiveTeam);
  }

  /// Simulates a play with defensive modifications and improved realism.
  PlayResult simulatePlayWithDefense(
    GameState gameState, 
    PlayCall offensivePlay, 
    PlayCall defensivePlay,
    Team offensiveTeam,
    Team defensiveTeam
  ) {
    PlayResult baseResult = simulatePlay(gameState, offensivePlay, offensiveTeam, defensiveTeam);
    
    if (defensivePlay.isDefense) {
      return _applyDefensiveModifications(baseResult, offensivePlay, defensivePlay.defensivePlay!);
    }
    
    return baseResult;
  }

  /// REALISM IMPROVEMENT: Reduced yard gains for running plays
  /// Target: Reduce average yards to match NFL statistics
  int _generateRunYardsImproved(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    
    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYardsImproved();
    }
    
    return _generateNormalRunYardsImproved();
  }

  /// REALISM IMPROVEMENT: More conservative goal line running
  int _generateGoalLineRunYardsImproved() {
    final roll = _random.nextInt(100);
    
    if (roll < 15) {
      // 15% chance of loss (was 10%)
      return -1 - _random.nextInt(3);
    } else if (roll < 50) {
      // 35% chance of no gain or 1 yard (was 30%)
      return _random.nextInt(2);
    } else if (roll < 85) {
      // 35% chance of short gain (was 40%)
      return 2 + _random.nextInt(3);
    } else {
      // 15% chance of bigger gain (was 20%)
      return 5 + _random.nextInt(4); // Reduced max from 6 to 4
    }
  }

  /// REALISM IMPROVEMENT: Significantly reduced running yards
  /// This addresses the 46.6% higher yardage issue
  int _generateNormalRunYardsImproved() {
    final roll = _random.nextInt(100);
    
    if (roll < 12) {
      // 12% chance of loss (was 8%)
      return -1 - _random.nextInt(4); // Increased loss range
    } else if (roll < 20) {
      // 8% chance of no gain (was 7%)
      return 0;
    } else if (roll < 70) {
      // 50% chance of short gain (was 45%)
      return 1 + _random.nextInt(4); // Reduced max from 5 to 4
    } else if (roll < 90) {
      // 20% chance of medium gain (was 25%)
      return 5 + _random.nextInt(5); // Reduced max from 7 to 5
    } else if (roll < 98) {
      // 8% chance of long gain (was 10%)
      return 10 + _random.nextInt(8); // Reduced max from 13 to 8
    } else {
      // 2% chance of breakaway (was 5%)
      return 18 + _random.nextInt(25); // Significantly reduced max
    }
  }

  /// REALISM IMPROVEMENT: Reduced turnover rates across all play types
  bool _shouldFumbleImproved() {
    return _random.nextInt(_fumbleRate) == 0;
  }

  bool _shouldReadOptionTurnoverImproved() {
    return _random.nextInt(_readOptionTurnoverRate) == 0;
  }

  bool _shouldQBTurnoverImproved() {
    return _random.nextInt(_qbTurnoverRate) == 0;
  }

  bool _shouldHailMaryTurnoverImproved() {
    return _random.nextInt(_hailMaryIntRate) == 0;
  }

  bool _shouldDeepPassTurnoverImproved() {
    return _random.nextInt(_deepPassIntRate) == 0;
  }

  bool _shouldMediumPassTurnoverImproved() {
    return _random.nextInt(_mediumPassIntRate) == 0;
  }

  bool _shouldShortPassTurnoverImproved() {
    return _random.nextInt(_shortPassIntRate) == 0;
  }

  bool _shouldScreenTurnoverImproved() {
    return _random.nextInt(_screenTurnoverRate) == 0;
  }

  bool _shouldPassStopClock() {
    return _random.nextInt(5) < 2;
  }

  /// REALISM IMPROVEMENT: Improved running play simulation by type
  PlayResult _simulateRunPlayByTypeImproved(GameState gameState, OffensiveRunPlay runPlay, Team offensiveTeam, Team defensiveTeam) {
    int yardsGained;
    Duration timeElapsed;
    bool isTurnover = false;
    
    switch (runPlay) {
      case OffensiveRunPlay.powerRun:
        yardsGained = _generatePowerRunYardsImproved(gameState);
        timeElapsed = Duration(seconds: 25 + _random.nextInt(16));
        isTurnover = _shouldFumbleImproved();
        break;
        
      case OffensiveRunPlay.insideRun:
        yardsGained = _generateInsideRunYardsImproved(gameState);
        timeElapsed = Duration(seconds: 25 + _random.nextInt(21));
        isTurnover = _shouldFumbleImproved();
        break;
        
      case OffensiveRunPlay.outsideRun:
        yardsGained = _generateOutsideRunYardsImproved(gameState);
        timeElapsed = Duration(seconds: 20 + _random.nextInt(26));
        isTurnover = _shouldFumbleImproved();
        break;
        
      case OffensiveRunPlay.jetSweep:
        yardsGained = _generateJetSweepYardsImproved(gameState);
        timeElapsed = Duration(seconds: 15 + _random.nextInt(21));
        isTurnover = _shouldFumbleImproved();
        break;
        
      case OffensiveRunPlay.readOption:
        yardsGained = _generateReadOptionYardsImproved(gameState);
        timeElapsed = Duration(seconds: 20 + _random.nextInt(21));
        isTurnover = _shouldReadOptionTurnoverImproved();
        break;
        
      case OffensiveRunPlay.qbRun:
        yardsGained = _generateQBRunYardsImproved(gameState);
        timeElapsed = Duration(seconds: 15 + _random.nextInt(31));
        isTurnover = _shouldQBTurnoverImproved();
        break;
    }
    
    final distanceToGoal = 100 - gameState.yardLine;
    final isScore = yardsGained >= distanceToGoal;
    final isFirstDown = !isScore && yardsGained >= gameState.yardsToGo;
    final stopClock = isScore || isTurnover;
    
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

  /// REALISM IMPROVEMENT: Improved passing play simulation
  PlayResult _simulatePassPlayByTypeImproved(GameState gameState, OffensivePassPlay passPlay, Team offensiveTeam, Team defensiveTeam) {
    int yardsGained;
    Duration timeElapsed;
    bool isTurnover = false;
    bool stopClock = false;
    
    switch (passPlay) {
      case OffensivePassPlay.hailMary:
        yardsGained = _generateHailMaryYardsImproved(gameState);
        timeElapsed = Duration(seconds: 8 + _random.nextInt(8));
        isTurnover = _shouldHailMaryTurnoverImproved();
        stopClock = true;
        break;
        
      case OffensivePassPlay.deepPass:
        yardsGained = _generateDeepPassYardsImproved(gameState);
        timeElapsed = Duration(seconds: 6 + _random.nextInt(10));
        isTurnover = _shouldDeepPassTurnoverImproved();
        stopClock = _shouldPassStopClock();
        break;
        
      case OffensivePassPlay.mediumPass:
        yardsGained = _generateMediumPassYardsImproved(gameState);
        timeElapsed = Duration(seconds: 5 + _random.nextInt(8));
        isTurnover = _shouldMediumPassTurnoverImproved();
        stopClock = _shouldPassStopClock();
        break;
        
      case OffensivePassPlay.shortPass:
        yardsGained = _generateShortPassYardsImproved(gameState);
        timeElapsed = Duration(seconds: 4 + _random.nextInt(8));
        isTurnover = _shouldShortPassTurnoverImproved();
        stopClock = _shouldPassStopClock();
        break;
        
      case OffensivePassPlay.wrScreen:
        yardsGained = _generateWRScreenYardsImproved(gameState);
        timeElapsed = Duration(seconds: 6 + _random.nextInt(15));
        isTurnover = _shouldScreenTurnoverImproved();
        stopClock = _shouldPassStopClock();
        break;
        
      case OffensivePassPlay.rbScreen:
        yardsGained = _generateRBScreenYardsImproved(gameState);
        timeElapsed = Duration(seconds: 8 + _random.nextInt(17));
        isTurnover = _shouldScreenTurnoverImproved();
        stopClock = _shouldPassStopClock();
        break;
    }
    
    final distanceToGoal = 100 - gameState.yardLine;
    final isScore = yardsGained >= distanceToGoal;
    final isFirstDown = !isScore && yardsGained >= gameState.yardsToGo;
    
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

  /// REALISM IMPROVEMENT: Improved special teams with reduced field goal accuracy
  PlayResult _simulateSpecialTeamsPlayImproved(GameState gameState, SpecialTeamsPlay specialPlay, Team offensiveTeam, Team defensiveTeam) {
    switch (specialPlay) {
      case SpecialTeamsPlay.kickFG:
        return _simulateFieldGoalImproved(gameState, offensiveTeam, defensiveTeam);
      case SpecialTeamsPlay.punt:
        return _simulatePuntImproved(gameState, offensiveTeam, defensiveTeam);
    }
  }

  // REALISM IMPROVEMENT: Reduced yard gains for all running play types

  int _generatePowerRunYardsImproved(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYardsImproved();
    }
    
    final roll = _random.nextInt(100);
    if (roll < 8) {
      return -1 - _random.nextInt(3); // Reduced loss range
    } else if (roll < 18) {
      return _random.nextInt(2);
    } else if (roll < 75) {
      return 2 + _random.nextInt(3); // Reduced from 4 to 3
    } else if (roll < 92) {
      return 5 + _random.nextInt(4); // Reduced from 5 to 4
    } else {
      return 9 + _random.nextInt(6); // Reduced significantly
    }
  }

  int _generateInsideRunYardsImproved(GameState gameState) {
    return _generateRunYardsImproved(gameState);
  }

  int _generateOutsideRunYardsImproved(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYardsImproved();
    }
    
    final roll = _random.nextInt(100);
    if (roll < 18) {
      return -2 - _random.nextInt(3); // Reduced loss range
    } else if (roll < 28) {
      return _random.nextInt(2);
    } else if (roll < 55) {
      return 2 + _random.nextInt(4); // Reduced max
    } else if (roll < 78) {
      return 6 + _random.nextInt(6); // Reduced max
    } else if (roll < 92) {
      return 12 + _random.nextInt(8); // Reduced max
    } else {
      return 20 + _random.nextInt(25); // Significantly reduced
    }
  }

  int _generateJetSweepYardsImproved(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 12) {
      return -3 - _random.nextInt(4);
    } else if (roll < 22) {
      return _random.nextInt(3);
    } else if (roll < 50) {
      return 3 + _random.nextInt(6); // Reduced max
    } else if (roll < 75) {
      return 9 + _random.nextInt(8); // Reduced max
    } else if (roll < 88) {
      return 17 + _random.nextInt(10); // Reduced max
    } else {
      return 27 + _random.nextInt(20); // Significantly reduced
    }
  }

  int _generateReadOptionYardsImproved(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 10) {
      return -1 - _random.nextInt(3);
    } else if (roll < 20) {
      return _random.nextInt(3);
    } else if (roll < 60) {
      return 3 + _random.nextInt(4); // Reduced max
    } else if (roll < 82) {
      return 7 + _random.nextInt(6); // Reduced max
    } else if (roll < 96) {
      return 13 + _random.nextInt(8); // Reduced max
    } else {
      return 21 + _random.nextInt(20); // Significantly reduced
    }
  }

  int _generateQBRunYardsImproved(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 8) {
      return -2 - _random.nextInt(4);
    } else if (roll < 18) {
      return _random.nextInt(3);
    } else if (roll < 55) {
      return 3 + _random.nextInt(5); // Reduced max
    } else if (roll < 78) {
      return 8 + _random.nextInt(6); // Reduced max
    } else if (roll < 92) {
      return 14 + _random.nextInt(8); // Reduced max
    } else {
      return 22 + _random.nextInt(18); // Significantly reduced
    }
  }

  // REALISM IMPROVEMENT: Reduced passing yards and increased incompletions

  int _generateHailMaryYardsImproved(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    final roll = _random.nextInt(100);
    
    if (roll < 85) {
      return 0; // Increased incompletion rate (was 80%)
    } else if (roll < 97) {
      return _random.nextInt(distanceToGoal ~/ 2) + (distanceToGoal ~/ 4);
    } else {
      return distanceToGoal;
    }
  }

  int _generateDeepPassYardsImproved(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 55) {
      return 0; // Increased incompletion rate (was 50%)
    } else if (roll < 78) {
      return 18 + _random.nextInt(12); // Reduced range (was 20-35)
    } else if (roll < 92) {
      return 30 + _random.nextInt(12); // Reduced range (was 36-50)
    } else {
      return 42 + _random.nextInt(20); // Reduced range (was 51-80)
    }
  }

  int _generateMediumPassYardsImproved(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 40) {
      return 0; // Increased incompletion rate (was 35%)
    } else if (roll < 72) {
      return 8 + _random.nextInt(5); // Reduced range (was 10-15)
    } else if (roll < 92) {
      return 13 + _random.nextInt(4); // Reduced range (was 16-20)
    } else {
      return 17 + _random.nextInt(10); // Reduced range (was 21-35)
    }
  }

  int _generateShortPassYardsImproved(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 25) {
      return 0; // Increased incompletion rate (was 20%)
    } else if (roll < 65) {
      return 2 + _random.nextInt(4); // Reduced range (was 3-7)
    } else if (roll < 88) {
      return 6 + _random.nextInt(5); // Reduced range (was 8-14)
    } else {
      return 11 + _random.nextInt(12); // Reduced range (was 15-34)
    }
  }

  int _generateWRScreenYardsImproved(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 18) {
      return -2 - _random.nextInt(3); // Reduced loss range
    } else if (roll < 32) {
      return _random.nextInt(4);
    } else if (roll < 65) {
      return 4 + _random.nextInt(6); // Reduced max
    } else if (roll < 85) {
      return 10 + _random.nextInt(8); // Reduced max
    } else {
      return 18 + _random.nextInt(20); // Reduced max
    }
  }

  int _generateRBScreenYardsImproved(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 12) {
      return -1 - _random.nextInt(2);
    } else if (roll < 28) {
      return _random.nextInt(5);
    } else if (roll < 68) {
      return 5 + _random.nextInt(6); // Reduced max
    } else if (roll < 88) {
      return 11 + _random.nextInt(8); // Reduced max
    } else {
      return 19 + _random.nextInt(16); // Reduced max
    }
  }

  /// REALISM IMPROVEMENT: Reduced field goal accuracy to lower scoring
  PlayResult _simulateFieldGoalImproved(GameState gameState, Team offensiveTeam, Team defensiveTeam) {
    final distanceToGoal = 100 - gameState.yardLine;
    final kickDistance = distanceToGoal + 17;
    
    // REALISM IMPROVEMENT: Reduced field goal success rates by ~10-15%
    bool isGood;
    if (kickDistance <= 30) {
      isGood = _random.nextInt(100) < 88; // Reduced from 95% to 88%
    } else if (kickDistance <= 40) {
      isGood = _random.nextInt(100) < 75; // Reduced from 85% to 75%
    } else if (kickDistance <= 50) {
      isGood = _random.nextInt(100) < 58; // Reduced from 70% to 58%
    } else if (kickDistance <= 60) {
      isGood = _random.nextInt(100) < 28; // Reduced from 40% to 28%
    } else {
      isGood = _random.nextInt(100) < 12; // Reduced from 20% to 12%
    }
    
    final kicker = _selectKicker(offensiveTeam);
    final defender = _selectDefender(defensiveTeam, preferredPosition: 'DT');
    final involvedPlayers = _selectSpecialTeamsPlayers(offensiveTeam, defensiveTeam);
    
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

  /// Improved punt simulation (mostly unchanged as punts don't affect scoring much)
  PlayResult _simulatePuntImproved(GameState gameState, Team offensiveTeam, Team defensiveTeam) {
    final distanceToGoal = 100 - gameState.yardLine;
    
    int puntYards;
    if (distanceToGoal > 60) {
      puntYards = 40 + _random.nextInt(21);
    } else if (distanceToGoal > 40) {
      puntYards = 35 + _random.nextInt(16);
    } else {
      puntYards = 25 + _random.nextInt(16);
    }
    
    puntYards = puntYards.clamp(0, distanceToGoal);
    final isBlocked = _random.nextInt(200) == 0;
    
    final punter = _selectPunter(offensiveTeam);
    final defender = _selectDefender(defensiveTeam, preferredPosition: 'S');
    final involvedPlayers = _selectSpecialTeamsPlayers(offensiveTeam, defensiveTeam);
    
    if (isBlocked) {
      final blocker = _selectDefender(defensiveTeam, preferredPosition: 'DE');
      
      return PlayResult(
        playType: PlayType.punt,
        yardsGained: -5 - _random.nextInt(11),
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
      isTurnover: true,
      isScore: false,
      isFirstDown: false,
      stopClock: true,
      primaryPlayer: punter,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }

  /// Defensive modifications (kept similar but with awareness of reduced offensive output)
  PlayResult _applyDefensiveModifications(
    PlayResult baseResult,
    PlayCall offensivePlay,
    DefensivePlay defensivePlay
  ) {
    int modifiedYards = baseResult.yardsGained;
    bool modifiedTurnover = baseResult.isTurnover;
    Duration modifiedTime = baseResult.timeElapsed;
    
    switch (defensivePlay) {
      case DefensivePlay.balanced:
        modifiedYards = _applyBalancedDefense(modifiedYards, offensivePlay);
        break;
        
      case DefensivePlay.blitz:
        final blitzResult = _applyBlitzDefense(modifiedYards, modifiedTurnover, offensivePlay);
        modifiedYards = blitzResult.$1;
        modifiedTurnover = blitzResult.$2;
        break;
        
      case DefensivePlay.defendPass:
        modifiedYards = _applyPassDefense(modifiedYards, offensivePlay);
        modifiedTurnover = _applyPassDefenseTurnover(modifiedTurnover, offensivePlay);
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

    modifiedYards = modifiedYards.clamp(-15, modifiedYards);
    
    final distanceToGoal = 100 - (baseResult.yardsGained - modifiedYards);
    final isScore = modifiedYards >= distanceToGoal && modifiedYards > 0;
    final isFirstDown = !isScore && !modifiedTurnover && modifiedYards >= 10;
    
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

  // Defensive modification methods (unchanged for brevity, but could be further tuned)
  int _applyBalancedDefense(int baseYards, PlayCall offensivePlay) {
    final adjustment = _random.nextInt(3) - 1;
    return baseYards + adjustment;
  }

  (int, bool) _applyBlitzDefense(int baseYards, bool baseTurnover, PlayCall offensivePlay) {
    if (offensivePlay.isPass) {
      final blitzSuccess = _random.nextInt(100) < 30;
      
      if (blitzSuccess) {
        final sackYards = -3 - _random.nextInt(8);
        final forcedTurnover = _random.nextInt(100) < 15;
        return (sackYards, baseTurnover || forcedTurnover);
      } else {
        final extraYards = 2 + _random.nextInt(6);
        return (baseYards + extraYards, baseTurnover);
      }
    } else if (offensivePlay.isRun) {
      final runDefense = _random.nextInt(100) < 40;
      
      if (runDefense) {
        final reduction = 1 + _random.nextInt(3);
        return (baseYards - reduction, baseTurnover);
      } else {
        final extraYards = 1 + _random.nextInt(4);
        return (baseYards + extraYards, baseTurnover);
      }
    }
    
    return (baseYards, baseTurnover);
  }

  int _applyPassDefense(int baseYards, PlayCall offensivePlay) {
    if (offensivePlay.isPass) {
      final passDefenseSuccess = _random.nextInt(100) < 60;
      
      if (passDefenseSuccess) {
        final reduction = (baseYards * 0.3).round() + _random.nextInt(3);
        return baseYards - reduction;
      }
    } else if (offensivePlay.isRun) {
      final extraYards = 1 + _random.nextInt(4);
      return baseYards + extraYards;
    }
    
    return baseYards;
  }

  bool _applyPassDefenseTurnover(bool baseTurnover, PlayCall offensivePlay) {
    if (offensivePlay.isPass && !baseTurnover) {
      final intChance = _random.nextInt(100) < 8;
      return intChance;
    }
    return baseTurnover;
  }

  int _applyRunDefense(int baseYards, PlayCall offensivePlay) {
    if (offensivePlay.isRun) {
      final runDefenseSuccess = _random.nextInt(100) < 70;
      
      if (runDefenseSuccess) {
        final reduction = (baseYards * 0.4).round() + _random.nextInt(2);
        return baseYards - reduction;
      }
    } else if (offensivePlay.isPass) {
      final extraYards = 1 + _random.nextInt(3);
      return baseYards + extraYards;
    }
    
    return baseYards;
  }

  int _applyPreventDefense(int baseYards, PlayCall offensivePlay) {
    if (baseYards > 15) {
      final bigPlayStop = _random.nextInt(100) < 75;
      
      if (bigPlayStop) {
        final cappedYards = 8 + _random.nextInt(8);
        return cappedYards;
      }
    } else if (baseYards > 0 && baseYards <= 8) {
      final extraYards = 1 + _random.nextInt(3);
      return baseYards + extraYards;
    }
    
    return baseYards;
  }

  int _applyStackTheBoxDefense(int baseYards, PlayCall offensivePlay) {
    if (offensivePlay.isRun) {
      final stackSuccess = _random.nextInt(100) < 75;
      
      if (stackSuccess) {
        final reduction = (baseYards * 0.5).round() + _random.nextInt(3);
        return (baseYards - reduction).clamp(-5, baseYards);
      }
    } else if (offensivePlay.isPass) {
      if (offensivePlay.passPlay == OffensivePassPlay.deepPass || 
          offensivePlay.passPlay == OffensivePassPlay.hailMary) {
        final extraYards = 3 + _random.nextInt(8);
        return baseYards + extraYards;
      } else {
        final extraYards = 1 + _random.nextInt(4);
        return baseYards + extraYards;
      }
    }
    
    return baseYards;
  }
}
