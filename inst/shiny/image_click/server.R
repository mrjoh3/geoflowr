

function(input, output) {

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
  output$download <- downloadHandler(
    filename = function() {
      paste('geoferenced', ".tif", sep = "")
    },
    content = function(file) {
      writeRaster(rfix, file)
    }
  )


}
