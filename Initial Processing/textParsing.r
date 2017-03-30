# Text csv
data = read.csv("./data/text_log.csv")
schemeName = "Text"

# Remove rows where there is invalid/no data
#
# The rows that qualify as invalid: 
# are ones that have the scheme listed as "unknown;N/A"
# and the ones that have the mode listed as "reset"
# and the ones that have the mode listed as "create"
data <- data[!(data$scheme == "unknown;N/A" | data$mode == "reset" | data$mode == "create"),]

# Get a list of unique user IDs
users = unique(data$user)

# Create the final dataframe sorted by user ID
finalFrame = data.frame(user=c(as.character(users)))

# Add blank columns for data to be added to
for (i in c("scheme","totalLogin","successLogin","failLogin","successTime","failTime")) finalFrame[,i] <- NA

# Iterate through all users
for (u in users)
{
  # get only data relevant to the current user
  userData <- data[data$user == u,]
  
  # Number of logins and number of successful logins start at 0
  numLogins = 0
  numSuccess = 0
  
  # List of login times
  loginTimeSuccess = c()
  loginTimeFail = c()
  
  # get a list of unique sites
  sites = unique(userData$site)
  
  # Iterate through all sites
  for (s in sites)
  {
    # get data relevant to the current site
    siteData <- userData[userData$site == s,]
    
    # Calculate the number of successful logins
    numSuccess <<- numSuccess + sum(apply(siteData, 1, function(x) x["mode"] == "login" & x["event"] == "success"))
    
    # Time storage
    tmp_timeStart = NULL
    tmp_timeEnd = NULL
    
    # get a list of all time differences between enter:start and enter:passwordSubmitted events
    listOfLoginTimes = apply(siteData, 1, function(x) {
      # This is a started login attempt, so we start the timer and also increment the total # of logins
      if (x["mode"] == "enter" & x["event"] == "start") {
        
        # Check if the user "failed" a login
        if (!is.null(tmp_timeEnd)) {
          # Add the login time to the failed list
          loginTimeFail <<- c(loginTimeFail, as.numeric(difftime(tmp_timeEnd, tmp_timeStart, units="secs")))
          
          # Set the new time values
          tmp_timeEnd <<- NULL
          tmp_timeStart <<- x["time"]
          
          # Increment the total number of logins
          numLogins <<- numLogins + 1
        } else {
          # Otherwise the user is just starting a login as normal
          tmp_timeStart <<- x["time"]
          numLogins <<- numLogins + 1
        }
        
        return (0)
      }
      # This is a login attempt being completed, so record the time since the last enter:start event
      else if (!is.null(tmp_timeStart) &  x["mode"] == "enter" & x["event"] == "passwordSubmitted") {
        tmp_timeEnd <<- x["time"]
        return(0)
      }
      # This is anything else (eg. a login:success event), so we don't care about it and do nothing
      else {
        # If this is a login:success event add the time to the succeeded list
        if (!is.null(tmp_timeEnd) & x["mode"] == "login" & x["event"] == "success") {
          loginTimeSuccess <<- c(loginTimeSuccess, as.numeric(difftime(tmp_timeEnd, tmp_timeStart, units="secs")))
        }
        # If this is a login:failure event add the time to the failed list
        else if (!is.null(tmp_timeEnd) & x["mode"] == "login" & x["event"] == "failure") {
          loginTimeFail <<- c(loginTimeFail, as.numeric(difftime(tmp_timeEnd, tmp_timeStart, units="secs")))
        }
        # If the time is not set, increment the number of logins
        else if (is.null(tmp_timeEnd)) {
          numLogins <<- numLogins + 1
        }
        
        # Set the time values to null, no matter what
        tmp_timeStart <<- NULL
        tmp_timeEnd <<- NULL
        
        return(0)
      }
    })
  
  } ###### END OF SITE LOOP
  
  # Now we know the total number of logins and the number of successful logins, so the number of failed
  # is just TOTAL - SUCCESSFUL == FAILED
  numFailed = numLogins - numSuccess
  
  ###### Calculate the means of the fail and succeeding login times #######
  # calculate the standard deviation
  sdSuccess = sd(loginTimeSuccess)
  sdFail = sd(loginTimeFail)
  
  # calculate the current mean
  meanSuccess = mean(loginTimeSuccess)
  meanFail = mean(loginTimeFail)
  
  # remove outliers
  loginTimeSuccess = loginTimeSuccess[!loginTimeSuccess %in% boxplot.stats(loginTimeSuccess)$out]
  loginTimeFail = loginTimeFail[!loginTimeFail %in% boxplot.stats(loginTimeFail)$out]
  
  
  # calculate the new means
  meanSuccess = mean(loginTimeSuccess)
  meanFail = mean(loginTimeFail)
  
  
  # Set all the values for the user in the final dataframe here...
  finalFrame$scheme[finalFrame$user == u] = schemeName
  
  finalFrame$totalLogin[finalFrame$user == u] = numLogins
  finalFrame$successLogin[finalFrame$user == u] = numSuccess
  finalFrame$failLogin[finalFrame$user == u] = numFailed
  
  finalFrame$successTime[finalFrame$user == u] = meanSuccess
  finalFrame$failTime[finalFrame$user == u] = meanFail
  
} ###### END OF USER LOOP

# Export to a .csv
addColNames = file.exists("./data/parsed_data.csv")
write.table(finalFrame, "./data/parsed_data.csv", sep=",", col.names = !addColNames, row.names = F, append = addColNames)
