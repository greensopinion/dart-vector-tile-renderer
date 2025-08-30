import 'dart:typed_data';

import 'bucket_unpacker.dart';

class TileRenderData {
  final List<PackedMesh> data = [];

  void addMesh(PackedMesh mesh) {
    data.add(mesh);
  }

  static TileRenderData unpack(Uint8List bytes) {
    final result = TileRenderData();
    final view =
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);

    final meshCount = _readHeader(view);
    int offset = 8;

    for (int i = 0; i < meshCount; i++) {
      final mesh = _readMesh(view, bytes, offset);
      result.addMesh(mesh.mesh);
      offset = mesh.nextOffset;
    }

    return result;
  }

  Uint8List pack() {
    final builder = BytesBuilder();

    _writeHeader(builder, data.length);

    for (final mesh in data) {
      _writeMesh(builder, mesh);
    }

    return builder.takeBytes();
  }

  static int _readHeader(ByteData view) {
    return view.getUint32(0, Endian.little);
  }

  static _MeshReadResult _readMesh(ByteData view, Uint8List bytes, int offset) {
    final header = _readMeshHeader(view, offset);
    offset += 18;

    final meshData = _readMeshData(bytes, offset, header);

    final mesh = PackedMesh(
      PackedGeometry(
        vertices: meshData.vertices,
        indices: meshData.indices,
        uniform: meshData.geometryUniform,
        type: header.geometryType,
      ),
      PackedMaterial(
        uniform: meshData.materialUniform,
        type: header.materialType,
      ),
    );

    return _MeshReadResult(mesh, meshData.nextOffset);
  }

  static _MeshHeader _readMeshHeader(ByteData view, int offset) {
    return _MeshHeader(
      geometryType: GeometryType.values[view.getUint8(offset)],
      materialType: MaterialType.values[view.getUint8(offset + 1)],
      verticesLength: view.getUint32(offset + 2, Endian.little),
      indicesLength: view.getUint32(offset + 6, Endian.little),
      geometryUniformLength: view.getUint32(offset + 10, Endian.little),
      materialUniformLength: view.getUint32(offset + 14, Endian.little),
    );
  }

  static _MeshData _readMeshData(
      Uint8List bytes, int offset, _MeshHeader header) {
    final vertices = _readByteDataView(bytes, offset, header.verticesLength);
    offset += header.verticesLength;

    final indices = _readByteDataView(bytes, offset, header.indicesLength);
    offset += header.indicesLength;

    ByteData? geometryUniform;
    if (header.geometryUniformLength > 0) {
      geometryUniform =
          _readByteDataView(bytes, offset, header.geometryUniformLength);
      offset += header.geometryUniformLength;
    }

    ByteData? materialUniform;
    if (header.materialUniformLength > 0) {
      materialUniform =
          _readByteDataView(bytes, offset, header.materialUniformLength);
      offset += header.materialUniformLength;
    }

    return _MeshData(
        vertices, indices, geometryUniform, materialUniform, offset);
  }

  static ByteData _readByteDataView(Uint8List bytes, int offset, int length) {
    return ByteData.view(bytes.buffer, bytes.offsetInBytes + offset, length);
  }

  static void _writeHeader(BytesBuilder builder, int meshCount) {
    final headerBytes = Uint8List(8);
    final headerView = ByteData.view(headerBytes.buffer);
    headerView.setUint32(0, meshCount, Endian.little);
    headerView.setUint32(4, 0, Endian.little); // reserved
    builder.add(headerBytes);
  }

  static void _writeMesh(BytesBuilder builder, PackedMesh mesh) {
    _writeMeshHeader(builder, mesh);
    _writeMeshData(builder, mesh);
  }

  static void _writeMeshHeader(BytesBuilder builder, PackedMesh mesh) {
    // Mesh Header (18 bytes total):
    //   - geometryType: uint8 (1 byte) at offset 0
    //   - materialType: uint8 (1 byte) at offset 1
    //   - verticesLength: uint32 (4 bytes) at offset 2
    //   - indicesLength: uint32 (4 bytes) at offset 6
    //   - geometryUniformLength: uint32 (4 bytes) at offset 10
    //   - materialUniformLength: uint32 (4 bytes) at offset 14
    final meshHeaderBytes = Uint8List(18);
    final meshHeaderView = ByteData.view(meshHeaderBytes.buffer);

    meshHeaderView.setUint8(0, mesh.geometry.type.index);
    meshHeaderView.setUint8(1, mesh.material.type.index);
    meshHeaderView.setUint32(
        2, mesh.geometry.vertices.lengthInBytes, Endian.little);
    meshHeaderView.setUint32(
        6, mesh.geometry.indices.lengthInBytes, Endian.little);
    meshHeaderView.setUint32(
        10, mesh.geometry.uniform?.lengthInBytes ?? 0, Endian.little);
    meshHeaderView.setUint32(
        14, mesh.material.uniform?.lengthInBytes ?? 0, Endian.little);

    builder.add(meshHeaderBytes);
  }

  static void _writeMeshData(BytesBuilder builder, PackedMesh mesh) {
    _writeByteData(builder, mesh.geometry.vertices);
    _writeByteData(builder, mesh.geometry.indices);

    if (mesh.geometry.uniform != null) {
      _writeByteData(builder, mesh.geometry.uniform!);
    }

    if (mesh.material.uniform != null) {
      _writeByteData(builder, mesh.material.uniform!);
    }
  }

  static void _writeByteData(BytesBuilder builder, ByteData data) {
    builder
        .add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}

class _MeshReadResult {
  final PackedMesh mesh;
  final int nextOffset;

  _MeshReadResult(this.mesh, this.nextOffset);
}

class _MeshHeader {
  final GeometryType geometryType;
  final MaterialType materialType;
  final int verticesLength;
  final int indicesLength;
  final int geometryUniformLength;
  final int materialUniformLength;

  _MeshHeader({
    required this.geometryType,
    required this.materialType,
    required this.verticesLength,
    required this.indicesLength,
    required this.geometryUniformLength,
    required this.materialUniformLength,
  });
}

class _MeshData {
  final ByteData vertices;
  final ByteData indices;
  final ByteData? geometryUniform;
  final ByteData? materialUniform;
  final int nextOffset;

  _MeshData(this.vertices, this.indices, this.geometryUniform,
      this.materialUniform, this.nextOffset);
}

class PackedMesh {
  final PackedGeometry geometry;
  final PackedMaterial material;

  PackedMesh(this.geometry, this.material);
}

class PackedGeometry {
  final ByteData vertices;
  final ByteData indices;
  final ByteData? uniform;
  final GeometryType type;

  PackedGeometry(
      {required this.vertices,
      required this.indices,
      this.uniform,
      required this.type});
}

class PackedMaterial {
  final ByteData? uniform;
  final MaterialType type;

  PackedMaterial({this.uniform, required this.type});
}
