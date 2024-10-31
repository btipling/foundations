# ft3d

Use to generate 3D textures. Currently supports marble and striped textures

```
mkdir texture3d
zig build ft3d -- --type striped --output texture3d --name striped.vol

zig build ft3d -- --type marble --output texture3d --name marble.vol
```

Then move the files to the app cache directory.