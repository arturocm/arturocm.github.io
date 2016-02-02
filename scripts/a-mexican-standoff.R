library(inegiR)
library(data.table)
library(leaflet)

#######################################################
################### Load Tokens #######################
#######################################################

source("/Users/arturocam/GitHub/extra/inegir_tokens.R")

#######################################################
##################### Functions #######################
#######################################################

###################### grid() #########################
# Used to "pack" circles over a rectangular area
# the output is a dataframe that can be use to loop
# through denue_inegi() funciton

# To cover Monterrey  area 25.827886, -100.499367 to 25.617245, -100.113159
# To cover Hermosillo area 29.169148, -111.078260 to 28.987318, -110.894239
# To cover Mexico (Country) 32.511930, -117.236049 to 16.709315, -87.487558

grid <- function(lat1=25.827886, lon1=-100.499367,
                 lat2=25.617245, lon2=-100.113159){
  lat = 0.07
  lon = 0.07
  grid_output <- cbind(lat1,lon1)
  x <- abs(round((lat1-lat2)/lat, digits = 0))+1
  y <- abs(round((lon1-lon2)/lon, digits = 0))+1
  for (i in 1:x){
    for (j in 1:y){
      la <- lat1-((i*lat)-lat)
      lo <- lon1+((j*lon)-lon)
      prev <- cbind(la,lo)
      grid_output <- rbind(grid_output, prev)
    }
  }
  return(as.data.frame(grid_output))
}

################## grid_map() ######################
# Used to loop a data.frame with coordenates through the
# through denue_inegi() funciton. The reazon why we need
# this formula is to bypass the error given by denue_inegi()
# when there are no results. This way the loop function
# continous until the last loop
### Note how at the end we remove duplicate values!

grid_map <- function(location = a,
                     key.word = "comercio al por menor"){
  output <- data.frame()
  for (i in 1:nrow(location)){
    mapa <- tryCatch(denue_inegi(location[i,1],
                                 location[i,2],
                                 token_denue,
                                 metros = 5000,
                                 keyword = key.word),
                     error = function(e){})
    output <- rbind(output,mapa)
    print(i)
  }
  return (unique(output))
}

################## data_etl() #########################
# Used to clean the results to the top 3 Convenience
# Stores. You can modify this formula to give you the
# specific results that you like

data_etl <- function(mapa=mapa){
  oxxo <- mapa[mapa$Nombre %like% "OXXO" | mapa$Razon %like% "OXXO",]
  seven <- mapa[mapa$Nombre %like% "ELEVEN" | mapa$Razon %like% "ELEVEN",]
  extra <- mapa[mapa$Nombre %like% "EXTRA" | mapa$Razon %like% "EXTRA",]
  oxxo$type <- "OXXO"
  seven$type <- "SEVEN"
  extra$type <- "EXTRA"
  output <- rbind(oxxo,seven,extra)
  return(output)
}


#######################################################
##################### Analysis ########################
#######################################################

# Grid to cover Hermosillo area
a <- grid(29.169148, -111.078260, 28.987318, -110.894239)
# Loop through grid to search for all convinience stores
mapa <- grid_map(a)
# Filter the results to only major competitors
mapa <- data_etl(mapa)


# Coordetes to center the map (Hermosillo)
latitud = 29.09915
longitud = -110.9383

# Asign colors to each store
pal <- colorFactor(c("blue","red", "green"),
                   domain = c("EXTRA","OXXO", "SEVEN"))

# Use leaflet to map those coordenates
map <- leaflet() %>%
  addTiles() %>%
  setView(longitud, latitud, zoom = 11) %>%
  addCircleMarkers(lat = mapa$Latitud,
                   lng = mapa$Longitud,
                   popup = mapa$Nombre,
                   radius = 3,
                   color = pal(mapa$type),
                   stroke = TRUE, fillOpacity = 0.5) %>%
  addProviderTiles("CartoDB.Positron")   %>%
  addLegend("bottomright",
            pal = pal,
            values = c("EXTRA","OXXO", "SEVEN"),
            opacity = .5)
map
