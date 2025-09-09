import '../models/game_state.dart';
import '../models/play_result.dart';

/// Manages downs and distance logic for a football game.
/// 
/// This service handles the core football rules around downs:
/// - Teams get 4 downs to advance 10 yards
/// - First down resets the down counter
/// - Turnover on downs when failing to get first down
class DownManager {
  /// Updates the down and distance based on a play result.
  /// 
  /// Returns a new [GameState] with updated down, yards to go, and yard line.
  /// Handles all standard football down progression rules.
  GameState updateDownAndDistance(GameState currentState, PlayResult playResult) {
    // If the game is over, don't update anything
    if (currentState.isGameOver) {
      return currentState;
    }
    
    // Handle turnovers - possession changes, reset to 1st and 10
    if (playResult.isTurnover) {
      return _handleTurnover(currentState, playResult);
    }
    
    // Handle scores - different logic depending on type of score
    if (playResult.isScore) {
      return _handleScore(currentState, playResult);
    }
    
    // Calculate new yard line
    final newYardLine = _calculateNewYardLine(currentState, playResult);
    
    // Check if we got a first down
    final yardsGained = playResult.yardsGained;
    final yardsNeededForFirstDown = currentState.yardsToGo;
    
    if (yardsGained >= yardsNeededForFirstDown || playResult.isFirstDown) {
      // First down achieved
      return currentState.copyWith(
        down: 1,
        yardsToGo: 10,
        yardLine: newYardLine,
      );
    }
    
    // No first down - advance to next down
    final newDown = currentState.down + 1;
    final newYardsToGo = yardsNeededForFirstDown - yardsGained;
    
    // Check for turnover on downs
    if (newDown > 4) {
      return _handleTurnoverOnDowns(currentState, newYardLine);
    }
    
    return currentState.copyWith(
      down: newDown,
      yardsToGo: newYardsToGo,
      yardLine: newYardLine,
    );
  }
  
  /// Calculates the new yard line after a play.
  /// 
  /// Takes into account field boundaries (1-99 yard field).
  /// Yard line represents distance from goal line - lower numbers are closer to goal.
  int _calculateNewYardLine(GameState currentState, PlayResult playResult) {
    // All teams move toward goal line (lower yard numbers)
    // Positive yards gained means getting closer to goal (lower yard line)
    final newYardLine = currentState.yardLine - playResult.yardsGained;
    
    // Ensure yard line stays within field boundaries (1-99)
    // If < 1, it's a touchdown. If > 99, it's a safety (rare)
    return newYardLine.clamp(1, 99);
  }
  
  /// Handles a turnover (fumble, interception, etc.).
  /// 
  /// Changes possession and resets to 1st and 10.
  GameState _handleTurnover(GameState currentState, PlayResult playResult) {
    final newYardLine = _calculateNewYardLine(currentState, playResult);
    
    // Flip the yard line for the new possession team
    final adjustedYardLine = 100 - newYardLine;
    
    return currentState.copyWith(
      down: 1,
      yardsToGo: 10,
      yardLine: adjustedYardLine,
      homeTeamHasPossession: !currentState.homeTeamHasPossession,
    );
  }
  
  /// Handles a scoring play.
  /// 
  /// For touchdowns, this would typically trigger a kickoff.
  /// For now, we'll just mark the score and prepare for next possession.
  GameState _handleScore(GameState currentState, PlayResult playResult) {
    final newYardLine = _calculateNewYardLine(currentState, playResult);
    
    // Add points to the scoring team
    int newHomeScore = currentState.homeScore;
    int newAwayScore = currentState.awayScore;
    
    if (currentState.homeTeamHasPossession) {
      newHomeScore += 7; // Touchdown (6) + Extra Point (1)
    } else {
      newAwayScore += 7;
    }
    
    // After a touchdown, the other team gets possession (kickoff)
    // For now, we'll place them at the 25-yard line (typical kickoff return)
    return currentState.copyWith(
      homeScore: newHomeScore,
      awayScore: newAwayScore,
      down: 1,
      yardsToGo: 10,
      yardLine: 25,
      homeTeamHasPossession: !currentState.homeTeamHasPossession,
    );
  }
  
  /// Handles turnover on downs (failed to get first down in 4 attempts).
  /// 
  /// Changes possession at the current spot.
  GameState _handleTurnoverOnDowns(GameState currentState, int yardLine) {
    // Flip the yard line for the new possession team
    final adjustedYardLine = 100 - yardLine;
    
    return currentState.copyWith(
      down: 1,
      yardsToGo: 10,
      yardLine: adjustedYardLine,
      homeTeamHasPossession: !currentState.homeTeamHasPossession,
    );
  }
  
  /// Determines if the offense is in the red zone (within 20 yards of goal).
  /// 
  /// Returns true if the team is in scoring position.
  bool isInRedZone(GameState gameState) {
    return gameState.yardLine <= 20;
  }
  
  /// Determines if the offense is in goal-to-go situation.
  /// 
  /// Returns true if the yards to go is less than the distance to the goal line.
  bool isGoalToGo(GameState gameState) {
    return gameState.yardsToGo >= gameState.yardLine;
  }
  
  /// Gets the effective yards to go (accounts for goal line).
  /// 
  /// In goal-to-go situations, the yards to go is effectively the yard line.
  int getEffectiveYardsToGo(GameState gameState) {
    if (isGoalToGo(gameState)) {
      return gameState.yardLine;
    }
    return gameState.yardsToGo;
  }
  
  /// Determines the field position category for strategic analysis.
  /// 
  /// Returns a descriptive string of the current field position.
  String getFieldPositionDescription(GameState gameState) {
    final yardLine = gameState.yardLine;
    
    if (yardLine <= 10) {
      return 'Goal Line';
    } else if (yardLine <= 20) {
      return 'Red Zone';
    } else if (yardLine <= 40) {
      return 'Scoring Territory';
    } else if (yardLine <= 60) {
      return 'Midfield';
    } else if (yardLine <= 80) {
      return 'Own Territory';
    } else {
      return 'Deep Own Territory';
    }
  }
}
