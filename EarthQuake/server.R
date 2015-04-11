library(datasets)
library(googleVis)
library(shiny)
library(caret)
library(rpart)
library(randomForest)


#Set seed for research reproduceability
set.seed(12323)

depthCategoryFunc <- function(x){
  if(x=="shadow"){
    "< 70km"
  }else if(x=="intermediate"){
    "70 - 300km"
  }else if(x=="deep"){
    "> 300km"
  }
}

quakes$depthCategory <-  ifelse(quakes$depth < 70,"shadow", ifelse(quakes$depth < 300,"intermediate", "deep"))
quakes$depthCategory <- as.factor(quakes$depthCategory)
quakes$depthCategoryDetail <- ifelse(quakes$depth < 70,"< 70km", ifelse(quakes$depth < 300,"70 - 300km", "> 300km"))

# Since random forest can take up to 24 factors, and our data Mag range is 4.0 to 6.4, we can fit them into category.
magCategory <- function(y){
  finalList <- vector()
  for(x in y){
    min <- 4.0
    max <- 6.4
    for(i in 0:4){
      j <- (4.0+0.5*i)
      k <- j + 0.5
      if((isTRUE(all.equal(x,j)) || x>j) && x<k){
        result <- paste(j,"<= mag <",k)
      }
    }
    finalList <- c(finalList, result)
  }
  finalList
}

quakes$magCategory <- as.factor(magCategory(quakes$mag))

# Adjust Lat Long attributes
quakes$latlong <- paste(quakes$lat,":",quakes$long, sep = "")
quakes$tip <- paste("<B>EarthQuake Prediction</B><BR>Magnitude=",quakes$mag,"<BR>Depth=",quakes$depth,"<BR>Stations=",quakes$stations,"<BR>Depth Category=",quakes$depthCategory, "(",quakes$depthCategoryDetail,")")
quakes$tip1 <- paste("<B>EarthQuake Prediction</B><BR>Magnitude=",quakes$mag,"<BR>Depth=",quakes$depth,"<BR>Stations=",quakes$stations,"<BR>Magnitude Category=",as.character(quakes$magCategory))


### Depth Category
newQuakes <- quakes[c(-3,-7)]
# Training and Testing set
inTrain <- createDataPartition(y=newQuakes$depthCategory, p=0.6, list=FALSE)
myTraining <- newQuakes[inTrain,]
myTesting <-  newQuakes[-inTrain,]
#modFitRF <- randomForest(depthCategory ~ lat + long + mag + stations , data=myTraining)


### Magnitude Category
newQuakes1 <- quakes[c(-4,-6)]
inTrain <- createDataPartition(y=newQuakes1$magCategory, p=0.6, list=FALSE)
myTraining1 <- newQuakes1[inTrain,]
myTesting1 <-  newQuakes1[-inTrain,]
#modFitRF1 <- randomForest(magCategory ~ lat + long + depth + stations , data=myTraining1)


shinyServer(function(input, output) {

  data <- reactive({
    if(input$predResponse == 'depth'){
      testing <- data.frame(lat= input$Lat, long= input$Long, mag=input$Magnitude, stations=input$Stations, latlong=paste(input$Lat, ":", input$Long, sep = ""))
    }else if(input$predResponse == 'magnitude'){
      testing <- data.frame(lat= input$Lat, long= input$Long, depth=input$Depth, stations=input$Stations)
    }
  })
  
  prediction <- reactive({
    if(input$predResponse == 'depth'){
      modFitRF <- randomForest(depthCategory ~ lat + long + mag + stations , data=myTraining)
      predict(modFitRF, data(), type = "class")
    }else if(input$predResponse == 'magnitude'){
      modFitRF1 <- randomForest(magCategory ~ lat + long + depth + stations , data=myTraining1)
      predict(modFitRF1, data(), type = "class")
    }                    
  })
  
  output$detail <- renderText({
    paste("<b>Selected location</b><br>Latitude:", input$Lat, "<br>Longitude:", input$Long , "<br>Stations:", input$Stations)
  })
  
  output$prediction <- renderText({
    ### Testing the progress widget
      withProgress(message = 'Loading...', value = 0, {
        n <- 2
        incProgress(1/n, detail = paste("Running Prediction Model", 45))
        cat <- prediction()
        Sys.sleep(0.2)
        
        incProgress(2/n, detail = paste("Finished Prediction Model",100)) 
        Sys.sleep(0.2)  
        
        if(input$predResponse == 'depth'){
          paste("Predicted Depth Category:", cat, "(", depthCategoryFunc(cat), ")")
        }else if(input$predResponse == 'magnitude'){
          paste("Predicted Magnitude Category:", cat)
        }
      })
  })
  
  output$plot <- renderPlot({
      if(input$predResponse == 'depth'){
        p <- ggplot(data=newQuakes1, aes(x=long,y=lat,col=depth)) + geom_point() + scale_colour_gradientn(colours=rainbow(5))
        p <- p + annotate("pointrange", x = input$Long, y = input$Lat, ymin=input$Lat, ymax=input$Lat, color="red", size = 1)
        p + annotate("text", x = input$Long, y = input$Lat-1, label="Selected Location", color="red")
      }else if(input$predResponse == 'magnitude'){
        p <- ggplot(data=newQuakes, aes(x=long,y=lat,col=mag)) + geom_point() 
        p <- p + annotate("pointrange", x = input$Long, y = input$Lat, ymin=input$Lat, ymax=input$Lat, color="red", size = 1)
        p + annotate("text", x = input$Long, y = input$Lat-1, label="Selected Location", color="red")
      }
  })
  
  output$gvis <- renderGvis({
    if(input$goPredict > 0 && input$googleMapCheck == TRUE){
      if(input$predResponse == 'depth'){
        gvisMap(newQuakes1, "latlong" , "tip", 
              options=list(showTip=TRUE, 
                           showLine=TRUE, 
                           enableScrollWheel=TRUE,
                           mapType='normal', 
                           useMapTypeControl=TRUE,
                           width=400,height=500))
      
      }else if(input$predResponse == 'magnitude'){
        gvisMap(newQuakes, "latlong" , "tip1", 
              options=list(showTip=TRUE, 
                           showLine=TRUE, 
                           enableScrollWheel=TRUE,
                           mapType='satellite', 
                           useMapTypeControl=TRUE,
                           width=400,height=500))
      } 
    }
  })
  
  output$explanation <- renderText({
    "<p>This application allows you to predict the magnitude / depth of the earthquake in the Fiji region.<br />
 The dataset is obtained from quakes which is available in r {datasets}. The data describes the earthquake events which occurred near Fiji since 1964.<br />
 <br />
The  controls allow you to obtain the following info:<br />
1. Predictive Response: Quake Depth / Magnitude returns a predicted quake depth / magnitude of the earthquake in the given lat/long.<br />
2. Display with Google map: Returns google map showing all the locations from quakes {datasets}.<br />
3. Latitude: Predict earthquake at this given lat.<br />
4. Longtitude: Predict earthquake at this given long.<br />
5. Magnitude of Quake: Predict earthquake with this magnitude.<br />
6. Depth of Quake: Predict earthquake with this depth<br />
7. Number of stations reported: Number of stations reported in this {datasets}<br /><br />
</p>"})
})