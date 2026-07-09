import 'package:flutter_gpu_shaders/build.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    await buildShaderBundleJson(
      buildInput: input,
      buildOutput: output,
      manifestFileName: 'tile.shaderbundle.json',
      // GLSL ES 3.00 for the OpenGL ES dialect, matching flutter_scene's
      // floor. Software GL stacks (Android emulators, Mesa llvmpipe) reject
      // the 1.00 form's textureLod extension at compile time.
      glesLanguageVersion: 300,
    );
  });
}
