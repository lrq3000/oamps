#!/bin/sh
echo "Starting OA vanilla 0.8.x server on port 27960, screen oa-vanilla and auto restart it at 4:02 AM everyday, and check if down each hour"
sh oamps.sh -c config.cfg -p 27960 -s oa-vanilla -r -a "2 4 * * *"
sh oamps.sh -c config.cfg -p 27960 -s oa-vanilla -a "@hourly"
echo "Done ! Have fun and play fair !"