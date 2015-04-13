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
    HTML("<p>This application allows you to predict the magnitude / depth of the earthquake in the Fiji region.<br/>
        The dataset is obtained from quakes which is available in r {datasets}. The data describes the earthquake events which occurred near Fiji since 1964.<br/>
        <br/>
        The  controls allow you to obtain the following info:<br/>
        1. Predictive Response: Quake Depth / Magnitude returns a predicted quake depth / magnitude of the earthquake in the given lat/long.<br/>
        2. Display with Google map: Returns google map showing all the locations from quakes {datasets}.<br/>
        3. Latitude: Predict earthquake at this given lat.<br/>
        4. Longtitude: Predict earthquake at this given long.<br/>
        5. Magnitude of Quake: Predict earthquake with this magnitude.<br/>
        6. Depth of Quake: Predict earthquake with this depth<br/>
        7. Number of stations reported: Number of stations reported in this {datasets}<br/><br/></p>"),
    
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