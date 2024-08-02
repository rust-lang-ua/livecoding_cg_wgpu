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

@fragment
fn fs_main(@builtin(position) pos: vec4f) -> @location(0) vec4f {
    let uv = pos.xy / 100;
    let perl = perlin(uv.x, uv.y) * 0.5 + 0.5;

    let color = vec3f(perl);
    return vec4f(color, 1.0);
}

/* Function to linearly interpolate between a0 and a1
 * Weight w should be in the range [0.0, 1.0]
 */
fn interpolate( a0: f32,  a1: f32,  w: f32) -> f32{
    /* // You may want clamping by inserting:
     * if (0.0 > w) return a0;
     * if (1.0 < w) return a1;
     */
    //return (a1 - a0) * w + a0;
    return (a1 - a0) * ((w * (w * 6.0 - 15.0) + 10.0) * w * w * w) + a0;
    /* // Use this cubic interpolation [[Smoothstep]] instead, for a smooth appearance:
     * return (a1 - a0) * (3.0 - w * 2.0) * w * w + a0;
     *
     * // Use [[Smootherstep]] for an even smoother result with a second derivative equal to zero on boundaries:
     * return (a1 - a0) * ((w * (w * 6.0 - 15.0) + 10.0) * w * w * w) + a0;
     */
}

/* Create pseudorandom direction vector
 */
fn randomGradient( ix: i32,  iy: i32) -> vec2f {
    // No precomputed gradients mean this works for any number of grid coordinates
    let w = u32(32);
    let s = w / 2; // rotation width
    var a = u32(ix);
    var b = u32(iy);
    a *= u32(3284157443); b ^= a << s | a >> w-s;
    b *= u32(1911520717); a ^= b << s | b >> w-s;
    a *= u32(2048419325);
    let random = 0.5 * time * f32(a) * (3.14159265 / f32(~(~u32(0) >> 1))); // in [0, 2*Pi]

    return vec2f(cos(random), sin(random));
}

// Computes the dot product of the distance and gradient vectors.
fn dotGridGradient( ix: i32,  iy: i32,  x: f32,  y: f32) -> f32 {
    // Get gradient from integer coordinates
    let gradient = randomGradient(ix, iy);

    // Compute the distance vector
    let dx = x - f32(ix);
    let dy = y - f32(iy);

    // Compute the dot-product
    return (dx*gradient.x + dy*gradient.y);
}

// Compute Perlin noise at coordinates x, y
fn perlin( x: f32, y: f32) -> f32 {
    // Determine grid cell coordinates
    let x0 = i32(floor(x));
    let x1 = x0 + 1;
    let y0 = i32(floor(y));
    let y1 = y0 + 1;

    // Determine interpolation weights
    // Could also use higher order polynomial/s-curve here
    let sx = x - f32(x0);
    let sy = y - f32(y0);

    // Interpolate between grid point gradients

    var n0 = dotGridGradient(x0, y0, x, y);
    var n1 = dotGridGradient(x1, y0, x, y);
    let ix0 = interpolate(n0, n1, sx);

    n0 = dotGridGradient(x0, y1, x, y);
    n1 = dotGridGradient(x1, y1, x, y);
    let ix1 = interpolate(n0, n1, sx);

    let value = interpolate(ix0, ix1, sy);
    return value; // Will return in range -1 to 1. To make it in range 0 to 1, multiply by 0.5 and add 0.5
}