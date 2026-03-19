// Generated model for Flutter
double evalModel(double x) {
  const List<double> p = [
    -0.0003169420828863197,
    0.034032918172781146,
    0.16395916165224575,
    -0.9371576673902607,
  ];
  final a = p[0];
  final b = p[1];
  final c = p[2];
  final d = p[3];
  return a * x * x * x + b * x * x + c * x + d;
}
