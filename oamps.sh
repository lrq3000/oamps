#!/usr/bin/env bash

# Copyright (C) 2010-2013 Larroque Stephen
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

#=== Declaring general vars
version="1.6.7"
lastchange="2012-03-26"
basemod="baseoa" #original mod (game without any custom mod),edit this var for other q3 based games (or even q3 itself)
basebin="oa_ded.i386" #server binary, edit it for other games
basebinpath="./" #path to the server binary
gtvbin="gtv" #filename of the gtv bin
gtvbinpath="./" #path to the gtv bin
screencmd="screen -A -m -d -S" #command to create a screen
noscreencmd="nohup" #command to create a server without screen # old value: "$TERM -hold -e"

#=== Current path detection
# Current working directory (needed for cron jobs)
WORKDIR=$(pwd)
# Current script filename
SCRIPTNAME=$(basename "$0")
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
# Filename of the shell/bash binary (needed for cron jobs)
# Note : In order to avoid duplicates in cron jobs, we use a conditionnal test here to try different options : first use sh, if non-existent use bash, if non-existent too use the default $SHELL binary
BASHDEFAULTBIN=$(basename "$SHELL")
BASHFOLDER=$(dirname "$SHELL")
if [ -x "$BASHFOLDER/sh" ]; then
	BASHBIN="sh"
elif [ -x "$BASHFOLDER/bash" ]; then
	BASHBIN="bash"
else
	BASHBIN="$BASHDEFAULTBIN"
fi

#=== Change the working directory to the current directory of the script (avoid problems with cron jobs and other unfortunate adventures)
cd "$SCRIPTPATH"

#=== Current date and time
today=$(date '+%Y-%m-%d')
currtime=$(date '+%H:%M:%S')

#=== Unique ID
# This ID will be prepended to any text output (via printtext function) to recognize each invocation of this script (for the case that there is a collision because 2 or more times this script is launched at the same moment)
uniqueid=$RANDOM # We call $RANDOM once and for all here because $RANDOM changes its value each time it is invocated

