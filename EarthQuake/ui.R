require(shiny)
 
shinyUI(pageWithSidebar(
  headerPanel("EarthQuakes(Fiji) Depth & Magnitude Prediction"),
  sidebarPanel(
    wellPanel(
      selectInput(inputId = "predResponse",label = "Select Predictive Response:", 
                  choices = c("Quake Depth" = "depth",
                              "Quake Magnitude" = "magnitude"),
                  selected = "depth"
      ),
      checkboxInput("googleMapCheck", label="Display with Google map", value=FALSE)
    ),
    
    wellPanel(
      sliderInput("Lat", "Latitude:", 
                min=-40, max=-10, value=-20,  step=0.01, round=FALSE, animate=TRUE),
      sliderInput("Long", "Longtitude:", 
                min=160, max=190, value=175,  step=0.1, round=FALSE, animate=TRUE),
    
      conditionalPanel(condition = "input.predResponse == 'depth'",
                sliderInput("Magnitude", "Magnitude of Quake:", min=4, max=6.4, value=4.5,  step=0.02, round=FALSE,animate=TRUE)
    ),
      conditionalPanel(condition = "input.predResponse == 'magnitude'",
                       sliderInput("Depth", "Depth of Quake:", min=40, max=680, value=300,  step=1, round=FALSE,animate=TRUE)    
    ),
    
      sliderInput("Stations", "Number of station reported", 
                min=1, max=150, value=70,  step=1, round=FALSE, animate=TRUE)
    ),
    
    actionButton('goPredict', 'Predict')
  ),
  mainPanel(
    htmlOutput("explanation"),
    
    conditionalPanel(
      condition = "input.goPredict==0",
      em("Please click on the Predict button to start...")
    ),
    
    conditionalPanel(
      condition = "input.goPredict>0",
      conditionalPanel(
        condition = "input.predResponse=='depth'",
        h4("Predicting EarthQuake Depth Category")
      ),
      conditionalPanel(
        condition = "input.predResponse=='magnitude'",
        h4("Predicting EarthQuake Magnitude Category")
      ),
      h5(htmlOutput("detail")),
      h5(textOutput("prediction")),
      plotOutput("plot")
    ),
    
    htmlOutput("gvis")
  )
)
)