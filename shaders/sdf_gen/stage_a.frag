uniform FragInfo {
    float width;
    float height;
    float radius;
}
frag_info;

uniform sampler2D glyph_texture;


in vec2 v_position;

out vec4 frag_color;

void main() {

    float dist = 9999;

    float minBound = max(v_position.y - (frag_info.radius / frag_info.height), 0);
    float maxBound = max(v_position.y + (frag_info.radius / frag_info.height), 1);
    float stepSize = 1 / frag_info.height;



    for (float i = minBound; i < maxBound; i += stepSize) {

        float existingValue = texture(glyph_texture, vec2(v_position.x, i)).x;

        float currentDist = abs(i - v_position.y) * frag_info.height / frag_info.radius;
        dist = min(dist, (currentDist * currentDist) + existingValue);

    }


    frag_color = vec4(vec3(dist), 1);
}