import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  Stream<UserAccelerometerEvent> userAccelerometerStream() {
    return userAccelerometerEvents;
  }

  Stream<GyroscopeEvent> gyroscopeStream() {
    return gyroscopeEvents;
  }
}

class SlidingWindow {
  SlidingWindow({this.size = 20});

  final int size;
  final List<double> _values = [];

  void add(double value) {
    _values.add(value);
    if (_values.length > size) {
      _values.removeAt(0);
    }
  }

  double get average {
    if (_values.isEmpty) {
      return 0;
    }
    final sum = _values.reduce((a, b) => a + b);
    return sum / _values.length;
  }

  double get max {
    if (_values.isEmpty) {
      return 0;
    }
    return _values.reduce((a, b) => a > b ? a : b);
  }
}
