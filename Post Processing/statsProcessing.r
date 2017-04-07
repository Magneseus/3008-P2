# Read in the data
data = read.csv("./data/parsed_data.csv")

# Seperate data by scheme
schemes = unique(data$scheme)


# Blank list of values
listVars = c()

# For each scheme type
for (s in schemes)
{
  # LOGIN NUMBER PROCESSING
  
  # Calculate statistics for Total Logins
  listVars = append(listVars, mean(data$totalLogin[data$scheme == s]))
  listVars = append(listVars, sd(data$totalLogin[data$scheme == s]))
  listVars = append(listVars, median(data$totalLogin[data$scheme == s]))
  
  # Calculate statistics for Successful Logins
  listVars = append(listVars, mean(data$successLogin[data$scheme == s]))
  listVars = append(listVars, sd(data$successLogin[data$scheme == s]))
  listVars = append(listVars, median(data$successLogin[data$scheme == s]))
  
  # Calculate statistics for Failed Logins
  listVars = append(listVars, mean(data$failLogin[data$scheme == s]))
  listVars = append(listVars, sd(data$failLogin[data$scheme == s]))
  listVars = append(listVars, median(data$failLogin[data$scheme == s]))
  
  
  # LOGIN TIME PROCESSING
  
  # Calculate statistics for Successful Login Times
  listVars = append(listVars, mean(data$successTime[data$scheme == s]))
  listVars = append(listVars, sd(data$successTime[data$scheme == s]))
  listVars = append(listVars, median(data$successTime[data$scheme == s]))
  
  # Calculate statistics for Failed Login Times
  listVars = append(listVars, mean(data$failTime[data$scheme == s]))
  listVars = append(listVars, sd(data$failTime[data$scheme == s]))
  listVars = append(listVars, median(data$failTime[data$scheme == s]))

} # END OF SCHEME LOOP

# Create the matrix
matrixVars = matrix(listVars, nrow = length(schemes), ncol = 15, byrow = TRUE)

# Name the matrix rows and columns
dimnames(matrixVars) = list(as.character(schemes), c("meanTotal","sdTotal","medianTotal","meanSuccess","sdSuccess","medianSuccess","meanFail","sdFail","medianFail","meanSuccessTime","sdSuccessTime","medianSuccessTime","meanFailTime","sdFailTime","medianFailTime"))

write.csv(matrixVars, file="./data/stats.csv")



# Now let's do the GRAPHS!!!!!!!!!!!
pdf(file="./data/all_graphs.pdf", paper="letter", height=10)

# Make Graphs for Total Logins
par(mfrow=c(3,length(schemes)))
for (s in schemes)
{
  hist(data$totalLogin[data$scheme == s], main=paste(as.character(s), "Total Logins"), xlab="Num Total Logins")
}

# Make Graphs for Successful Logins
for (s in schemes)
{
  hist(data$successLogin[data$scheme == s], main=paste(as.character(s), "Successful Logins"), xlab="Num Successful Logins")
}

# Make Graphs for Falied Logins
for (s in schemes)
{
  hist(data$failLogin[data$scheme == s], main=paste(as.character(s), "Failed Logins"), xlab="Num Failed Logins")
}
#readline("next?")



# LOGIN TIME PROCESSING HISTOGRAMS

# Make Graphs for Successful Login Times
#par(mfrow=c(2,length(schemes)))
layout(matrix(c(0,0,0, 1,2,3, 4,5,6, 0,0,0), nrow = 4, ncol = 3, byrow = TRUE))
for (s in schemes)
{
  hist(data$successTime[data$scheme == s], main=paste(as.character(s), "Success Time"), xlab="Time")
}

# Make Graphs for Failed Login Times
for (s in schemes)
{
  hist(data$failTime[data$scheme == s], main=paste(as.character(s), "Failed Time"), xlab="Time")
}
#readline("next?")

# LOGIN TIME PROCESSING BOXPLOTS

# Make Graphs for Successful Login Times
#par(mfrow=c(2,length(schemes)))
layout(matrix(c(0,0,0, 1,2,3, 4,5,6, 0,0,0), nrow = 4, ncol = 3, byrow = TRUE))
for (s in schemes)
{
  boxplot(data$successTime[data$scheme == s], main=paste(as.character(s), "Success Time"), xlab="Time")
}

# Make Graphs for Failed Login Times
for (s in schemes)
{
  boxplot(data$failTime[data$scheme == s], main=paste(as.character(s), "Failed Time"), xlab="Time")
}

# Finish the PDF
dev.off()

