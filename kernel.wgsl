const BRAILLE_ZERO = 0x2800;
override imageWidth: u32;
override imageHeight: u32;
override threshold: f32;

@group(0) @binding(0) var inputTex: texture_2d<f32>;
@group(0) @binding(1) var<storage, read_write> outputBuf: array<atomic<u32>>;

const LUT: array<u32, 8> = array(0,3,1,4,2,5,6,7);

@compute @workgroup_size(2,4)
fn main (
    @builtin(global_invocation_id) gid: vec3u,
    @builtin(local_invocation_id) lid: vec3u,
    @builtin(workgroup_id) wid: vec3u,
) {
    if (gid.y >= imageHeight || gid.x >= imageWidth) { return; }

    let color = textureLoad(inputTex, vec2u(gid.x, gid.y), 0);
    let intensity = (color. r + color.g + color.b) / 3.0;
    let relativepos = lid.y * 2u + lid.x;
    let dotIdx = LUT[relativepos];
    let mask = u32(intensity > threshold) << dotIdx;

    let out_index = wid.y * imageHeight + wid.x + lid.x*2 + lid.y*4;
    let offset = lid.x * 16u;
    atomicStore(&outputBuf[out_index], (0x30 + wid.x) << offset);
}