
struct UniformParameters {
    view_matrix: mat4x4<f32>,
    perspective_matrix: mat4x4<f32>,
    inv_perspective_matrix: mat4x4<f32>,
    time: f32
}

struct InputVertex {
    @location(0) position: vec3f,
    @location(1) normal: vec3f,
    @location(2) uv: vec2f,
    @location(3) color: vec4f,
}

struct OutputVertex {
    @builtin(position) position: vec4f,
    @location(0) normal: vec3f,
    @location(1) uv: vec2f,
    @location(2) color: vec4f,
}

@group(0) @binding(0) var<uniform> uniforms: UniformParameters;
@group(1) @binding(0) var sky_texture: texture_cube<f32>;
@group(1) @binding(1) var sky_sampler: sampler;

const resolution: vec2f = vec2f(1600.0, 900.0);

@vertex
fn vs_main(in_vert: InputVertex) -> OutputVertex {
    var out_vert: OutputVertex;
    out_vert.position = uniforms.perspective_matrix * uniforms.view_matrix * vec4f(in_vert.position * 5.0, 1.0);
    out_vert.normal = in_vert.normal;
    out_vert.uv = in_vert.uv;
    out_vert.color = in_vert.color;
    return out_vert;
}

@fragment
fn fs_main(frag: OutputVertex) -> @location(0) vec4f {   
    let noise = domainWarp(frag.uv * 100.0);
    let diffuse_color = vec3f(pallete(noise));

    let light_dir = vec3f(1.0, 1.0, 1.0);
    let diffuse_value = saturate(dot(frag.normal, normalize(light_dir)));
    let color = diffuse_color * diffuse_value;

    return vec4f(color, 1.0);
}



///SKY

struct SkyVSOut {
    @builtin(position) position: vec4f,
    @location(0) uv: vec3f
}

@vertex
fn sky_vs_main(@builtin(vertex_index) id: u32) -> SkyVSOut {
    let x = i32(id) & 2;
    let y = i32(id) & 1;

    let pos = vec4f(
        f32(x) * 4.0 - 1.0,
        1.0 - f32(y) * 4.0,
        1.0,
        1.0
    );

    let view_inv = transpose(mat3x3<f32>(
        uniforms.view_matrix[0].xyz,
        uniforms.view_matrix[1].xyz,
        uniforms.view_matrix[2].xyz
    ));

    let view_pos = uniforms.inv_perspective_matrix * pos;

    var out_vert: SkyVSOut;
    out_vert.position = pos;
    out_vert.uv = view_inv * view_pos.xyz;

    return out_vert;
}

@fragment
fn sky_fs_main(frag: SkyVSOut) -> @location(0) vec4f {   
    return textureSample(sky_texture, sky_sampler, frag.uv);
}





//Misc 
fn pallete(t: f32) -> vec3f {
    let offset = vec3f(0.500, 0.500, 0.500); 
    let amp = vec3f(0.500, 0.500, 0.500);
    let freq =  vec3f(0.800, 0.800, 0.500);
    let phase = vec3f(0.000, 0.200, 0.500);

    return offset + amp * cos( 6.28 * (freq * t + phase));
}

fn domainWarp(pos2: vec2f) -> f32 {
    let r = length(pos2);
    let t = length(atan(pos2));
    let pos = vec2f(r, t);
    let offset = vec2f(
        fbm(pos + vec2f(15.424, 42.14), 2),
        fbm(pos + vec2f(74.824, 378.54), 2)
    );

    return fbm(pos + offset, 2);
}

fn fbm(pos: vec2f, octaves: i32) -> f32 {
    var accum = 0.0;
    var result = 0.0;
    var freq = 1.0;
    var amp = 1.0;

    for(var i = 0; i < octaves; i += 1) {
        let noise = perlinNoise(pos * freq) * 0.5 + 0.5;
        result += noise * amp;
        accum += amp;
        freq *= 2.0;
        amp *= 0.5;
    }

    return result / accum;
}

fn perlinNoise(pos: vec2f) -> f32 {
    let base = floor(pos);
    let dist = fract(pos);

    let d1 = dot(randomGradient(base + vec2f(0.0, 0.0)), dist - vec2f(0.0, 0.0));
    let d2 = dot(randomGradient(base + vec2f(1.0, 0.0)), dist - vec2f(1.0, 0.0));
    let d3 = dot(randomGradient(base + vec2f(0.0, 1.0)), dist - vec2f(0.0, 1.0));
    let d4 = dot(randomGradient(base + vec2f(1.0, 1.0)), dist - vec2f(1.0, 1.0));

    let k = smoothstep(vec2f(0.0), vec2f(1.0), dist);

    let lerp1 = mix(d1, d2, k.x);
    let lerp2 = mix(d3, d4, k.x);

    return mix(lerp1, lerp2, k.y);
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
    let random = 0.5 * uniforms.time * f32(a) * (3.14159265 / f32(~(~u32(0) >> 1))); // in [0, 2*Pi]

    return vec2f(cos(random), sin(random));
}


