# Image to braille on your GPU

Inspired by when people spam twitch chat with 'ascii art'
Theres some other people who have made this sort of program before. Look up braille ascii
Usage: clone this repository. Get a server running on localhost (`python3 -m http.server`). Open the page in a browser with WebGPU support (Chrome)

## Why does this exist?
To learn WebGPU. 
Thanks to https://developer.mozilla.org/en-US/docs/Web/API/webGPU_API and some other links, it wasn't too hard copypastaing the code and then tweaking

### Roadmap
 - dithering
 - works on many images
 - verify that im not screwing something up somewhere (invert acts kinda weird it looks like image width is changing)
 - twitch emote or FFZ/BTTV/7TV integration
  - this includes making the spam the right size (and making a nice looking webpage (ew))
 - optimize it. 
  - Im wasting memory by using u32 for one character. Can use u16 but wgsl has no u16 type so i have to manually pack it.
  - Can use a textDecoder if I properly pack
  - Other stuff. I dont know if i even implemented this effieciently right now or if theres a lot of perf left on the table
 - Batch image processing. The GPU should be able to do way more than one picture at a time (cuz its fast) 