Getting and Clearning Data Course project
================================

This repository contains the implementation of the following requirements as the "Getting and Cleaning Data" course project. 
The data to be used is available on the following URL: https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

The data represents data collected from the acceleromenters from Samsumg Galaxy S smarphone. A full description of the exeriment can be found on the following URL: http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 

The goal is to create one R script called run_analysis.R that does the following. 

1. Merges the training and the test sets to create one data set.
2. Extracts only the measurements on the mean and standard deviation for each measurement. 
3. Uses descriptive activity names to name the activities in the data set
4. Appropriately labels the data set with descriptive variable names. 
5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

Below is a short description of the directions I used while doing this project.
At first I decided to use data.table package instead of using data.frame's. 

1. On the first part, the general idea is to read both data sets and rbind them. Then you find out there is no read.fwf for data.table. It would be possible to load into a data.frame and then cast it to data.table. One possible command to read the file was:
dt<-as.data.table(read.fwf('test/X_test.txt',header=F, widths=rep(c(-1,15),561), buffersize= 10)))
The command above takes a little over 60 seconds to run.
Then I checked on how to use the fread command for fixed width field files and came up with a two step process. Looking quickly at the data it's clear that it is separated by single spaces, but in some cases for positive numbers, it appears to be double spaces. It messed up a normal read.csv or other functions. 
But I found the two step process a lot better and faster than the previous approach. First it substitutes double spaces by one single space and also substitutes lines that starts with one space to no space using sed. It creates a new file and then I read this new file now with single space separator with fread in less than 1/2 second into a data.table.
The same approach is used on both data sets and its smaller files are also loaded and binded to the data.table's. At the end I used rbindlist with the test and train data.tables to create a single data.table with everything.

2. For the second piece of this project I used the file features.txt. This file has all the variable names and their column position. The idea was to grep the file features.txt to get what columns had mean or std in their names and then filter the data.table created in step one (the column names were set previously). My assumption here was to take ALL variables that included mean or std in their names.

3. The activity descriptions can be found in the file activity_labels.txt. The contents of this file was loaded into a data.frame and then used to add a new column with the activity descriptions in the data.table at the end of the process.

4. The labels added to the resulting dataset was basically the variable names found on features.txt file with a bit of editting. The variables were uppercased and a few other edits were made.

5. For the fifth part I used the data.table option to create a key on activity number and subject id and then grouped the rows based on this key, for each group calculated the mean. The command used was the following:
DT[,lapply(.SD,mean),by=key(DT)]
The column names were renamed to indicate that it was a summarization of the original values. MEAN_OF was added to the variable names.
The data was saved with the command write.table using row.name=FALSE and can be reloaded using the following commands:
fread('resultingDataset.csv', sep=' ')
read.table('resultingDataset.csv', sep=' ', header=T)

