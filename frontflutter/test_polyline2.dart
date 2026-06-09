import 'dart:math' as math;

void main() {
  String encodedPolyline = "a}nbg@ily{hEn@~NRlFiJy@oJWsT[so@eAwE`AeDr@iCjAaI|EyBxA{XnNmFpCyOvIcAbAo@dA]hBQvAS~BW`DsApTeAlPq@|GWnCWpAoArCo@vB_@hDDtDf@hDbArD|@fCbAvBf@`@~H`I|EdE|BdBlCp@jDv@~EPzB@nCQr@EtDe@n@KpOyBlEo@lJaB|_AuNdFk@d@GdDSxDGfD?xDJ~NdBpIpAxEv@tEtAvBv@zDlDvNqBr}@sOhd@{HnCw@tEqAnH@~h@jLfQlDxFtA`JlBbs@fPvSnFjHdBvIlBdShEvaAxTjEdAdGpAjq@xOjNjDlCl@fl@lNtDz@`e@fKhG|A{A|RgGdb@}Gpi@s@hFo@hFeB~MuL~bAyEv_@yNvhAcCfKeBrHuWlsAaAxGcGyA??";
  int precision = 6;
  final int factor = math.pow(10, precision).toInt();
  int index = 0;
  int lat = 0;
  int lng = 0;
  
  double minLat = 90, maxLat = -90;
  double minLng = 180, maxLng = -180;

  try {
    while (index < encodedPolyline.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      if (index >= encodedPolyline.length) break;
      do {
        byte = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      double finalLat = lat / factor;
      double finalLng = lng / factor;
      if (finalLat < minLat) minLat = finalLat;
      if (finalLat > maxLat) maxLat = finalLat;
      if (finalLng < minLng) minLng = finalLng;
      if (finalLng > maxLng) maxLng = finalLng;
    }
  } catch (e) {
    print('Error: $e at index $index');
  }
  print('minLat: $minLat, maxLat: $maxLat');
  print('minLng: $minLng, maxLng: $maxLng');
}
