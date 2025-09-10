import 'dart:math';
import '../models/game_state.dart';
import '../models/play_result.dart';
import '../models/play_call.dart';

/// Service responsible for simulating individual football plays.
/// 
/// This class handles the simulation of different types of plays and generates
/// realistic outcomes based on game situation and statistical probabilities.
class PlaySimulator {
  final Random _random = Random();

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
  PlayResult simulateRunPlay(GameState gameState) {
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
  PlayResult simulatePlay(GameState gameState, PlayCall playCall) {
    if (playCall.isRun) {
      return _simulateRunPlayByType(gameState, playCall.runPlay!);
    } else if (playCall.isPass) {
      return _simulatePassPlayByType(gameState, playCall.passPlay!);
    } else if (playCall.isSpecialTeams) {
      return _simulateSpecialTeamsPlay(gameState, playCall.specialTeamsPlay!);
    }
    
    // Fallback to basic run if somehow no valid play type
    return simulateRunPlay(gameState);
  }

  /// Simulates a play with both offensive and defensive calls.
  /// 
  /// The defensive play call modifies the outcome of the offensive play,
  /// creating realistic interactions between offensive and defensive strategies.
  /// This is the primary method for simulating plays in a full game context.
  PlayResult simulatePlayWithDefense(
    GameState gameState, 
    PlayCall offensivePlay, 
    PlayCall defensivePlay
  ) {
    // First simulate the base offensive play
    PlayResult baseResult = simulatePlay(gameState, offensivePlay);
    
    // Then apply defensive modifications
    if (defensivePlay.isDefense) {
      return _applyDefensiveModifications(baseResult, offensivePlay, defensivePlay.defensivePlay!);
    }
    
    // If no defensive play provided, return base result
    return baseResult;
  }

  /// Generates realistic yards gained for a running play.
  /// 
  /// Uses weighted distribution to favor realistic outcomes:
  /// - Most runs gain 1-8 yards
  /// - Occasional short losses (-1 to -3 yards)
  /// - Rare long gains (15+ yards)
  /// - Considers field position for goal line situations
  int _generateRunYards(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    
    // Goal line situations: limited upside, more conservative
    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYards();
    }
    
    // Normal field position: full range of possibilities
    return _generateNormalRunYards();
  }

  /// Generates yards for goal line running situations.
  /// 
  /// Goal line runs have different dynamics:
  /// - Limited big play potential
  /// - Higher chance of short gains
  /// - Possible stuffs for loss
  int _generateGoalLineRunYards() {
    final roll = _random.nextInt(100);
    
    if (roll < 10) {
      // 10% chance of loss
      return -1 - _random.nextInt(3); // -1 to -3 yards
    } else if (roll < 40) {
      // 30% chance of no gain or 1 yard
      return _random.nextInt(2); // 0 to 1 yards
    } else if (roll < 80) {
      // 40% chance of short gain
      return 2 + _random.nextInt(3); // 2 to 4 yards
    } else {
      // 20% chance of bigger gain
      return 5 + _random.nextInt(6); // 5 to 10 yards
    }
  }

  /// Generates yards for normal field position running plays.
  /// 
  /// Uses realistic NFL running statistics:
  /// - Average run: ~4.5 yards
  /// - Distribution favors 1-8 yard gains
  /// - Occasional losses and big plays
  int _generateNormalRunYards() {
    final roll = _random.nextInt(100);
    
    if (roll < 8) {
      // 8% chance of loss
      return -1 - _random.nextInt(5); // -1 to -5 yards
    } else if (roll < 15) {
      // 7% chance of no gain
      return 0;
    } else if (roll < 60) {
      // 45% chance of short gain (1-5 yards)
      return 1 + _random.nextInt(5); // 1 to 5 yards
    } else if (roll < 85) {
      // 25% chance of medium gain (6-12 yards)
      return 6 + _random.nextInt(7); // 6 to 12 yards
    } else if (roll < 95) {
      // 10% chance of long gain (13-25 yards)
      return 13 + _random.nextInt(13); // 13 to 25 yards
    } else {
      // 5% chance of breakaway run (26+ yards)
      return 26 + _random.nextInt(55); // 26 to 80 yards
    }
  }

