# ft3d

Use to generate 3D textures. Currently supports marble and striped textures

```
mkdir texture3d
zig build ft3d -- --type striped --output texture3d --name striped.vol

zig build ft3d -- --type marble --output texture3d --name marble.vol
```

Then move the files to the app cache directory.

Easy dev loop command I use:
```
 zig build ft3d -- --type wave --output texture3d --name wave.vol && mv -Force .\texture3d\wave.vol C:\Users\swart\AppData\Local\foundations_game_engine\textures_3d\cgpoc && zig build run
```