#=== No argument error
if [ $# -lt 1 ]; then
  echo "Type ./$SCRIPTNAME --help or bash $SCRIPTNAME --help to get more infos."
  exit
fi

#=== Show version
if [[ "$@" =~ "--version" ]]; then
	echo
	echo "** OpenArena multi-purpose servers launcher version $version on $lastchange"
	echo "** by GrosBedo - contributions by Heap"
	echo "** Licensed under LGPL v3+ (LGPL v3 or above)"
	echo

	exit
fi

#=== Help message
if [[ "$@" =~ "--help" ]]; then
  echo "Usage: ./$SCRIPTNAME [OPTION1] [VALUE1] [OPTION2] [VALUE2]...
Launch an OpenArena server (or any q3 based game) with pre-configured features. Include GTV (GamersTV) management features.

  -a, --addcron          add a cron job for the current arguments (will store ALL arguments into current user's cron). Value is cron date (in the form mm hh jj MMM JJJ or @something (@weekly, @daily, @hourly, @reboot, etc...)

  -b, --basepath         set the base (root) path of your game server's files (binaries, paks, ressources, etc...). This is used to make your game server believe it resides in another folder than where it is executed from (used for cron jobs too since cron needs absolute paths). Default to the folder where the game server binary resides.
  Note : basepath should be used for GTV instead of homepath (because GTV doesn't redirect everything to homepath, for example the delay folder).
  Note2: see --homepath, an extension of --basepath.

  -bin, --binfullpath    specify the server binary (permits to launch different games servers) - Note: basepath and homepath will be relative to the binary location

  -c, --config           use this config (_NO_ .cfg extension [eg: -c yourconfig]). Will append a number if -n or take all configs with the same pattern in the folder if -m is specified (eg: for \"oacl-config\" it will generate oacl-config0.cfg, oacl-config1.cfg).
  Note : Extension of your config must be .cfg ! eg: yourconfig.cfg
  Note2 : Your config must reside in the basepath/basemod (=baseoa) or homepath/basemod or homepath/mod folder! Absolute paths are NOT supported (by game engine)!
  
  -ct, --countdown		 say a countdown (in seconds) to the server before doing anything (should be used with -r, -k or -k2, but not only). The time will be automatically divided by 2 for each say. Eg: --countdown 60 will warn players 1 minute before the restart, then 30 sec, then 15 sec, then 7 sec, then 3 sec, then 2, then 1 second.
  
  -ctm, --countdownmessage	 custom message for countdown in the format 'say Warning: %countdown before restarting!' - default: 'say ^3Warning: the server will be restarted for maintenance in %countdown'

  -e, --exec             exec directly a command to the server (server is found via --config or --screenname)
  
  -ec, --execconfig      exec an external config file, just like commands were inputted directly inside the console (eg: yourconf.cfg)
  Note : path can either be absolute, or relative to this script directory.

  -ed, --execdelay       add a delay before executing the external config file
  
  -ext, --extend         add your own custom commandline arguments (eg: --extend \"+set mapname hihi +cvar_restart\")
  Note : custom commands will be executed after the normal commands that this script generates.
  
  -f, --fixgravity       fix the gravity for OA vanilla only, to compensate with the use of pmove_float

  -g, --gamemod          specify a gamemod (eg: baseoa, cpma, oacl2010). Defaults to baseoa. NEVER set this with GTV, leave it empty !

  -gb, --gamebasemod     specify a game base mod (eg: baseoa for OpenArena). Used by game servers for path in files searching.

  -h, --homepath         set the home path of media files (configs, paks, models and maps). By default, the same as where the game server binary resides, but by setting it you can specify a folder where all the pak and maps resides different than your game folder basepath, useful if you don't have admin rights (ie: game folder at /usr/lib/openarena and your own folder that you will set as homepath at /home/yourlogin/.openarena)
  Note : OpenArena home resides in ~/.openarena by default, this behaviour is changed here

  -hb, --heartbeat       activates regular heartbeats to the master listing server (used for GTV so it stays in the listing).

  -hs, --heartbeatscreen sets heartbeat screen name, if not specified, it will be launched in another terminal.

  -ht, --heartbeattime   sets the delay between each heartbeat to the master listing server (in seconds). Default : 5 min (300 sec).

  -k, --killall          kill all game terminals containing a config name similar in --config, or all screen sessions containing a similar name in --screenname. This will be done prior launching any server.
 
  -k2, --killall2        kill ALL game terminals, or ALL screen sessions (if using --screenname. Eg: -k2 -s), without any distinction.

  -j, --junk             clean the junk server config files created by CPMA or OA (q3config_server.cfg) and do a cvar_restart, and can clean the delay temp folder of GTV.

  -lan, --lan            set dedicated 1, no heartbeat to internet master listing server, your server will only be accessible via LAN
  
  -l, --log              specify the log used by your game server, to enable log rotation based on max size (rotation based on creation date is impossible on Unix)
  Note : big logs are known to produce lags. It is strongly advised to rotate your server's log.
  
  -lm, --logmaxsize      cut down the log logs to x KiloBytes (default: 5000KB = 5MB)

  -lof, --logoutputfolder backup the outputted logs in the specified folder (ordered by config name, date and time)

  -m, --multiple         run as many servers as the number of configs there are, screenname and ports are incremented (eg: '-m --config oacl-cpma' will launch a server for oacl-cpma-ctf.cfg , oacl-cpma-insta.cfg , oacl-cpma-elim.cfg , etc...)
  
  -n, --number           number of servers to run, ports and screenname are incremented (eg: '-p 10000 -s screen -n 3 -c oacl-cpma' will launch a server with oacl-cpma0.cfg on screen0 port 10000, a server with oacl-cpma1.cfg on screen1 port 10001, a server with oacl-cpma2.cfg on screen2 port 10002) 

  -o, --outputlog        saves all output of this script into the specified log
  
  -p, --port             port of your server. Will be incremented when using --number and --multiple

  -r, --restart          force restart : kill each server before relauching it

  -s, --screenname       screen session name for each servers (if not supplied another detached terminal will be opened)
  
  -s2, --screenname2     set the screen session name based on the config name (no need to supply a value here). Eg: --config oacl-cpma1.cfg will set screen oacl-cmpa1.cfg
  Note : with --multiple option, the full name of the config files found will be used.

  -tv, --gtv             enable gtv launching (one at a time).
  
  -tvb, --gtvbasepath    gtv basepath - useful to tell GTV where to find basemod folder (baseoa) and config folder (gtv3)
  
  -tvh, --gtvhomepath    gtv homepath - Note: homepath should be the same as homepath, for GTV to find the required mod's pk3s, but NOT to find basemod folder nor GTV config files (look for gtvbasepath)!

  -tvc, --gtvconfig      gtv config (with extension!), defaults to gtv.cfg if argument not supplied
  Note: must reside in gtvbasepath/gtv3 folder! It won't work in any other place (nor in gtvhomepath, contrary to homepath for game servers!)
  
  -tve, --gtvexec        exec directly a command to the GTV server (server is found via --gtvonfig or --gtvscreenname)
  
  -tvec, --gtvexecconfig exec an external config file for GTV, just like commands were inputted directly inside the console

  -tved, --gtvexecdelay  add a delay before executing the external config file for GTV

  -tvm, --gtvmaster      apply a trick to register to the supplied master listing server (you can see the GTV server in the game browser !)
  Note : the trick uses hping3, so you need it to be installed on your system for the trick to work, and since hping3 is a root tool, it will ask your user (not root!) password to issue a sudo hping3 !
  Note2: you can also use hping v1, but NOT hping2 which contains a bug that prevent the script from working on certain systems.

  -tvmp, --gtvmasterport port of the master listing server

  -tvmd,--gtvmasterdelay delay after launching the GTV server, before sending the heartbeat (GTV has to be fully started for the heartbeat to work !). Default to 5 sec.

  -tvp, --gtvport        set this port for GTV (if blank then GTV will take the last port, after all servers were launched)

  -tvs, --gtvscreenname  screen session name for GTV (if not supplied another detached terminal will be opened)

  -tvbin, --gtvfullpath  full pathname to the gtv binary (included the binary name and extension !) - Note: gtv basepath and homepath will be relative to the binary location
  
  -v, --verbose          show more informations, mainly for debugging purposes
  
  --version              show the version

  -vm, --vmgame          set the vm_game property (only useful for mods !). 0 = load aside on its own memory, 1 = load normally, 2 = load in the same memory as the core game
  
  -w, --watch            set the time (in seconds) to considerate the crashlog.txt (a file created when your server crashes but still stays in memory) as new enough to relaunch the server. -1 : Crashlog Watching Disabled, 0 : Unlimited, > 0 : timeframe to considerate the crashlog as valid to relaunch the server (Default : 24h = 86400).
  Note : the crashlog.txt file gets renamed after the server has been restarted, so the server can't be restarted twice for the same crash.
  

      --help      show this help

== General Notes:
  All paths are relative to the script location (this is to avoid problems when calling this script from cron jobs).

== Exemples:
  ./$SCRIPTNAME -c oacl-edit-me -g oacl2010 -p 27960 -s oaclserver --- launch a server with gamemod oacl2010 and config oacl-edit-me.cfg and port 27960 on screen named oaclserver.

  ./$SCRIPTNAME -c oacl-edit-me -g oacl2010 -p 27960 -s oaclserver -n 3 --- launch 3 servers with gamemod oacl2010 and config oacl-edit-me0.cfg then oacl-edit-me1.cfg then oacl-edit-me2.cfg and port 27960-27962 on screens named oaclserver0 to oaclserver2.

  ./$SCRIPTNAME -c oacl-edit-me -g oacl2010 -p 27960 -s oaclserver -r -a @daily --- kill a server and restart it, then add a cron job to automatically restart this server daily.

  ./$SCRIPTNAME -c oacl-edit-me -g oacl2010 -p 27960 -s oaclserver -a @hourly --- launch the server, then add a cron job to try each hour to relaunch this server (without -r the script don't kill the server, it relaunch it only if it doen't already exists).

  ./$SCRIPTNAME -n 0 -hb -tv -tvp 31000 -tvc gtv.cfg -tvm dpmaster.deathmask.net -tvmp 27950 --- launch no game server, only a GTV server with port 31000 and config gtv.cfg and register to the master listing server of OpenArena and send regular heartbeats to stay on the servers list.
  
  ./$SCRIPTNAME -n 0 -c oacl-edit-me -s oaclserver -ec 'morecommands.cfg' -ed 5 --- wait 5 seconds and sends all the commands contained inside 'morecommands.cfg' to the server at screen 'oaclserver'
  
  ./$SCRIPTNAME -n 0 -k -s oaclserver --- kill all servers with a screen name containing 'oaclserver'
"
  exit
fi 

#=== Arguments parsing
argslist=("$@") #store all arguments in a list so we can directly access the needed values for each argument
allargs="$@" #store all arguments in a line so we can use it for cron job
COUNT=0 #keep count of current argument so we can get the value in the next argument (eg : --port 27960)
# Parsing the arguments
for arg in "$@"
do
    #echo $COUNT you typed ${arg}. #debugline
    if [ "$arg" = "--addcron" ]  || [ "$arg" = "-a" ]; then # add a cron job for the supplied arguments (should be used once !), value must be in the form mm hh jj MMM JJJ or @something (@weekly, @daily, @hourly, @reboot, etc...)
      addcron="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--basepath" ]  || [ "$arg" = "-b" ]; then # force useage of basepath instead of homepath
      basepath="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--binfullpath" ]  || [ "$arg" = "-bin" ]; then # full pathname to the server binary (included the binary name and extension !), this permits to launch several servers with different games
      binfullpath="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--config" ]  || [ "$arg" = "-c" ]; then # name of the config (in baseoa or mod folder)
      config="${argslist[$COUNT+1]}"
	elif [ "$arg" = "--countdown" ]  || [ "$arg" = "-ct" ]; then # countdown (in seconds) to warn players before restarting the server
      countdown="${argslist[$COUNT+1]}"
	elif [ "$arg" = "--countdownmessage" ]  || [ "$arg" = "-ctm" ]; then # custom message for countdown in the format ''Warning: %countdown before restarting!''
      countdownmessage="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--exec" ]  || [ "$arg" = "-e" ]; then # exec directly a command to the server (server is found via --config or --screenname)
      gexec="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--execconfig" ]  || [ "$arg" = "-ec" ]; then # exec an external config file, just like commands were inputted directly inside the console
      gexecconfig="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--execdelay" ]  || [ "$arg" = "-ed" ]; then # add a delay before executing the external config file
      gexecdelay="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--extend" ]  || [ "$arg" = "-ext" ]; then # add your own custom commandline arguments
      cmdlinecustomargs="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--fixgravity" ]  || [ "$arg" = "-f" ]; then # change gravity for vanilla OA to set a server-side physics of 125Hz
      fixgravity="true"
    elif [ "$arg" = "--gamemod" ]  || [ "$arg" = "-g" ]; then # name of the mod folder
      mod="${argslist[$COUNT+1]}"
	elif [ "$arg" = "--gamebasemod" ]  || [ "$arg" = "-gb" ]; then # name of the base mod folder (eg: baseoa for OpenArena). Used by game servers for path in files searching.
      basemod="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--heartbeat" ]  || [ "$arg" = "-hb" ]; then # activates regular heartbeats to the master listing server (used for GTV so it stays in the listing).
      heartbeat="true"
    elif [ "$arg" = "--heartbeatscreen" ]  || [ "$arg" = "-hs" ]; then # sets heartbeat screen name, if not specified, it will be launched in another terminal.
      heartbeatscreen="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--heartbeattime" ]  || [ "$arg" = "-ht" ]; then # sets the delay between each heartbeat to the master listing server (in seconds). Default : 5 min (300 sec).
      heartbeattime="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--homepath" ]  || [ "$arg" = "-h" ]; then # sets fs_homepath (better than fs_basepath for most uses) to the specified value. By default, the same as where the script resides, but by setting it you can specify a folder where all the pak and maps resides different than your game folder, useful if you don't have admin rights (ie: game folder at /usr/lib/openarena and your own folder that you will set as homepath at /home/yourlogin/.openarena)
      homepath="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--junk" ]  || [ "$arg" = "-j" ]; then # clean the junk server config files created by CPMA or OA (q3config_server.cfg) and do a cvar_restart
      junk="true"
    elif [ "$arg" = "--killall" ]  || [ "$arg" = "-k" ]; then # kill ALL game terminal containing the value supplied in --config, or ALL screen sessions containing the value in --screenname
      killall="true"
    elif [ "$arg" = "--killall2" ]  || [ "$arg" = "-k2" ]; then # kill ALL game terminal, and ALL screen sessions before relaunching the servers
      killall2="true"
    elif [ "$arg" = "--lan" ]  || [ "$arg" = "-lan" ]; then # set dedicated 1, no heartbeat to internet master listing server, your server will only be accessible via LAN
      lan="true"
	elif [ "$arg" = "--log" ]  || [ "$arg" = "-l" ]; then # log to cut for rotation
      log2rotate="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--logmaxsize" ]  || [ "$arg" = "-lm" ]; then # cut down logs to x KBytes, because they can slow down the server a lot if they get too big
      logmaxsize="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--logoutputfolder" ]  || [ "$arg" = "-lof" ]; then # backup the outputted logs in the specified folder
      logoutputfolder="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--multiple" ]  || [ "$arg" = "-m" ]; then # run as many servers as the number of configs
      multiple="true"
    elif [ "$arg" = "--number" ]  || [ "$arg" = "-n" ]; then # number of servers to run
      nbserv="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--outputlog" ]  || [ "$arg" = "-o" ]; then # saves all output of this script into the specified log
      outputlog="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--port" ]  || [ "$arg" = "-p" ]; then # port of your server. Set a value between 27960-27963 for the server to show in LAN game servers browser (useless for internet).
      port="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--restart" ]  || [ "$arg" = "-r" ]; then # kill each server before relauching it
      restart="true"
    elif [ "$arg" = "--screenname" ]  || [ "$arg" = "-s" ]; then # screen session name for each servers (if not supplied another detached terminal will be opened)
      screenname="${argslist[$COUNT+1]}"
	elif [ "$arg" = "--screenname2" ]  || [ "$arg" = "-s2" ]; then # set the screen session name based on the config name (no need to supply a value here). Eg: --config oacl-cpma1.cfg will set screen oacl-cmpa1.cfg
      screenname2="true"
    elif [ "$arg" = "--verbose" ]  || [ "$arg" = "-v" ]; then # show more informations, mainly for debugging purposes
      verbose="true"
    elif [ "$arg" = "--vmgame" ]  || [ "$arg" = "-vm" ]; then # sets the vm_game property (only useful for mods !). 0 = load aside on its own memory, 1 = load normally, 2 = load in the same memory as the core game
      vmgame="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--watch" ]  || [ "$arg" = "-w" ]; then # sets the time (in seconds) to considerate the crashlog.txt (a file created when your server crashes but still stays in memory) as new enough to relaunch the server. -1 : Crashlog Watching Disabled, 0 : Unlimited, > 0 : timeframe to considerate the crashlog as valid to relaunch the server
      crashlogtime="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtv" ]  || [ "$arg" = "-tv" ]; then # enable gtv launching
      gtv="true"
	elif [ "$arg" = "--gtvbasepath" ]  || [ "$arg" = "-tvb" ]; then # gtv basepath - useful to tell GTV where to find basemod folder (baseoa) and config folder (gtv3)
      gtvbasepath="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvconfig" ]  || [ "$arg" = "-tvc" ]; then # gtv config, defaults to gtv.cfg if argument not supplied
      gtvconfig="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvexec" ]  || [ "$arg" = "-tve" ]; then # exec directly a command to the GTV server (server is found via --config or --screenname)
      gtvexec="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvexecconfig" ]  || [ "$arg" = "-tvec" ]; then # exec an external config file for GTV, just like commands were inputted directly inside the console
      gtvexecconfig="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvexecdelay" ]  || [ "$arg" = "-tved" ]; then # add a delay before executing the external config file for GTV
      gtvexecdelay="${argslist[$COUNT+1]}"
	elif [ "$arg" = "--gtvhomepath" ]  || [ "$arg" = "-tvh" ]; then # gtv homepath - Note: homepath should be the same as homepath, for GTV to find the required mod's pk3s, but NOT to find basemod folder nor GTV config files (look for gtvbasepath)!
      gtvhomepath="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvmaster" ]  || [ "$arg" = "-tvm" ]; then # apply a trick to register to the supplied master listing server (you can see the GTV server in the game browser !)
      gtvmaster="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvmasterdelay" ]  || [ "$arg" = "-tvmd" ]; then # delay after launching the GTV server, before sending the heartbeat (GTV has to be fully started for the heartbeat to work !). Default to 5 sec.
      gtvmasterdelay="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvmasterport" ]  || [ "$arg" = "-tvmp" ]; then # port of the master listing server
      gtvmasterport="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvport" ]  || [ "$arg" = "-tvp" ]; then # set this port for GTV (if blank then GTV will take the last port, after all servers were launched)
      gtvport="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvscreenname" ]  || [ "$arg" = "-tvs" ]; then # screen session name for GTV (if not supplied another detached terminal will be opened)
      gtvscreenname="${argslist[$COUNT+1]}"
    elif [ "$arg" = "--gtvfullpath" ]  || [ "$arg" = "-tvbin" ]; then # full pathname to the gtv binary (included the binary name and extension !)
      gtvfullpath="${argslist[$COUNT+1]}"
    fi
    let COUNT=$COUNT+1
