# LinuxWelcome
In 3 simple steps: creates a welcome message whenever you open your first terminal and welcomes you by showing your relevant system info such as: Date &amp; Time info, System Info, User Info, Hardware Info, Network Info, System Status, Development Envrionments installed, System Health &amp; Recommendations and useful Quick Commands
(the commands are in parenthesis)

Step 1:
#Save the script as welcome.sh & make sure you're in the Downloads folder or wherever you saved welcome.sh
Make it executable, in a terminal type: (chmod +x welcome.sh)
Run the script: (./welcome.sh)

Step 2:
#To make it available for all users system-wide, so any user can type run this script with the word welcome
(sudo cp welcome.sh /usr/local/bin/welcome)
(sudo chmod +x /usr/local/bin/welcome)


Step 3:
#Add to global bashrc to show welcome message for all users when they login/start a terminal
(sudo nano /etc/bash.bashrc)
#anywhere there is free space at the bottom of the file copy & paste the following text, then ctrl + o, to save it, then ctrl +x to exit:

(if [ -z "$WELCOME_SHOWN" ] && [ -n "$PS1" ]; then
    export WELCOME_SHOWN=1
    /usr/local/bin/welcome
fi)

