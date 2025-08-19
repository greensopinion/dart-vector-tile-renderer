import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';

void main() {
  group('TileRenderData', () {
    test('pack and unpack empty data', () {
      final originalData = TileRenderData();
      
      final packed = originalData.pack();
      final bytes = packed.materialize().asUint8List();
      final unpacked = TileRenderData.unpack(bytes);
      
      expect(unpacked.data.length, equals(0));
    });

    test('pack and unpack single mesh with basic data', () {
      final originalData = TileRenderData();
      
      // Create test data
      final verticesData = Uint8List.fromList([1, 2, 3, 4]);
      final indicesData = Uint8List.fromList([5, 6, 7, 8]);
      
      final geometry = PackedGeometry(
        vertices: ByteData.view(verticesData.buffer),
        indices: ByteData.view(indicesData.buffer),
        type: GeometryType.line,
      );
      
      final material = PackedMaterial(
        type: MaterialType.colored,
      );
      
      final mesh = PackedMesh(geometry, material);
      originalData.addMesh(mesh);
      
      // Pack and unpack
      final packed = originalData.pack();
      final bytes = packed.materialize().asUint8List();
      final unpacked = TileRenderData.unpack(bytes);
      
      // Verify unpacked data
      expect(unpacked.data.length, equals(1));
      final unpackedMesh = unpacked.data[0];
      
      expect(unpackedMesh.geometry.type, equals(GeometryType.line));
      expect(unpackedMesh.material.type, equals(MaterialType.colored));
      
      expect(unpackedMesh.geometry.vertices.lengthInBytes, equals(4));
      expect(unpackedMesh.geometry.indices.lengthInBytes, equals(4));
      expect(unpackedMesh.geometry.uniform, isNull);
      expect(unpackedMesh.material.uniform, isNull);
      
      // Verify actual data content
      final unpackedVertices = unpackedMesh.geometry.vertices.buffer
          .asUint8List(unpackedMesh.geometry.vertices.offsetInBytes, 4);
      final unpackedIndices = unpackedMesh.geometry.indices.buffer
          .asUint8List(unpackedMesh.geometry.indices.offsetInBytes, 4);
      
      expect(unpackedVertices, equals([1, 2, 3, 4]));
      expect(unpackedIndices, equals([5, 6, 7, 8]));
    });

    test('pack and unpack mesh with uniform data', () {
      final originalData = TileRenderData();
      
      // Create test data with uniforms
      final verticesData = Uint8List.fromList([10, 20]);
      final indicesData = Uint8List.fromList([30, 40]);
      final geometryUniformData = Uint8List.fromList([50, 60, 70]);
      final materialUniformData = Uint8List.fromList([80, 90, 100, 110]);
      
      final geometry = PackedGeometry(
        vertices: ByteData.view(verticesData.buffer),
        indices: ByteData.view(indicesData.buffer),
        uniform: ByteData.view(geometryUniformData.buffer),
        type: GeometryType.polygon,
      );
      
      final material = PackedMaterial(
        uniform: ByteData.view(materialUniformData.buffer),
        type: MaterialType.line,
      );
      
      final mesh = PackedMesh(geometry, material);
      originalData.addMesh(mesh);
      
      // Pack and unpack
      final packed = originalData.pack();
      final bytes = packed.materialize().asUint8List();
      final unpacked = TileRenderData.unpack(bytes);
      
      // Verify unpacked data
      expect(unpacked.data.length, equals(1));
      final unpackedMesh = unpacked.data[0];
      
      expect(unpackedMesh.geometry.type, equals(GeometryType.polygon));
      expect(unpackedMesh.material.type, equals(MaterialType.line));
      
      expect(unpackedMesh.geometry.vertices.lengthInBytes, equals(2));
      expect(unpackedMesh.geometry.indices.lengthInBytes, equals(2));
      expect(unpackedMesh.geometry.uniform!.lengthInBytes, equals(3));
      expect(unpackedMesh.material.uniform!.lengthInBytes, equals(4));
      
      // Verify actual data content
      final unpackedVertices = unpackedMesh.geometry.vertices.buffer
          .asUint8List(unpackedMesh.geometry.vertices.offsetInBytes, 2);
      final unpackedIndices = unpackedMesh.geometry.indices.buffer
          .asUint8List(unpackedMesh.geometry.indices.offsetInBytes, 2);
      final unpackedGeometryUniform = unpackedMesh.geometry.uniform!.buffer
          .asUint8List(unpackedMesh.geometry.uniform!.offsetInBytes, 3);
      final unpackedMaterialUniform = unpackedMesh.material.uniform!.buffer
          .asUint8List(unpackedMesh.material.uniform!.offsetInBytes, 4);
      
      expect(unpackedVertices, equals([10, 20]));
      expect(unpackedIndices, equals([30, 40]));
      expect(unpackedGeometryUniform, equals([50, 60, 70]));
      expect(unpackedMaterialUniform, equals([80, 90, 100, 110]));
    });

    test('pack and unpack multiple meshes', () {
      final originalData = TileRenderData();
      
      // Create multiple meshes with different types and data
      for (int i = 0; i < 3; i++) {
        final verticesData = Uint8List.fromList([i * 10, i * 10 + 1]);
        final indicesData = Uint8List.fromList([i * 20, i * 20 + 2]);
        
        final geometry = PackedGeometry(
          vertices: ByteData.view(verticesData.buffer),
          indices: ByteData.view(indicesData.buffer),
          type: GeometryType.values[i % GeometryType.values.length],
        );
        
        final material = PackedMaterial(
          type: MaterialType.values[i % MaterialType.values.length],
        );
        
        final mesh = PackedMesh(geometry, material);
        originalData.addMesh(mesh);
      }
      
      // Pack and unpack
      final packed = originalData.pack();
      final bytes = packed.materialize().asUint8List();
      final unpacked = TileRenderData.unpack(bytes);
      
      // Verify unpacked data
      expect(unpacked.data.length, equals(3));
      
      for (int i = 0; i < 3; i++) {
        final unpackedMesh = unpacked.data[i];
        
        expect(unpackedMesh.geometry.type, 
            equals(GeometryType.values[i % GeometryType.values.length]));
        expect(unpackedMesh.material.type, 
            equals(MaterialType.values[i % MaterialType.values.length]));
        
        final unpackedVertices = unpackedMesh.geometry.vertices.buffer
            .asUint8List(unpackedMesh.geometry.vertices.offsetInBytes, 2);
        final unpackedIndices = unpackedMesh.geometry.indices.buffer
            .asUint8List(unpackedMesh.geometry.indices.offsetInBytes, 2);
        
        expect(unpackedVertices, equals([i * 10, i * 10 + 1]));
        expect(unpackedIndices, equals([i * 20, i * 20 + 2]));
      }
    });

    test('pack and unpack with mixed uniform presence', () {
      final originalData = TileRenderData();
      
      // Mesh 1: no uniforms
      final mesh1Vertices = Uint8List.fromList([1, 2]);
      final mesh1Indices = Uint8List.fromList([3, 4]);
      final mesh1 = PackedMesh(
        PackedGeometry(
          vertices: ByteData.view(mesh1Vertices.buffer),
          indices: ByteData.view(mesh1Indices.buffer),
          type: GeometryType.line,
        ),
        PackedMaterial(type: MaterialType.colored),
      );
      originalData.addMesh(mesh1);
      
      // Mesh 2: geometry uniform only
      final mesh2Vertices = Uint8List.fromList([5, 6]);
      final mesh2Indices = Uint8List.fromList([7, 8]);
      final mesh2GeometryUniform = Uint8List.fromList([9, 10, 11]);
      final mesh2 = PackedMesh(
        PackedGeometry(
          vertices: ByteData.view(mesh2Vertices.buffer),
          indices: ByteData.view(mesh2Indices.buffer),
          uniform: ByteData.view(mesh2GeometryUniform.buffer),
          type: GeometryType.polygon,
        ),
        PackedMaterial(type: MaterialType.line),
      );
      originalData.addMesh(mesh2);
      
      // Mesh 3: material uniform only
      final mesh3Vertices = Uint8List.fromList([12, 13]);
      final mesh3Indices = Uint8List.fromList([14, 15]);
      final mesh3MaterialUniform = Uint8List.fromList([16, 17]);
      final mesh3 = PackedMesh(
        PackedGeometry(
          vertices: ByteData.view(mesh3Vertices.buffer),
          indices: ByteData.view(mesh3Indices.buffer),
          type: GeometryType.background,
        ),
        PackedMaterial(
          uniform: ByteData.view(mesh3MaterialUniform.buffer),
          type: MaterialType.colored,
        ),
      );
      originalData.addMesh(mesh3);
      
      // Pack and unpack
      final packed = originalData.pack();
      final bytes = packed.materialize().asUint8List();
      final unpacked = TileRenderData.unpack(bytes);
      
      // Verify unpacked data
      expect(unpacked.data.length, equals(3));
      
      // Mesh 1: no uniforms
      final unpackedMesh1 = unpacked.data[0];
      expect(unpackedMesh1.geometry.uniform, isNull);
      expect(unpackedMesh1.material.uniform, isNull);
      
      // Mesh 2: geometry uniform only
      final unpackedMesh2 = unpacked.data[1];
      expect(unpackedMesh2.geometry.uniform, isNotNull);
      expect(unpackedMesh2.material.uniform, isNull);
      expect(unpackedMesh2.geometry.uniform!.lengthInBytes, equals(3));
      
      // Mesh 3: material uniform only
      final unpackedMesh3 = unpacked.data[2];
      expect(unpackedMesh3.geometry.uniform, isNull);
      expect(unpackedMesh3.material.uniform, isNotNull);
      expect(unpackedMesh3.material.uniform!.lengthInBytes, equals(2));
    });

    test('handles large data correctly', () {
      final originalData = TileRenderData();
      
      // Create a mesh with larger data arrays
      final largeVerticesData = Uint8List(1000);
      final largeIndicesData = Uint8List(500);
      
      // Fill with pattern data
      for (int i = 0; i < largeVerticesData.length; i++) {
        largeVerticesData[i] = i % 256;
      }
      for (int i = 0; i < largeIndicesData.length; i++) {
        largeIndicesData[i] = (i * 2) % 256;
      }
      
      final geometry = PackedGeometry(
        vertices: ByteData.view(largeVerticesData.buffer),
        indices: ByteData.view(largeIndicesData.buffer),
        type: GeometryType.line,
      );
      
      final material = PackedMaterial(type: MaterialType.colored);
      final mesh = PackedMesh(geometry, material);
      originalData.addMesh(mesh);
      
      // Pack and unpack
      final packed = originalData.pack();
      final bytes = packed.materialize().asUint8List();
      final unpacked = TileRenderData.unpack(bytes);
      
      // Verify the data integrity
      expect(unpacked.data.length, equals(1));
      final unpackedMesh = unpacked.data[0];
      
      expect(unpackedMesh.geometry.vertices.lengthInBytes, equals(1000));
      expect(unpackedMesh.geometry.indices.lengthInBytes, equals(500));
      
      // Verify pattern integrity
      final unpackedVertices = unpackedMesh.geometry.vertices.buffer
          .asUint8List(unpackedMesh.geometry.vertices.offsetInBytes, 1000);
      final unpackedIndices = unpackedMesh.geometry.indices.buffer
          .asUint8List(unpackedMesh.geometry.indices.offsetInBytes, 500);
      
      for (int i = 0; i < 1000; i++) {
        expect(unpackedVertices[i], equals(i % 256));
      }
      for (int i = 0; i < 500; i++) {
        expect(unpackedIndices[i], equals((i * 2) % 256));
      }
    });
  });
}