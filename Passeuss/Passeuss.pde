import java.awt.Robot;
import java.awt.AWTException;
import java.util.Date;
import java.text.*;

Robot robot; // robot just used to simulate enter press

final int passwordSize = 4; // number of words the password has
String[] wordsPossible; // list of words to be used in passwords
PFont font;

boolean confirming = true; // whether or not the user in the confirmation stage of the program
int currSite = 0; // which site (of three) the user is on
int[] siteOrder; // the randomly assigned order of sites to be tested
int counter = 0; // where in the site tests they are

PrintWriter logfile; // the file that is written to to keep track of logs
DateFormat logDateFormat;
Date date;

String entry = null; // what the user has entered in the text box
int showWrong = 0; // timer for displaying the "incorrect" message
int tries = 0; // how many failures they have incurred this password
 
boolean complete = false; // have they finished the program

String[] generatedPassword = null; // the newest generated password

String username;
String[] sites; // name of the sites
String[] passwords; // passwords for each site

void setup() 
{
  size(700, 130);

  try { 
    robot = new Robot();
  } 
  catch (AWTException e) {
    e.printStackTrace();
    exit();
  }

  logDateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss:SSS");
  date = new Date();

  // load in the previous logs. Processing can't append to a file.
  String[] oldLogs = loadStrings("logfile.txt");

  logfile = createWriter("logfile.txt");
  // write the old logs to the "new" file
  for (int i=0; i<oldLogs.length; i++) logfile.print(oldLogs[i]);

  // load all possible words
  wordsPossible = loadStrings("SEUSS_WORDS.txt");
  
  // load and set the font to be used in UI
  font = loadFont("ArialMT-48.vlw");
  textFont(font, 20);

  // generate a random username
  username = "user" + int(random(1000));
  
  // assign names for each site
  sites = new String[3];
  sites[0] = "Email";
  sites[1] = "Bank";
  sites[2] = "Facebook";

  // randomize the order of the sites
  siteOrder = new int[3];
  for (int i=0; i<sites.length; i++) siteOrder[i] = -1;

  for (int i=0; i<sites.length; i++)
  {
    int spot;
    do
    {
      spot = int(random(sites.length));
    } 
    while (siteOrder[spot] != -1);

    siteOrder[spot] = i;
  }

  // initalize the password array
  passwords = new String[sites.length];

  for (int i=0; i<sites.length; i++) passwords[i] = null;
}

void draw()
{

  if (complete) exit();

  background(#ffffff);
  fill(0);

  textAlign(LEFT, CENTER);
  text("Hello "+username+".", 10, 10);

  if (confirming)
  {

    if (currSite == -1 || currSite >= sites.length)
    {
      confirming = false;
      currSite = -1;
    } else 
    {
      // if I haven't generated a password, generate one
      if (generatedPassword == null)
      {
        generatedPassword = generatePasswordArray();
      }

      String printString = "Your new " + sites[currSite] + " password is '";
      for (int i=0; i<generatedPassword.length; i++) printString += generatedPassword[i] + " ";
      printString = printString.substring(0, printString.length() - 1);
      printString += "', with no spaces.";

      // set the site's password
      passwords[currSite] = generatePasswordString(generatedPassword);

      text(printString, 10, 40);

      text("Please confirm.", 10, 70);
    }
  } else
  {
    if (currSite == -1 || currSite >= sites.length)
    {
      currSite = siteOrder[0];
    }

    String printString = "Please enter your " + sites[currSite] + " password.";
    text(printString, 10, 40);
  }


  noFill();

  // highlight the text box if it is selected
  if (entry != null) 
    strokeWeight(2);

  rectMode(CENTER);
  rect(310, 70, 300, 20);
  if (entry != null)
  {
    // display the **'d password
    String hidden = "";
    for (int i=0; i<entry.length(); i++) hidden += "*";
    text(hidden, 165, 73);
  }

  strokeWeight(1);
  rect(500, 70, 50, 20);
  text("OK", 485, 70);
  fill(0);

  // show the "incorrect" statement if there's still time in the timer
  if (showWrong > 0) text("Incorrect.", 10, 100);
  showWrong = max(0, showWrong-1);
}

// called when the program ends
void exit()
{
  // finish writing the file and close file
  logfile.flush();
  logfile.close();
  
  // actually close the program
  super.exit();
}

void mouseClicked() 
{
  // clicking the text box
  if (constrain(mouseX, 160, 460) == mouseX && constrain(mouseY, 60, 80) == mouseY)
  {    
    entry = ""; 
  }
  else if (constrain(mouseX, 475, 525) == mouseX && constrain(mouseY, 60, 80) == mouseY) // clicking ok button
  {
    // simulate enter being hit
    robot.keyPress(ENTER);
  } else
  {
    // generates a new password to be used when creating. Do we want to keep this?
    //generatedPassword = generatePasswordArray();
  }
}

void keyTyped() 
{
  if (entry != null)
  {
    if (key == ENTER || key == RETURN) {
      if (verifyPassword(entry))
      {
        //println(currSite + " " + entry);
        
        // if you successfully confirm a password
        if (confirming)
        {
          // move to the next site
          currSite++;
          
          // reset the tries counter
          tries = 0;
          
          // log successful create
          log("create/success");
        } else
        {
          // if we're not confirming, try to move to the next random site
          counter++;
          if (counter < siteOrder.length)
          {
            // set the current site to the random site
            currSite = siteOrder[counter];
          } else
          {
            // if we've traversed all of the sites, we're done
            complete = true;
          }

          // log successful entry
          log("login/success");
        }

        generatedPassword = null;
      } else
      {
        // entry fail
        
        // set timer to ~2 seconds
        showWrong = 120;
        
        // if you fail three attempts to enter pass, log a failure
        if (!confirming) 
        {
          tries++;
          if (tries == 3)
          {
            tries = 0;
            
            // log failure
            log("login/failure");
          }
        }
      }
      entry = null;
    } else if (key == BACKSPACE) {
      entry = entry.substring(0, (max(0, entry.length()-1)));
    } else {
      entry += key;
    }
  }
}

// generates random (non-unique) words from the word list for password
String[] generatePasswordArray() 
{
  String[] pass = new String[passwordSize];

  for (int i=0; i<passwordSize; i++) 
  {
    pass[i] = wordsPossible[(int)random(wordsPossible.length)];
  }

  return pass;
}

// simply puts the array of words into a single password string
String generatePasswordString(String[] arr)
{
  String pass = "";

  for (int i=0; i<arr.length; i++)
  {
    pass += arr[i];
  }

  return pass;
}

// returns whether or not a user's password attempt matches the saved password
boolean verifyPassword(String attempt) 
{
  return attempt.equals(passwords[currSite]);
}

// writes a log to the log file, with the correct time
// also resets the timer when logged
void log(String text)
{
  //int diff = millis() - timers[whichTimer];
  //timers[whichTimer] = millis();
  date = new Date();
  String dateString = logDateFormat.format(date);
  logfile.print("LOG: " + username + "," + text + "," + dateString + ";");
}