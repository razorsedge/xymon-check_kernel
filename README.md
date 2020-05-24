# Xymon Monitor Kernel Version Test

- Allows the Xymon client to test that the running kernel is the latest installed kernel.
- Test via "DEBUG=y xymoncmd ksh check_kernel.ksh"

On the Xymon SERVER:
  Add to columndoc.csv:
```
kernel;The <b>kernel</b> column shows the status of the running kernel.;
```

On the Xymon CLIENT:
  Add to /etc/xymon-client/client.d/check_kernel:
```
[kernel]
      ENVFILE /etc/xymon-client/xymonclient.cfg
      CMD $XYMONCLIENTHOME/ext/check_kernel.ksh
      LOGFILE $XYMONCLIENTHOME/logs/check_kernel.log
      INTERVAL 15m
```

