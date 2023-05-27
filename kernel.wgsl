const BRAILLE_ZERO = 0x2800;
const NEWLINE_CHAR = 0x0d;
override imageWidth: u32;
override imageHeight: u32;
override threshold: f32;
override invert: bool;

@group(0) @binding(0) var inputTex: texture_2d<f32>;
@group(0) @binding(1) var<storage, read_write> outputBuf: array<u32>;

const BRAILLE_DOT_TABLE: array<u32, 8> = array(0,3,1,4,2,5,6,7);
// const DITHER_MATRIX = mat2x2f(0.0, 0.5, 0.75, 0.25);

@compute @workgroup_size(2,4)
fn main (@builtin(global_invocation_id) gid: vec3u) {
    let pix = gid.xy * vec2u(2,4);
    if (pix.y >= imageHeight || pix.x > imageWidth) { return; }
    if (pix.x == imageWidth) {
        let out_index = gid.x + gid.y * (imageWidth/2);
        outputBuf[out_index] = NEWLINE_CHAR; 
        return;
    }
    var result: u32 = BRAILLE_ZERO;
    for (var dy: u32 = 0u; dy < 4; dy++) {
        for (var dx: u32 = 0u; dx < 2; dx++) {
            // let dither_scale = DITHER_MATRIX[u32(pix.x + dx) % 2][u32(pix.y + dy) %2];
            let color = textureLoad(inputTex, vec2u(pix.x + dx, pix.y +dy), 0);
            let luminosity = dot(color.rgb, vec3f(0.21,0.72,0.07));
            let dotIdx = BRAILLE_DOT_TABLE[dy * 2u + dx];
            if invert {
                result |= u32(luminosity <= threshold) << dotIdx;    
            } else {
                result |= u32(luminosity > threshold) << dotIdx;    
            }
        }
    }
    
    let out_index = gid.x + gid.y * (imageWidth/2);
    outputBuf[out_index] =  result;
}