/// Represents the complete state of an American football game at any given moment.
/// 
/// This class serves as the single source of truth for all game information,
/// including scores, clock, field position, and possession details.
class GameState {
  /// Home team score
  final int homeScore;
  
  /// Away team score  
  final int awayScore;
  
  /// Current quarter (1-4, with overtime as 5+)
  final int quarter;
  
  /// Time remaining in the current quarter
  final Duration gameClock;
  
  /// Current down (1-4)
  final int down;
  
  /// Yards needed for a first down
  final int yardsToGo;
  
  /// Current yard line (0-100, with 50 being midfield)
  /// Values 1-49 represent distance from the goal line the offense is attacking
  /// Values 51-99 represent distance from the goal line the offense is defending
  final int yardLine;
  
  /// True if home team has possession, false if away team has possession
  final bool homeTeamHasPossession;
  
  /// Timeouts remaining for home team
  final int homeTimeouts;
  
  /// Timeouts remaining for away team
  final int awayTimeouts;
  
  /// Whether the game is currently in progress
  final bool gameInProgress;
  
  const GameState({
    required this.homeScore,
    required this.awayScore,
    required this.quarter,
    required this.gameClock,
    required this.down,
    required this.yardsToGo,
    required this.yardLine,
    required this.homeTeamHasPossession,
    required this.homeTimeouts,
    required this.awayTimeouts,
    required this.gameInProgress,
  });
  
  /// Creates a new game state with the kickoff configuration
  factory GameState.kickoff() {
    return const GameState(
      homeScore: 0,
      awayScore: 0,
      quarter: 1,
      gameClock: Duration(minutes: 15), // 15 minutes per quarter
      down: 1,
      yardsToGo: 10,
      yardLine: 25, // Typical kickoff return position
      homeTeamHasPossession: false, // Away team typically receives kickoff
      homeTimeouts: 3,
      awayTimeouts: 3,
      gameInProgress: true,
    );
  }
  
  /// Creates a copy of this game state with modified values
  GameState copyWith({
    int? homeScore,
    int? awayScore,
    int? quarter,
    Duration? gameClock,
    int? down,
    int? yardsToGo,
    int? yardLine,
    bool? homeTeamHasPossession,
    int? homeTimeouts,
    int? awayTimeouts,
    bool? gameInProgress,
  }) {
    return GameState(
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      quarter: quarter ?? this.quarter,
      gameClock: gameClock ?? this.gameClock,
      down: down ?? this.down,
      yardsToGo: yardsToGo ?? this.yardsToGo,
      yardLine: yardLine ?? this.yardLine,
      homeTeamHasPossession: homeTeamHasPossession ?? this.homeTeamHasPossession,
      homeTimeouts: homeTimeouts ?? this.homeTimeouts,
      awayTimeouts: awayTimeouts ?? this.awayTimeouts,
      gameInProgress: gameInProgress ?? this.gameInProgress,
    );
  }
  
  /// Returns the score of the team currently in possession
  int get possessionTeamScore => homeTeamHasPossession ? homeScore : awayScore;
  
  /// Returns the score of the team not currently in possession  
  int get defensiveTeamScore => homeTeamHasPossession ? awayScore : homeScore;
  
  /// Returns true if the game is over
  bool get isGameOver => !gameInProgress;
  
  /// Returns true if this is overtime
  bool get isOvertime => quarter > 4;
  
  /// Returns a string representation of the current down and distance
  String get downAndDistance {
    return '${down}${_getOrdinalSuffix(down)} & $yardsToGo';
  }
  
  /// Helper method to get ordinal suffix for down number
  String _getOrdinalSuffix(int number) {
    switch (number) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      case 4:
        return 'th';
      default:
        return 'th';
    }
  }
  
  @override
  String toString() {
    final quarterStr = isOvertime ? 'OT' : 'Q$quarter';
    final time = '${gameClock.inMinutes}:${(gameClock.inSeconds % 60).toString().padLeft(2, '0')}';
    final possession = homeTeamHasPossession ? 'HOME' : 'AWAY';
    
    return 'GameState(${homeScore}-${awayScore}, $quarterStr $time, $downAndDistance at $yardLine, $possession possession)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is GameState &&
        other.homeScore == homeScore &&
        other.awayScore == awayScore &&
        other.quarter == quarter &&
        other.gameClock == gameClock &&
        other.down == down &&
        other.yardsToGo == yardsToGo &&
        other.yardLine == yardLine &&
        other.homeTeamHasPossession == homeTeamHasPossession &&
        other.homeTimeouts == homeTimeouts &&
        other.awayTimeouts == awayTimeouts &&
        other.gameInProgress == gameInProgress;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      homeScore,
      awayScore,
      quarter,
      gameClock,
      down,
      yardsToGo,
      yardLine,
      homeTeamHasPossession,
      homeTimeouts,
      awayTimeouts,
      gameInProgress,
    );
  }
}
