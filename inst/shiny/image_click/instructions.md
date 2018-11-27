

### Instructions

Select points on the map and then click on the image.
Pick a North East point first followed by a South West point.
There is currently no error checking or validation. Then click
the georeference button and wait. Close the app once complete; a raster called
`rfix` will be in your environment. Plot this using:

```r
plotRGB(rfix)
maps::map(add = TRUE)
points(pts)
```
