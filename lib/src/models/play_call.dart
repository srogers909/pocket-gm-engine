/// Represents the primary type of offensive play
enum OffensivePlayType {
  pass,
  run,
}

/// Specific passing plays available to the offense
enum OffensivePassPlay {
  /// Desperation deep pass, typically used when time is running out
  hailMary,
  
  /// Deep pass beyond 20 yards downfield to exploit defensive weaknesses
  deepPass,
  
  /// Medium pass between 10-20 yards for balanced risk/reward
  mediumPass,
  
  /// Short pass within 10 yards for consistent, manageable yardage
  shortPass,
  
  /// Wide receiver screen pass with blockers setting up downfield
  wrScreen,
  
  /// Running back screen pass to draw rush upfield then block
  rbScreen,
}

/// Specific running plays available to the offense
enum OffensiveRunPlay {
  /// Physical downhill running with multiple blockers at point of attack
  powerRun,
  
  /// Run attacking the interior of the defensive line
  insideRun,
  
  /// Run designed to attack the perimeter and outflank defense
  outsideRun,
  
  /// Fast receiver motion across formation taking quick handoff
  jetSweep,
  
  /// QB reads specific defender to decide between handoff or keep
  readOption,
  
  /// Quarterback intentionally carries the ball
  qbRun,
}

/// Special teams plays for specific situations
enum SpecialTeamsPlay {
  /// Attempt to kick field goal for 3 points
  kickFG,
  
  /// Punt the ball to surrender possession but gain field position
  punt,
}

/// Defensive plays available to counter offensive strategies
enum DefensivePlay {
  /// Balanced approach defending equally against run and pass
  balanced,
  
  /// Aggressive strategy sending extra rushers to pressure QB
  blitz,
  
  /// Strategy focused on preventing forward passes and limiting air yards
  defendPass,
  
  /// Strategy focused on stopping running plays and controlling line of scrimmage
  defendRun,
  
  /// Conservative deep coverage to prevent big plays, typically used late in game
  prevent,
  
  /// Bringing extra defenders close to line of scrimmage to stop the run
  stackTheBox,
}

/// Represents the key players involved in a play
class PlayPlayers {
  /// Quarterback executing the play
  final dynamic quarterback;
  
  /// Primary skill position player (RB for runs, WR/TE for passes)
  final dynamic primarySkillPlayer;
  
  /// Primary defender covering/tackling the play
  final dynamic primaryDefender;
  
  /// Offensive line average rating (simplified for now)
  final double offensiveLineRating;
  
  /// Defensive line average rating (simplified for now)
  final double defensiveLineRating;

  PlayPlayers({
    required this.quarterback,
    this.primarySkillPlayer,
    this.primaryDefender,
    this.offensiveLineRating = 50.0,
    this.defensiveLineRating = 50.0,
  });
}

/// Represents coaching staff influence on a play
class PlayCoaching {
  /// Offensive coordinator for scheme bonuses
  final dynamic offensiveCoordinator;
  
  /// Defensive coordinator for scheme bonuses
  final dynamic defensiveCoordinator;
  
  /// Head coach for game management and leadership bonuses
  final dynamic headCoach;

  PlayCoaching({
    this.offensiveCoordinator,
    this.defensiveCoordinator,
    this.headCoach,
  });
}

/// Represents a complete play call including type, specific play, and player data
class PlayCall {
  /// The primary category of play (pass, run, or special teams)
  final OffensivePlayType? offensiveType;
  
  /// Specific passing play if this is a pass play
  final OffensivePassPlay? passPlay;
  
  /// Specific running play if this is a run play
  final OffensiveRunPlay? runPlay;
  
  /// Special teams play if applicable
  final SpecialTeamsPlay? specialTeamsPlay;

  /// Defensive play if applicable
  final DefensivePlay? defensivePlay;

  /// Key players involved in this play
  final PlayPlayers? players;

  /// Coaching staff influence on this play
  final PlayCoaching? coaching;
  
  /// Referee for penalty calling tendencies
  final dynamic referee;

  PlayCall._({
    this.offensiveType,
    this.passPlay,
    this.runPlay,
    this.specialTeamsPlay,
    this.defensivePlay,
    this.players,
    this.coaching,
    this.referee,
  });

  /// Creates a pass play call
  factory PlayCall.pass(OffensivePassPlay passPlay) {
    return PlayCall._(
      offensiveType: OffensivePlayType.pass,
      passPlay: passPlay,
    );
  }

  /// Creates a run play call
  factory PlayCall.run(OffensiveRunPlay runPlay) {
    return PlayCall._(
      offensiveType: OffensivePlayType.run,
      runPlay: runPlay,
    );
  }

  /// Creates a special teams play call
  factory PlayCall.specialTeams(SpecialTeamsPlay specialTeamsPlay) {
    return PlayCall._(
      specialTeamsPlay: specialTeamsPlay,
    );
  }

  /// Creates a defensive play call
  factory PlayCall.defense(DefensivePlay defensivePlay) {
    return PlayCall._(
      defensivePlay: defensivePlay,
    );
  }

