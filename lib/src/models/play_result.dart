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
  
  /// Whether the play resulted in a first down
  final bool isFirstDown;
  
  /// Whether the clock should stop after this play
  final bool stopClock;
  
  /// Optional description of what happened on the play
  final String? description;
  
  /// The player who executed the play (rusher, passer, kicker, etc.)
  final String? primaryPlayer;
  
  /// The target player for passes (receiver) or null for other plays
  final String? targetPlayer;
  
  /// The defending player who made the tackle/caused turnover (if any)
  final String? defender;
  
  /// Additional players involved in the play (blockers, coverage, etc.)
  final List<String> involvedPlayers;
  
  const PlayResult({
    required this.playType,
    required this.yardsGained,
    required this.timeElapsed,
    this.isTurnover = false,
    this.isScore = false,
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
    String? primaryPlayer,
    String? defender,
    List<String> involvedPlayers = const [],
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
    String? primaryPlayer,
    String? targetPlayer,
    String? defender,
    List<String> involvedPlayers = const [],
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
    String? primaryPlayer,
    String? targetPlayer,
    String? defender,
    List<String> involvedPlayers = const [],
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
    String? primaryPlayer,
    String? targetPlayer,
    String? defender,
    List<String> involvedPlayers = const [],
  }) {
    return PlayResult(
      playType: playType,
      yardsGained: yardsGained,
      timeElapsed: timeElapsed ?? const Duration(seconds: 10),
      isScore: true,
      stopClock: true, // Scores stop the clock
      description: description,
      primaryPlayer: primaryPlayer,
      targetPlayer: targetPlayer,
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
    if (isScore) flags.add('SCORE');
    if (isFirstDown) flags.add('1ST DOWN');
    if (stopClock) flags.add('CLOCK STOPS');
    
    final flagsStr = flags.isNotEmpty ? ' [${flags.join(', ')}]' : '';
    
    return 'PlayResult(${playType.name.toUpperCase()}: $yards yards, $time$flagsStr)';
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
