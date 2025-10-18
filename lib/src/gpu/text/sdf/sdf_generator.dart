import 'dart:math' as math;
import 'dart:typed_data';

/// Generates a Signed Distance Field (SDF) from a bitmap using the Felzenszwalb/Huttenlocher
/// distance transform algorithm. This creates smooth gradients for text rendering.
///
/// [bitmap] - Input bitmap where non-zero values represent text pixels
/// [width] - Width of the bitmap
/// [height] - Height of the bitmap
/// [radius] - Maximum distance to compute (controls SDF gradient range)
/// [cutoff] - Bias applied to the final distance values (shifts the zero-crossing)
/// Returns a Uint8List representing the SDF where 128 is the zero-crossing
Uint8List generateSDF(
    Uint8List bitmap, int width, int height, int radius, double cutoff) {
  final totalPixels = width * height;

  // Distance grids for computing exterior and interior distances
  // We compute both inside and outside distances separately, then combine them
  final exteriorDistanceGrid = Float64List(totalPixels);
  final interiorDistanceGrid = Float64List(totalPixels);

  // Working arrays for the 1D distance transform algorithm
  final maxDimension = math.max(width, height);
  final workingDistances = Float64List(maxDimension); // f array in algorithm
  final separatorPositions =
      Float64List(maxDimension + 1); // z array: separator positions
  final parabolicVertices =
      Int32List(maxDimension); // v array: parabola vertices

  // Initialize distance grids based on bitmap values
  // For exterior distances: start with 0 for text pixels, infinity for background
  // For interior distances: start with 0 for background pixels, infinity for text
  const double infinity =
      999999.0; // Large value representing infinite distance

  for (int i = 0; i < totalPixels; i++) {
    final pixelValue = bitmap[i];
    // Exterior grid: compute distances from outside the text shape
    exteriorDistanceGrid[i] = pixelValue == 0 ? infinity : 0.0;
    // Interior grid: compute distances from inside the text shape
    interiorDistanceGrid[i] = pixelValue > 0 ? infinity : 0.0;
  }

  // Phase 1: Transform along columns (vertical direction)
  // Process each column independently using 1D distance transform
  for (int columnIndex = 0; columnIndex < width; columnIndex++) {
    _computeDistanceTransform1D(
        exteriorDistanceGrid,
        workingDistances,
        parabolicVertices,
        separatorPositions,
        columnIndex,
        width,
        height,
        width);
    _computeDistanceTransform1D(
        interiorDistanceGrid,
        workingDistances,
        parabolicVertices,
        separatorPositions,
        columnIndex,
        width,
        height,
        width);
  }

  // Phase 2: Transform along rows (horizontal direction)
  // Process each row independently using 1D distance transform
  for (int rowIndex = 0; rowIndex < height; rowIndex++) {
    final rowStartOffset = rowIndex * width;
    _computeDistanceTransform1D(exteriorDistanceGrid, workingDistances,
        parabolicVertices, separatorPositions, rowStartOffset, width, 1, 1);
    _computeDistanceTransform1D(interiorDistanceGrid, workingDistances,
        parabolicVertices, separatorPositions, rowStartOffset, width, 1, 1);
  }

  // Combine interior and exterior distances to create the final SDF
  final sdfResult = Uint8List(totalPixels);
  for (int i = 0; i < totalPixels; i++) {
    // Compute signed distance: negative inside text, positive outside
    // Subtract interior distance from exterior distance
    final signedDistance =
        math.sqrt(exteriorDistanceGrid[i]) - math.sqrt(interiorDistanceGrid[i]);

    // Normalize to 0-255 range with cutoff bias
    // cutoff shifts the zero-crossing point, radius controls the gradient scale
    final normalizedValue =
        math.max(0, math.min(255, (signedDistance / radius + cutoff) * 255));
    sdfResult[i] = normalizedValue.round();
  }

  return sdfResult;
}

