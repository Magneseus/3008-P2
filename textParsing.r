# Text csv
data = read.csv("./data/text_log.csv")

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
  
  # get a list of unique sites
  sites = unique(userData$site)
  
  # Iterate through all sites
  for (s in sites)
  {
    # get data relevant to the current site
    siteData <- userData[userData$site == s,]
    
    # Naive way to calculate sums of the logins, does not take into account user entering the password
    # and then not hitting the login button
    numLogin = sum(apply(siteData, 1, function(x) x["mode"] == "login"))
    numSuccess = sum(apply(siteData, 1, function(x) x["mode"] == "login" & x["event"] == "success"))
    numFail = sum(apply(siteData, 1, function(x) x["mode"] == "login" & x["event"] == "fail"))
    
    # get a list of all time differences between enter:start and enter:passwordSubmitted events
    tmp_timeStart = NULL
    listOfLoginTimes = apply(siteData, 1, function(x) {
      if (x["mode"] == "enter" & x["event"] == "start") {
        tmp_timeStart <<- x["time"]
        return (0)
      }
      else if (!is.null(tmp_timeStart) &  x["mode"] == "enter" & x["event"] == "passwordSubmitted") {
        return(as.numeric(difftime(x["time"], tmp_timeStart, units="secs")))
      }
      else {
        return(0)
      }
    })
    
    # calculate the mean
    meanLoginTime = mean(listOfLoginTimes)
  }
  
}