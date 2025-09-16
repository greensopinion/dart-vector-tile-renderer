const float TILE_SIZE = 256.0;

float getScaleFactor(mat4 cameraTransform, mat4 modelTransform) {
    mat4 matrix = transpose(modelTransform) * cameraTransform;
    return length(vec2(matrix[0][0], matrix[1][0])) / TILE_SIZE;
}