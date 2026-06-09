import 'dart:io';

void main() {
  final lines = File('output.txt').readAsLinesSync();
  double minLat = 90;
  double maxLat = -90;
  double minLng = 180;
  double maxLng = -180;

  for (var line in lines) {
    if (line.isEmpty) continue;
    final parts = line.replaceFirst('Point: ', '').split(', ');
    final lat = double.parse(parts[0]);
    final lng = double.parse(parts[1]);
    if (lat < minLat) minLat = lat;
    if (lat > maxLat) maxLat = lat;
    if (lng < minLng) minLng = lng;
    if (lng > maxLng) maxLng = lng;
  }
  print('minLat: $minLat, maxLat: $maxLat');
  print('minLng: $minLng, maxLng: $maxLng');
}
