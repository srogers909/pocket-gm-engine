import 'dart:math';
import '../models/game_state.dart';
import '../models/play_result.dart';

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
    final distanceToGoal = gameState.yardLine;
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

  /// Simulates any type of play based on game situation.
  /// 
  /// Currently defaults to running plays, but will be expanded
  /// to include passing, punting, and special teams plays.
  PlayResult simulatePlay(GameState gameState) {
    // For Phase 3, we only implement running plays
    return simulateRunPlay(gameState);
  }

  /// Generates realistic yards gained for a running play.
  /// 
  /// Uses weighted distribution to favor realistic outcomes:
  /// - Most runs gain 1-8 yards
  /// - Occasional short losses (-1 to -3 yards)
  /// - Rare long gains (15+ yards)
  /// - Considers field position for goal line situations
  int _generateRunYards(GameState gameState) {
    final distanceToGoal = gameState.yardLine;
    
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

  /// Determines if a fumble occurs on the play.
  /// 
  /// Fumbles are rare events that should happen occasionally
  /// but not frequently enough to be unrealistic.
  /// NFL average: ~1 fumble per 40-50 rushes
  bool _shouldFumble() {
    // Approximately 2% chance of fumble (1 in 50)
    return _random.nextInt(50) == 0;
  }
}
