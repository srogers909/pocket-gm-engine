import 'dart:math';
import '../models/game_state.dart';
import '../models/play_call.dart';
import 'package:pocket_gm_generator/pocket_gm_generator.dart';

/// Fixed version of PlaySimulator with corrected attribute calculations
class PlaySimulatorFixed {
  final Random _random = Random();

  /// Generates realistic yards gained for a running play using player attributes.
  int _generateRunYards(GameState gameState, [PlayCall? playCall]) {
    final distanceToGoal = 100 - gameState.yardLine;

    // Goal line situations: limited upside, more conservative
    if (distanceToGoal <= 5) {
      return _generateGoalLineRunYards(playCall);
    }

    // Normal field position: full range of possibilities
    return _generateNormalRunYards(playCall);
  }

  /// Fixed goal line yards calculation with correct attribute logic
  int _generateGoalLineRunYards([PlayCall? playCall]) {
    // Base probability thresholds for goal line situations
    int lossThreshold = 10;
    int noGainThreshold = 40;
    int shortGainThreshold = 80;

    // Base yard ranges for goal line
    int maxLoss = 3;
    int maxNoGain = 1;
    int maxShortGain = 3;
    int maxBigGain = 6;

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;
      
      // Get skill player rating (for RB: positionRating1 = Rush Power)
      double skillPlayerRating = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final player = players.primarySkillPlayer as Player;
        skillPlayerRating = player.positionRating1.toDouble(); // Rush Power rating
      }

      // Get offensive line rating
      double offensiveLineRating = players.offensiveLineRating;
      
