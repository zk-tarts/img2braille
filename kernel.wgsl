const BRAILLE_ZERO = 2800;

override imageWidth : u32;
override imageHeight : u32;
override threshold: f32 = 0.5;

@group(0) @binding(0) var<storage, read> inputTex: texture_storage_2d<rgba8unorm, read>;
@group(0) @binding(1) var<storage, read_write> outputBuf: array<u32>;


@compute @workgroup_size(2,4)
fn main (@builtin(global_invocation_id) gid: vec3u) {
    let segmentX = gid.x * 2;
    let segmentY = gid.y * 4;
    if (segmentY >= imageHeight || segmentY >= imageWidth) { return; }
   
    var result = array<vec4<bool>,2>;
    for (var y: u32 = 0u; y < 4; y++) {
        for (var x: u32 = 0u; x < 2; x++) {
            let pixelY = segmentY + y;
            let pixelX = segmentX + x;
            let color = textureLoad(inputTex, vec2u(pixelX, pixelY));
            let intensity = (color. r + color.g + color.b) / 3.0;
            result[x][y] = (intensity > threshold);
        }
    }
    let col_1237 = vec4(result[0].xyz, result[1].z); 
    let col_4568 = vec4(result[0].w, result[1].xyw);
    // does not work rn i just made something up
    outputBuf[segmentY * imageWidth + segmentX] |= BRAILLE_ZERO + col_1237; 
    outputBuf[(segmentY + 1) * imageWidth + segmentX] |= BRAILLE_ZERO + col_4568;
}