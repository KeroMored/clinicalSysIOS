abstract class LabTestsState {}

class LabTestsInitial extends LabTestsState {}

class StatisticsLoaded extends LabTestsState {
  final Map<String, dynamic> stats;

  StatisticsLoaded(this.stats);
}
