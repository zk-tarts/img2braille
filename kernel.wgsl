const BRAILLE_ZERO = 0x2800;
const NEWLINE_CHAR = 0x0d;
override imageWidth: u32;
override imageHeight: u32;
override threshold: f32;

@group(0) @binding(0) var inputTex: texture_2d<f32>;
@group(0) @binding(1) var<storage, read_write> outputBuf: array<u32>;

const LUT: array<u32, 8> = array(0,3,1,4,2,5,6,7);

@compute @workgroup_size(2,4)
fn main (@builtin(global_invocation_id) gid: vec3u) {
    let pix = gid.xy * vec2u(2,4); // top left corner of the 2x4 braille rect
    if (pix.y >= imageHeight || pix.x > imageWidth) { return; }
    if (pix.x == imageWidth) {
        let out_index = gid.x + gid.y * (imageWidth/2);
        outputBuf[out_index] = NEWLINE_CHAR; 
        return;
    }

    var result: u32 = BRAILLE_ZERO;
    for (var dy: u32 = 0u; dy < 4; dy++) {
        for (var dx: u32 = 0u; dx < 2; dx++) {
            let color = textureLoad(inputTex, vec2u(pix.x + dx, pix.y +dy), 0);
            let intensity = dot(color.rgb, vec3f(1/3.0f));
            let dotIdx = LUT[dy * 2u + dx];
            result |= u32(intensity > threshold) << dotIdx;    
        }
    }
    
    let out_index = gid.x + gid.y * (imageWidth/2);
    outputBuf[out_index] =  result;
}