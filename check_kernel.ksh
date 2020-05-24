#!/bin/ksh
#
# $Id$
#
# Xymon Monitor Kernel Version Test
#     - Allows the Xymon client to test that the running kernel is the latest
#       installed kernel.
#     - Test via "DEBUG=y xymoncmd ksh check_kernel.ksh"
#
# On the Xymon SERVER:
#   Add to columndoc.csv:
# kernel;The <b>kernel</b> column shows the status of the running kernel.;
#
#
# On the Xymon CLIENT:
#   Add to /etc/xymon-client/client.d/check_kernel:
# [kernel]
# 	ENVFILE /etc/xymon-client/xymonclient.cfg
# 	CMD $XYMONCLIENTHOME/ext/check_kernel.ksh
# 	LOGFILE $XYMONCLIENTHOME/logs/check_kernel.log
# 	INTERVAL 15m
#
# EXIT CODE:
#     0 = success
#     1 = print_help function (or incorrect commandline)
#     2 = ERROR: Must be root.
#     9 = ERROR: Missing Xymon environment. Please use xymoncmd.
#
AUTHOR="Mike Arnold <mike at razorsedge dot org>"
VERSION=20200524
LOCATION="http://www.razorsedge.org/~mike/software/check_kernel.ksh"
#
if [ $DEBUG ]; then set -x; fi
#
##### START CONFIG ###################################################

##### STOP CONFIG ####################################################
PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin:${PATH}
COLUMN=kernel
COLOR=clear

# Function to print the help screen.
print_help () {
  print "Usage:  $1"
  print "        $1 [-h|--help]"
  print "        $1 [-v|--version]"
  print "   ex.  $1"
  exit 1
}

# Function to check for root priviledges.
check_root () {
  if [[ $($ID | $AWK -F= '{print $2}' | $AWK -F"(" '{print $1}' 2>/dev/null) -ne 0 ]]; then
    print "You must have root priviledges to run this program."
    exit 2
  fi
}

# If the variable DEBUG is set, then turn on tracing.
# http://www.research.att.com/lists/ast-users/2003/05/msg00009.html
if [ $DEBUG ]; then
  # This will turn on the ksh xtrace option for mainline code
  set -x

  # This will turn on the ksh xtrace option for all functions
  typeset +f |
  while read F junk
  do
    typeset -ft $F
  done
  unset F junk
fi

# Process arguments.
while [[ $1 = -* ]]; do
  case $1 in
    -h|--help)
      print_help "$(basename $0)"
      ;;
    -v|--version)
      print "\tXymon Monitor Kernel Version Test"
      print "\t$LOCATION"
      print "\tVersion: $VERSION"
      print "\tWritten by: $AUTHOR"
      exit 0
      ;;
    *)
      print_help "$(basename $0)"
      ;;
  esac
  shift
done

# Check to see if we have no parameters.
#if [[ ! $# -ge 1 ]]; then print_help "$(basename $0)"; fi

# Lets not bother continuing unless we have the privs to do something.
#check_root

# main
# If we are running outside of the Xymon environment, then complain.
if [ -z "$XYMONCLIENTHOME" ]; then
  echo "ERROR: Missing Xymon environment. Please use xymoncmd."
  echo '       Test via "DEBUG=y xymoncmd ksh check_kernel.ksh"'
  exit 9
fi

#KERNEL_INSTALLED=$(ls -v /boot/vmlinuz* | tail -1 | sed -e 's|/boot/vmlinuz-||')
KERNEL_INSTALLED=$(rpm -q --queryformat '%{BUILDTIME} %{VERSION}-%{RELEASE}.%{ARCH}\n' kernel | sort | tail -1 | awk '{print $2}')
KERNEL_BOOT=$(uname -r)
KERNEL_INSTALLED_BUILDDATE=$(rpm -q --queryformat '%{BUILDTIME}\n' kernel-${KERNEL_INSTALLED})
KERNEL_BOOT_BUILDDATE=$(rpm -q --queryformat '%{BUILDTIME}\n' kernel-${KERNEL_BOOT})
KERNEL_INSTALLED_BUILDDATE_HUMAN=$(date -d @${KERNEL_INSTALLED_BUILDDATE} '+%Y-%m-%d')
KERNEL_BOOT_BUILDDATE_HUMAN=$(date -d @${KERNEL_BOOT_BUILDDATE} '+%Y-%m-%d')

if [[ "$KERNEL_INSTALLED_BUILDDATE" -gt "$KERNEL_BOOT_BUILDDATE" ]]; then
  COLOR=yellow
  MSG="

Reboot required.
"
elif [[ "$KERNEL_INSTALLED_BUILDDATE" -lt "$KERNEL_BOOT_BUILDDATE" ]]; then
  COLOR=red
  MSG="

Running kernel is newer than the version found on disk.
"
elif [[ "$KERNEL_INSTALLED_BUILDDATE" -eq "$KERNEL_BOOT_BUILDDATE" ]] && [[ "$KERNEL_INSTALLED" == "$KERNEL_BOOT" ]]; then
  COLOR=green
  MSG="

All OK.
"
elif [[ "$KERNEL_INSTALLED_BUILDDATE" -eq "$KERNEL_BOOT_BUILDDATE" ]] && [[ "$KERNEL_INSTALLED" != "$KERNEL_BOOT" ]]; then
  COLOR=yellow
  MSG="

Reboot required.
"
else
  # We should never get here.
  COLOR=clear
  MSG="

Unknown error.
"
fi

  MSG="$MSG
Running KERNEL:   $KERNEL_BOOT from $KERNEL_BOOT_BUILDDATE_HUMAN
Installed KERNEL: $KERNEL_INSTALLED from $KERNEL_INSTALLED_BUILDDATE_HUMAN
"

# Send the message to the Xymon server.
if [ $DEBUG ]; then
  echo $BB $BBDISP "\"status $MACHINE.$COLUMN $COLOR $($DATE) $MSG"\"
else
  $BB $BBDISP "status $MACHINE.$COLUMN $COLOR $($DATE) $MSG"
fi

exit 0
