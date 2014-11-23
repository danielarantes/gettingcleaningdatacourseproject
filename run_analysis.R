#You should create one R script called run_analysis.R that does the following. 
#Merges the training and the test sets to create one data set.
#Uses descriptive activity names to name the activities in the data set
#Appropriately labels the data set with descriptive variable names. 
#Extracts only the measurements on the mean and standard deviation for each measurement. 
#From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

# loads data.table library
library(data.table)

# sets the working directory
setwd('~/2014/Coursera//GettingAndCleaningData/project1//UCI HAR Dataset/')

# reads the activity labels
act_labels<-read.csv('activity_labels.txt', sep=' ', header=F)
names(act_labels)<-c('number', 'descr')

# substitutes double spaces and lines that starts with a space so we can use the fread easily.
# I tried to use it directly using pipe function but it didnt work well. So it is a two step process.
system("sed 's/  / /g' < test/X_test.txt | sed 's/^ //g' > test/X_test2.txt")
system("sed 's/  / /g' < train/X_train.txt | sed 's/^ //g' > train/X_train2.txt")

# reads the files and creates a data.table for each set
dt_test<-fread('test/X_test2.txt', sep=' ')
dt_train<-fread('train/X_train2.txt', sep=' ')

# loads y_test
y_test<-read.csv('test/y_test.txt', header=F)
# loads y_train
y_train<-read.csv('train/y_train.txt', header=F)

# adds the activities to the data.table. Just like cbind.
dt_test<-dt_test[,activity_number:=y_test]
# adds the activities to the data.table
dt_train<-dt_train[,activity_number:=y_train]

# reads the subject ids (for the experiment)
train_subjects<-read.csv('train//subject_train.txt', header=F, sep=' ')
test_subjects<-read.csv('test//subject_test.txt', header=F, sep=' ')

# adds the subject ids to the dataset
dt_train<-dt_train[,subject_id:=train_subjects]
dt_test<-dt_test[,subject_id:=test_subjects]

# rbinds the data.tables creating one data set.
# 1 - that is the first part of the assignment
complete_dataset<-rbindlist(list(dt_test, dt_train))

# reorder the data.table columns so the new added columns appear first
setcolorder(complete_dataset, c(names(complete_dataset)[562:563], names(complete_dataset)[1:561]))

# removes the data.tables created earlier
rm(dt_test)
rm(dt_train)

#=======================================================================
# reads the features file
features<-read.csv('features.txt', sep=' ', header=F)
names(features)<-c('colnumber', 'featurename')

# transforming factors to character
features$featurename<-as.character(features$featurename)

# setting all in upper case
features$featurename<-casefold(features$featurename, upper=T)

# removing (), - and ,
features$featurename<-sapply(features$featurename, FUN=function(x) gsub('-',replacement='.',x))
features$featurename<-sapply(features$featurename, FUN=function(x) gsub('\\(\\)',replacement='',x))
features$featurename<-sapply(features$featurename, FUN=function(x) gsub(',',replacement='_',x))
features$featurename<-sapply(features$featurename, FUN=function(x) gsub('^T',replacement='TIME_',x))
features$featurename<-sapply(features$featurename, FUN=function(x) gsub('^F',replacement='FREQ_',x))

# adds proper column names to all columns
# 4 - that is the fourth part of the project.
setnames(complete_dataset, c(casefold(names(complete_dataset)[1:2], upper=T),features$featurename))

# greps the second column of the features data frame (featurename column) searching for mean
meanColumns<-features[sapply(features[2], FUN=function(x) grepl('MEAN', x)),]

# greps the second column of the features data frame (featurename column) searching for std
stdColumns<-features[sapply(features[2], FUN=function(x) grepl('STD', x)),]

# puts them together
meanStdColumns<-rbind(meanColumns, stdColumns)

# filters the columns with MEAN in their name.
# I considered important to keep the new added columns in there.
# 2 - that is the second part of the project.
meanStdDT<-complete_dataset[,c(names(complete_dataset)[1:2], meanStdColumns$featurename), with=F]

# sets keys for the grouping used below
setkey(meanStdDT,ACTIVITY_NUMBER,SUBJECT_ID)

# calculates the mean for each sub data.table by the groups indicated by the keys
# so for each pair (activity_number, subject_id) and each column, a mean will be calculated
resultingDT<-meanStdDT[,lapply(.SD,mean),by=key(meanStdDT)]
resultingDT<-resultingDT[,ACTIVITY_DESCR:=sapply(resultingDT$ACTIVITY_NUMBER,FUN=function(x) { act_labels$descr[x]})]

# reorder the data.table columns so the new added columns appear first
setcolorder(resultingDT, c(names(resultingDT)[89], names(resultingDT)[1:88]))

# renames the column names to indicate they are a summarization of the original values
namesDT<-names(resultingDT)
for(i in 4:length(namesDT)){
  setnames(resultingDT, namesDT[i], paste('MEAN_OF_', namesDT[i], sep=''))
}

# saves the resulting dataset
write.table(resultingDT, file='../data/resultingDataset.csv', row.name=FALSE) 
