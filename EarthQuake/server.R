library(datasets)
library(plotGoogleMaps)
library(sp)
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
modFitRF <- randomForest(depthCategory ~ lat + long + mag + stations , data=myTraining)

#coordinates(newQuakes) = ~ long + lat  
#proj4string(newQuakes) = CRS("+proj=longlat")

### Magnitude Category
newQuakes1 <- quakes[c(-4,-6)]
inTrain <- createDataPartition(y=newQuakes1$magCategory, p=0.6, list=FALSE)
myTraining1 <- newQuakes1[inTrain,]
myTesting1 <-  newQuakes1[-inTrain,]
modFitRF1 <- randomForest(magCategory ~ lat + long + depth + stations , data=myTraining1)

#coordinates(newQuakes1) = ~ long + lat  
#proj4string(newQuakes1) = CRS("+proj=longlat")


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
      predict(modFitRF, data(), type = "class")
    }else if(input$predResponse == 'magnitude'){
      predict(modFitRF1, data(), type = "class")
    }                    
  })
  
  output$detail <- renderText({
    paste("<b>Selected location</b><br>Latitude:", input$Lat, "<br>Longitude:", input$Long , "<br>Stations:", input$Stations)
  })
  
  output$prediction <- renderText({
    cat <- prediction()
    if(input$predResponse == 'depth'){
      paste("Predicted Depth Category:", cat, "(", depthCategoryFunc(cat), ")")
    }else if(input$predResponse == 'magnitude'){
      paste("Predicted Magnitude Category:", cat)
    }   
  })
  
  output$plot <- renderPlot({
    if(input$predResponse == 'depth'){
      p <- ggplot(data=newQuakes1, aes(x=lat,y=long,col=depth)) + geom_point() + scale_colour_gradientn(colours=rainbow(5))
      p <- p + annotate("pointrange", x = input$Lat, y = input$Long, ymin=input$Long, ymax=input$Long, color="red", size = 1)
      p + annotate("text", x = input$Lat, y = input$Long-1, label="Selected Location", color="red")
    }else if(input$predResponse == 'magnitude'){
      p <- ggplot(data=newQuakes, aes(x=lat,y=long,col=mag)) + geom_point() 
      p <- p + annotate("pointrange", x = input$Lat, y = input$Long, ymin=input$Long, ymax=input$Long, color="red", size = 1)
      p + annotate("text", x = input$Lat, y = input$Long-1, label="Selected Location", color="red")
    }
  })
  
  output$gvis <- renderGvis({
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
  })
})