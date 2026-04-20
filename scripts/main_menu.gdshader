shader_type canvas_item;

uniform float strength = 5.0;
uniform float speed = 2.0;

void fragment() {
    vec2 uv = UV;

    uv.y += sin(uv.x * 10.0 + TIME * speed) * 0.02 * strength;
    uv.x += cos(uv.y * 10.0 + TIME * speed) * 0.02 * strength;

    COLOR = texture(TEXTURE, uv);
}