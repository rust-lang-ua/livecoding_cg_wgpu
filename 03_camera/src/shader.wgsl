
struct UniformParameters {
    view_matrix: mat4x4<f32>,
    perspective_matrix: mat4x4<f32>,
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
    let light_dir = vec3f(1.0, 1.0, 1.0);
    let diffuse_value = saturate(dot(frag.normal, normalize(light_dir)));
    let color = vec3(1.0) * diffuse_value;

    return vec4f(color, 1.0);
}

