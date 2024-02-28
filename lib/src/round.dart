import 'dart:math';

/// Round number to precision
num round(num value, [num precision = 0]) {
  if (!(precision >= 0)) {
    throw Exception("precision must be a positive number");
  }
  num multiplier = pow(10, precision);
  num result = (value * multiplier);
  return result.round() / multiplier;
}
