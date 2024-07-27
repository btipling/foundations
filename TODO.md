# TODOs

Things to try and do as I learn more about graphical programming

## Point, line, plane & polygon equation programs

- [x] A program that lets you add and subtract vectors together visually to visually see displacement!
        - [ ] I need an arrow drawer!
- [ ] A program that draws a line and then a user clicks on the screen and it draws a new line from the original line. Reports distance to the line.
- [ ] A program that draws a line and a point, maybe a ray, and by interacting the user can add another point further down the line
- [ ] Detect if 3 or more points are collinear
- [ ] A program that draws a line from a plane to a point where the user may have clicked or used ui to create a point in 3D
- [ ] A program that detects if a point lies within a convex polyhederon by checking all of its planes using the generalized plane equation
- [ ] A frustum cull type operation that culls objects not within a set of planes but with it visible from the camera
- [ ] Determine if four points are coplanar or collinear via triple scalar product (cross products for collinear)
- [ ] Determine if a 3D point lying within a triangle plane lies within a triangle or external to it
- [ ] Write a program to describe the barycentric coordinates in a triangle
- [ ] Given a generalized plane equation and a point, draw a plane
- [ ] Draw a cube or other polygon with normals, give a color to +Z different from the other normals to
        prove that the +Z side by default faces the camera as NDC is a left handed coordinate system, the color should be the one facing the viewer
- [ ] I really need to do a lot with the normalized plane equation to understand how it works once I have projections.
- [ ] Do a thing to reflect something around an abitrary plane centered around the origin.
- [ ] All the plane things from Chapter 3 in FGED, intersection of a line in a plane, reflecting a point across a plane, intersecting planes...

## Interpolation, curves and arcs

- [ ] Draw an arc in the world, maybe with some kind of animation going back and forth
- [ ] maybe show a number in the animation above that shows the arc distance left from beginning to end
- [ ] Draw a camera sequence that curves around a path using both constant rate and ease in and out methods
- [ ] Do a slerp thing
- [ ] Get fraction of the angular displacement of a quaternion, follow code example in 3D Math primer and my reading notes for that chapter

## Misc

- [ ] Check handedess of spherical coordinate code. Make sure it works for x up left handed.
- [ ] Check the handedness of my rotation matrices
- [ ] Move all the scenes and object points to be left handed X up.
- [ ] investigate fixing drag and drop in lines to use withinCircle

## Ideas

Make a bunch of small single level games, a racing game, a 3D fps game of some kind in a small level, a platform game, a small voxel game and then build out the concepts from the books into an engine that will make each of these games look better and do more things. Like shadows, lighting, physics, collisons etc.

Armored core was a really cool game.

- [ ] Make a flying game with a plane with proper yaw pitch roll for fun above some terrain.
