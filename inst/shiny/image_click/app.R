
library(mapedit)
library(mapview)
library(shiny)
library(raster)
library(sf)
library(affinething)

# use this to set map extent
world1 <- sf::st_as_sf(maps::map('world', plot = FALSE, fill = TRUE))
map <- viewExtent(world1, alpha.regions = 0, stroke = FALSE)

# Define UI for application that draws a histogram
ui <- fluidPage(

   # Application title
   titlePanel("Click on an Image"),
   fluidRow(height = '600px',
     column(6,
            shiny::imageOutput('image', click = 'imageClick', height = '400px')),
     column(6,
            editModUI("editor", height = 600))
   ),
   fluidRow(height = '100px',
            column(6,
                   tableOutput('img_clicks')),
            column(6,
                   actionButton('btn', 'Georeference'))
   ),
   fluidRow()
)


server <- function(input, output) {

  # record clicked points
  img_pts <- reactiveValues(x=NULL, y=NULL)

  geo_pts <- callModule(editMod, "editor", map@map)

  # Listen for clicks
  observe({
    # Initially will be empty
    if (is.null(input$imageClick)){
      return()
    }

    # third click will clear
    isolate({

        img_pts$x <- c(img_pts$x, input$imageClick$x)
        img_pts$y <- c(img_pts$y, input$imageClick$y)

    })

    output$img_clicks <- renderTable({data.frame(img_pts$x,
                                                 img_pts$y)})

  })

  # check inputs and georeference
  observeEvent(input$btn, {

    r <- brick('world.png')
    xy <<- cbind(img_pts$x[1:2],
                 nrow(r) - img_pts$y[1:2])

    pts <<- st_coordinates(geo_pts()$finished)

    withProgress(message = 'Georeferencing Image', {
      rfix  <<- setExtent(r, affinething::domath(pts, xy, r = r))
    })


  })

  output$image <- renderImage({
    filename <- 'world.png'
    list(src = filename)
  }, deleteFile = FALSE)


}

# Run the application
shinyApp(ui = ui, server = server)

