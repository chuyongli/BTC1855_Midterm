# BTC1855_Midterm Code Plan
Below outlines the code plan for BTC1855's Midterm. I have separated the steps
by branches.

# main-branch
The main purpose of this branch is to clean the dataset that will be utilized
for the following sections/branches of code.
Step 1: Open the data set and save it to an object.
Step 2: Explore the data set. Determine how many variables and observations it 
contains and the internal structure of the data set.
Step 3: Check for any structural errors and fix them accordingly (uniformity, renaming columns, re-coding variables, removing duplicates, keep/drop columns, transform into tidy structure, converting to factors, etc.).
Step 4: Check for data irregularities, specifically ensuring that the data is valid.
Step 5: Check for any missing values/observations for each variable. Remove them
or impute them with appropriate values.

# EDA-branch
Conduct exploratory data analysis on the cleaned dataset.
Step 1: 

# Trip-branch
Find the number of cancelled trips, record their ids for report, and then remove them from dataset.
Step 1: Extract the observations where the trip starts and ends at the same station.
Step 2: From those observations, extract those where the duration is less than 3 minutes.
Step 3: Save the number of those trips and their ids in the code and in the document.
Step 3: Remove them from the dataset.

# Outliers-branch
Identify outliers in the trips, record the trip ids, and remove them from the dataset.
Step 1: Look at the overall summary of the interested variables to determine if there are any extreme values.
Step 2: Settle on an appropriate criteria for removing outliers.
Step 3: Identify outliers based on the specified criteria.
Step 4: Save the number of those trips and their ids in the code and in the document.
Step 5: Remove them from the dataset.

# Highest-Volume-Weekday-branch
Determine the highest volume hours on weekdays. In other words, the hours of weekdays where the trip volume is highest.
Step 1: Extract all trip data that occurred on a weekday.
Step 2: Create a dataframe with two columns. One that contains hours throughout a day and counts of active trip in the other.
Step 3: For the starting hour of each trip, increase their count by 1 in the dataframe created in step 2.
Step 4: Create a histogram using the created dataframe to visually identify the rush hour.
Step 5: Identify the top 5 rush hours.

# Top-10-Rush-Hour-branch
Determine the 10 most frequent starting stations and ending stations during the rush hours during weekdays.

Starting Station:
Step 1: Filter weekday trips to select only those that start during a rush hour.
Step 2: Select relevant columns (starting station name, starting station id, start hour).
Step 3: Count the number of occurrences of each station name and arrange them in descending order.
Step 4: Select the top 10 and save it.

Ending Station:
Step 1: Extract all trip data that ended on a weekday.
Step 2: Filter weekday trips to select only those that end during a rush hour.
Step 3: Select relevant columns (ending station name, ending station id, end hour).
Step 4: Count the number of occurrences of each station name and arrange them in descending order.
Step 5: Select the top 10 and save it.

# Top-10-Weekend-branch


# Monthly-Bike-Utilization-branch

# Correlation-branch


