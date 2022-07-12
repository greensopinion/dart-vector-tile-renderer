## 2.5.2

* improve text halo at high zoom levels

## 2.5.1

* improve support for overzooming

## 2.5.0

* improve preprocessing capability so that additional preprocessing can be separated from drawing
* more optimizations

## 2.4.7

* fix bug that prevented some themes from working with an exception "Cannot get paths from a point feature"

## 2.4.6

* add minimal support for fill-extrusion polygons by rendering a polygon without extrusion

## 2.4.5

* enable caching and incremental instantiation of TextPainter, see `TextPainterProvider` for details
## 2.4.3

* improved performance with expression short-circuit for constant expressions

## 2.4.2

* improved performance with expression caching
## 2.4.1

* add support for line-cap and line-join layout
## 2.4.0

* text halo color can now use expressions
* add support for text-justify and text-max-width
* bug fix to theme filters that reference zoom level
* breaking API change, `TilesetPreprocessor` now requires a zoom level

## 2.3.3

* improve support for color expressions
* add support for case expressions
* support let and var expressions
* add support for cubic-bezier interpolation
## 2.3.2

* added support for more theme expressions: math, coalesce, step
* theme background color and text anchor can now use expressions
## 2.3.1

* performance improvements
* support for `geometry-type` expression
## 2.3.0

* performance improvements

Thanks to Gabriel Terwesten for their contributions.
## 2.2.8

* add theme copy function
## 2.2.7

* reduce memory overhead by filtering tile data with the theme
## 2.1.6

* make tileset compatible with passing between isolates
## 2.1.5

* improve support for theme expressions
* improve support for linear/exponential interpolation
* improve label placement to have fewer unlabelled roads
* improve efficiency of rendering by moving more calculations into the `TilesetPreprocessor`
* improve efficiency of rendering with a change to the `vector_tile` dependency
## 2.1.4

* reduce CPU overhead of text rendering
## 2.1.3

* introduce tileset preprocessing to reduce CPU overhead while rendering
## 2.0.2

* reduced memory overhead when rendering to a Canvas that is scaled and clipped
* reduced CPU overhead of text labels
## 2.0.0

* support multiple source tiles so that it's possible to have multiple data sources, for exmaple when rendering hillshade
## 1.0.7

* only abbreviate place names that appear at the end of text
## 1.0.6

* add theme versioning
## 1.0.4

* add abbreviations for place names
## 1.0.3

* improve label collision detection

## 1.0.2

* fix support for visibility=none layout
## 1.0.1

* improve text support with font family, italic, and text-transform
* avoid placing text on tile boundaries
## 1.0.0

* expose ID on themes
## 0.1.14

* reduce memory usage
* enable rendering within a clip to avoid using excessive raster cache
## 0.1.12

* support fractional scale values for image size
## 0.1.11

* support text-halo-width and text-halo-color
## 0.1.10

* avoid label collisions by eliminating labels that would draw over others
* rotate labels to align with roads 

## 0.1.9

* improve performance
* improve line size interpolation
* introduce `zoomScaleFactor` for rendering tiles at greater than
  their normal size
## 0.1.7

* improved theme color support
* correct default stroke width for lines

## 0.1.4

* improved theme api
* improved light theme
* support theme filter operators `>=`, `<=`, `<`, `>`

## 0.1.3

* added example app
* minor API improvements

## 0.1.2

* performance improvement
* zoom theme filtering

## 0.1.1

* Initial release, supporting theming, polygons and lines.
