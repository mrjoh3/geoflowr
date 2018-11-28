library(mapedit)
library(mapview)
library(leaflet)
library(maptools)
library(shiny)
library(raster)
library(sf)
library(affinething)

library(sp)
library(rgdal)
library(rgeos)



# use this to set map extent
world <- sf::st_as_sf(maps::map('world', plot = FALSE, fill = TRUE))
world1 <- world[world$ID != 'Antarctica',]
#map <- viewExtent(world1, alpha.regions = 0, stroke = FALSE)

map <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron, group = 'Default') %>%
  addTiles(group = 'OSM') %>%
  addMouseCoordinates(style = "detailed",
                      epsg = 3857,
                      proj4string = NULL,
                      native.crs = FALSE) %>%
  addEasyButton(easyButton(
    icon="fa-globe", title="Zoom to Level 1",
    onClick=JS("function(btn, map){ map.setZoom(2); }"))) %>%
  addEasyButton(easyButton(
    icon="fa-crosshairs", title="Locate Me",
    onClick=JS("function(btn, map){ map.locate({setView: true}); }"))) %>%
  setView(0,0,2) %>%
  #leafletCRS(crsClass = 'L.CRS.EPSG4326', code = "EPSG:4326") %>%
  addGraticule(group = 'Grid Lines',
               style = list(color = "#FF0000",
                            weight = .5)) %>%
  addLayersControl(baseGroups = c('Default', 'OSM'),
                   overlayGroups = c("Grid Lines"),
                   options = layersControlOptions(collapsed = FALSE))
