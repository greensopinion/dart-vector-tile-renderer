in vec2 position;

out vec2 v_position;

void main() {
    v_position = vec2((position.x + 1.0) * 0.5, 1 - (position.y + 1.0) * 0.5);
    gl_Position = vec4(position, 0, 1);
}