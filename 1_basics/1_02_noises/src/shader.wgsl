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
    var uv = (pos.xy - resolution / 2.0) / 100;

    //let noise = fbm(uv, 5);
    //let noise = 1.0 - worleyNoise(uv);
    var noise = domainWarp(uv);

    let lightDir = vec3f(1.0, 1.0, 1.0);
    let viewDir = vec3f(0.0, 0.0, 1.0);

    let normal = normalize(vec3f(dpdx(noise), dpdy(noise), 0.001));

    var d = saturate(dot(normalize(lightDir), normal));
    
    let diffuseLight = vec3f(0.0, 0.3, 0.6) * 0.5 + d * 0.2;

    var phongValue = saturate(dot(normalize(lightDir + viewDir), normal));
    phongValue = pow(phongValue, 32.0);

    var color = mix(
        vec3f(0.0, 43.0, 255.0) / 255.0,
        vec3f(49.0, 192.0, 255.0) / 255.0,
        smoothstep(0.0, 1.0, noise)
    );

    color = color * diffuseLight + phongValue;
    //color = pow(color, vec3f(1 / 2.2));
    //color = vec3f(noise);

    return vec4f(color, 1.0);
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

fn worleyNoise(pos: vec2f) -> f32 {
    let base = floor(pos);
    let dist = fract(pos);

    var accum = 0.0;
    var minDist = 1.0;
    let k = -5.0;

    for(var x = -1.0; x <= 1.0; x += 1.0) {
        for(var y = -1.0; y <= 1.0; y += 1.0) {
            let offset = vec2f(x, y);
            let cellP = abs(vec2f(
                perlinNoise(base + offset + vec2f(12.515, 166.424)),
                perlinNoise(base + offset + vec2f(82.115, 76.624))
            ));
            let currDist = cellP + offset - dist;
            accum += exp(length(currDist) * k);
            //minDist = min(minDist, length(currDist));
        }
    }

    return log(accum) / k;
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
    let random = 0.5 * time * f32(a) * (3.14159265 / f32(~(~u32(0) >> 1))); // in [0, 2*Pi]

    return vec2f(cos(random), sin(random));
}

