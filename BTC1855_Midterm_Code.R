# BTC1855 - Midterm
# By Trinley Palmo

# Libraries needed
library(lubridate)
library(dplyr)

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
trips1$start_date <- mdy_hm(trips1$start_date)
trips1$end_date <- mdy_hm(trips1$end_date)

# Find the observations where the trip starts and ends at the same station.
same_station_row <- which(trips1$start_station_id == trips1$end_station_id)
# Select just the rows for trips that might be cancelled trips.
potential_cancelled <- trips1[same_station_row,] %>%
  select(c("id", "duration", "start_station_name", 
           "start_station_id", "end_station_name", "end_station_id", "bike_id"))

# Find the observations where the duration is less than 3 minutes.
# Set the threshold in minutes for potentially cancelled trips.
min_threshold <- 3
# Covert the threshold into seconds.
sec_threshold <- 3*60
# Select observations from the potentially cancelled trips dataframe that has a
# duration of less than 3 minutes.
cancelled <- potential_cancelled %>%
  filter(duration < sec_threshold)

# Trip IDs of trips that are likely to be "cancelled trips"
cancelled_id <- cancelled$id
# Number of these likely "cancelled trips"
num_cancelled <- length(cancelled_id)

# Remove the cancelled trips from the dataset.
trips_valid <- trips1 %>%
  filter(!(id %in% cancelled_id))

# Remove outliers from trips dataset
# Check the variables from trips dataset to determine if there are any extreme 
# values
summary(trips_valid)
# Create histogram with duration variable to visually determine if there are 
# outliers
hist(trips_valid$duration)
# Check extreme values on both ends of duration
head(sort(trips_valid$duration), 20)
head(sort(trips_valid$duration, decreasing = T), 20)

# Identify first and third quartiles, interquartile range, and the upper and 
# lower limits of duration.
duration_q1 <- quantile(trips_valid$duration, probs = 0.25)
duration_q3 <- quantile(trips_valid$duration, probs = 0.75)
duration_IQR <- IQR(trips_valid$duration)
duration_upper <-  duration_q3 + 1.5 * duration_IQR
duration_lower <- duration_q1 - 1.5 * duration_IQR
# Remove outliers based on IQR
trips_valid1 <- trips_valid %>%
  filter(duration_lower < duration) %>%
  filter(duration < duration_upper)

# Identify the trip id and number of trips that were removed as outliers
outliers_trips <- trips_valid[["id"]] - trips_valid1[["id"]]
outlier_trips_id <- setdiff(trips_valid$id, trips_valid1$id)
num_outliers_trips <- length(outlier_trips_id)

## Correlation
# Cleaning up the weather dataset further
nrow(weather1)
weather2 <- na.omit(weather1)
nrow(weather2)
print((1825-1301) < (0.3*1825))
# The number of missing data is less than 30% of the original data - it's okay
# to remove.

#' Add a `city` column to trips dataset by performing a left join with the 
#' stations dataset, based on their station names (Make sure that the station 
#' names are either all lowercase or all uppercase so that they are 
#' standardized). Rearrange based on starting station names.
new_trips_valid1 <- trips_valid1 %>%
  mutate(
    date = as.Date(start_date),
    start_station_name = trimws(tolower(start_station_name))) %>%
  arrange(start_station_name)

# Standardized names of stations in stations dataset. Extracted the names of
# stations and corresponding city names.
new_stations <- stations %>%
  mutate(
    name = trimws(tolower(name))
  ) %>%
  select(name, city)

# Perform the left join to add the city information
trips_with_city <- new_trips_valid1 %>%
  left_join(new_stations, by = c("start_station_name" = "name"))

# Check if there are any remaining missing city values.
any(is.na(trips_with_city$city))

# Extract observations that have missing city values and are NOT missing zip
# code information.
missing_city_trips <- trips_with_city %>%
  filter(is.na(city) & !is.na(zip_code))

# Remove duplicates from weather. This produces a dataframe that provides unique
# city and zip codes, which can be used to update the missing city observations. 
zip_code_city <- weather2 %>%
  distinct(zip_code, city)

# Join the zip_code_city to the extracted missing city rows. This will fill in 
# the city based on matching zip codes. Then extract just the id of the
# observation and the city column. This will be used to join with the previous
# dataframe from which missing city observations were extracted from.
missing_city_filled <- missing_city_trips %>%
  left_join(zip_code_city, by = "zip_code") %>%
  rename(start_city = city.y) %>%
  select(id, start_city)

# Combine the original dataframe with the updated city information. Remove 
# start city and zip code columns.
trips_with_city2 <- trips_with_city %>%
  left_join(missing_city_filled, by = "id") %>%
  mutate(
    city = if_else(is.na(city), start_city, city)) %>%
  select(-start_city, -zip_code)
