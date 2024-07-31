# BTC1855 - Midterm
# By Trinley Palmo

# Libraries needed
library(lubridate)

# Set working directory foro where to find the data files
setwd("C://Users/tpalm/Desktop/MY FILES/UofT/MBiotech/BTC1855/babs")

# Read the data files and save them to objects.
stations <- read.csv("station.csv")
weather <- read.csv("weather.csv")
trips <- read.csv("trip.csv")

# First, work with the `stations` dataset.
# Explore the `stations` dataset.
dim(stations)
str(stations)
summary(stations)

# Convert installation date to datetime objects.
stations$installation_date <- mdy(stations$installation_date)

# Next, work with the `weather` dataset.
# Explore the `weather` dataset.
dim(weather)
str(weather)
summary(weather)