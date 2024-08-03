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
outlier_trips_id <- setdiff(trips_valid$id, trips_valid1$id)
num_outliers_trips <- length(outlier_trips_id)

# Extract weekday and hour information for each trip
trips_valid2 <- trips_valid1 %>%
  mutate(
    start_wdy = wday(start_date, week_start = 1),
    start_hour = hour(start_date),
    end_wdy = wday(end_date, week_start = 1),
    end_hour = hour(end_date)
  )

# Filter for trips that start on a weekday (Mon - Fri)
trips_valid2_weekday <- trips_valid2 %>%
  filter(start_wdy < 6)

# Create a dataframe to track active trips per hour
hours_tracker <- data.frame(hour = 0:23, active_trips = 0)

# Count the number of active trips during the weekdays per hour
# Go through each observation in the trips_valid2_weekday dataset
for (i in seq(nrow(trips_valid2_weekday))) {
  # Get the start hour for the current trip
  start_hour <- trips_valid2_weekday$start_hour[i]
  # Increase the corresponding hour in the hours_tracker by 1
  hours_tracker$active_trips[hours_tracker$hour == start_hour] <- 
    hours_tracker$active_trips[hours_tracker$hour == start_hour] + 1
}

# Print the updated hours_tracker to see the result
print(hours_tracker)

# Plot the data as a histogram to visualize the hours of active trips
rush_hour_hist <- ggplot(hours_tracker, aes(x = hour, y = active_trips)) +
  geom_col(fill = "blue") +
  labs(title = "Active Trips Per Hour During Weekdays",
       x = "Hour of Day",
       y = "Number of Active Trips") +
  theme_minimal()
rush_hour_hist

# Identify the top 5 rush hours
rush_hours_wkdy <- hours_tracker %>%
  arrange(desc(active_trips)) %>%
  head(5) 

# Print the peak hours
print(rush_hours_wkdy)

# Create a function that finds the top start stations, given a data on the rush
# hours and a dataframe containing relevant trip data (station names, id, start 
# hour). Returns the top 10 most frequent starting stations during the rush hour.
get_top_rush_start_stations <- function(rush_hours, trip_data) {
  
  # Extract rush hours list from the provided rush hour dataframe
  rush_hours_list <- rush_hours$hour
  
  # Filter for trips that started during a rush hour and select relevant columns
  rush_hour_station <- trip_data %>%
    filter(start_hour %in% rush_hours_list) %>%
    select(start_station_name, start_station_id, start_hour)
  
  # Calculate top 10 starting stations by counting the number of occurrences of
  # each start station name, arrange them in descending order, and returning the
  # first 10.
  top_10_station_start <- rush_hour_station %>%
    count(start_station_name) %>%
    arrange(desc(n)) %>%
    head(10)
  
  # Return the names of the stations
  top_10_station_start$start_station_name
}

# Create a function that finds the top end stations, given a data on the rush
# hours and a dataframe containing relevant trip data (station names, id, end 
# hour). Returns the top 10 most frequent ending stations during the rush hour.
get_top_rush_end_stations <- function(rush_hours, trip_data) {
  
  # Extract rush hours list from the provided rush hour dataframe
  rush_hours_list <- rush_hours$hour
  
  # Filter for trips that ended during a rush hour and select relevant columns
  rush_hour_station <- trip_data %>%
    filter(end_hour %in% rush_hours_list) %>%
    select(end_station_name, end_station_id, end_hour)
  
  # Calculate top 10 ending stations by counting the number of occurrences of
  # each end station name, arrange them in descending order, and returning the
  # first 10.
  top_10_station_end <- rush_hour_station %>%
    count(end_station_name) %>%
    arrange(desc(n)) %>%
    head(10)
  
  # Return the names of the stations
  top_10_station_end$end_station_name
}

# Top 10 Start and End stations during rush hours on weekdays
top10_start_station_wkdy <- get_top_rush_start_stations(rush_hours_wkdy, trips_valid2_weekday)
trips_valid2_weekday_end <- trips_valid2 %>%
  filter(end_wdy < 6)
top10_end_station_wkdy <- get_top_rush_end_stations(rush_hours_wkdy, trips_valid2_weekday_end)
top10_start_station_wkdy
top10_end_station_wkdy
