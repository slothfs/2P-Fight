shader_type canvas_item;

void fragment() {
    float t = TIME * 3.0;

    float r = sin(t) * 0.5 + 0.5;
    float g = sin(t + 2.0) * 0.5 + 0.5;
    float b = sin(t + 4.0) * 0.5 + 0.5;

    COLOR = vec4(r, g, b, 1.0);
}