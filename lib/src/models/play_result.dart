import 'package:pocket_gm_generator/src/models/player.dart';

/// Represents the outcome of a single football play.
/// 
/// This class captures all the information needed to update the game state
/// after a play has been executed, including yards gained, time elapsed,
/// and any special outcomes like turnovers or scores.
class PlayResult {
  /// The type of play that was executed
  final PlayType playType;
  
  /// Yards gained (positive) or lost (negative) on the play
  final int yardsGained;
  
  /// Time that elapsed during the play
  final Duration timeElapsed;
  
  /// Whether the play resulted in a turnover
  final bool isTurnover;
  
  /// Whether the play resulted in a score (touchdown or safety)
  final bool isScore;
  
  /// The number of points scored on this play (0 if no score)
  final int pointsScored;
  
  /// Whether the play resulted in a first down
  final bool isFirstDown;
  
  /// Whether the clock should stop after this play
  final bool stopClock;
  
  /// Optional description of what happened on the play
  final String? description;
  
  /// The player who executed the play (rusher, passer, kicker, etc.)
  final Player? primaryPlayer;
  
  /// The target player for passes (receiver) or null for other plays
  final Player? targetPlayer;
  
  /// The defending player who made the tackle/caused turnover (if any)
  final Player? defender;
  
  /// Additional players involved in the play (blockers, coverage, etc.)
  final List<Player> involvedPlayers;
  
  const PlayResult({
    required this.playType,
    required this.yardsGained,
    required this.timeElapsed,
    this.isTurnover = false,
    this.isScore = false,
    this.pointsScored = 0,
    this.isFirstDown = false,
    this.stopClock = false,
    this.description,
    this.primaryPlayer,
    this.targetPlayer,
    this.defender,
    this.involvedPlayers = const [],
  });
  
