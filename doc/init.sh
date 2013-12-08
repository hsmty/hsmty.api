#!/bin/sh
set -e

### BEGIN INIT INFO
# Provides:		hsmty-api
# Required-Start:	$local_fs $remote_fs $network $time
# Required-Stop:	$local_fs $remote_fs $network $time
# Should-Start:		$syslog
# Should-Stop:		$syslog
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	HSMTY Web API server
### END INIT INFO

cd /var/www/hsmty_api
su www-data -c"./lib/hsmty/control.rb $1"
RETVAL=$?

exit $RETVAL
