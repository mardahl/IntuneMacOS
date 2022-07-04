#!/bin/zsh
#set -x

############################################################################################
##
## Script to emulate LAPS on MacOS
## 
## VER 1.0.0
##
## Change Log
##
## 2022-06-20  - First draft version
## 
##
## Copyright Michael Mardahl (github.com/mardahl)
## MIT License
## NOTE: FileVault encrypted devices can't use this script as is.
##       Use this at your own risk - you might go insane...
##
## Credits: Some parts borrowed from @jonnokid and @nverselab /twitter
############################################################################################




## Declaring variables
username=administrator                                              #admin username to create/update on the device
password="$(openssl rand -base64 8 |md5 |head -c8;echo)$(date)"     #generate random 8char string and add date info
password=${password// }                                             #remove spaces from password

scriptname="user-$username"                                         #name of this script
logdir="/Library/Logs/Microsoft/IntuneScripts/$scriptname"          # The location of our logs and last updated data
log="$logdir/$scriptname.log"                                       # The location of the script log file

# Functions 

function startLog() {

    ###################################################
    ###################################################
    ##
    ##  start logging - Output to log file and STDOUT
    ##
    ####################
    ####################

    if [[ ! -d "$logdir" ]]; then
        ## Creating Metadirectory
        echo "$(date) | Creating [$logdir] to store logs"
        mkdir -p "$logdir"
    fi

    echo "Initializing a fresh log file..." >| $log
    exec > >(tee -a "$log") 2>&1
    
}

###################################################################################
###################################################################################
##
## Begin Script Body
##
#####################################
#####################################

# Initiate logging
startLog

echo ""
echo "##############################################################"
echo "# $(date) | Logging run of [$scriptname] script to [$log]"
echo "##############################################################"
echo ""

# Create User and add to admins
echo "$(date) | Testing for existing $username"
# test for user
user_not_exist=$(id -u $username > /dev/null 2>&1; echo $?)

#create user or update user password
if [ "$user_not_exist" = "1" ]; then
    echo "$(date) | No existing user named $username. Creating $username."
    dscl . -create /Users/$username
    dscl . -create /Users/$username UserShell /bin/bash
    dscl . -create /Users/$username RealName $username
    dscl . -create /Users/$username UniqueID "510"
    dscl . -create /Users/$username PrimaryGroupID 20
    dscl . -create /Users/$username NFSHomeDirectory /Users/$username
    dscl . -passwd /Users/$username $password
    dscl . -append /Groups/admin GroupMembership $username
    echo ""
    echo "##############################################################"
    echo "# $(date) | Created user: $username - password is: $password"
    echo "##############################################################"
    echo ""
else
    echo "$(date) | Existing $username found. Rotating passw."
    dscl . -passwd /Users/$username $password
fi

echo "$(date) | Cleaning passw from logfiles."

# remove password from IntuneMDMLog
MDMlogs=(/Library/Logs/Microsoft/Intune/IntuneMDMDaemon*.log)
for mdmlogpath in $MDMlogs
do
    sed -n -i '' -e '/password/d' $mdmlogpath
done
# remove password line from local log file to avoid storing password in cleartext
sed -n -i '' -e '/password/d' $log
echo "$(date) | Removed passw from device local log file."
