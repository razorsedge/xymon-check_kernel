[kernel]
      ENVFILE /etc/xymon-client/xymonclient.cfg
      CMD $XYMONCLIENTHOME/ext/check_kernel.ksh
      LOGFILE $XYMONCLIENTHOME/logs/check_kernel.log
      INTERVAL 15m
