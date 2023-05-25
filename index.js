/// <reference types="@webgpu/types" />
window.addEventListener("DOMContentLoaded", async () => {
    const res = await fetch ('./kernel.wgsl')
    const shader_src =  await res.text()
    const imageWidth = 255;
    const imageHeight = 255;
    const threshold = 0.5;

    if (!("gpu" in navigator)) {
        console.log("WebGPU is not supported. Enable chrome://flags/#enable-unsafe-webgpu flag.");
        return;
    }

    const adapter = await navigator.gpu.requestAdapter()
    if (!adapter) {
        console.log("Failed to get GPU adapter.");
        return;
    }
    const device= await adapter.requestDevice()
    
    const inputTexture = device.createTexture({
        size: {
            width : imageWidth,
            height: imageHeight,
        },
        format: "rgba8unorm",
        usage: GPUTextureUsage.TEXTURE_BINDING
    })
    
    const outputBuffer = device.createBuffer({
        size: Math.floor(imageHeight*imageWidth / 8),
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC
    })

    const shaderModule = device.createShaderModule({code: shader_src})
    
    const computePipeline = device.createComputePipeline({
        layout: "auto",
        compute : {
            module: shaderModule,
            entryPoint : "main",
            constants: {
                imageWidth,
                imageHeight,
                threshold,
            },
        },
    })
    
    const bindgroup = device.createBindGroup({
        layout: computePipeline.getBindGroupLayout(0),
        entries: [
            {
                binding: 0,
                resource: inputTexture.createView()
            },
            {
                binding: 1,
                resource: {
                    buffer: outputBuffer
                }
            }
        ]
    })

    const commandEncoder = device.createCommandEncoder();
    const passEncoder = commandEncoder.beginComputePass();
    passEncoder.setPipeline(computePipeline)
    passEncoder.setBindGroup(0,bindgroup)
    const workgroupCountX = Math.ceil(imageHeight / 8*2);
    const workgroupCountY = Math.ceil(imageWidth / 8*4);
    passEncoder.dispatchWorkgroups(workgroupCountX, workgroupCountY);      
    passEncoder.end()

    const gpuReadBuffer = device.createBuffer({
        size: Math.floor(imageHeight*imageWidth / 8),
        usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
    })

    commandEncoder.copyBufferToBuffer(
        outputBuffer,
        0,
        gpuReadBuffer,
        0,
        Math.floor(imageHeight*imageWidth / 8)
    )

    const gpuCommands = commandEncoder.finish()
    device.queue.submit([gpuCommands])

    await gpuReadBuffer.mapAsync(GPUMapMode.READ);
    const result_buffer = gpuReadBuffer.getMappedRange()
    console.log(_arrayBufferToString(result_buffer))
})

// stolen from stack overflow
function _arrayBufferToString( buffer ) {
    var binary = '';
    var bytes = new Uint8Array( buffer );
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return binary
}
    