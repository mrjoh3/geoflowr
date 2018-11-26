
library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(

   # Application title
   titlePanel("Click on an Image"),

   shiny::imageOutput('image', clickId = 'imageClick', height = '400px'),
   textOutput('text')

)


server <- function(input, output) {

  # record clicked points
  val <- reactiveValues(x=NULL, y=NULL)

  # Listen for clicks
  observe({
    # Initially will be empty
    if (is.null(input$imageClick)){
      return()
    }

    isolate({
      val$x <- input$imageClick$x
      val$y <- input$imageClick$y
    })

    output$text <- renderText({paste0('X: ', val$x, '--', 'Y: ', val$y)})
  })

  output$image <- renderImage({
    filename <- 'world.png'
    list(src = filename)
  }, deleteFile = FALSE)


}

# Run the application
shinyApp(ui = ui, server = server)