  /// Creates a copy of this PlayCall with additional player and coaching data
  PlayCall withPlayerData({
    PlayPlayers? players,
    PlayCoaching? coaching,
    dynamic referee,
  }) {
    return PlayCall._(
      offensiveType: offensiveType,
      passPlay: passPlay,
      runPlay: runPlay,
      specialTeamsPlay: specialTeamsPlay,
      defensivePlay: defensivePlay,
      players: players ?? this.players,
      coaching: coaching ?? this.coaching,
      referee: referee ?? this.referee,
    );
  }

  /// Returns true if this is a passing play
  bool get isPass => offensiveType == OffensivePlayType.pass;

  /// Returns true if this is a running play
  bool get isRun => offensiveType == OffensivePlayType.run;

  /// Returns true if this is a special teams play
  bool get isSpecialTeams => specialTeamsPlay != null;

  /// Returns true if this is a defensive play
  bool get isDefense => defensivePlay != null;

  /// Returns a human-readable description of the play
  String get description {
    if (isPass && passPlay != null) {
      return _getPassPlayDescription(passPlay!);
    } else if (isRun && runPlay != null) {
      return _getRunPlayDescription(runPlay!);
    } else if (isSpecialTeams && specialTeamsPlay != null) {
      return _getSpecialTeamsDescription(specialTeamsPlay!);
    } else if (isDefense && defensivePlay != null) {
      return _getDefensivePlayDescription(defensivePlay!);
    }
    return 'Unknown Play';
  }

  String _getPassPlayDescription(OffensivePassPlay play) {
    switch (play) {
      case OffensivePassPlay.hailMary:
        return 'Hail Mary';
      case OffensivePassPlay.deepPass:
        return 'Deep Pass';
      case OffensivePassPlay.mediumPass:
        return 'Medium Pass';
      case OffensivePassPlay.shortPass:
        return 'Short Pass';
      case OffensivePassPlay.wrScreen:
        return 'WR Screen';
      case OffensivePassPlay.rbScreen:
        return 'RB Screen';
    }
  }

  String _getRunPlayDescription(OffensiveRunPlay play) {
    switch (play) {
      case OffensiveRunPlay.powerRun:
        return 'Power Run';
      case OffensiveRunPlay.insideRun:
        return 'Inside Run';
      case OffensiveRunPlay.outsideRun:
        return 'Outside Run';
      case OffensiveRunPlay.jetSweep:
        return 'Jet Sweep';
      case OffensiveRunPlay.readOption:
        return 'Read Option';
      case OffensiveRunPlay.qbRun:
        return 'QB Run';
    }
  }

  String _getSpecialTeamsDescription(SpecialTeamsPlay play) {
    switch (play) {
      case SpecialTeamsPlay.kickFG:
        return 'Field Goal Attempt';
      case SpecialTeamsPlay.punt:
        return 'Punt';
    }
  }

  String _getDefensivePlayDescription(DefensivePlay play) {
    switch (play) {
      case DefensivePlay.balanced:
        return 'Balanced Defense';
      case DefensivePlay.blitz:
        return 'Blitz';
      case DefensivePlay.defendPass:
        return 'Defend Pass';
      case DefensivePlay.defendRun:
        return 'Defend Run';
      case DefensivePlay.prevent:
        return 'Prevent Defense';
      case DefensivePlay.stackTheBox:
        return 'Stack the Box';
    }
  }

  /// Converts the PlayCall to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'offensiveType': offensiveType?.name,
      'passPlay': passPlay?.name,
      'runPlay': runPlay?.name,
      'specialTeamsPlay': specialTeamsPlay?.name,
      'defensivePlay': defensivePlay?.name,
    };
  }

  /// Creates a PlayCall from a JSON representation
  factory PlayCall.fromJson(Map<String, dynamic> json) {
    final offensiveTypeStr = json['offensiveType'] as String?;
    final passPlayStr = json['passPlay'] as String?;
    final runPlayStr = json['runPlay'] as String?;
    final specialTeamsPlayStr = json['specialTeamsPlay'] as String?;
    final defensivePlayStr = json['defensivePlay'] as String?;

    return PlayCall._(
      offensiveType: offensiveTypeStr != null 
          ? OffensivePlayType.values.firstWhere((e) => e.name == offensiveTypeStr)
          : null,
      passPlay: passPlayStr != null 
          ? OffensivePassPlay.values.firstWhere((e) => e.name == passPlayStr)
          : null,
      runPlay: runPlayStr != null 
          ? OffensiveRunPlay.values.firstWhere((e) => e.name == runPlayStr)
          : null,
      specialTeamsPlay: specialTeamsPlayStr != null 
          ? SpecialTeamsPlay.values.firstWhere((e) => e.name == specialTeamsPlayStr)
          : null,
      defensivePlay: defensivePlayStr != null 
          ? DefensivePlay.values.firstWhere((e) => e.name == defensivePlayStr)
          : null,
    );
  }

  @override
  String toString() {
    return 'PlayCall: $description';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayCall &&
        other.offensiveType == offensiveType &&
        other.passPlay == passPlay &&
        other.runPlay == runPlay &&
        other.specialTeamsPlay == specialTeamsPlay &&
        other.defensivePlay == defensivePlay;
  }

  @override
  int get hashCode {
    return Object.hash(offensiveType, passPlay, runPlay, specialTeamsPlay, defensivePlay);
  }
}
