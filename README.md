# Real-time Rendering of Procedurally Generated Terrain

This is a [Nau](https://github.com/Nau3D/nau) project with GLSL shaders implementing procedurally generated terrain. It employs many real-time rendering techniques and allows for many types of terrain (realistic or toon-like, static or animated):

<p align="center">
    <img src="imgs/ExampleProcedural.gif" width="900" />
</p>


**Features**

- Procedural generation with various noise functions such as Perlin, Simplex and Voronoi noise.
- Variable terrain detail via a extensively parametrized and customizable [Fractional Brownian Motion](https://en.wikipedia.org/wiki/Fractional_Brownian_motion) implementation.
- Dynamic level of detail (LOD) via variable tessellation levels.
- Dynamic Blinn–Phong lighting model.
- Height based texturing, applied with noise based sampling to disguise obvious texture repetition/tiling.


Dependencies
====

This project is specifically made to run on the [Nau](https://github.com/Nau3D/nau) rendering engine.
