import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

/// Base class for the tile renderer's geometries.
///
/// flutter_scene 0.18.1 delivers the per-draw model transform through an
/// instance-rate vertex buffer (see [UnskinnedGeometry.instancedVertexLayout]
/// / `kUnskinnedInstancedLayout`) and validates that layout *by attribute
/// name* against the bound vertex shader. Our geometries use custom vertex
/// shaders with their own inputs (`SimpleVertex`, `LineVertex`, ...) that read
/// the model transform from a `FrameInfo` uniform, so the standard instanced
/// layout does not apply. Without this override the pipeline build throws e.g.
/// "VertexAttribute name 'position' does not match any input declared by the
/// bound vertex shader".
///
/// This base therefore:
///  * returns a null [instancedVertexLayout], so the pipeline is built from
///    the shader's own reflected vertex descriptor (no name mismatch) and the
///    encoder takes the non-instanced, per-draw-uniform path; and
///  * fills, in [bind], the `FrameInfo` UBO our shaders expect
///    ({ model_transform, camera_transform, camera_position }) — which
///    flutter_scene's own `UnskinnedGeometry.bind` no longer provides now that
///    the model transform moved to the instance buffer.
abstract class TileGeometry extends UnskinnedGeometry {
  gpu.BufferView? _vertexBufferView;
  gpu.BufferView? _indexBufferView;
  gpu.IndexType _tileIndexType = gpu.IndexType.int16;

  @override
  gpu.VertexLayout? get instancedVertexLayout => null;

  // Capture the buffer views as they pass through so [bind] can rebind them
  // (the base class keeps them private). Both setters are the sink for
  // `uploadVertexData`.
  @override
  void setVertices(gpu.BufferView vertices, int vertexCount) {
    super.setVertices(vertices, vertexCount);
    _vertexBufferView = vertices;
  }

  @override
  void setIndices(gpu.BufferView indices, gpu.IndexType indexType) {
    super.setIndices(indices, indexType);
    _indexBufferView = indices;
    _tileIndexType = indexType;
  }

  @override
  void bind(
    gpu.RenderPass pass,
    gpu.HostBuffer transientsBuffer,
    Matrix4 modelTransform,
    Matrix4 cameraTransform,
    Vector3 cameraPosition,
  ) {
    pass.bindVertexBuffer(_vertexBufferView!);
    final indices = _indexBufferView;
    if (indices != null) {
      pass.bindIndexBuffer(indices, _tileIndexType);
    }

    // FrameInfo UBO, std140: mat4 model_transform, mat4 camera_transform,
    // vec3 camera_position (16 + 16 + 3 floats).
    final frameInfo = Float32List(35)
      ..setRange(0, 16, modelTransform.storage)
      ..setRange(16, 32, cameraTransform.storage)
      ..setRange(32, 35, [cameraPosition.x, cameraPosition.y, cameraPosition.z]);
    pass.bindUniform(
      vertexShader.getUniformSlot('FrameInfo'),
      transientsBuffer.emplace(ByteData.sublistView(frameInfo)),
    );
  }
}