done

#=== Servers and Misc Functions
function printtext {
# Print any text passed as an argument, with added features like an unique id (in case of output logging collision when the script is launched several times at the same time)
if (( $# > 0 )); then # if at leaste one text was supplied, then we send that text
	for param in "$@"; do
		echo "[$uniqueid~$(date '+%H:%M:%S')] $param"
	done
else # else, send an empty line
	echo
fi
}

function check_server_screen {
# Check if a screen with the _exact_ name to the server you want to launch already exists
  local name=$1
  local result=$(screen -ls | grep -Eo "[0-9]+\.$name\W")
  if [[ $(screen -ls | grep -Eo "[0-9]+\.$name\W") != "" ]]; then
	if [ -n "$verbose" ]; then printtext "Check : found the following screens : $result"; fi
    return 1
  else
    return 0
  fi
}

function check_server_noscreen {
# Check if a process with the _exact_ config to the server you want to launch already exists
  local config=$1
  local bin=$(basename "$binfullpath") # get only the binary name without directory path

  local result=$(ps aux | grep "$bin" | grep "$config" | awk '{print $2}') # if -E, must escape the point in $config. Old: local result=$(ps aux | grep '$noscreencmd' | grep '$binfullpath' | grep -E '$config\W' | awk '{print $2}')
  if [[ "$result" != "" ]]; then
	if [ -n "$verbose" ]; then printtext "Check : found the following processes : $result"; fi
    return 1
  else
    return 0
  fi
}

function check_crashlog {
# Check if the crashlog.txt file exists. This file is created by game servers engine when they crash, but don't quit (logical error, not critical but enough to shutdown and renders the server inaccessible).
# This is particularly useful since the normal check (check the server's process or screen existence) is not enough if the server process or screen is still present, but frozen. With crashlog, you can know.
	local path="$1"
	local mod="$2"
	if (( $crashlogtime < 0 )); then # if user supplied --watch -1 then it deactivates the checking of the existence of the crashlog
		return 0
	elif (( $crashlogtime == 0 )); then # if 0, no timelimit, just check if crashlog exists.
		if [ -e "$path/$mod/crashlog.txt" ]; then
			rename_crashlog "$path" "$mod"
			return 1
		else
			return 0
		fi
	elif (( $crashlogtime > 0 )); then # if a positive value is supplied (or by default), the crashlog will be checked, and a time will be compared : time will be compared between now and the last crashlog.txt modification date, if the difference is under this threshold, server is killed, restarted and crashlog.txt is renamed to crashlog_[time].txt
		if [ -e "$path/$mod/crashlog.txt" ]; then
			local crashlog_lastchange=$(date -r "$path/$mod/crashlog.txt" "+%s") # crashlog is necessarily generated in the specified mod folder, even if the engine always look in the basemod folder (baseoa), it does store the files it creates in the mod folder
			local now=$(date "+%s")
			if (( $now - $crashlog_lastchange <= $crashlogtime )); then # if the difference between now and the last modification date of the crashlog is below the threshold, then we restart the server because it means that the crashlog was created recently
				rename_crashlog "$path" "$mod"
				return 1
			else
				return 0
			fi
		else
			return 0
		fi
	fi
}

function rename_crashlog {
	local path="$1"
	local mod="$2"
	local now=$(date "+%Y-%m-%d_%Hh%M")
	cp "$path/$mod/crashlog.txt" "$path/$mod/crashlog_$now.txt"
	unlink "$path/$mod/crashlog.txt"
	if [ -n "$verbose" ]; then printtext "Renaming $path/$mod/crashlog.txt to crashlog_$now.txt"; fi
}

function launch_server {
  local port=$1
  local config=$2
  local nb=$3
  if [[ ! "$config" =~ ".cfg" ]]; then # add the .cfg extension if not present, and we add the nb if it exists
    config="$config$nb.cfg"
  fi
  if [ -n "$screenname2" ]; then # with --screenname2, we use the config as the screenname
	screenname="$config"
	nb='' # remove the $nb counter, to fix later tests and checks
  fi
  check_crashlog "$basepath" "$mod"
  checkcrashlog_exist_basepath=$?
  check_crashlog "$homepath" "$mod"
  checkcrashlog_exist_homepath=$?
  if [ -n "$screenname" ]; then # if screen name is supplied, we can call the screen function, else we just call another terminal
    if [ -n "$restart" ] || [[ $checkcrashlog_exist_basepath == 1 ]] || [[ $checkcrashlog_exist_homepath == 1 ]]; then # if argument -r or --restart or if a crashlog is found, we first kill the server before starting it (hence restarting it)
		printtext "Killing the server(s) (by screenname) before restarting it..."
		if [ -n "$multiple" ] && [ -z "$restart" ]; then # if multiple servers are launched at once, if we find a crashlog, then we should restart _all_ servers with this screenname/config (because we can't know for which server the crashlog was created since it is summoned in the same folder for all servers). When --restart is issued, there is no need to do such a trick as each screen will be restarted one by one (without this check all servers will be killed each time a server is launched, so only the last one would survive).
			kill_screen "$screenname" # due to the loose search nature of kill_screen, searching for $screenname will effectively find and kill all servers in a case of multiple servers
		else
			kill_screen "$screenname$nb" # else, for any other case, we kill the exact screen we are looking for (with the $nb, which may be empty)
		fi
	fi
    check_server_screen "$screenname$nb" # we check if the server already exists with the same screenname (to not relaunch another server if it's already launched, by launching this function regularly, you can automatically relaunch the server if it gets down)
    checkservexists=$?
    if [[ $checkservexists == 0 ]]; then
      launch_server_screen "$screenname$nb" "$port" "$config"
	else
	  printtext "WARNING: Server already exists ! Nothing done. Use -r to force restart server."
    fi
  else # no screen name supplied, we launch the servers with $noscreencmd and use relative terminal-wise functions
    if [ -n "$restart" ] || [[ $checkcrashlog_exist_basepath == 1 ]] || [[ $checkcrashlog_exist_homepath == 1 ]]; then # if argument -r or --restart or if a crashlog is found, we first kill the server before starting it (hence restarting it)
		printtext "Killing the server(s) (by pid) before restarting it..."
		if [ -n "$multiple" ] && [ -z "$restart" ]; then # if multiple servers are launched at once, if we find a crashlog, then we should restart _all_ servers with this screenname/config. When --restart is issued, there is no need to do such a trick as each screen will be restarted one by one (without this check all servers will be killed each time a server is launched, so only the last one would survive).
			kill_term "$config"
		else
			kill_term "$config$nb"
		fi
	fi
    check_server_noscreen "$config$nb" # check if a terminal exists with the same config in the parameters, to avoid doubling and launching twice the same server
    checkservexists=$?
    if [[ $checkservexists == 0 ]]; then
      launch_server_noscreen "$port" "$config$nb"
	else
	  printtext "WARNING: Server already exists ! Nothing done. Use -r to force restart server."
    fi
  fi
}

function launch_server_screen {
  local name=$1
  local port=$2
  local config=$3
  if [ -n "$fixgravity" ] && [ $mod = "baseoa" ]; then gravity='+set changegravity "seta g_gravity 768"';fi
  #if [ -z "$nolog" ]; then log="+set g_log $logfolder/$today.log";fi
  $screencmd $name $binfullpath $cvarrestart +set net_port $port $dedicated +set fs_basepath $basepath +set fs_homepath $homepath +set fs_game $mod +set vm_game $vmgame $gravity +exec $config $cmdlinecustomargs
  if [ -n "$verbose" ]; then printtext "$screencmd $name $binfullpath $cvarrestart +set net_port $port $dedicated +set fs_basepath $basepath +set fs_homepath $homepath +set fs_game $mod +set vm_game $vmgame $gravity +exec $config $cmdlinecustomargs"; fi
}

function launch_server_noscreen {
  local port=$1
  local config=$2
  if [ -n "$fixgravity" ] && [ $mod = "baseoa" ]; then gravity='+set changegravity "seta g_gravity 768"';fi
  #if [ -z "$nolog" ]; then log="+set g_log $logfolder/$today.log";fi
  $noscreencmd  $binfullpath $cvarrestart +set net_port $port $dedicated +set fs_basepath $basepath +set fs_homepath $homepath +set fs_game $mod +set vm_game $vmgame $gravity +exec $config $cmdlinecustomargs > /dev/null 2>&1 &
  if [ -n "$verbose" ]; then printtext "$noscreencmd  $binfullpath $cvarrestart +set net_port $port $dedicated +set fs_basepath $basepath +set fs_homepath $homepath +set fs_game $mod +set vm_game $vmgame $gravity +exec $config $cmdlinecustomargs > /dev/null 2>&1 &"; fi
}

function launch_gtv {
  local port=$1
  local config=$2
  local name=$3
  if [ -n "$name" ]; then
    if [ -n "$restart" ]; then
	  printtext "Killing the GTV server(s) (by screenname) before restarting it..."
	  kill_screen "$name"
	fi
    check_server_screen "$name"
    check=$?
    if [[ $check == 0 ]]; then
      launch_gtv_screen "$name" "$port" "$config"
	else
	  printtext "WARNING: GTV server already exists ! Nothing done. Use -r to force restart server."
    fi
  else
    if [ -n "$restart" ]; then
	  printtext "Killing the GTV server(s) (by pid) before restarting it..."
	  kill_term "$config"
	fi
    check_server_noscreen "$config"
    check=$?
    if [[ $check == 0 ]]; then
      launch_gtv_noscreen "$port" "$config"
	else
	  printtext "WARNING: GTV server already exists ! Nothing done. Use -r to force restart server."
    fi
  fi
}

function launch_gtv_screen {
  local name=$1
  local port=$2
  local config=$3
  # compute gtv basepath and homepath
  local gtvbasepathparam=""
  if [ -n "$gtvbasepath" ]; then
	gtvbasepathparam="+set fs_basepath $gtvbasepath +set fs_homepath $gtvhomepath"
  else
	gtvbasepathparam="+set fs_basepath $basepath +set fs_homepath $homepath"
  fi
  # fs_basepath or fs_homepath is needed to properly enable a GTV server, even without autodownload
  # DO NOT EVER SET +set fs_game $mod IN GTV ! Else you'll get an infinite autodl bug !
  $screencmd $name $gtvfullpath $cvarrestart +set net_port $port $dedicated $gtvbasepathparam +set fs_restrict 0 +set com_zonemegs 64 +set vm_game 2 +exec $config
  if [ -n "$verbose" ]; then printtext "$screencmd $name $gtvfullpath $cvarrestart +set net_port $port $dedicated $gtvbasepathparam +set fs_restrict 0 +set com_zonemegs 64 +set vm_game 2 +exec $config"; fi
}

function launch_gtv_noscreen {
  local port=$1
  local config=$2
  # compute gtv basepath and homepath
    local gtvbasepathparam=""
  if [ -n "$gtvbasepath" ]; then
	gtvbasepathparam="+set fs_basepath $gtvbasepath +set fs_homepath $gtvhomepath"
  else
	gtvbasepathparam="+set fs_basepath $basepath +set fs_homepath $homepath"
  fi
  # fs_basepath or fs_homepath is needed to properly enable a GTV server, even without autodownload
  # DO NOT EVER SET +set fs_game $mod IN GTV ! Else you'll get an infinite autodl bug !
  $noscreencmd  $gtvfullpath $cvarrestart +set net_port $port $dedicated $gtvbasepathparam +set fs_restrict 0 +set com_zonemegs 64 +set vm_game 2 +exec $config > /dev/null 2>&1 &
  if [ -n "$verbose" ]; then printtext "$noscreencmd  $gtvfullpath $cvarrestart +set net_port $port $dedicated $gtvbasepathparam +set fs_restrict 0 +set com_zonemegs 64 +set vm_game 2 +exec $config > /dev/null 2>&1 &"; fi
}

function make_heartbeater {
  local localport=$1
  local master=$2
  local masterport=$3
  local delaytime=$4

  # we need to make a script and launch it with sudo, else it will ask for user's password each 5 minutes
  echo "#!/bin/sh
while [ 1 ]; do
  echo [\$(date '+%H:%M:%S')] Sending heartbeat to $master:$masterport from port $localport ...
  echo -e \"\xff\xff\xff\xffheartbeat QuakeArena-1\" > heartbeat.bin
  sudo hping3 -s $localport -p $masterport --udp --file heartbeat.bin -d 1024 -c 1 $master
  echo Done, waiting for $delaytime seconds to send next heartbeat...
  echo ---------------------------------
  echo
  sleep $delaytime
done" > heartbeater_local-"$localport"_master-"$master".sh # we set an unique filename so there's no collision if we setup multiple GTV servers and heartbeats on the same machine
  chmod +x heartbeater_local-"$localport"_master-"$master".sh
}

function launch_heartbeat {
  local localport=$1
  local master=$2
  local name=$3

  if [ -n "$name" ]; then
    if [ -n "$restart" ]; then kill_screen "$name";fi
    check_server_screen "$name"
    check=$?
    if [[ $check == 0 ]]; then
      launch_heartbeat_screen "$name" "$localport" "$master"
    fi
  else
    if [ -n "$restart" ]; then kill_term heartbeater_local-"$localport"_master-"$master".sh;fi
    check_server_noscreen heartbeater_local-"$localport"_master-"$master".sh
    check=$?
    if [[ $check == 0 ]]; then
      launch_heartbeat_noscreen "$localport" "$master"
    fi
  fi
}

function launch_heartbeat_screen {
  local name=$1
  local localport=$2
  local master=$3
  printtext "Password needed to launch the heartbeater script..."
  sudo hping3 --version #make sure that we have the permission required to use hping3, else in the next command it will ask in the screen, and so the user won't see the requirement of the password. You can also use NOPASSWD: /path/to/hping3 in your sudoer file (use visudo)
  $screencmd $name sudo sh heartbeater_local-"$localport"_master-"$master".sh
  if [ -n "$verbose" ]; then printtext "$screencmd $name sudo sh heartbeater_local-"$localport"_master-"$master".sh"; fi
}

function launch_heartbeat_noscreen {
  local localport=$1
  local master=$2
  sudo $noscreencmd  sh heartbeater_local-"$localport"_master-"$master".sh > /dev/null 2>&1 &
  if [ -n "$verbose" ]; then printtext "sudo $noscreencmd  sh heartbeater_local-"$localport"_master-"$master".sh > /dev/null 2>&1 &"; fi
}

function kill_screen { # kill one or several process contaning a similar name to the one specified
  local name=$1
  for onescreen in $(screen -ls | grep -Eo "[0-9]+\.\S*$name\S*"); do
    screen -S $onescreen -p 0 -X quit
	if [ -n "$verbose" ]; then printtext "screen -S $onescreen -p 0 -X quit"; fi
  done
}

function kill_term { # kill one or several process containing a config with a similar name to the one specified
  local config=$1
  local bin=$(basename "$binfullpath") # get only the binary name without directory path

  for oneterm in $(ps aux | grep "$bin" | grep "$config" | awk '{print $2}'); do
    kill $oneterm
	if [ -n "$verbose" ]; then printtext "kill $oneterm"; fi
  done
}

function kill_all_screen { # kill all screens (no distinction if they are for OA ! TIP : Create a specific user for running servers, so you only get screens containing servers)
  for onescreen in $(screen -ls | grep -Eo "[0-9]+\.\S+"); do
    screen -S $onescreen -p 0 -X quit
	if [ -n "$verbose" ]; then printtext "screen -S $onescreen -p 0 -X quit"; fi
  done
}

function kill_all_term { # kill all servers in terminal, based on the mod if specified, or on just the binary if not
  local mod=$1
  local bin=$(basename "$binfullpath") # get only the binary name without directory path
  if [ -n $mod ]; then
	# DEPRECATED: for oneterm in $(ps aux | grep $noscreencmd | grep "fs_game $mod" | cut -d " " -f3); do
    for oneterm in $(ps aux | grep "$bin" | grep "fs_game $mod" | awk '{print $2}'); do
      kill $oneterm
	  if [ -n "$verbose" ]; then printtext "kill $oneterm"; fi
    done
  else
    for oneterm in $(ps aux | grep "$bin" | awk '{print $2}'); do
      kill $oneterm
	  if [ -n "$verbose" ]; then printtext "kill $oneterm"; fi
    done
  fi
}

function callconfig_term {
  # UNTESTED FUNCTION ! Don't know if it really works.
  local config=$1
  local command=$2
  #for oneterm in $(ps aux | grep $noscreencmd | grep $config | cut -d " " -f3); do
  #for oneterm in $(ps aux | grep $noscreencmd | grep $config | awk '{print $2}'); do
  for oneterm in $(jobs -l | grep "$config" | awk '{print $1}' | grep -Eo "\d+"); do
	#fg $oneterm
	#echo $command
	#echo -e "\r\n"
	#bg
	pressenter=$(echo -e "\r\n") # simulate pressing the enter key after the last command
	jobs -x "$command$pressenter" "$oneterm"
  done
}

function callconfig_screen { # a function is used to find the right screen because even if the name of the screen is supplied, there can be several screens with similar names, and we have then to process each screen by ourselves
  local name=$1
  local command=$2
  for onescreen in $(screen -ls | grep -Eo "[0-9]+\.\S*$name\S*"); do
	pressenter=$(echo -e "\r\n") # simulate pressing the enter key after the last command
	screen -S $onescreen -p 0 -X stuff $"$command$pressenter" # screen -X executes screen commands, not normal commands. You then have to use some screen keywords, like _stuff $""_ or _window_ or such.
	# Note : -p 0 is UTTERMOST IMPORTANT ! It specifies the window to which send the commands supplied in -X. By default, it will take the value of the last window you accessed (either a number or the name of the bin file), but if you didn't attach yet to this screen and spawned it as detached mode, then -X won't work, unless you specify -p 0 (or whatever window fits you, try with "-p =" to get a list or "-p -" to get a blank).
	# Note 2 : -p 0 avoids the "A screen session started in detached mode cannot accept any 'stuff' commands unless the the session is first attached, and then re-detached." bug.
	# For more infos, see : http://osdir.com/ml/gnu.screen.user/2007-07/msg00004.html and http://www.mail-archive.com/screen-users@gnu.org/msg01084.html

	# Standard way if the bash shell doesn't support stuff $"" :
	#screen -S $onescreen -X stuff \
    #"$(printf '%b' "$command$pressenter\015")" -p 0
	if [ -n "$verbose" ]; then printtext "screen -S $onescreen -p 0 -X stuff $\"$command$pressenter\""; fi
  done
}

function callconfig { # this function parse a quake 3 compatible config file and input it directly inside the console of your server, just like you were typing inside it. This can have several practical uses, like for GTV auto-describe the rooms after gtv_connect successfully did its job.
	local exectype=$1 # specify if 1 that the supplied execparam is a config file, or if any other value (generally 2) that it's a single command to execute directly
	local execparam=$2 #the config to exec OR the commands to send (this is defined with the value of $exectype)
	local config=$3 #the original config file used for your server (this is used in order to find the terminal, useless for screen)
	if [ -n $4 ]; then local screenname=$4; fi #the screen where your server resides if you used a screen command instead of a terminal
	
	if (( exectype == 1 )); then # If it's a config file, we read it and store it in $command
		command="$(cat $execparam)"
	else # else, it's a single command we directly store in $command
		command="$execparam"
	fi
	if [ -n "$screenname" ]; then
		callconfig_screen "$screenname" "$command"
	else
		callconfig_term "$config" "$command"
	fi
}

function log_cut { # cut a specified log file and output the rest into a backup log, ordered by config name, date and time
	local log="$1"
	local maxsize="$2"
	local name="$3"
	local currtime=$(date '+%H-%M-%S')
	local logout=$name"_"$today"_"$currtime.log
	
	if [ "$log" == "$(basename $log)" ]; then # if user supplied a relative path to the log, then we make out an absolute one (necessary for cron jobs)
		log="$logfolder/$log"
	fi
	
	local logsize=$(du -b $log | awk '{ print $1 }')
	if (( $logsize >= $maxsize )); then
		cp "$log" "$logoutputfolder/$logout"
		#unlink "$log"
		#touch "$log"
		cat /dev/null > "$log" # we empty the file without removing or moving it, so the game server can still continuously open the file and get no deny access (if the game server gets a writing error once, it will stop logging out until the next map change)
		#tail -c $maxsize "$logoutputfolder/$logout" > "$log"
		#if [ -n "$verbose" ]; then printtext "tail -c $maxsize '$logoutputfolder/$logout' > '$log'"; fi
	else
		printtext "Log is too small, no rotation done."
	fi
}

function logs_cut_all {
  for onelog in $(ls $logfolder/*.log); do
    cp $onelog $onelog.old
    tail -c $logmaxsize $onelog.old > $onelog
	if [ -n "$verbose" ]; then printtext "tail -c $logmaxsize $onelog.old > $onelog"; fi
  done
}

function add_to_cron {
	# Parse the arguments and quotes the ones containing spaces (else if we would just use $@, we would get no quotes and the cron would bug next time it would launch the commands containing spaces but no quotes)
	local allargs="" # Initialize the var that will contain all args
	local count=0
	for arg in "${argslist[@]}"; do # We use the argslist because we already parsed $@, now it's empty
		if [[ "$arg" = *\ * ]]; then
			# If the arg contains any space, we double quote it
			if (( $count == 0 )); then # If it's the first arg, we don't add a space before
				allargs="\"$arg\""
			else
				allargs="$allargs \"$arg\""
			fi
		else
			# Else if the arg does NOT contain any space, we can use it as it is (particularly if it's a parameter like -v, it shouldn't be quoted)
			if (( $count == 0 )); then # If it's the first arg, we don't add a space before
				allargs="$arg"
			else
				allargs="$allargs $arg"
			fi
		fi
		let count=count+1
	done
	local crontask="$BASHFOLDER/$BASHBIN $SCRIPT $allargs" # We set the full cron command : the bash, the script path and the args, later we will add the time to run the job (date contained in $addcron)
	#local crontask="$WORKDIR/$BASHBIN $SCRIPT $allargs" # Alternative based on the current working directory (remove the cd at the beginning)
	#local crontask="$SCRIPTPATH/$BASHBIN $SCRIPTNAME $allargs"

	# Compare with current crontab and load the cron command
	local JOBPRESENT=$(crontab -l | grep -F -i "$addcron $crontask") # Check if a cronjob already exists for the current commandline (whole commandline with arguments !), -F is here to enforce the recognition of special meta-characters like * (star) or "
	if [ "$JOBPRESENT" == "" ]; then
		local statictime="$currtime" # We need to store the time once and for all in a var, or else the time could change in 1 sec, and the file would be different (since $currtime does call the date function dynamically)
		touch "$SCRIPTPATH/oacrontab_$statictime.tmp" # Creating an empty file
		echo -e "$(crontab -l)\n" >> "$SCRIPTPATH/oacrontab_$statictime.tmp" # Output inside the file the current cron jobs list
		echo "$addcron $crontask" >> "$SCRIPTPATH/oacrontab_$statictime.tmp" # Output our new cron job (an empty line will be created due to \n in the previous statement)
		crontab "$SCRIPTPATH/oacrontab_$statictime.tmp" # Update cron with the content of our temporary cronfile
		if [ -n "$verbose" ]; then cat "$SCRIPTPATH/oacrontab_$statictime.tmp"; fi # Show the content of our cronfile if verbose mode is activated
		unlink "$SCRIPTPATH/oacrontab_$statictime.tmp" # Delete the temp cronfile
		#echo -e "$(crontab -l)\n$addcron $crontask" > oacrontab.tmp ; crontab oacrontab.tmp # Old way to do all the previous stuff in one line, may not be as reliable
		#if [ -n "$verbose" ]; then echo "$(crontab -l)\n$addcron $crontask"; fi
	else
		if [ -n "$verbose" ]; then printtext "$addcron $crontask"; fi
		printtext "Same cron job already exists ! This one will not be added..."
	fi
}

function heartbeat {
  local localport=$1
  local masterserverport=$2
  local masterserveraddr=$3 # masterserveraddr can either be an ip address or a DNS
  echo -e "\xff\xff\xff\xffheartbeat QuakeArena-1" > heartbeat.bin
  sudo hping3 -s "$localport" -p "$masterserverport" --udp --file heartbeat.bin -d 1024 -c 1 "$masterserveraddr" # Send 1 heartbeat with -c 1 before stopping and launching the GTV server (don't modify -c because it increments the source port number for each sent packet)
  if [ -n "$verbose" ]; then printtext "sudo hping3 -s $localport -p $masterserverport --udp --file heartbeat.bin -d 1024 -c 1 $masterserveraddr"; fi
}

function absolutepath {
	local path=$1 # path that needs to be checked if relative or absolute
	local fullpath=$2 # if specified, absolute path to prepend if the path is relative (else it will try to auto detect)
	
	local firstchar=${path:0:1}
	local first2chars=${path:0:2}
	if [[ "$firstchar" != "/" ]] && [[ "$first2chars" != "~/" ]]; then # if the $path is NOT an absolute path but a relative path
		if [ -n "$fullpath" ]; then
			path="$fullpath/$path" # we prepend the fullpath of the path
		else
			path=$(readlink -f "$path") # or if no fullpath is supplied, we try to autodetect the absolute path using readlink
		fi
	fi # else if it's already an absolute path, we do nothing
	
	if [ ! -r "$path" ]; then # check that the file exists
		printtext "WARNING: file does not exist or cannot be accessed: $path"
	fi
	
	return="$path" # return the path (will replace the first argument, the path)
}

# - Config reformatting
# reformat the config filename supplied without the .cfg extension or any other extension (so that we can add it later if needed or not, ie: with --multiple, we need to have the filename without the extension)
function reformatconfig {
	local file=$1

	local pointindex=$(expr index "${file: -5}" '\.') # detect a period in the last 5 characters of the string
	while [[ $pointindex > 0 ]]; do # if a period is detected in the last 5 characters of the string
		local lenconfig=$(expr length $file) # get the length of the string
		local lenconfig=$lenconfig-5+$pointindex-1 # get the length without extension
		local file=${file:0:lenconfig} #${file%".cfg"} # remove the extension ($total_length - $extension_length)
		local pointindex=$(expr index "${file: -5}" '\.') # detect again a period and continue until we are left only with the filename without extension (necessary for multiple option of this script)
	done
	
	return="$file" # return the reformatted filename
}

#=== Variables check

# - Output logging for this script output (must be first to be able to log everything) (must be first)
if [ -n "$outputlog" ]; then # if an output log filepath was supplied, we redirect all the outputs to this file
  exec 2>&1 >> "$SCRIPTPATH/$outputlog" # exec >> myStandardOutFile.txt redirects all standard output to this file
  # reminder : to redirect a specific block of commands :
  #{
  #echo "My echo msg1"
  #echo "My echo msg2"
  #echo "My echo msg3"
  #} > myStandardOutFile.txt
fi

# - Printing date before any action (must be second)
printtext "Current date and time : $today $currtime" #Important to permit later reviewing of logged outputs

# - Servers and GTV binaries (must be third)
if [ -z "$binfullpath" ]; then # if user has not supplied a custom server bin path, we use the default one
  binfullpath="$basebinpath$basebin"
else # else we try to autodetect the path if it's relative
  absolutepath "$binfullpath"
  binfullpath="$return"
fi

if [ -z "$gtvfullpath" ]; then # if user has not supplied a custom gtv bin path, we use the default one
  gtvfullpath="$gtvbinpath$gtvbin" # TODOMAYBE: same as above, maybe use readlink? but for now all works well.
else # else we try to autodetect the path if it's relative
  absolutepath "$gtvfullpath"
  gtvfullpath="$return"
fi

# - Number of servers (must be fourth)
if [ -z "$nbserv" ]; then # if no number of server was supplied, we launch one
  nbserv=1
fi

# - Basepath and Homepath (must be fifth)
if [ -z "$basepath" ]; then # if no basepath is supplied, then default to the current game or gtv binary directory
  if (( $nbserv <= 0)) && [ -n "$gtv" ]; then # if the script is launched only for a gtv server (eg: -n 0 -tv) then we set the default basepath to the gtv binary, not the game binary (since we aren't going to launch a game server, that would be stupid)
	basepath=$(dirname "$gtvfullpath")
  else
	basepath=$(dirname "$binfullpath") # else we set the default basepath to the directory of the supplied game binary
  fi
fi

if [ -z "$homepath" ]; then # if no homepath is supplied, then default to the current script directory (by default OA stores in /home/user/.openarena)
  # homepath="~/.openarena" # default homefolder for openarena on linux
  # homepath="$SCRIPTPATH" # default to script's location - DEPRECATED: now homepath default to where the game server binaries reside (or gtv binary if no server is launched)
  if (( $nbserv <= 0)) && [ -n "$gtv" ]; then
	homepath=$(dirname "$gtvfullpath")
  else
	homepath=$(dirname "$binfullpath")
  fi
fi

if [ -z "$gtvbasepath" ] && [ -n "$gtv" ]; then # if no basepath supplied for gtv, we set it relative to the GTV binary location
	gtvbasepath=$(dirname "$gtvfullpath")
fi

if [ -z "$gtvhomepath" ] && [ -n "$gtv" ]; then # if no homepath supplied for gtv, we set it relative to the GTV binary location
	gtvhomepath=$(dirname "$gtvfullpath")
fi

# - Config reformatting
if [ -n "$config" ]; then
	reformatconfig "$config"
	config="$return"
fi

if [ -n "$gtvconfig" ]; then
	reformatconfig "$gtvconfig"
	gtvconfig="$return.cfg"
fi

# - Basic mod and stuffs settings
if [ -z "$mod" ]; then # if no mod was supplied, default to the default mod
  mod="$basemod"
fi

if [ -n "$lan" ]; then # if lan mode activated, set dedicated 1
  dedicated="+set dedicated 1"
else # else, dedicated 2 which activates the sending of heartbeats to the master listing server
  dedicated="+set dedicated 2"
fi

if [ -z "$vmgame" ]; then # if no heartbeat delay for master server trick for GTV, then default to 5 sec
  if [[ "$mod" == "baseoa" || "$mod" == "baseq3" ]]; then
    vmgame="2"
  elif [[ "$mod" == "cpma" || "$mod" == "oacl2010" || "$mod" == "cpmaoacl2010" ]]; then
    vmgame="2"
  elif [[ "$mod" == "excessiveplus" || "$mod" == "oacl2010xp" || "$mod" == "eplus" ]]; then
    vmgame="0"
  else # for all other unknown mods
    vmgame="2"
  fi
fi

# - GTV stuffs
if [ -z "$gtvconfig" ]; then # if no gtv config was supplied, the default config is gtv.cfg
  gtvconfig="gtv.cfg"
fi

if [ -z "$gtvmasterdelay" ]; then # if no heartbeat delay for master server trick for GTV, then default to 5 sec
  gtvmasterdelay=5
fi

if [ -n "$heartbeat" ]; then # if heartbeat is activated but no specified heartbeattime, then sets the default value of 5 minutes (300 seconds)
  if [ -z "$heartbeattime" ]; then
    heartbeattime="300"
  fi
fi

# - Logs rotation and logs cut
if [ -n "$log2rotate" ]; then
	if [ -z "$logfolder" ]; then # default folder where the logs of the game resides
		logfolder="$homepath/$mod"
	fi

	if [ -z "$logoutputfolder" ]; then # default folder to store the cut/rotated logs
		logoutputfolder="$homepath/$mod/logs"
	fi

	if [ -z "$logmaxsize" ]; then
		logmaxsize=5000
	fi
	
	if [ -n "$logmaxsize" ]; then # convert maxsize from Bytes into KiloBytes
		let logmaxsize=$logmaxsize*1000
	fi
fi

# - Junk management
if [ -n "$junk" ]; then cvarrestart="+cvar_restart";fi # If we chose to cleanup junk, then we add the +cvar_restart command that makes the engine resets all cvars (the engine can cache cvars and remember them the next time you launch a server, even if you exec a different config. This command cleanup everything but can make the engine bug if you try to just after load a config, so this junk cleanup should be run once a day)

# - Crashlog autorestart
if [ -z "$crashlogtime" ]; then # Time for comparison between now and the last crashlog.txt modification date, if the difference is under this threshold, server is killed, restarted and crashlog.txt is renamed to crashlog_[time].txt
	crashlogtime=86400 # Equivalent to 24h
fi

# - External config execution
if [ -n "$gexec" ] || [ -n "$gexecconfig" ]; then # set a default 0 sec delay before sending commands (else it will produce an error if the var is empty)
	if [ -z "$gexecdelay" ]; then
		gexecdelay=0
	fi
fi

if [ -n "$gtvexec" ] || [ -n "$gtvexecconfig" ]; then # set a default 0 sec delay before sending commands (else it will produce an error if the var is empty)
	if [ -z "$gtvexecdelay" ]; then
		gtvexecdelay=0
	fi
fi

if [ -n "$gexecconfig" ]; then # set the full absolute path to the exec config file
	absolutepath "$gexecconfig" "$SCRIPTPATH"
	gexecconfig="$return"
fi

if [ -n "$gtvexecconfig" ]; then # set the full absolute path to the exec config file
	absolutepath "$gtvexecconfig" "$SCRIPTPATH"
	gtvexecconfig="$return"
fi

# - Other vars
if [ -z "$countdownmessage" ]; then # default message for countdown if no custom is specified
	countdownmessage="say ^3Warning: the server will be restarted for maintenance in %countdown"
fi

#=== Files existence check

if (( $nbserv > 0 )); then
	if [ ! -x "$binfullpath" ]; then # If the file does NOT exist (you need an absolute path for that)
		printtext "WARNING: server binary file does not exist at $binfullpath or cannot be accessed or is not an executable [chmod +x yourbin] !"
	fi
fi

if [ ! -r "$basepath/$basemod/$config.cfg" ] && [ ! -r "$homepath/$basemod/$config.cfg" ] && [ ! -r "$homepath/$mod/$config.cfg" ]; then
	printtext "WARNING: config file $config.cfg does not exist or cannot be accessed! Check that your config is either in homepath/modfolder/ or homepath/basemod/ or basepath/basemod/"
fi

if [ -n "$gexecconfig" ]; then
	if [ ! -r "$gexecconfig" ]; then
		printtext "WARNING: exec file $gexecconfig does not exist or cannot be accessed !"
	fi
fi

if [ -n "$gtv" ]; then
	if [ ! -r "$gtvbasepath/gtv3/$gtvconfig" ]; then
		printtext "WARNING: GTV config file $homepath/gtv3/$gtvconfig does not exist or cannot be accessed !"
	fi

	if [ ! -x "$gtvfullpath" ]; then
		printtext "WARNING: GTV binary file $gtvfullpath does not exist or cannot be accessed or is not an executable [chmod +x yourbin] !"
	fi
	
	if [ -n "$gtvexecconfig" ]; then
		if [ ! -r "$gtvexecconfig" ]; then
			printtext "WARNING: GTV exec file $gtvexecconfig does not exist or cannot be accessed !"
		fi
	fi
fi

if [ -n "$log2rotate" ]; then
	if [ ! -d "$logoutputfolder" ]; then # if the output log folder does not exists, we create it
		mkdir "$logoutputfolder"
		printtext "Creating directory '$logoutputfolder' for log rotation..."
	fi
fi
	
#=== Add current cmd to a cron job
if [ -n "$addcron" ]; then
  printtext "Adding job to cron..."
  add_to_cron
  printtext "Done !"
  printtext
fi

#=== Clean logs
if [ -n "$log2rotate" ]; then
  printtext "Cutting/Rotating log $log2rotate..."
  log_cut "$log2rotate" "$logmaxsize" "$config"
  printtext "Done !"
  printtext
fi

#=== Clean junk servers files
if [ -n "$junk" ]; then
  printtext "Deleting junk servers file..."
  unlink "$homepath/baseoa/q3config_server.cfg"
  if [ -n "$verbose" ]; then printtext "unlink $homepath/baseoa/q3config_server.cfg"; fi
  unlink "$homepath/$mod/q3config_server.cfg"
  if [ -n "$verbose" ]; then printtext "unlink $homepath/$mod/q3config_server.cfg"; fi

  if [ -n "$gtv" ]; then
	printtext "Cleaning the GTV delay folder..."
	unlink "$basepath/gtv3/delay/*"
	if [ -n "$verbose" ]; then printtext "-> cleaning $basepath/gtv3/delay/*"; fi
	unlink "$homepath/gtv3/delay/*"
	if [ -n "$verbose" ]; then printtext "-> cleaning $homepath/gtv3/delay/*"; fi
  fi
  printtext "Done !"
  printtext
fi

#=== Game Servers Launcher
# - Countdown before doing anything 
if [ -n "$countdown" ] && [[ $countdown > 0 ]]; then
	#if [ -n "$killall" ] || [ -n "$killall2" ] || [ -n "$restart" ]; then # enable only if -k or -k2 or -r are specified, so it's only if we do an action that shutdown/restart the server and can disconnect players along the way
		# We regularly print countdowns until it's below 1 second
		while (( "$countdown" >= 1 )); do
			# Beautifying the printing of the countdown
			if (( "$countdown" >= 60 )); then # if the countdown is in minutes
				ctval=$(( $countdown / 60))
				ctval="$ctval minutes"
				# Checking if seconds need to be added
				ctsec=$(( $countdown % 60))
				if (( "$ctsec" > 0 )); then
					ctval="$ctval and $ctsec seconds"
				fi
			else # else, the countdown is only in seconds
				ctval="$countdown seconds"
			fi
			ctmsg=${countdownmessage//%countdown/"$ctval"} # substituting the %countdown placeholder with the real countdown
			
			# Sending the countdown to a screen if a screenname was supplied, or in a terminal
			if [ -n "$screenname" ]; then
				printtext "Now sending the following countdown message to screen(s) $screenname: \"$ctmsg\""
				callconfig 2 "$ctmsg" "$config" "$screenname"
			else
				printtext "Now sending the following countdown message to terminal running the server(s) with config $config: \"$ctmsg\""
				callconfig 2 "$ctmsg" "$config"
			fi
			
			# Dividing the countdown by two each cycle, eg: for --countdown 30 it will show a message at 30 seconds before the end, then 15s, then 8s, then 4s, then 2s, then 1s and stop here the countdown.
			if (( "$countdown" == "3" )); then # since expr() function and $(()) or $[] only compute integers and round to the nearest, lowest integer, we always miss the countdown at 2 seconds if we don't do it manually.
				countdown=2
			else
				#countdown=$(expr $countdown / 2)
				countdown=$(($countdown / 2))
			fi
			
			# Wait before printing the next countdown notice
			sleep "$countdown" 
		done
	#fi
fi

# - Kill all servers if argument, depending on either config name or screen name
if [ -n "$killall" ]; then
  if [ -n "$screenname" ]; then # if screen name is supplied, we can call the screen function, else we just call another terminal
	printtext "Killing all screens with a name similar to \"$screenname\"..."
    kill_screen "$screenname"
  else
	printtext "Killing all processes with a config name similar to \"$config\"..."
    kill_term "$config"
  fi
  printtext "Done !"
  printtext
fi

# - Kill all servers if argument, without any distinction
if [ -n "$killall2" ]; then
  if [ -n "$screenname" ]; then # if screen name is supplied, we can call the screen function, else we just call another terminal
	printtext "Killing _ALL_ screens without any distinction..."
    kill_all_screen "$screenname"
  else
	printtext "Killing _ALL_ processes with mod \"$mod\"..."
    kill_all_term "$mod"
  fi
  printtext "Done !"
  printtext
fi

# - Start / Restart servers
if (( $nbserv > 0 )); then # If -n 0 is supplied, then we launch no game server and show no message
  printtext "Launching game server(s)..."
  if [ -n "$multiple" ]; then # Launch any number of servers, for each $config*.cfg
	# Check the arguments to avoid doubles (else you can launch twice or more the same server)
    if [ "$mod" != "$basemod" ]; then
	  if [ "$basepath" != "$homepath" ]; then
        listallconfigs="ls $basepath/$basemod/$config*.cfg $homepath/$basemod/$config*.cfg $homepath/$mod/$config*.cfg"
	  else
	    listallconfigs="ls $homepath/$basemod/$config*.cfg $homepath/$mod/$config*.cfg"
	  fi
    else
	  if [ "$basepath" != "$homepath" ]; then
        listallconfigs="ls $basepath/$basemod/$config*.cfg $homepath/$basemod/$config*.cfg"
	  else
	    listallconfigs="ls $homepath/$basemod/$config*.cfg"
	  fi
    fi
	if [ -n "$verbose" ]; then printtext "$listallconfigs"; fi
	if [ -n "$verbose" ]; then temptext=$( $listallconfigs ); printtext "$temptext"; fi
	# Launch as many servers as configs found
    counter=1
    for conf in $( $listallconfigs ); do
	  conf=$(basename "$conf") # extract the filename from the fullpath of each config files, since the server's engine already looks inside the homepath and basepath
	  if [ -n "$verbose" ]; then printtext "Extracted config : $conf"; fi
      printtext "Launching multiple servers : $counter- config $conf port $port on screen $screenname$counter..."
      launch_server "$port" "$conf" $counter
      let port=$port+1
      let counter=$counter+1
    done
  elif (( $nbserv == 1 )); then # Launch only one server
      printtext "Launching server : config $config.cfg port $port on screen $screenname..."
      launch_server "$port" "$config"
  elif (( $nbserv > 1 )); then # Launch $nbserv number of servers
    for (( i=1;i<=$nbserv;i++)); do
      printtext "Launching server : config $config$i.cfg port $port on screen $screenname$i..."
      launch_server "$port" "$config" $i
      let port=$port+1
    done
  fi
  printtext "Done !"
  printtext
fi

#=== GTV Launcher
if [ -n "$gtv" ]; then
  printtext "Now launching the GTV server, please wait..."
  if [ -z "$gtvport" ]; then
    let gtvport=$port+1
  fi
  # Launching the GTV server
  if [ -n "$gtvscreenname" ]; then
	printtext "Launching GTV server : config $gtvconfig port $gtvport on screen $gtvscreenname..."
    launch_gtv "$gtvport" "$gtvconfig" "$gtvscreenname"
  else
	printtext "Launching GTV server : config $gtvconfig port $gtvport..."
    launch_gtv "$gtvport" "$gtvconfig"
  fi
  printtext "GTV server launched !"
  printtext
  if [ -n "$gtvmaster" ]; then
    if [ -z "$gtvmasterport" ]; then
      printtext "ERROR : you need a --gtvmasterport for the --gtvmaster trick to work !"
      exit
    fi
    printtext "Sending heartbeat..."
    # Trick to make the GTV server register in the master listing server, by sending a heartbeat (GTV miss this function), and then the master listing server does the rest of the communication with the GTV server, because then the dialog is the same as with any player
    if (( $gtvmasterdelay > 0 )); then
		sleep "$gtvmasterdelay" # We have to wait for the GTV server to be fully up so it can respond to the master listing server
	fi
    heartbeat "$gtvport" "$gtvmasterport" "$gtvmaster" # Send a first heartbeat to show on master listing server, this is not sufficient to actually _stay_ in the server listing, you have to repetitively send heartbeats each 5 min
    printtext "Heartbeat sent successfully ! Have fun !"
    printtext
  fi
  # Calling an external config to execute more commands (if supplied, it's optional -- you can directly issue commands with --gtvexec) - This is a copy-paste of the Exec Config Extender below (but necessary because of the different printtext)
  if [ -n "$gtvexec" ] || [ -n "$gtvexecconfig" ]; then
	printtext "Preparing to exec commands for GTV"
	if (( $gtvexecdelay > 0 )); then # If the delay is positive, then we wait for this time
		printtext "...waiting for the delay of $gtvexecdelay seconds..."
		sleep "$gtvexecdelay"
	fi
	# Setting the vars
	if [ -n "$gtvexecconfig" ]; then
		gtvexectype=1
		gtvexecparam="$gtvexecconfig"
		gtvexecmsg="contained inside the file $gtvexecconfig"
	else
		gtvexectype=2
		gtvexecparam="$gtvexec"
		gtvexecmsg="\"$gtvexec\""
	fi
	# Now sending the commands supplied in the file, send to a screen if a screenname for GTV was supplied, or in a terminal
	if [ -n "$gtvscreenname" ]; then
		printtext "Now sending the command(s) $gtvexecmsg to GTV server(s) in screen(s) $gtvscreenname (the server(s) can take some time to execute them all)"
		callconfig "$gtvexectype" "$gtvexecparam" "$gtvconfig" "$gtvscreenname"
	else
		printtext "Now sending the command(s) $gtvexecmsg to terminal running the GTV server(s) with config $gtvconfig (the server(s) can take some time to execute them all)"
		callconfig "$gtvexectype" "$gtvexecparam" "$gtvconfig"
	fi
	printtext "Execing done !"
  fi
  printtext "All GTV jobs done !"
  printtext
fi

#=== Exec Config Extender
# Calling an external config to execute more commands (if supplied, it's optional - you can directly issue commands with --exec)
# This functionnality is as most generic as possible, so it's possible to call this script only to exec some config (with -n 0 argument, no game server will be launched), so you can completely integrate this script as a tool in your bash scripts. It can be used for GTV servers too by supplying a gtv config file in the --config arg and/or a gtv screen name in --screenname.
if [ -n "$gexec" ] || [ -n "$gexecconfig" ]; then
	printtext "Preparing to exec commands..."
	if (( $gexecdelay > 0 )); then # If the delay is positive, then we wait for this time
		printtext "...waiting for the delay of $gexecdelay seconds..."
		sleep "$gexecdelay"
	fi
	# Setting the vars
	if [ -n "$gexecconfig" ]; then
		gexectype=1
		gexecparam="$gexecconfig"
		gexecmsg="contained inside the config file $gexecconfig"
	else
		gexectype=2
		gexecparam="$gexec"
		gexecmsg="\"$gexec\""
	fi
	# Now sending the commands supplied in the file, send to a screen if a screenname was supplied, or in a terminal
	if [ -n "$screenname" ]; then
		printtext "Now sending the command(s) $gexecmsg to screen(s) $screenname (the server(s) can take some time to execute them all)"
		callconfig "$gexectype" "$gexecparam" "$config" "$screenname"
	else
		printtext "Now sending the command(s) $gexecmsg to terminal running the server(s) with config $config (the server(s) can take some time to execute them all)"
		callconfig "$gexectype" "$gexecparam" "$config"
	fi
	printtext "Execing done !"
	printtext
fi

#=== GTV Heartbeater
# heartbeats needs to be sent regularly to stay in the servers listing (default : 5 minutes like normal game servers)
# notes to dev : this part has to be at the really end, so the script can do all other jobs !
if [ -n "$heartbeat" ]; then
  if (( $heartbeattime < 5 )); then heartbeattime=5 ; fi # sets the minimum delay between each heartbeats to 5 seconds
  printtext "Now making a heartbeater script to send regular heartbeats for GTV to stay in servers list..."
  make_heartbeater "$gtvport" "$gtvmaster" "$gtvmasterport" "$heartbeattime"
  printtext "Done ! Now launching the script (sudo is issued to use hping3, please input your password when asked)..."
  if [ -n "$heartbeatscreen" ]; then
    launch_heartbeat "$gtvport" "$gtvmaster" "$heartbeatscreen"
  else
    launch_heartbeat "$gtvport" "$gtvmaster"
  fi
  printtext "Done !"
  printtext
fi

printtext "Everything is done ! Exiting."
printtext "-----------------------------"
