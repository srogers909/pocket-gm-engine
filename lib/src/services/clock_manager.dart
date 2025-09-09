import '../models/game_state.dart';
import '../models/play_result.dart';

/// Manages the game clock and time-related operations for a football game.
/// 
/// This service handles starting, stopping, and updating the game clock
/// based on play outcomes and football rules.
class ClockManager {
  /// Updates the game clock based on a play result.
  /// 
  /// Returns a new [GameState] with the updated clock time.
  /// The clock behavior follows standard NFL rules:
  /// - Clock runs after most plays
  /// - Clock stops for incomplete passes, out of bounds, timeouts, etc.
  /// - Clock stops when a quarter ends
  GameState updateClock(GameState currentState, PlayResult playResult) {
    // If the game is over, don't update the clock
    if (currentState.isGameOver) {
      return currentState;
    }
    
    Duration newClock;
    
    // If the clock should stop after this play, only subtract the play time
    if (playResult.stopClock) {
      newClock = currentState.gameClock - playResult.timeElapsed;
    } else {
      // Clock continues running - subtract more time for the delay between plays
      final totalTimeElapsed = playResult.timeElapsed + const Duration(seconds: 25); // Typical play clock
      newClock = currentState.gameClock - totalTimeElapsed;
    }
    
    // Ensure clock doesn't go negative
    if (newClock.isNegative) {
      newClock = Duration.zero;
    }
    
    return currentState.copyWith(gameClock: newClock);
  }
  
  /// Determines if the quarter should end based on the current clock.
  /// 
  /// Returns true if the quarter has ended (clock at 00:00).
  bool isQuarterEnded(GameState gameState) {
    return gameState.gameClock.inSeconds <= 0;
  }
  
  /// Starts the next quarter.
  /// 
  /// Returns a new [GameState] with the next quarter started.
  /// Handles transition from regulation to overtime.
  GameState startNextQuarter(GameState currentState) {
    final nextQuarter = currentState.quarter + 1;
    
    // Determine clock time for next quarter
    Duration clockTime;
    if (nextQuarter <= 4) {
      // Regular quarters are 15 minutes
      clockTime = const Duration(minutes: 15);
    } else {
      // Overtime periods are typically 10 minutes (simplified)
      clockTime = const Duration(minutes: 10);
    }
    
    return currentState.copyWith(
      quarter: nextQuarter,
      gameClock: clockTime,
    );
  }
  
  /// Determines if the game should end.
  /// 
  /// Returns true if the game should end based on NFL rules:
  /// - After 4 quarters if there's no tie
  /// - After overtime period(s) based on scoring rules
  bool shouldGameEnd(GameState gameState) {
    // Game ends if clock is at zero and we're past regulation
    if (gameState.gameClock.inSeconds <= 0) {
      // In regulation, game only ends if it's not tied
      if (gameState.quarter <= 4) {
        return gameState.homeScore != gameState.awayScore;
      }
      
      // In overtime, game ends if someone has scored (simplified rule)
      if (gameState.quarter > 4) {
        return gameState.homeScore != gameState.awayScore;
      }
    }
    
    return false;
  }
  
  /// Ends the current game.
  /// 
  /// Returns a new [GameState] with the game marked as finished.
  GameState endGame(GameState currentState) {
    return currentState.copyWith(gameInProgress: false);
  }
  
  /// Formats the game clock for display.
  /// 
  /// Returns a string in MM:SS format.
  static String formatClock(Duration clock) {
    final minutes = clock.inMinutes;
    final seconds = clock.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Returns the time remaining in the current quarter as a percentage.
  /// 
  /// Useful for UI progress indicators. Returns 0.0 to 1.0.
  double getQuarterProgress(GameState gameState) {
    final totalQuarterTime = gameState.quarter <= 4 
        ? const Duration(minutes: 15) 
        : const Duration(minutes: 10);
    
    final elapsed = totalQuarterTime - gameState.gameClock;
    return elapsed.inSeconds / totalQuarterTime.inSeconds;
  }
}
