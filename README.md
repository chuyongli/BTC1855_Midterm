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
Identify outliers in the dataset, record the trip ids, and remove them from the dataset.
Step 1: Look at the overall summary of the interested variables to determine if there are any extreme values.
Step 2: Settle on an appropriate criteria for removing outliers.
Step 3: Identify outliers based on the specified criteria.
Step 4: Save the number of those trips and their ids in the code and in the document.
Step 5: Remove them from the dataset.

# Highest-Volume-Weekday-branch
Determine the highest volume hours on weekdays. In other words, the hours of weekdays where the trip volume is highest.
Step 1:

# Top-10-Rush-Hour-branch


# Top-10-Weekend-branch


# Monthly-Bike-Utilization-branch

# Correlation-branch


