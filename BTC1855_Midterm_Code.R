# BTC1855 - Midterm
# By Trinley Palmo

# Install required libraries
# install.packages("lubridate")
# install.packages("dplyr")
# install.packages("funModeling")
# install.packages("Hmisc")
# install.packages("corrplot")
# install.packages("tidyr")
# install.packages("ggplot2)

# Libraries needed
library(lubridate)
library(dplyr)
library(funModeling)
library(Hmisc)
library(corrplot)
library(tidyr)
library(ggplot2)

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

# Check for missing values and empty strings in `stations` dataset.
any(is.na(stations))
# No missing values

# Check for empty strings in `stations` dataset.
for (var in names(stations)) {
  print(var)
  print(paste0("# of empty strings: ",length(which(stations[var] == ""))))
}
# There are no empty strings

# Check if there are duplicate stations
length(unique(stations$name)) == nrow(stations)
# There are no duplicates

# Check the unique cities that these stations are found in.
cities <- unique(stations$city)
cities
length(cities)

# Next, work with the `weather` dataset.
# Explore the `weather` dataset.
dim(weather)
str(weather)
summary(weather)

# Convert date to datetime objects.
weather$date <- mdy(weather$date)

# Check if precipiation measure has any alpha characters in it
head(sort(weather$precipitation_inches))
tail(sort(weather$precipitation_inches))

# `T` represents when amount is less than 0.01in. Impute the `T` to 0.001.
weather <- weather %>% mutate(
  precipitation_inches = case_when(
    precipitation_inches == 'T' ~ "0.001",
    .default = precipitation_inches))

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
  print(paste0("# of NAs: ",length(which(is.na(weather[var])))))
  print(paste0("# of empty strings: ",length(which(weather[var] == ""))))
}

# Create a new dataframe where the empty strings in events are imputed to "None".
weather1 <- weather %>%
  mutate(events = case_when(
    events == "" ~ "none",
    .default = events))

# Confirm that there are no more empty strings in `events`.
which(weather1$events == "")

# Remove all NAs in weather1
weather2 <- na.omit(weather1)
dropped_na <- nrow(weather1) - nrow(weather2)
dropped_na

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

# Drop zip_code column as that only refers to the home zip code of
# subscribers/users. It does not reflect the zip code of the start or end 
# stations.
trips1 <- trips %>%
  select(-zip_code)

# Convert start and end dates to datetime objects.
trips1$start_date <- mdy_hm(trips1$start_date)
trips1$end_date <- mdy_hm(trips1$end_date)

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
# Convert to dataframe and export it as .csv
cancelled_df <- as.data.frame(cancelled_id) %>%
  rename(cancelled_trip_id = cancelled_id)
write.csv(cancelled_df, 
          file = "C://Users/tpalm/Desktop/MY FILES/UofT/MBiotech/BTC1855/BTC1855_Midterm/cancelled_trip_ids.csv", 
          row.names = FALSE)
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
# Use log10 to better visualize the duration data. This will help with 
# identifying potential patterns and outliers.
hist(log10(trips_valid$duration))
# Most duration values are below 10^3. Check if the upper limit of the dataset
# using IQR would compliment this finding.

# Identify first and third quartiles, interquartile range, and the upper and 
# lower limits of duration.
duration_q1 <- quantile(trips_valid$duration, probs = 0.25)
duration_q3 <- quantile(trips_valid$duration, probs = 0.75)
duration_IQR <- IQR(trips_valid$duration)
duration_upper <-  duration_q3 + 1.5 * duration_IQR
duration_lower <- duration_q1 - 1.5 * duration_IQR
duration_upper
duration_lower
# The limits are sufficient.

# Remove outliers based on IQR
trips_valid1 <- trips_valid %>%
  filter(duration_lower < duration) %>%
  filter(duration < duration_upper)
hist(trips_valid1$duration)