  /// Simulates a specific type of running play based on the play call.
  /// 
  /// Different run plays have different characteristics:
  /// - Power runs: higher chance of short gains, lower big play potential
  /// - Outside runs: higher variance, more big plays or losses
  /// - QB runs: different dynamics based on mobility
  PlayResult _simulateRunPlayByType(GameState gameState, OffensiveRunPlay runPlay) {
    int yardsGained;
    Duration timeElapsed;
    bool isTurnover = false;
    
    switch (runPlay) {
      case OffensiveRunPlay.powerRun:
        yardsGained = _generatePowerRunYards(gameState);
        timeElapsed = Duration(seconds: 25 + _random.nextInt(16)); // 25-40s
        isTurnover = _shouldFumble();
        break;
        
      case OffensiveRunPlay.insideRun:
        yardsGained = _generateInsideRunYards(gameState);
        timeElapsed = Duration(seconds: 25 + _random.nextInt(21)); // 25-45s
        isTurnover = _shouldFumble();
        break;
        
      case OffensiveRunPlay.outsideRun:
        yardsGained = _generateOutsideRunYards(gameState);
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

  /// Simulates a specific type of passing play based on the play call.
  /// 
  /// Different pass plays have different characteristics:
  /// - Deep passes: high risk/reward, more variance
  /// - Short passes: reliable, consistent gains
  /// - Screens: potential for big gains with good blocking
  PlayResult _simulatePassPlayByType(GameState gameState, OffensivePassPlay passPlay) {
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
        yardsGained = _generateShortPassYards(gameState);
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
    
    return PlayResult(
      playType: PlayType.pass,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed,
      isTurnover: isTurnover,
      isScore: isScore,
      isFirstDown: isFirstDown,
      stopClock: stopClock || isScore || isTurnover,
    );
  }

  /// Simulates special teams plays (field goals and punts).
  PlayResult _simulateSpecialTeamsPlay(GameState gameState, SpecialTeamsPlay specialPlay) {
    switch (specialPlay) {
      case SpecialTeamsPlay.kickFG:
        return _simulateFieldGoal(gameState);
      case SpecialTeamsPlay.punt:
        return _simulatePunt(gameState);
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
  
  /// Power runs emphasize short, consistent gains with low variance
  int _generatePowerRunYards(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    
    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYards();
    }
    
    final roll = _random.nextInt(100);
    if (roll < 5) {
      return -1 - _random.nextInt(3); // Loss
    } else if (roll < 15) {
      return _random.nextInt(2); // 0-1 yards
    } else if (roll < 70) {
      return 2 + _random.nextInt(4); // 2-5 yards (emphasis on short gains)
    } else if (roll < 90) {
      return 6 + _random.nextInt(5); // 6-10 yards
    } else {
      return 11 + _random.nextInt(10); // 11-20 yards
    }
  }

  /// Inside runs attack the middle, moderate variance
  int _generateInsideRunYards(GameState gameState) {
    return _generateRunYards(gameState); // Use existing method as baseline
  }

  /// Outside runs have higher variance - big plays or losses
  int _generateOutsideRunYards(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    
    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYards();
    }
    
    final roll = _random.nextInt(100);
    if (roll < 15) {
      return -2 - _random.nextInt(4); // Higher chance of loss
    } else if (roll < 25) {
      return _random.nextInt(2); // 0-1 yards
    } else if (roll < 50) {
      return 2 + _random.nextInt(6); // 2-7 yards
    } else if (roll < 75) {
      return 8 + _random.nextInt(8); // 8-15 yards
    } else if (roll < 90) {
      return 16 + _random.nextInt(15); // 16-30 yards
    } else {
      return 31 + _random.nextInt(50); // 31-80 yards (breakaway potential)
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

  /// Deep pass (20+ yards)
  int _generateDeepPassYards(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 50) {
      return 0; // Incomplete
    } else if (roll < 75) {
      return 20 + _random.nextInt(16); // 20-35 yards
    } else if (roll < 90) {
      return 36 + _random.nextInt(15); // 36-50 yards
    } else {
      return 51 + _random.nextInt(30); // 51-80 yards
    }
  }

  /// Medium pass (10-20 yards)
  int _generateMediumPassYards(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 35) {
      return 0; // Incomplete
    } else if (roll < 70) {
      return 10 + _random.nextInt(6); // 10-15 yards
    } else if (roll < 90) {
      return 16 + _random.nextInt(5); // 16-20 yards
    } else {
      return 21 + _random.nextInt(15); // 21-35 yards (YAC)
    }
  }

  /// Short pass (under 10 yards)
  int _generateShortPassYards(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 20) {
      return 0; // Incomplete
    } else if (roll < 60) {
      return 3 + _random.nextInt(5); // 3-7 yards
    } else if (roll < 85) {
      return 8 + _random.nextInt(7); // 8-14 yards
    } else {
      return 15 + _random.nextInt(20); // 15-34 yards (YAC breakaway)
    }
  }

  /// WR Screen - relies on blocking setup
  int _generateWRScreenYards(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 15) {
      return -2 - _random.nextInt(4); // Loss if defense reads it
    } else if (roll < 30) {
      return _random.nextInt(4); // 0-3 yards
    } else if (roll < 60) {
      return 4 + _random.nextInt(8); // 4-11 yards
    } else if (roll < 80) {
      return 12 + _random.nextInt(13); // 12-24 yards
    } else {
      return 25 + _random.nextInt(35); // 25-59 yards (big play)
    }
  }

