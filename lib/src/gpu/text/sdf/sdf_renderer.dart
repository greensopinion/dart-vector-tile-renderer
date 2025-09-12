

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_generator.dart';
import 'package:vector_tile_renderer/src/image_to_png.dart';

import '../../shaders.dart';

class SdfRenderer {
  final AtlasConfig atlasConfig;
  final int cellSize;

  SdfRenderer(this.atlasConfig, this.cellSize);

  static final _vertices = Float32List.fromList([
    -1, -1,
    1, -1,
    -1,  1,
    1, -1,
    1, 1,
    -1,  1,
  ]);

  gpu.Texture renderToSDF(Uint8List glyphs) {
    final atlasWidth = atlasConfig.gridCols * cellSize;
    final atlasHeight = atlasConfig.gridRows * cellSize;

    final transientBuffer = gpu.gpuContext.createHostBuffer();

    print("width: ${atlasWidth.toDouble()}, height: ${atlasHeight.toDouble()}, radius: ${atlasConfig.sdfRadius.toDouble()}");

    final uniformBufferView = transientBuffer.emplace(
        Float32List.fromList([atlasWidth.toDouble(), atlasHeight.toDouble(), atlasConfig.sdfRadius.toDouble()]).buffer.asByteData()
    );

    final vertexBuffer = gpu.gpuContext.createDeviceBufferWithCopy(ByteData.sublistView(_vertices));

    final vertexBufferView = gpu.BufferView(
      vertexBuffer,
      offsetInBytes: 0,
      lengthInBytes: _vertices.buffer.lengthInBytes,
    );

    final inputTexture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, atlasWidth, atlasHeight, format: gpu.PixelFormat.r8g8b8a8UNormInt);
    inputTexture.overwrite(ByteData.sublistView(glyphs));

    _saveTextureToFile(inputTexture, "input_sdf.png");


    final intermediateTexture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, atlasWidth, atlasHeight, format: gpu.PixelFormat.r8g8b8a8UNormInt);
    final outputTexture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, atlasWidth, atlasHeight, format: gpu.PixelFormat.r8g8b8a8UNormInt);

    _draw(inputTexture, intermediateTexture, uniformBufferView, vertexBufferView, shaderLibrary["SdfBasicVertex"]!, shaderLibrary["SdfFragmentA"]!);
    _draw(intermediateTexture, outputTexture, uniformBufferView, vertexBufferView,  shaderLibrary["SdfBasicVertex"]!, shaderLibrary["SdfFragmentB"]!);

    // Debug: Save output texture as image (async)
    _saveTextureToFile(outputTexture, "output_sdf.png");

    return outputTexture;
  }

  void _saveTextureToFile(gpu.Texture texture, String filename) {
    texture.asImage().toPng().then((byteData) {
      final file = File("${Directory.current.path}/$filename");

      file.writeAsBytes(byteData.buffer.asUint8List()).then((_) {
        // ignore: avoid_print
        print("SDF texture saved to ${file.path}");
      }).catchError((e) {
        // ignore: avoid_print
        print("Failed to write SDF file: $e");
      });
    }).catchError((e) {
      // ignore: avoid_print
      print("Failed to convert SDF texture to image: $e");
    });
  }


  void _draw(gpu.Texture input, gpu.Texture output, gpu.BufferView uniform, gpu.BufferView vertices, gpu.Shader vertexShader, gpu.Shader fragmentShader) {
    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    
    final renderTarget = gpu.RenderTarget.singleColor(
      gpu.ColorAttachment(texture: output, clearValue: Vector4(0, 0, 0, 0), loadAction: gpu.LoadAction.clear),
    );

    final renderPass = commandBuffer.createRenderPass(renderTarget);

    renderPass.setCullMode(gpu.CullMode.none);
    renderPass.setPrimitiveType(gpu.PrimitiveType.triangle);
    renderPass.setWindingOrder(gpu.WindingOrder.counterClockwise);

    final pipeline = gpu.gpuContext.createRenderPipeline(vertexShader, fragmentShader);
    renderPass.bindPipeline(pipeline);

    renderPass.bindVertexBuffer(vertices, _vertices.length ~/ 2);

    final textureSlot = fragmentShader.getUniformSlot('glyph_texture');
    renderPass.bindTexture(textureSlot, input);

    final uniformSlot = fragmentShader.getUniformSlot('FragInfo');
    renderPass.bindUniform(uniformSlot, uniform);

    renderPass.draw();
    
    commandBuffer.submit();
  }
}