# Identify the trip id and number of trips that were removed as outliers
outlier_trips_id <- setdiff(trips_valid$id, trips_valid1$id)
# Convert to dataframe and export it as .csv
outliers_df <- as.data.frame(outlier_trips_id)
write.csv(outliers_df, 
          file = "C://Users/tpalm/Desktop/MY FILES/UofT/MBiotech/BTC1855/BTC1855_Midterm/outliers_trip_ids.csv", 
          row.names = FALSE)
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
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"))
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

# Top 10 most frequent starting stations and ending stations during the weekend
# Starting Station
# Filter for trips that start on a weekend (Sat - Sun) and select the relevant 
# columns.
trips_valid2_wkd_start <- trips_valid2 %>%
  filter(start_wdy >= 6) %>%
  select(start_station_name, start_station_id, start_hour)

# Calculate top 10 starting stations by counting the number of occurrences of
# each start station name, arrange them in descending order, and returning the
# first 10.

top10_start_station_wkd <- trips_valid2_wkd_start %>%
  count(start_station_name) %>%
  arrange(desc(n)) %>%
  head(10)
top10_start_station_wkd$start_station_name

# Ending station
# Filter for trips that end on a weekend (Sat - Sun) and select the relevant 
# columns.
trips_valid2_wkd_end <- trips_valid2 %>%
  filter(end_wdy >= 6) %>%
  select(end_station_name, end_station_id, end_hour)

# Calculate top 10 ending stations by counting the number of occurrences of
# each end station name, arrange them in descending order, and returning the
# first 10.
top10_end_station_wkd <- trips_valid2_wkd_end %>%
  count(end_station_name) %>%
  arrange(desc(n)) %>%
  head(10)
top10_end_station_wkd$end_station_name

# Calculate the average utilization of each bike for each month 
# (total time used/total time in month). 

# Add a column to the trip data that identifies the month in which the trip took
# place in.
trips_valid_month <- trips_valid1 %>% mutate(
  month = month(start_date)
)

# Extract all unique bike ids
all_bike_id <- unique(trips_valid_month$bike_id)

# Create an empty dataframe to store the monthly utilization rate for each bike.
monthly_utilization <- data.frame()

for (i in all_bike_id) {
  # Filter the data for the current bike id.
  indiv_bike_data <- trips_valid_month %>%
    filter(bike_id == i)
  
  # Group the indiv_bike_data by month and calculate the total duration for each 
  # month.
  monthly_bike_data <- indiv_bike_data %>%
    group_by(month) %>%
    summarise(total_duration = sum(duration)) %>%
  # Create a new column in the filtered set that provides the number of days in 
  # each month
    mutate(
      num_days = case_when(
        month %in% c(1, 3, 5, 7, 8, 10, 12) ~ 31,
        month %in% c(4, 6, 9, 11) ~ 30,
        month == 2 ~ 28),
      # Create a new column in the filtered set that calculates the total number 
      # of seconds in the month based on the number of days.
      monthly_sec = 60*60*24*num_days,
      # Add a new column that calculates the monthly utilization rate by 
      # dividing total duration of the trip for each month by the total number 
      # of seconds per month.
      monthly_util = total_duration / monthly_sec,
    # Add a new column that calculates the monthly utilization rate in 
    # percentages.
    monthly_util_percent = monthly_util * 100,
    # Add a new column containing the current bike id.
    bike_id = i)
  # Append the monthly utilization data for the current bike to the monthly 
  # utilization dataset.
  monthly_utilization <- rbind(monthly_utilization, monthly_bike_data)
}

# Rearrange and select the relevant columns
monthly_utilization <- monthly_utilization %>%
  select(bike_id, month, monthly_util, monthly_util_percent) %>%
  arrange(bike_id)
monthly_utilization
# Export it as a CSV
write.csv(monthly_utilization, 
          file = "C://Users/tpalm/Desktop/MY FILES/UofT/MBiotech/BTC1855/BTC1855_Midterm/monthly_utilization.csv", 
          row.names = FALSE)

## Correlation

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
# Check how many are missing 
length(which((is.na(trips_with_city$city))))
# Check if any other columns have missing values.
describe(trips_with_city)
# No other columns are missing values. 5598 observations have missing city
# information. The remaining stations do not have sufficient information to
# identify their city. We need to know the city for each trip in order to join 
# with weather data. Remove those observations.
trips_with_city2 <- na.omit(trips_with_city)

