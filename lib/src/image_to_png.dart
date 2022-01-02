import 'dart:typed_data';
import 'dart:ui';

extension ImageToPng on Image {
  Future<Uint8List> toPng() async {
    final bytes = await toByteData(format: ImageByteFormat.png);
    if (bytes == null) {
      throw Exception('Cannot encode as png');
    }
    return Uint8List.sublistView(bytes);
  }
}