/// Computes 1D Euclidean Distance Transform using the linear-time algorithm
/// This is the core of the Felzenszwalb/Huttenlocher 2D distance transform
///
/// [distanceGrid] - The 2D distance grid being processed
/// [workingDistances] - Temporary array for distance values along the scan line
/// [parabolicVertices] - Indices of vertices that form the lower envelope of parabolas
/// [separatorPositions] - Positions where parabolas intersect (decision boundaries)
/// [startOffset] - Starting index in the grid for this scan line
/// [scanLength] - Number of pixels to process in this direction
/// [unusedStart] - Legacy parameter (not used)
/// [stepSize] - Step size between consecutive pixels (1 for rows, width for columns)
void _computeDistanceTransform1D(
    Float64List distanceGrid,
    Float64List workingDistances,
    Int32List parabolicVertices,
    Float64List separatorPositions,
    int startOffset,
    int scanLength,
    int unusedStart,
    int stepSize) {
  int envelopeSize = 0; // Number of parabolas in the lower envelope

  // Copy scan line data from the 2D grid to working array
  for (int i = 0; i < scanLength; i++) {
    workingDistances[i] = distanceGrid[startOffset + i * stepSize];
  }

  // Build the lower envelope of parabolas
  // Each pixel with finite distance creates a parabola y = (x-i)² + f[i]
  // We maintain only the visible (lowest) portions of these parabolas
  const double infinity = 999999.0;

  for (int currentPixel = 0; currentPixel < scanLength; currentPixel++) {
    if (workingDistances[currentPixel] != infinity) {
      if (envelopeSize == 0) {
        // First parabola - it covers everything initially
        parabolicVertices[0] = currentPixel;
        separatorPositions[0] = double.negativeInfinity;
        separatorPositions[1] = double.infinity;
        envelopeSize = 1;
      } else {
        // Remove parabolas that are completely dominated by the new one
        while (envelopeSize > 0) {
          final previousVertex = parabolicVertices[envelopeSize - 1];

          // Calculate intersection point of two parabolas
          // Parabola 1: (x-j)² + f[j], Parabola 2: (x-i)² + f[i]
          // Intersection at: x = ((f[i] + i²) - (f[j] + j²)) / (2i - 2j)
          final intersectionPoint =
              ((workingDistances[currentPixel] + currentPixel * currentPixel) -
                      (workingDistances[previousVertex] +
                          previousVertex * previousVertex)) /
                  (2 * currentPixel - 2 * previousVertex);

          // If intersection is at or before the start of the previous parabola's domain,
          // the previous parabola is completely dominated
          if (intersectionPoint <= separatorPositions[envelopeSize - 1]) {
            envelopeSize--;
          } else {
            break;
          }
        }

        // Add the new parabola to the envelope
        if (envelopeSize < scanLength) {
          parabolicVertices[envelopeSize] = currentPixel;

          // Calculate where this parabola starts being optimal
          if (envelopeSize > 0) {
            final prevVertex = parabolicVertices[envelopeSize - 1];
            separatorPositions[envelopeSize] =
                ((workingDistances[currentPixel] +
                            currentPixel * currentPixel) -
                        (workingDistances[prevVertex] +
                            prevVertex * prevVertex)) /
                    (2 * currentPixel - 2 * prevVertex);
          } else {
            separatorPositions[envelopeSize] = double.negativeInfinity;
          }

          separatorPositions[envelopeSize + 1] = double.infinity;
          envelopeSize++;
        }
      }
    }
  }

  // If no parabolas were added, all pixels had infinite distance
  if (envelopeSize == 0) return;

  // Fill in the distance values using the lower envelope
  // For each pixel position, find which parabola gives the minimum distance
  int currentParabolaIndex = 0;
  for (int pixelPosition = 0; pixelPosition < scanLength; pixelPosition++) {
    // Move to the next parabola if we've crossed its domain boundary
    while (currentParabolaIndex < envelopeSize - 1 &&
        separatorPositions[currentParabolaIndex + 1] <= pixelPosition) {
      currentParabolaIndex++;
    }

    // Compute distance using the optimal parabola at this position
    if (currentParabolaIndex < envelopeSize) {
      final optimalVertex = parabolicVertices[currentParabolaIndex];
      final horizontalDistance = pixelPosition - optimalVertex;
      // Distance² = (horizontal distance)² + original distance² at vertex
      distanceGrid[startOffset + pixelPosition * stepSize] =
          workingDistances[optimalVertex] +
              horizontalDistance * horizontalDistance;
    }
  }
}