# Join the trips data with the weather information by date and city. Make events
# column into a factor, after making all NA events into `None`. The factor should
# have levels and be ordered. Convert cloud_cover into a factor as well.
trips_with_weather <- trips_with_city2 %>%
  left_join(weather2, by = c("date", "city")) %>%
  mutate(events = factor(case_when(
    is.na(events) ~ "None",
    .default = events), levels = c("None", "fog", "rain", "fog-rain"), 
    ordered = TRUE),
    cloud_cover = factor(cloud_cover))

# Create a new dataframe that groups the trips with weather dataframe by 
# date and city. It should also contain summary of daily metrics of trips and
# weather. Daily rentals counts the number of rentals for each date per city. 
# Duration calculates the total number of seconds of the trip for each date per 
# city. For the weather information, since all trips would have the same value 
# if the trip occurred in the same city and the same day, the value for each 
# weather measure is the same as the first value in the dataframe that 
# corresponds to the specific city and date.
daily_metrics <- trips_with_weather %>%
  group_by(date, city) %>%
  summarise(
    daily_rentals = n(),
    total_duration = sum(duration),
    max_temperature_f = first(max_temperature_f),
    mean_temperature_f = first(mean_temperature_f),
    min_temperature_f = first(min_temperature_f),
    max_visibility_miles = first(max_visibility_miles),
    mean_visibility_miles = first(mean_visibility_miles),
    min_visibility_miles = first(min_visibility_miles),
    max_wind_speed_mph = first(max_wind_Speed_mph),
    mean_wind_speed_mph = first(mean_wind_speed_mph),
    max_gust_speed_mph = first(max_gust_speed_mph),
    precipitation_inches = first(precipitation_inches),
    event = first(as.numeric(events)),
    cloud_cover = first(as.numeric(cloud_cover)),
    .groups = "drop"
  )

View(daily_metrics)

# Prepare the data metrics for correlation analysis by selecting only numeric 
# variables.
correlation_data <- daily_metrics %>%
  select(-date, -city)

# Compute the correlation matrix with only complete observations.
correlation_matrix <- cor(correlation_data, use = "complete.obs", 
                          method = "pearson")
correlation_matrix

# Visualize the correlation matrix
trip_weather_corrplot <- corrplot(correlation_matrix, 
                                  title = "Correlation Plot of Bike Rental Patterns and Weather Metrics",
                                  method = "color", 
                                  type = "upper", 
                                  order = "hclust",
                                  tl.col = "black", 
                                  tl.cex = 0.8,
                                  tl.srt = 45,
                                  mar=c(0,0,2,0)) 

# Convert the full correlation_matrix to a dataframe
correlation_matrix_df <- as.data.frame(as.table(correlation_matrix))

# Export it as .csv
write.csv(correlation_matrix_df, 
          file = "C://Users/tpalm/Desktop/MY FILES/UofT/MBiotech/BTC1855/BTC1855_Midterm/full_trip_weather_correlation.csv", 
          row.names = FALSE)

# Extract weather_measures
weather_measures <- correlation_data %>%
  select(-daily_rentals, -total_duration) %>% names()

# Convert the correlation matrix to a data frame. To make it easier to read
# the correlation matrix dataframe, remove the correlation of each variable 
# with itself, and correlations where both variables are in weather measures. 
# This allows us to focus on how weather impacts bike rental patterns and not on
# each other.
correlation_matrix_mod <- correlation_matrix_df %>%
  filter(Var1 != Var2) %>%
  filter(!(Var1 %in% weather_measures 
           & Var2 %in% weather_measures))

# Find the highest positive and negative correlations
highest_correlation <- correlation_matrix_mod %>%
  arrange(desc(abs(Freq)))

highest_correlation
write.csv(highest_correlation, file = "C://Users/tpalm/Desktop/MY FILES/UofT/MBiotech/BTC1855/BTC1855_Midterm/trip_weather_correlation.csv", 
          row.names = FALSE)
