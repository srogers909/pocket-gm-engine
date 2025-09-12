/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'src/engine_base.dart';

// Models
export 'src/models/play_call.dart';
export 'src/models/play_result.dart';
export 'src/models/game_state.dart';

// Services
export 'src/services/ai_coach.dart';
export 'src/services/play_simulator.dart';
export 'src/services/play_simulator_enhanced.dart';
export 'src/services/clock_manager.dart';
export 'src/services/down_manager.dart';

// Re-export generator models that the engine depends on
export 'package:pocket_gm_generator/pocket_gm_generator.dart';
