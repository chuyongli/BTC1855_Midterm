# BTC1855 - Midterm
# By Trinley Palmo

# Install required libraries
# install.packages("lubridate")
# install.packages("dplyr")
# install.packages("funModeling")
# install.packages("Hmisc")

# Libraries needed
library(lubridate)
library(dplyr)
library(funModeling)
library(Hmisc)

# Set working directory for where to find the data files
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

# Check for missing values in `stations` dataset.
any(is.na(stations))
# No missing values

# Next, work with the `weather` dataset.
# Explore the `weather` dataset.
dim(weather)
str(weather)
summary(weather)

# Convert date to datetime objects.
weather$date <- mdy(weather$date)

# Convert precipitation measure into numeric objects.
weather$precipitation_inches <- as.numeric(weather$precipitation_inches)

# Convert zip code into character strings
weather$zip_code <- as.character(weather$zip_code)

# Check all unique events.
unique(weather$events)
# "Rain" and "rain" are both separate values, even though it is describing the
# same event. Fix this input error in the events column.
weather$events <- tolower(weather$events)
# Double check all unique values in the new dataframe.
unique(weather$events)

# Summary function showed that there are NAs in the dataset.
# Check number of missing values (NAs and empty strings) in the dataset
for (var in names(weather)) {
  print(var)
  print(paste0("# of NAs: ",length(is.na(weather$var))))
  print(paste0("# of empty strings: ",length(which(weather[var] == ""))))
}

# Create a new dataframe where the empty strings in events are imputed to "None".
weather1 <- weather %>%
  mutate(events = case_when(
    events == "" ~ "None",
    .default = events))

# Confirm that there are no more empty strings in `events`.
which(weather1$events == "")

# Explore the `trips` dataset.
dim(trips)
str(trips)
names(trips)
summary(trips)

# Check for missing values
any(is.na(trips))
# Check for empty strings in the dataset
for (var in names(trips)) {
  print(var)
  print(paste0("# of empty strings: ",length(which(trips[var] == ""))))
}

# Impute the empty strings to NAs
trips1 <- trips %>%
  mutate(zip_code = case_when(
    zip_code == "" ~ NA,
    .default = zip_code
  ))

# Confirm that there are no more empty strings in `events`.
which(trips1$zip_code == "")

# Convert start and end dates to datetime objects.
trips$start_date <- mdy_hm(trips$start_date)
trips$end_date <- mdy_hm(trips$end_date)


# Create a function for conducting exploratory data analysis
eda <- function(df) {
  glimpse(df)
  freq(df)
  plot_num(df)
  print(profiling_num(df))
  describe(df)
}

# Conduct EDA for the weather and trips datasets
eda(weather1)
eda(trips1)
