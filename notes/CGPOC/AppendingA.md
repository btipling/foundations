# Appendix A - Installation and Setup for PC

Install Visual Studio 2022

Check hardware for OpenGL support with GLView https://www.realtech-vr.com/home/?page_id=1402 

Says to use CMAKE with GLFW, I did not need that personally, just did windows only build in my build.zig. They're advising building a libs. I did static libs.

GLEW instructions also include a lib. I used glad.

I'm skipping GLM for now, going to write my own math to learn how to do it, I would use GLM though.

SOIL2 requires premake https://premake.github.io/

VS instructions for combinging all the libraries. Put 'lib' libraries in lib, headers in include, pretty standard, dll top level.

Use VS template

VS code can build a release mode with all the files and images and models your project needs. I actually don't know how to do this with zig's build system.

