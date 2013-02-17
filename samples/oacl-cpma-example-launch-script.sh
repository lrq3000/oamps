#!/bin/sh
echo "Starting OACL server CPMA on port 27960, screen oacl-cpma and auto restart it at 4:02 AM everyday, and check if down each hour"

# Add to cron some warning messages that will be shown to the players minutes prior to restarting the servers
sh oamps.sh -n 0 -c oacl-edit-me -s oacl-cpma -e "say ^1WARNING: Server will restart for maintenance in 10 minutes !" -a "52 3 * * *" -o oacl-launcher.log
sh oamps.sh -n 0 -c oacl-edit-me -s oacl-cpma -e "say ^1WARNING: Server will restart for maintenance in 2 minutes !" -a "0 4 * * *" -o oacl-launcher.log
sh oamps.sh -n 0 -c oacl-edit-me -s oacl-cpma -e "say ^1WARNING: Server will restart for maintenance NOW !" -a "1 4 * * *" -o oacl-launcher.log

# Starting/restarting all the servers and add these lines to crontab
# Note : it is VERY important to restart the server at 4:02 AM and not 4:00 AM, because if we restart at 4:00 AM and at the same time we check if the server is down hourly, there is a risk that both of the commands will be launched at the same time, resulting in servers duplicates (2 servers will be launched instead of just one!).
# Note2 : the -o option is used to log the output of oamps.sh instead of having it printed on-screen. This practice is very advised when you use --addcron, because you will much more information to understand what happened if your cronjob failed you.
sh oamps.sh -c oacl-edit-me -g cpmaoacl2010 -p 27960 -s oacl-cpma -r -a "2 4 * * *" -o oacl-launcher.log
sh oamps.sh -c oacl-edit-me -g cpmaoacl2010 -p 27960 -s oacl-cpma -a "@hourly" -o oacl-launcher.log
echo "Done ! Have fun and play fair !"