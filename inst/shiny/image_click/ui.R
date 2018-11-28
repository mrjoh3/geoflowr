fluidPage(

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
