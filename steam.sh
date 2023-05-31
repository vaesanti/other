#!/bin/bash

# figure out the absolute path to the script being run a bit
# non-obvious, the ${0%/*} pulls the path out of $0, cd's into the
# specified directory, then uses $PWD to figure out where that
# directory lives - and all this in a subshell, so we don't affect
# $PWD

STEAMROOT=$(cd "${0%/*}" && echo $PWD)

#determine platform
UNAME=`uname`
if [ "$UNAME" == "Linux" ]; then
   PLATFORM=linux32
   # prepend our lib path to LD_LIBRARY_PATH
   export LD_LIBRARY_PATH="${STEAMROOT}"/${PLATFORM}:$LD_LIBRARY_PATH
else # if [ "$UNAME" == "Darwin" ]; then
   PLATFORM=osx32
   # prepend our lib path to LD_LIBRARY_PATH
   export DYLD_LIBRARY_PATH="${STEAMROOT}"/${PLATFORM}:$DYLD_LIBRARY_PATH
   # make sure our architecture is sane
   ARCH=`arch`
   case "$ARCH" in
      ppc* )
	    osascript -e 'tell application "Dock" 
			display dialog "Steam is only supported on Intel-based Macs." buttons "Exit" default button 1 with title "Unsupported Architecture" with icon stop
			activate
			end tell'
		exit -1
	  ;;
   esac
   # make sure we're running >= 10.5.0
   OSXVER=`sw_vers -productVersion`
   case "$OSXVER" in
      10.0.* | 10.1.* | 10.2.* | 10.3.* | 10.4.* )
	    osascript -e 'tell application "Dock" 
			display dialog "Steam Requires OSX 10.5 or greater" buttons "Exit" default button 1 with title "Unsupported Operating System" with icon stop
			activate
			end tell'
		exit -1
	  ;;
   esac  
fi

if [ -z $STEAMEXE ]; then
  STEAMEXE=steam
fi

ulimit -n 2048

# and launch steam
cd "$STEAMROOT"

STATUS=42
while [ $STATUS -eq 42 ]; do
	${DEBUGGER} "${STEAMROOT}"/${PLATFORM}/${STEAMEXE} "$@"
	STATUS=$?
	# are we running osx?
	if [ $STATUS -eq 42 -a ${PLATFORM} == "osx32" -a -f Info.plist ]; then
		# are we running from in a bundle?
		exec open "${STEAMROOT}"/../..
	fi
done
exit $STATUS
