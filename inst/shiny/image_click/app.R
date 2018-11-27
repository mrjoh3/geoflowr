
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
   titlePanel("Image Georeferencing"),
   fluidRow(
     column(2,
            includeMarkdown('instructions.md')
     ),
     column(4,
            h3("Import File to Georeference"),
            wellPanel(
              fileInput('add_file', 'Select File')
            ),
            downloadButton('download', 'Download Corrected Image')
            ),
   column(3,
          h3('Parameters'),
          tabsetPanel(type = "tabs",
                      tabPanel('Georefernce Method',
                               wellPanel(style = "background: #ffe6e6",
                               selectizeInput('method', 'Choose',
                                              choices = c('No Click'= 1,
                                                          '2 Click Image - Known Map Coordinates' = 2,
                                                          '2 Click Image - 2 Click Map Coordinates' = 3
                                              ),
                                              selected = 3),
                               numericInput('crs', 'Define CRS', 4283))),
                      tabPanel('Known Spatial Information',
                               wellPanel(style = "background: #ffe6e6",
                               sliderInput('x', 'X Max and Min', min = -180, max = 180, value = c(-90, 90)),
                               sliderInput('y', 'Y Max and Min', min = -90, max = 90, value = c(-45, 45))))
          )),
   column(3,
          actionButton('btn', 'Run Georeference'),
          hr(),
          h4('Image Clicks'),
          tableOutput('img_clicks')
   ),
   tags$hr()),
   fluidRow(
     column(8,
            shiny::imageOutput('image', click = 'imageClick')),
     column(4,
            editModUI("editor", height = 500)),
   tags$hr()),
   fluidRow(column(12,
                   plotOutput('corrected')))
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

    filename <- 'world.png' # default not working

    # check if file has been uploaded
    if (!is.null(req(input$add_file))) {
      filename <- input$add_file$datapath
    }

    r <- brick(filename)

    xy <<- cbind(img_pts$x[1:2],
                 nrow(r) - img_pts$y[1:2])

    pts <<- sf::st_coordinates(geo_pts()$finished)

    withProgress(message = 'Georeferencing Image', {
      rfix  <<- setExtent(r, affinething::domath(pts, xy, r = r))
    })

    output$corrected <- renderPlot({
      plotRGB(rfix)
      maps::map(add = TRUE)
      points(pts)
    })

  })

  # observe file upload and render
  output$image <- renderImage({

    filename <- 'world.png' # default not working

    # check if file has been uploaded
    if (!is.null(req(input$add_file))) {
      filename <- input$add_file$datapath
    }

    list(src = filename)
  }, deleteFile = FALSE)

  # Downloadable georeferenced image
  output$downloadData <- downloadHandler(
    filename = function() {
      paste('geoferenced', ".tif", sep = "")
    },
    content = function(file) {
      writeRaster(rfix, file)
    }
  )


}

# Run the application
shinyApp(ui = ui, server = server)