      // Get defensive line rating (opponent strength)
      double defensiveLineRating = players.defensiveLineRating;

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach = playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.rushingOffense / 25.0).clamp(0.0, 4.0); // Scale 0-100 to 0-4
      }

      // FIXED CALCULATION: Calculate advantage relative to league average (50)
      double offensiveAdvantage = (skillPlayerRating + offensiveLineRating) / 2.0; // Average of ratings
      double netAdvantage = offensiveAdvantage - defensiveLineRating + coachingBonus;
      
      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier = (netAdvantage - 50.0) / 3.0; // Scale to roughly -16 to +16
      advantageModifier = advantageModifier.clamp(-15.0, 15.0);

      print('🔍 Goal Line Analysis:');
      print('  Skill Player: $skillPlayerRating, O-Line: $offensiveLineRating, Defense: $defensiveLineRating, Coaching: $coachingBonus');
      print('  Net Advantage: $netAdvantage, Modifier: $advantageModifier');

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce bad outcomes, increase good outcomes
        lossThreshold = (lossThreshold - advantageModifier).round().clamp(2, 18);
        noGainThreshold = (noGainThreshold - (advantageModifier * 1.5)).round().clamp(15, 50);
        shortGainThreshold = (shortGainThreshold - (advantageModifier / 2)).round().clamp(70, 90);
        
        // Slightly increase yard potential (limited in goal line)
        maxShortGain = (maxShortGain + (advantageModifier / 5)).round().clamp(3, 5);
        maxBigGain = (maxBigGain + (advantageModifier / 3)).round().clamp(6, 10);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase bad outcomes, reduce good outcomes
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + absAdvantage).round().clamp(2, 25);
        noGainThreshold = (noGainThreshold + (absAdvantage * 1.5)).round().clamp(30, 60);
        shortGainThreshold = (shortGainThreshold + (absAdvantage / 2)).round().clamp(75, 95);
        
        // Decrease yard potential
        maxLoss = (maxLoss + (absAdvantage / 5)).round().clamp(3, 6);
        maxShortGain = (maxShortGain - (absAdvantage / 5)).round().clamp(2, 3);
        maxBigGain = (maxBigGain - (absAdvantage / 3)).round().clamp(4, 6);
      }

      print('  Adjusted Thresholds - Loss: $lossThreshold, NoGain: $noGainThreshold, Short: $shortGainThreshold');
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss
      return -1 - _random.nextInt(maxLoss); // -1 to -maxLoss yards
    } else if (roll < noGainThreshold) {
      // No gain or minimal gain
      return _random.nextInt(maxNoGain + 1); // 0 to maxNoGain yards
    } else if (roll < shortGainThreshold) {
      // Short gain
      return 2 + _random.nextInt(maxShortGain); // 2 to (2 + maxShortGain) yards
    } else {
      // Bigger gain (limited in goal line)
      return 5 + _random.nextInt(maxBigGain); // 5 to (5 + maxBigGain) yards
    }
  }

  /// Fixed normal run yards calculation with correct attribute logic
  int _generateNormalRunYards([PlayCall? playCall]) {
    // Base probability thresholds (can be modified by player attributes)
    int lossThreshold = 8;
    int noGainThreshold = 15;
    int shortGainThreshold = 60;
    int mediumGainThreshold = 85;
    int longGainThreshold = 95;

    // Base yard ranges (can be modified by player attributes)
    int baseShortYards = 5;
    int baseMediumYards = 7;
    int baseLongYards = 13;
    int baseBreakawayYards = 55;

    // Apply player attribute modifiers if available
    if (playCall?.players != null) {
      final players = playCall!.players!;
      
      // Get skill player rating
      double skillPlayerRating = 50.0; // Default average rating
      if (players.primarySkillPlayer != null) {
        final player = players.primarySkillPlayer as Player;
        skillPlayerRating = player.positionRating1.toDouble(); // Position-specific rating (e.g., Rush Power for RB)
      }

      // Get offensive line rating
      double offensiveLineRating = players.offensiveLineRating;
      
      // Get defensive line rating (opponent strength)
      double defensiveLineRating = players.defensiveLineRating;

      // Apply coaching bonus if available
      double coachingBonus = 0.0;
      if (playCall.coaching?.offensiveCoordinator != null) {
        final coach = playCall.coaching!.offensiveCoordinator as OffensiveCoordinator;
        coachingBonus = (coach.rushingOffense / 25.0).clamp(0.0, 4.0); // Scale 0-100 to 0-4
      }

      // FIXED CALCULATION: Calculate advantage relative to league average (50)
      double offensiveAdvantage = (skillPlayerRating + offensiveLineRating) / 2.0; // Average of ratings
      double netAdvantage = offensiveAdvantage - defensiveLineRating + coachingBonus;
      
      // Normalize advantage relative to average (50): range roughly -50 to +50
      double advantageModifier = (netAdvantage - 50.0) / 2.5; // Scale to roughly -20 to +20
      advantageModifier = advantageModifier.clamp(-20.0, 20.0);

      print('🔍 Normal Run Analysis:');
      print('  Skill Player: $skillPlayerRating, O-Line: $offensiveLineRating, Defense: $defensiveLineRating, Coaching: $coachingBonus');
      print('  Net Advantage: $netAdvantage, Modifier: $advantageModifier');

      // Adjust probability thresholds based on advantage
      if (advantageModifier > 0) {
        // Positive advantage: reduce bad outcomes, increase good outcomes
        lossThreshold = (lossThreshold - (advantageModifier / 2)).round().clamp(1, 15);
        noGainThreshold = (noGainThreshold - advantageModifier).round().clamp(5, 25);
        longGainThreshold = (longGainThreshold - advantageModifier).round().clamp(80, 98);
        
        // Increase yard potential
        baseShortYards = (baseShortYards + (advantageModifier / 4)).round().clamp(3, 8);
        baseMediumYards = (baseMediumYards + (advantageModifier / 3)).round().clamp(5, 12);
        baseLongYards = (baseLongYards + (advantageModifier / 2)).round().clamp(10, 20);
        baseBreakawayYards = (baseBreakawayYards + advantageModifier).round().clamp(40, 80);
      } else if (advantageModifier < 0) {
        // Negative advantage: increase bad outcomes, reduce good outcomes
        double absAdvantage = -advantageModifier;
        lossThreshold = (lossThreshold + (absAdvantage / 2)).round().clamp(1, 25);
        noGainThreshold = (noGainThreshold + absAdvantage).round().clamp(5, 35);
        longGainThreshold = (longGainThreshold + absAdvantage).round().clamp(85, 99);
        
        // Decrease yard potential
        baseShortYards = (baseShortYards - (absAdvantage / 4)).round().clamp(2, 5);
        baseMediumYards = (baseMediumYards - (absAdvantage / 3)).round().clamp(4, 7);
        baseLongYards = (baseLongYards - (absAdvantage / 2)).round().clamp(8, 13);
        baseBreakawayYards = (baseBreakawayYards - absAdvantage).round().clamp(30, 55);
      }

      print('  Adjusted Thresholds - Loss: $lossThreshold, NoGain: $noGainThreshold, Long: $longGainThreshold');
    }

    final roll = _random.nextInt(100);

    if (roll < lossThreshold) {
      // Loss
      return -1 - _random.nextInt(5); // -1 to -5 yards
    } else if (roll < noGainThreshold) {
      // No gain
      return 0;
    } else if (roll < shortGainThreshold) {
      // Short gain
      return 1 + _random.nextInt(baseShortYards); // 1 to baseShortYards
    } else if (roll < mediumGainThreshold) {
      // Medium gain
      return 6 + _random.nextInt(baseMediumYards); // 6 to (6 + baseMediumYards)
    } else if (roll < longGainThreshold) {
      // Long gain
      return 13 + _random.nextInt(baseLongYards); // 13 to (13 + baseLongYards)
    } else {
      // Breakaway run
      return 26 + _random.nextInt(baseBreakawayYards); // 26 to (26 + baseBreakawayYards)
    }
  }

  /// Test method to demonstrate the fix
  void testAttributeCalculations() {
    print('\n=== TESTING FIXED ATTRIBUTE CALCULATIONS ===\n');
    
    // Create test scenarios
    final testScenarios = [
      {'name': 'Elite RB', 'skillRating': 95.0, 'olineRating': 80.0, 'defenseRating': 70.0, 'coaching': 85.0},
      {'name': 'Average RB', 'skillRating': 73.0, 'olineRating': 75.0, 'defenseRating': 75.0, 'coaching': 65.0},
      {'name': 'Poor RB', 'skillRating': 55.0, 'olineRating': 70.0, 'defenseRating': 80.0, 'coaching': 45.0},
    ];

    for (var scenario in testScenarios) {
      print('--- ${scenario['name']} ---');
      
      // Calculate the fixed logic
      double skillPlayerRating = scenario['skillRating'] as double;
      double offensiveLineRating = scenario['olineRating'] as double;
      double defensiveLineRating = scenario['defenseRating'] as double;
      double coachingBonus = (scenario['coaching'] as double) / 25.0;
      
      double offensiveAdvantage = (skillPlayerRating + offensiveLineRating) / 2.0;
      double netAdvantage = offensiveAdvantage - defensiveLineRating + coachingBonus;
      double advantageModifier = (netAdvantage - 50.0) / 2.5;
      advantageModifier = advantageModifier.clamp(-20.0, 20.0);
      
      print('  Ratings: Skill=$skillPlayerRating, O-Line=$offensiveLineRating, Defense=$defensiveLineRating, Coaching=${coachingBonus.toStringAsFixed(1)}');
      print('  Offensive Average: ${offensiveAdvantage.toStringAsFixed(1)}');
      print('  Net Advantage: ${netAdvantage.toStringAsFixed(1)}');
      print('  Advantage Modifier: ${advantageModifier.toStringAsFixed(1)}');
      print('  Expected: ${advantageModifier > 0 ? "POSITIVE (Better)" : advantageModifier < 0 ? "NEGATIVE (Worse)" : "NEUTRAL"}');
      print('');
    }
  }
}