  /// RB Screen - similar to WR but different timing
  int _generateRBScreenYards(GameState gameState) {
    final roll = _random.nextInt(100);
    if (roll < 10) {
      return -1 - _random.nextInt(3); // Loss
    } else if (roll < 25) {
      return _random.nextInt(5); // 0-4 yards
    } else if (roll < 65) {
      return 5 + _random.nextInt(8); // 5-12 yards
    } else if (roll < 85) {
      return 13 + _random.nextInt(12); // 13-24 yards
    } else {
      return 25 + _random.nextInt(30); // 25-54 yards
    }
  }

  /// Field goal simulation
  PlayResult _simulateFieldGoal(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    final kickDistance = distanceToGoal + 17; // Add 10 for end zone + 7 for snap
    
    // Success rate based on distance
    bool isGood;
    if (kickDistance <= 30) {
      isGood = _random.nextInt(100) < 95; // 95% success
    } else if (kickDistance <= 40) {
      isGood = _random.nextInt(100) < 85; // 85% success
    } else if (kickDistance <= 50) {
      isGood = _random.nextInt(100) < 70; // 70% success
    } else if (kickDistance <= 60) {
      isGood = _random.nextInt(100) < 40; // 40% success
    } else {
      isGood = _random.nextInt(100) < 20; // 20% success (very long)
    }
    
    return PlayResult(
      playType: PlayType.fieldGoal,
      yardsGained: 0,
      timeElapsed: Duration(seconds: 5),
      isTurnover: false,
      isScore: isGood,
      isFirstDown: false,
      stopClock: true,
    );
  }

  /// Punt simulation
  PlayResult _simulatePunt(GameState gameState) {
    final distanceToGoal = 100 - gameState.yardLine;
    
    // Punt distance varies by field position
    int puntYards;
    if (distanceToGoal > 60) {
      puntYards = 40 + _random.nextInt(21); // 40-60 yards
    } else if (distanceToGoal > 40) {
      puntYards = 35 + _random.nextInt(16); // 35-50 yards
    } else {
      puntYards = 25 + _random.nextInt(16); // 25-40 yards (shorter field)
    }
    
    // Ensure punt doesn't go past opponent goal line
    puntYards = puntYards.clamp(0, distanceToGoal);
    
    // Small chance of blocked punt
    final isBlocked = _random.nextInt(200) == 0; // 0.5% chance
    
    if (isBlocked) {
      return PlayResult(
        playType: PlayType.punt,
        yardsGained: -5 - _random.nextInt(11), // Loss on blocked punt
        timeElapsed: Duration(seconds: 3),
        isTurnover: true,
        isScore: false,
        isFirstDown: false,
        stopClock: true,
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
    DefensivePlay defensivePlay
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

    // Ensure yards don't become unrealistically negative
    modifiedYards = modifiedYards.clamp(-15, modifiedYards);
    
    // Recalculate dependent fields based on modified yards
    final distanceToGoal = 100 - (baseResult.yardsGained - modifiedYards); // Approximate field position
    final isScore = modifiedYards >= distanceToGoal && modifiedYards > 0;
    final isFirstDown = !isScore && !modifiedTurnover && modifiedYards >= 10; // Simplified first down check
    
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

  /// Balanced defense provides neutral modifications against all play types
  int _applyBalancedDefense(int baseYards, PlayCall offensivePlay) {
    // Balanced defense doesn't heavily favor stopping any particular play type
    // Apply small random variance (-1 to +1 yards)
    final adjustment = _random.nextInt(3) - 1; // -1, 0, or 1
    return baseYards + adjustment;
  }

  /// Blitz defense increases pressure but leaves coverage vulnerable
  (int, bool) _applyBlitzDefense(int baseYards, bool baseTurnover, PlayCall offensivePlay) {
    if (offensivePlay.isPass) {
      // Blitz is effective against pass plays - higher chance of sacks/pressure
      final blitzSuccess = _random.nextInt(100) < 30; // 30% chance of significant pressure
      
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
      final runDefense = _random.nextInt(100) < 40; // 40% chance blitz still helps
      
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
      final passDefenseSuccess = _random.nextInt(100) < 60; // 60% chance of good coverage
      
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
      final runDefenseSuccess = _random.nextInt(100) < 70; // 70% chance of good run stop
      
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
      final bigPlayStop = _random.nextInt(100) < 75; // 75% chance to limit big plays
      
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
      final stackSuccess = _random.nextInt(100) < 75; // 75% chance of good run stop
      
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
