/// A class to hold the detailed breakdown of a play simulation.
///
/// This class stores a log of calculation steps that occurred during the
/// simulation, providing transparency into how the final outcome was determined.
class SimulationBreakdown {
  /// A list of human-readable strings detailing each step of the simulation.
  final List<String> logs = [];

  /// Adds a log entry describing a calculation step.
  void addLog(String message) {
    logs.add(message);
  }

  /// Adds a section header to help organize the logs.
  void addSection(String sectionName) {
    if (logs.isNotEmpty) {
      logs.add(''); // Add empty line for spacing
    }
    logs.add('--- $sectionName ---');
  }

  /// Adds a calculation step with input values and result.
  void addCalculation(String description, Map<String, dynamic> inputs, dynamic result) {
    final inputStr = inputs.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    logs.add('$description ($inputStr) → $result');
  }

  /// Returns all logs as a formatted string.
  String getFormattedLogs() {
    return logs.join('\n');
  }

  /// Returns true if there are any logs recorded.
  bool get hasLogs => logs.isNotEmpty;
}
