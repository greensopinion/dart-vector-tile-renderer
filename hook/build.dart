import 'package:flutter_gpu_shaders/build.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    await buildShaderBundleJson(
        buildInput: input,
        buildOutput: output,
        manifestFileName: 'shaders/tile.shaderbundle.json');
  });
}
