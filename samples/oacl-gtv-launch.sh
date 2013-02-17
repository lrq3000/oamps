#!/bin/sh
echo "Starting GTV server on port 31000, screen oacl-gtv and auto restart it at each reboot, and check for it each hour (autorelaunch if killed)"
sh oamps.sh -n 0 -tv -tvs oacl-gtv -tvp 31000 -tvc oacl-gtv-editme.cfg -tvm dpmaster.deathmask.net -tvmp 27950 -r -a "@reboot" # launch no game server (-n 0) then launch a GTV server.
sh oamps.sh -n 0 -tv -tvs oacl-gtv -tvp 31000 -tvc oacl-gtv-editme.cfg -tvm dpmaster.deathmask.net -tvmp 27950 -a "@hourly" # check each hour that the GTV server is not killed, or autorelaunch it if that's the case.
sh oamps.sh -n 0 -hb -hs oacl-heartbeater -tvp 31000 -tvm dpmaster.deathmask.net -tvmp 27950 -a "@reboot" # sends regular heartbeats, and launch this function at each reboot.
#sh oamps.sh -n 0 -c oacl-gtv-editme -s oacl-gtv -e "gtv_description 2 OACL-Hihi" -v
sh oamps.sh -n 0 -c oacl-gtv-editme -s oacl-gtv -ec "gtv3/oacl-gtv-description.cfg" -ed 90 # wait for a delay of 90 seconds (better be long to be sure all gtv_connection are finished), then auto set rooms descriptions by execing the content of a config file containing the gtv_description commands
echo "Done ! Have fun and play fair !"