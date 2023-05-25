const BRAILLE_ZERO = 2800;
override imageWidth: u32;
override imageHeight: u32;
override threshold: f32 = 0.5;

@group(0) @binding(0) var inputTex: texture_2d<f32>;
@group(0) @binding(1) var<storage, read_write> outputBuf: array<u32>;


@compute @workgroup_size(2,4)
fn main (@builtin(global_invocation_id) gid: vec3u) {
    let segmentX = gid.x * 2;
    let segmentY = gid.y * 4;
    if (segmentY+4 >= imageHeight || segmentX+2 >= imageWidth) { return; }
   
    var result: u32 = 0u;
    for (var y: u32 = 0u; y < 4; y++) {
        for (var x: u32 = 0u; x < 2; x++) {
            let pixelY = segmentY + y;
            let pixelX = segmentX + x;
            let color = textureLoad(inputTex, vec2u(pixelX, pixelY), 0);
            let intensity = (color. r + color.g + color.b) / 3.0;
            let dotIdx = y * 2u + x;
            result |= (u32(intensity > threshold) << dotIdx);
        }
    }
    
    let out_index = (segmentY * imageWidth + segmentX);
    outputBuf[out_index] |= BRAILLE_ZERO + result; 
}