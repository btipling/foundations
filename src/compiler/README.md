# Foundation Simple Shader Compiler

## About

Currenly a super basic shader compiler thatjust looks for `//#include "` for the source file, with no recursion and does
a replace.

That's it. Will likely do more later. I just needed for the shader madness to end.

## Running

```bash
zig build fssc -- --source .\src\foundations\scenes\cgpoc\chapter10\surface_detail\earth_frag.glsl --name earth_frag_improved --output .\src\foundations\scenes\cgpoc\chapter10\surface_detail\
```
