import java.awt.Robot;
import java.awt.AWTException;
import javax.swing.JFrame;

Robot robot;

final int passwordSize = 4;
String[] wordsPossible;
PFont font;

boolean confirming = true;
int currSite = 0;
int[] siteOrder;
int counter = 0;

// timers
int[] timers;
final int CREATE = 0, SUCCESS = 1, FAILURE = 2;

PrintWriter logfile;

boolean entering = false;
String entry = null;
int showWrong = 0;
int tries = 0;

boolean complete = false;

String[] generatedPassword = null;

String username;
String[] sites;
String[] passwords;

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
 //((JFrame)frame).setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
   String[] oldLogs = loadStrings("logfile.txt");
  
  logfile = createWriter("logfile.txt");
  for(int i=0; i<oldLogs.length; i++) logfile.print(oldLogs[i]);

  wordsPossible = loadStrings("SEUSS_WORDS.txt");
  font = loadFont("ArialMT-48.vlw");
  textFont(font, 20);

  username = "user" + int(random(1000));
  sites = new String[3];
  sites[0] = "Email";
  sites[1] = "Bank";
  sites[2] = "Facebook";

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

  passwords = new String[sites.length];

  for (int i=0; i<sites.length; i++) passwords[i] = null;

  timers = new int[3];
  for (int i=0; i<timers.length; i++) timers[i] = 0;
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
      if (generatedPassword == null)
      {
        generatedPassword = generatePasswordArray();
      }

      String printString = "Your new " + sites[currSite] + " password is '";
      for (int i=0; i<generatedPassword.length; i++) printString += generatedPassword[i] + " ";
      printString = printString.substring(0, printString.length() - 1);
      printString += "', with no spaces.";

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

  if (entry != null) 
    strokeWeight(2);

  rectMode(CENTER);
  rect(310, 70, 300, 20);
  if (entry != null)
  {
    String hidden = "";
    for (int i=0; i<entry.length(); i++) hidden += "*";
    text(hidden, 165, 73);
  }

  strokeWeight(1);
  rect(500, 70, 50, 20);
  text("OK", 485, 70);
  fill(0);

  if (showWrong > 0) text("Incorrect.", 10, 100);
  showWrong = max(0, showWrong-1);
}

void exit()
{
  logfile.flush();
  logfile.close();
  super.exit();
}

void mouseClicked() 
{
  if (constrain(mouseX, 160, 460) == mouseX && constrain(mouseY, 60, 80) == mouseY)
  {
    if (entry == null)
    {
      timers[CREATE] = millis();
      timers[SUCCESS] = millis();
      if(tries == 0) timers[FAILURE] = millis();
    }
    
    entry = "";
  } else if (constrain(mouseX, 475, 525) == mouseX && constrain(mouseY, 60, 80) == mouseY)
  {
    robot.keyPress(ENTER);
  } else
  {
    generatedPassword = generatePasswordArray();
  }
}

void keyTyped() 
{
  if (entry != null)
  {
    if (key == ENTER || key == RETURN) {
      if (verifyPassword(entry))
      {
        println(currSite + " " + entry);
        if (confirming)
        {
          currSite++;
          // log successful create
          log("create/success", CREATE);
        } else
        {
          counter++;
          if (counter < siteOrder.length)
          {
            currSite = siteOrder[counter];
          } else
          {
            complete = true;
          }

          // log successful entry
          log("login/success", SUCCESS);
        }

        generatedPassword = null;
      } else
      {
        // entry fail
        showWrong = 120;
        if (!confirming) 
        {
          tries++;
          if (tries == 3)
          {
            tries = 0;
            // log failure
            log("login/failure", FAILURE);
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

String[] generatePasswordArray() 
{
  String[] pass = new String[passwordSize];

  for (int i=0; i<passwordSize; i++) 
  {
    pass[i] = wordsPossible[(int)random(wordsPossible.length)];
  }

  return pass;
}

String generatePasswordString(String[] arr)
{
  String pass = "";

  for (int i=0; i<arr.length; i++)
  {
    pass += arr[i];
  }

  return pass;
}

boolean verifyPassword(String attempt) 
{
  return attempt.equals(passwords[currSite]);
}

void log(String text, int whichTimer)
{
  int diff = millis() - timers[whichTimer];
  timers[whichTimer] = millis();
  logfile.print("LOG: " + username + "," + text + "," + diff + "ms;");
}