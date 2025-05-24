import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' as m;
import 'package:flutter_gpu/gpu.dart' as gpu;

import '../themes/theme.dart';
import '../tileset.dart';
import 'color_extension.dart';
import 'shaders.dart';

/// Experimental: renders tiles using flutter_gpu
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///
class TileRenderer {
  final Theme theme;
  Tileset? tileset;

  TileRenderer({required this.theme});

  void render(ui.Canvas canvas, ui.Size size) {
    final tileset = this.tileset ?? Tileset({});

    final texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.devicePrivate, size.width.toInt(), size.height.toInt());
    final renderTarget = gpu.RenderTarget.singleColor(gpu.ColorAttachment(
        texture: texture, clearValue: m.Colors.lightBlue.vector4));

    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    final renderPass = commandBuffer.createRenderPass(renderTarget);

    final vert = shaderLibrary['SimpleVertex']!;
    final frag = shaderLibrary['SimpleFragment']!;
    final pipeline = gpu.gpuContext.createRenderPipeline(vert, frag);

    final points = [
      ui.Offset(-0.5, -0.5),
      ui.Offset(0.5, -0.5),
      ui.Offset(0.0, 0.5),
      ui.Offset(0.0, 0.0)
    ];
    final vertices = Float32List.fromList(
        points.expand((o) => [o.dx, o.dy]).toList(growable: false));
    final verticesDeviceBuffer = gpu.gpuContext
        .createDeviceBufferWithCopy(ByteData.sublistView(vertices));

    renderPass.bindPipeline(pipeline);
    renderPass.setPrimitiveType(gpu.PrimitiveType.lineStrip);

    final verticesView = gpu.BufferView(
      verticesDeviceBuffer,
      offsetInBytes: 0,
      lengthInBytes: verticesDeviceBuffer.sizeInBytes,
    );
    renderPass.bindVertexBuffer(verticesView, points.length);
    renderPass.draw();

    commandBuffer.submit();
    final image = texture.asImage();
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());
  }

  /// Must call to release resources when done.
  void dispose() {}
}
