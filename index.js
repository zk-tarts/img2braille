/// <reference types="@webgpu/types" />
window.addEventListener("DOMContentLoaded", async () => {
    const output_container = document.getElementById('output_container')
    const shader_src = await fetch ('./kernel.wgsl').then(res=>res.text())
    const threshold = 0.993;

    if (!("gpu" in navigator)) {
        console.log("WebGPU is not supported.");
        return;
    }

    const adapter = await navigator.gpu.requestAdapter()
    if (!adapter) {
        console.log("Failed to get GPU adapter.");
        return;
    }
    const device= await adapter.requestDevice()
    const image = await loadImage('https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Banana-Single.jpg/160px-Banana-Single.jpg')
    output_container.style.width =  `${image.width}ch`
    output_container.style.lineBreak = 'anywhere'
    const imageWidth = image.width %2 == 0 ? image.width : image.width + 1  
    const imageHeight = image.height%4 == 0  ? image.height : image.height + (4-(image.height%4))
    console.log(imageWidth, imageHeight)
    const texture = device.createTexture({
        size: {
            width : imageWidth,
            height: imageHeight,
        },
        format: "rgba8unorm",
        usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT
    })

    const bitmap = await createImageBitmap(image)
    device.queue.copyExternalImageToTexture(
        {source: bitmap},
        {texture},
        {width: image.width, height: image.height, depthOrArrayLayers: 1}
    )

    const outputSize =  (imageHeight / 4) * (imageWidth / 2)
    const outputBuffer = device.createBuffer({
        size: outputSize ,
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
                resource: texture.createView()
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
    const workgroupCountX = imageWidth / 2
    const workgroupCountY = imageHeight / 4
    passEncoder.dispatchWorkgroups(workgroupCountX, workgroupCountY);      
    passEncoder.end()   

    const gpuReadBuffer = device.createBuffer({
        size: outputSize ,
        usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
    })

    commandEncoder.copyBufferToBuffer(
        outputBuffer,
        0,
        gpuReadBuffer,
        0,
        outputSize 
    )

    const gpuCommands = commandEncoder.finish()
    device.queue.submit([gpuCommands])

    await gpuReadBuffer.mapAsync(GPUMapMode.READ);
    const result_buffer = gpuReadBuffer.getMappedRange()
    console.log(result_buffer)
    output_container.textContent = _arrayBufferToString(result_buffer)
})

// stolen from stack overflow
function _arrayBufferToString( buffer ) {
    var binary = '';
    var bytes = new Uint16Array( buffer );
    var len = bytes.byteLength / bytes.BYTES_PER_ELEMENT;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return binary
}

function loadImage(url) {
    return new Promise((resolve, reject) => {
        const image = new Image()
        image.crossOrigin = 'anonymous'
        image.onload = () => resolve(image)
        image.onerror = reject
        image.src = url
    })
}
    