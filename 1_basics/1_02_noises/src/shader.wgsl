@vertex
fn vs_main(@builtin(vertex_index) id: u32) -> @builtin(position) vec4f {
    var pos = array<vec3f, 6>(
        vec3f(-1.0, -1.0, 0.0),
        vec3f(1.0, 1.0, 0.0),
        vec3f(-1.0, 1.0, 0.0),
        vec3f(-1.0, -1.0, 0.0),
        vec3f(1.0, -1.0, 0.0),
        vec3f(1.0, 1.0, 0.0),
    );

    return vec4f(pos[id], 1.0);
}

@group(0) @binding(0) var<uniform> time: f32;

const resolution: vec2f = vec2f(1600.0, 900.0);

@fragment
fn fs_main(@builtin(position) pos: vec4f) -> @location(0) vec4f {
    var uv = pos.xy / 100;
    uv = pos.xy / resolution;

    let color = vec3f(uv.x);
    return vec4f(color, 1.0);
}

fn randomGradient(posf: vec2f) -> vec2f {
    let posi = vec2i(posf);
    let w = u32(32);
    let s = w / 2; // rotation width
    var a = u32(posi.x);
    var b = u32(posi.y);
    a *= u32(3284157443); b ^= a << s | a >> w-s;
    b *= u32(1911520717); a ^= b << s | b >> w-s;
    a *= u32(2048419325);
    let random = 0.5 * time * f32(a) * (3.14159265 / f32(~(~u32(0) >> 1))); // in [0, 2*Pi]

    return vec2f(cos(random), sin(random));
}

