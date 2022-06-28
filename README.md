# Real-time Rendering of Procedurally Generated Terrain

This is a NAU3D project with GLSL shader implementing procedurally generated terrain.

**Features**

- Procedural generation with various noise functions such as Perlin, Simplex and Voronoi noise.
- Variable terrain detail via a extensively parametrized [Fractional Brownian Motion](https://en.wikipedia.org/wiki/Fractional_Brownian_motion) implementation.
- Dynamic Blinn–Phong lighting model.
- Height based texturing, applied with noise based sampling to disguise obvious texture repetition/tiling.

<p align="center">
    <img src="imgs/ExampleProcedural.gif" width="900" />
</p>

Dependencies
====

This project is specifically made to run on the [Nau](https://github.com/Nau3D/nau) rendering engine.
