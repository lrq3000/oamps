****************************
* OAMPS LAUNCHERS EXAMPLES *
****************************

README
------
OAMPS has always been thought and coded to be used as a command to be fully automated with bash scripting. The true power of OAMPS can only be unleashed when using it in bash scripts.

To demonstrate this, you can find in the samples folder a set of launchers that makes use of the scripting functionnality of OAMPS.

Place these files in your game server's root, along with oamps.sh (or you can change the paths by yourself), and then chmod +x the .sh files and execute them with sh (same as oamps.sh, see the README in the parent folder for oamps.sh for more detailed instructions).

You can find :
- one simple launcher with the basic commandlines to launch a server.
- one advanced launcher with advanced functionnalities with output logging and messages warning for players before restart (advised for administrators).
- three advanced launchers used for the OpenArena Clan League 2010 (OACL2010). These are to be used with the OACL config (see oa-cl.ucoz.org).
- one launcher for GTV. This one is the most complicated and is only needed if you use GTV. It will show you how to launch a GTV server and show it in the servers list.

If you feel lost at any moment about the commands used in the launchers, please read the help (sh oamps.sh --help).

Note : If you are using the launchers with the oacl config, in the launchers please edit "-c config.cfg" into "-c oacl-edit-me".

--------
GrosBedo