  /// Creates a simple rushing play result
  factory PlayResult.rush({
    required int yardsGained,
    Duration? timeElapsed,
    bool isFirstDown = false,
    String? description,
    Player? primaryPlayer,
    Player? defender,
    List<Player> involvedPlayers = const [],
  }) {
    return PlayResult(
      playType: PlayType.rush,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed ?? const Duration(seconds: 6), // Typical play duration
      isFirstDown: isFirstDown,
      stopClock: false, // Rush plays typically don't stop the clock
      description: description,
      primaryPlayer: primaryPlayer,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }
  
  /// Creates a simple passing play result
  factory PlayResult.pass({
    required int yardsGained,
    Duration? timeElapsed,
    bool isFirstDown = false,
    bool isComplete = true,
    String? description,
    Player? primaryPlayer,
    Player? targetPlayer,
    Player? defender,
    List<Player> involvedPlayers = const [],
  }) {
    return PlayResult(
      playType: PlayType.pass,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed ?? const Duration(seconds: 8), // Typical pass play duration
      isFirstDown: isFirstDown,
      stopClock: !isComplete, // Incomplete passes stop the clock
      description: description,
      primaryPlayer: primaryPlayer,
      targetPlayer: targetPlayer,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }
  
  /// Creates a turnover result
  factory PlayResult.turnover({
    required PlayType playType,
    required int yardsGained,
    Duration? timeElapsed,
    String? description,
    Player? primaryPlayer,
    Player? targetPlayer,
    Player? defender,
    List<Player> involvedPlayers = const [],
  }) {
    return PlayResult(
      playType: playType,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed ?? const Duration(seconds: 5),
      isTurnover: true,
      stopClock: true, // Turnovers stop the clock
      description: description,
      primaryPlayer: primaryPlayer,
      targetPlayer: targetPlayer,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }
  
  /// Creates a touchdown result
  factory PlayResult.touchdown({
    required PlayType playType,
    required int yardsGained,
    Duration? timeElapsed,
    String? description,
    Player? primaryPlayer,
    Player? targetPlayer,
    Player? defender,
    List<Player> involvedPlayers = const [],
  }) {
    return PlayResult(
      playType: playType,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed ?? const Duration(seconds: 10),
      isScore: true,
      pointsScored: 6, // Touchdowns are worth 6 points
      stopClock: true, // Scores stop the clock
      description: description,
      primaryPlayer: primaryPlayer,
      targetPlayer: targetPlayer,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }
  
  /// Creates a field goal result
  factory PlayResult.fieldGoal({
    required int yardsGained,
    Duration? timeElapsed,
    bool isGood = true,
    String? description,
    Player? primaryPlayer,
    List<Player> involvedPlayers = const [],
  }) {
    return PlayResult(
      playType: PlayType.fieldGoal,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed ?? const Duration(seconds: 5),
      isScore: isGood,
      pointsScored: isGood ? 3 : 0, // Field goals are worth 3 points if successful
      stopClock: true, // Field goal attempts stop the clock
      description: description,
      primaryPlayer: primaryPlayer,
      involvedPlayers: involvedPlayers,
    );
  }
  
  /// Creates an extra point result
  factory PlayResult.extraPoint({
    required int yardsGained,
    Duration? timeElapsed,
    bool isGood = true,
    String? description,
    Player? primaryPlayer,
    List<Player> involvedPlayers = const [],
  }) {
    return PlayResult(
      playType: PlayType.extraPoint,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed ?? const Duration(seconds: 5),
      isScore: isGood,
      pointsScored: isGood ? 1 : 0, // Extra points are worth 1 point if successful
      stopClock: true, // Extra point attempts stop the clock
      description: description,
      primaryPlayer: primaryPlayer,
      involvedPlayers: involvedPlayers,
    );
  }
  
  /// Creates a safety result
  factory PlayResult.safety({
    required int yardsGained,
    Duration? timeElapsed,
    String? description,
    Player? primaryPlayer,
    Player? defender,
    List<Player> involvedPlayers = const [],
  }) {
    return PlayResult(
      playType: PlayType.rush, // Safeties can occur on various play types
      yardsGained: yardsGained,
      timeElapsed: timeElapsed ?? const Duration(seconds: 8),
      isScore: true,
      pointsScored: 2, // Safeties are worth 2 points
      stopClock: true, // Safeties stop the clock
      description: description,
      primaryPlayer: primaryPlayer,
      defender: defender,
      involvedPlayers: involvedPlayers,
    );
  }
  
  @override
  String toString() {
    final yards = yardsGained >= 0 ? '+$yardsGained' : '$yardsGained';
    final time = '${timeElapsed.inSeconds}s';
    final flags = <String>[];
    
    if (isTurnover) flags.add('TURNOVER');
    if (isScore) flags.add('SCORE ($pointsScored pts)');
    if (isFirstDown) flags.add('1ST DOWN');
    if (stopClock) flags.add('CLOCK STOPS');
    
    final flagsStr = flags.isNotEmpty ? ' [${flags.join(', ')}]' : '';
    
    // Build detailed player information
    final playerDetails = <String>[];
    if (primaryPlayer != null) {
      playerDetails.add('${_getPlayerRoleForPlayType(playType)}: ${primaryPlayer!.commonName}');
    }
    if (targetPlayer != null) {
      playerDetails.add('Target: ${targetPlayer!.commonName}');
    }
    if (defender != null) {
      playerDetails.add('Defender: ${defender!.commonName}');
    }
    
    final playerStr = playerDetails.isNotEmpty ? ' | ${playerDetails.join(', ')}' : '';
    
    return 'PlayResult(${playType.name.toUpperCase()}: $yards yards, $time$flagsStr$playerStr)';
  }
  
  /// Helper method to get the appropriate role label for the primary player based on play type
  String _getPlayerRoleForPlayType(PlayType type) {
    switch (type) {
      case PlayType.rush:
        return 'Rusher';
      case PlayType.pass:
        return 'Passer';
      case PlayType.punt:
        return 'Punter';
      case PlayType.fieldGoal:
      case PlayType.extraPoint:
        return 'Kicker';
      case PlayType.kickoff:
        return 'Kicker';
      case PlayType.kneel:
      case PlayType.spike:
        return 'QB';
      default:
        return 'Player';
    }
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PlayResult &&
        other.playType == playType &&
        other.yardsGained == yardsGained &&
        other.timeElapsed == timeElapsed &&
        other.isTurnover == isTurnover &&
        other.isScore == isScore &&
        other.isFirstDown == isFirstDown &&
        other.stopClock == stopClock &&
        other.description == description;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      playType,
      yardsGained,
      timeElapsed,
      isTurnover,
      isScore,
      isFirstDown,
      stopClock,
      description,
    );
  }
}

/// Enumeration of different types of football plays
enum PlayType {
  /// Running play
  rush,
  
  /// Passing play
  pass,
  
  /// Punt
  punt,
  
  /// Field goal attempt
  fieldGoal,
  
  /// Extra point attempt
  extraPoint,
  
  /// Kickoff
  kickoff,
  
  /// Kneel down
  kneel,
  
  /// Spike (intentional incomplete pass to stop clock)
  spike,
}
