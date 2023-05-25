const BRAILLE_ZERO = 0x2800;
override imageWidth: u32;
override imageHeight: u32;
override threshold: f32;

@group(0) @binding(0) var inputTex: texture_2d<f32>;
@group(0) @binding(1) var<storage, read_write> outputBuf: array<u32>;


@compute @workgroup_size(4,2)
fn main (@builtin(global_invocation_id) gid: vec3u) {
    let segmentX = gid.x;
    let segmentY = gid.y;
    if (segmentY >= imageHeight || segmentX >= imageWidth) { return; }
   
    var result: u32 = 0u;
    let pixelX1 = segmentX;
    let pixelX2 = segmentX + 1u;
    for (var y: u32 = 0u; y < 3; y++) {
        let pixelY = segmentY + y;
        
        let color1 = textureLoad(inputTex, vec2u(pixelX1, pixelY), 0);
        let color2 = textureLoad(inputTex, vec2u(pixelX2, pixelY), 0);
        
        let intensity1 = (color1. r + color1.g + color1.b) / 3.0;
        let intensity2 = (color2. r + color2.g + color2.b) / 3.0;

        let dotIdx1 = y;
        let dotIdx2 = y + 3;

        let mask1 = u32(intensity1 > threshold) << dotIdx1;  
        let mask2 = u32(intensity2 > threshold) << dotIdx2;

        result |= mask1;
        result |= mask2;      
    }

    let pixelY = segmentY + 3u;
    
    let color1 = textureLoad(inputTex, vec2u(pixelX1, pixelY), 0);
    let color2 = textureLoad(inputTex, vec2u(pixelX2, pixelY), 0);
    
    let intensity1 = (color1. r + color1.g + color1.b) / 3.0;
    let intensity2 = (color2. r + color2.g + color2.b) / 3.0;

    let mask1 = u32(intensity1 > threshold) << 6u;  
    let mask2 = u32(intensity2 > threshold) << 7u;

    result |= mask1;
    result |= mask2;      

    let out_index = (segmentY * imageWidth + segmentX);
    outputBuf[out_index] = result + BRAILLE_ZERO; 
}