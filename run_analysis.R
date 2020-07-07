## Data transformation script
## **Getting & Cleaning Data Course Project: Tidying Up UCI HAR Data Set**
## Script generates data set addressing end of course project requirements and following tidy data principles

## Script to acquire a data and create a tidy set

library(dplyr)                                               # Dplyr used to merge and summarise data

## Set constants
cat("Starting data acquisition and cleaning:\n")
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip" ## Source URL
sourcefilename <- "UCI_dataset.zip"                          # Source file name
sourcefoldername <- "UCI HAR Dataset/"                       # Name of the folder with unzipped data
outputfilename <- "run_analysis_output.txt"                  # Name of the output file with tidy data set
activity_name <- data.frame (                                # Data frame with descriptive activity names
  c(1:6), 
  c("Walking","Walking upstairs","Walking downstairs","Sitting","Standing","Lying"))
colnames(activity_name) <- c("labelid","activity")

## Download and unzip data file
cat("...Downloading file with UCI HAR data set\n")
download.file (url, sourcefilename, quiet = TRUE)             # Download file from the specified url
unlink(sourcefoldername, recursive=TRUE)                      # Delete folder created during previous downloads
cat ("...Decompressing the downloaded file\n")
unzip (sourcefilename)                                        # Unzip downloaded file

## Read data
cat("...Reading data from the extracted files\n")
in_test_measurement <- read.table(                            # Read test measurements
    file = paste0(sourcefoldername,"test/X_test.txt"),
    colClasses =rep("numeric",561))
in_train_measurement <- read.table(                           # Read training measurements
    file = paste0(sourcefoldername,"train/X_train.txt"),
    colClasses = rep("numeric",561)) 
in_test_label <- read.table(                                  # Read test labels
    file = paste0(sourcefoldername,"test/y_test.txt"),   
    col.names ="labelid")
in_train_label <- read.table(                                 # Read training labels
    file = paste0(sourcefoldername,"train/y_train.txt"), 
    col.names ="labelid")         
in_test_subject <-                                            # Read test subject ids
    read.table (paste0(sourcefoldername,"test/subject_test.txt"),  
    col.names = "subject")  
in_train_subject <-                                           # Read training subject ids
    read.table (paste0(sourcefoldername,"train/subject_train.txt"),
    col.names ="subject")
in_feature_name <-                                            # Read feature names
    read.table(paste0(sourcefoldername,"features.txt"))$V2

## Merge the training and the test sets to create one data set
cat("...Transforming source data\n")
merged_measurement <- bind_cols(                              # Combine columns with...
    bind_rows(in_test_measurement, in_train_measurement),     # ...merged test & training measurements
    bind_rows(in_test_label, in_train_label),                 # ...merged test & training data labels
    bind_rows(in_test_subject, in_train_subject))             # ...merged test & training subject data

## Extract only the measurements on the mean and standard deviation for each measurement
## See CodeBook.md for rationale behind selection of the variables
selected_feature <-                                           # Create vector with indices of selected features to be extracted, i.e....
  grep("mean|std", in_feature_name, ignore.case = TRUE)       # ...containing 'min' or 'std' anywhere in their name
  

selected_column <- c(                                         # Create vector with indices of columns to be extracted,
    selected_feature,                                         # ...containing all selected features
    562, 563)                                                 # ...and indices of labelid and activity columns

extracted_measurement <-                                      # Create cut-down dataset with columns...
    select(merged_measurement,                                # ...selected from full data set using
    all_of(selected_column))                                  # ...the selected_column vector defined above
                                                                             
## Use descriptive activity names to name the activities in the data set
labelled_measurement <-                                       # Add descriptive activity names...
    extracted_measurement %>%                                 # ... to the cut-down data set by
    inner_join(activity_name, by="labelid") %>%               # ... joining it with activity name data frame
    select (-labelid)                                         # ... and removing labelid column supporting the join

## Label the data set with descriptive variable names
var_names <-                                                # Create vector with descriptive and easy-to use variable names by...
  c(                                                        # ...concatenating values transformed as follows:
    tolower(                                                # ...- lowercase all characters
    gsub("\\(|,|-","_", (                                   # ...- replace "(" and "-" by "_"
    gsub("\\(\\)|\\)","", (                                 # ...- remove all instances of ")" and "()" in
    in_feature_name[selected_feature]))))),                 # ....feature names corresponding to indices of selected features.
    "subject", "activity")                                  # ... then add 'activity' and 'subject' as last two column names.

colnames(labelled_measurement) <- var_names        # Rename labelled measurement data set with the variable name vector

## Create a second, independent tidy data set with the average of each variable for each activity and each subject
tidy_dataset <-                                                             # Create tidy output data set...
  labelled_measurement %>%                                                  # ... from labelled measurements data set by
  group_by (activity, subject) %>%                                          # ... grouping by activity and subject
  summarise(across(tbodyacc_mean_x:angle_z_gravitymean, mean),              # ... averaging all measurements within each group
            .groups="keep") %>%                                             # ... whilst keeping groups created by group_by
  rename_at(vars(tbodyacc_mean_x:angle_z_gravitymean), ~ paste0(., "_avg")) # ... and rename columns with results (by adding '_avg' to the end)

cat("...Writing the tidy output data set to", outputfilename, "\n")

write.table(x=tidy_dataset, file=outputfilename, row.name=FALSE)            # Write resulting tidy data set into a txt file.
