import 'dart:io';
import 'dart:typed_data';

Future<File> writeTestFile(Uint8List bytes, String filename) async {
  final folder = await Directory('build/tmp').create(recursive: true);
  final file = File('${folder.absolute.path}/$filename');
  await file.writeAsBytes(bytes);
  return file;
}
