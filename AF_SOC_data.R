# Africa-wide SOC data setup 
# M. Walsh, September 2017

# Required packages
# install.packages(c("downloader","rgdal","raster","caret")), dependencies=TRUE)
suppressPackageStartupMessages({
  require(downloader)
  require(rgdal)
  require(raster)
  require(caret)
})

# Data downloads -----------------------------------------------------------
# set working directory
dir.create("AF_SOC", showWarnings=F)
setwd("./AF_SOC")

# download SOC data
download("https://www.dropbox.com/s/cn85c3jrlx2wgbp/SOCSAT.zip?dl=0", "SOCSAT.zip", mode="wb")
unzip("SOCSAT.zip", overwrite=T)
prof <- read.table("Profiles.csv", header=T, sep=",") ## profile locations
samp <- read.table("Samples.csv", header=T, sep=",") ## samples in profiles

# download Africa Gtifs and stack in raster (note this is a big 1Gb+ download)
download("https://www.dropbox.com/s/8kw4jitwp1n1bmc/AF_test_grids.zip?raw=1", "AF_test_grids.zip", mode="wb")
unzip("AF_test_grids.zip", overwrite=T)
glist <- list.files(pattern="tif", full.names=T)
grids <- stack(glist)

# Data setup ---------------------------------------------------------------
# project SOC coords to grid CRS
prof.proj <- as.data.frame(project(cbind(prof$Lon, prof$Lat), "+proj=laea +ellps=WGS84 +lon_0=20 +lat_0=5 +units=m +no_defs"))
colnames(prof.proj) <- c("x","y")
soc <- cbind(prof, prof.proj)
coordinates(prof) <- ~x+y
projection(prof) <- projection(grids)

# extract gridded variables at profile locations
socgrid <- extract(grids, prof)
prof <- as.data.frame(cbind(prof, socgrid))
soc <- merge(prof, samp, by="PID")
soc <- soc[!(soc$Lon=="NA" & soc$Lat=="NA"),] ## delete non-georeferenced profiles

# Write file
write.csv(soc, "socdat.csv", row.names = FALSE)