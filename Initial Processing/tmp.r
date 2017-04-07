
data = read.csv("./data/logfile_others.csv")

users = unique(data$user)

# Create the final dataframe sorted by user ID
finalFrame = data.frame(user=c(as.character(users)))

# Add blank columns for data to be added to
for (i in c("numSuccess","numFail","successTime","failTime")) finalFrame[,i] <- NA


# Iterate through all users
for (u in users)
{
  # get only data relevant to the current user
  userData <- data[data$user == u,]
  
  # Calculate the number of successful/failed logins
  numSuccess = sum(apply(userData, 1, function(x) x["type"] == "login/success"))
  numFails = sum(apply(userData, 1, function(x) x["type"] == "login/failure"))
  
  # List of login times
  loginTimeSuccess = c()
  loginTimeFail = c()
  
  # Time storage
  prev_time = NULL
  
  # get a list of all time differences between enter:start and enter:passwordSubmitted events
  listOfLoginTimes = apply(userData, 1, function(x) {
    
    if (x["type"] == "login/success" | x["type"] == "create/success") {
      loginTimeSuccess <<- c(loginTimeSuccess, as.numeric(difftime(x["time"], prev_time, units="secs")))
    }
    else if (x["type"] == "login/failure") {
      loginTimeFail <<- c(loginTimeFail, as.numeric(difftime(x["time"], prev_time, units="secs")))
    }
    
    prev_time <<- x["time"]
  })
  
  ###### Calculate the means of the fail and succeeding login times #######
  # calculate the standard deviation
  sdSuccess = sd(loginTimeSuccess)
  sdFail = sd(loginTimeFail)
  
  # calculate the current mean
  meanSuccess = mean(loginTimeSuccess)
  meanFail = mean(loginTimeFail)
  
  # Set all the values for the user in the final dataframe here...
  finalFrame$numSuccess[finalFrame$user == u] = numSuccess
  finalFrame$numFail[finalFrame$user == u] = numFails
  
  finalFrame$successTime[finalFrame$user == u] = meanSuccess
  finalFrame$failTime[finalFrame$user == u] = meanFail
  
} ###### END OF USER LOOP

# Export to a .csv
write.table(finalFrame, "./data/parsed_data_custom.csv", sep=",", col.names = TRUE)


