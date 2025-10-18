# vector_tile_renderer

A vector tile renderer for use in creating map tile images or writing to a canvas.
Written in Dart to enable use of vector tiles with Flutter.

Looking for a flutter map widget that uses vector tiles? Take a look at [vector_map_tiles](https://github.com/greensopinion/flutter-vector-map-tiles)

## Version 7.0.0-beta

Version 7.0.0 depends on `flutter_gpu` and the Flutter development channel, which are pre-release software and can change at any time. See details on the [official Flutter GPU page](https://github.com/flutter/engine/blob/main/docs/impeller/Flutter-GPU.md).

For production apps, use version 6.0 of this library.

## Example

An example of output:

![rendered tile](https://raw.githubusercontent.com/greensopinion/dart-vector-tile-renderer/main/rendered-tile.png)

## Known Issues

* Theme layer types not implemented: circle, fill-extrusion, heatmap, hillshade, sky

## Development

### Continuous Integration

CI with GitHub Actions:

[![CI status](https://github.com/greensopinion/dart-vector-tile-renderer/actions/workflows/CI.yaml/badge.svg)](https://github.com/greensopinion/dart-vector-tile-renderer/actions)

### Resources

* [Maputnik Style Editor](https://maputnik.github.io/)
* Theme [style specification](https://docs.mapbox.com/mapbox-gl-js/style-spec/)

## Contributors

Many thanks to [the contributors](https://github.com/greensopinion/dart-vector-tile-renderer/graphs/contributors) who helped to improve this library.

## Sponsorship

<a href="https://github.com/EpicRideWeather" target="_blank">
  <img
    src="https://www.epicrideweather.com/images/epic-logo-r.svg"
    alt="Epic Ride Weather logo"
    width="64px"
  />
</a>

Development of this library is supported by [Epic Ride Weather](https://epicrideweather.com), the app that helps cyclists beat the rain and cheat the wind.

## License

Copyright 2021 David Green

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software without
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
