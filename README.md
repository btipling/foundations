# Foundations

![bg](https://github.com/user-attachments/assets/ed006c20-98ce-453c-ab6c-30930010545d)

This is an attempt to build a game engine and learn graphics programming in zig. This project is named after Eric Lengyel game engine series [Foundations of Game Engine Development](https://foundationsofgameenginedev.com/) which is pretty cool. This project will be mostly in
OpenGL but I might attempt a Vulkan triangle or two as well as try other things.

This will be a mostly from scratch graphical programming engine/project with self-teaching in mind, with my own math, as raw OpenGL as possible, just a few barebones dependencies cimgui, glad, glfw. I may eventually add an obj/glftf and image loader for textures and for audio.  Working my way through my books.

I realized I had too many layers in blockens that blocked understanding and I wanted everything to be mine, so that I could understand everything from the ground up. I'm not using any tutorials, no off the shelf code. It will all be my math, my code all the way down to the shaders.

If I want to understand or experiment with some new culling mechanism. I can do it in this project without figuring it out in the middle of a game I'm working on.

These are the books I am going to use to learn are listed below. I will not reproduce any of the content from these books, am just sharing that I'm using them to learn how to do graphics
programming and build a game engine.

* <https://foundationsofgameenginedev.com/>
* <https://www.mathfor3dgameprogramming.com/>
* <https://www.gameenginebook.com/>
* <https://athena.ecs.csus.edu/~gordonvs/textC2E.html>
* <https://athena.ecs.csus.edu/~gordonvs/textC3E.html>
* <https://essentialmath.com/book.htm>
* <https://www.gamemath.com/>

![Torus](https://github.com/user-attachments/assets/2ed06912-4b29-423d-b78c-4dcf87fa5812)

![Solar System](https://github.com/user-attachments/assets/34e66724-25fc-43bb-82a0-7180ddd8d8d4)

![Shadows](https://github.com/user-attachments/assets/629025f8-6f5f-4bc9-bb6e-6844005a2130)

## Note

The textures and models from the book I use in the CGPOC section may be copyrighted and thus they aren't included and won't load.

## Open Source Dependencies

I am grateful for to the open source community for creating tools and libraries that anyone can use for free. This project depends on the following open source projects:

### Glad

The MIT License (MIT)
Copyright (c) 2013-2022 David Herberth

### Dear Imgui

The MIT License (MIT)
Copyright (c) 2014-2024 Omar Cornut

### cimgui

The MIT License (MIT)
Copyright (c) 2015 Stephan Dilly

### GLFW

GLFW 3.5 - <www.glfw.org>
A library for OpenGL, window and input
Copyright (c) 2002-2006 Marcus Geelnard
Copyright (c) 2006-2018 Camilla Löwy <elmindreda@glfw.org>

### STB

MIT License
Copyright (c) 2017 Sean Barrett

### PNC GLSL

MIT License
Copyright 2020 Riccardo Scalco
https://github.com/riccardoscalco/glsl-pcg-prng/

