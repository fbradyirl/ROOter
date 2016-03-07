#!/bin/sh

waitfor() {
	CNTR=0
	while [ ! -e /tmp/modgone ]; do
		sleep 1
		CNTR=`expr $CNTR + 1`
		if [ $CNTR -gt 60 ]; then
			break
		fi
	done
}

power_toggle() {
	MODE=$1
	if [ -f "/tmp/gpiopin" ]; then
		rm -f /tmp/modgone
		source /tmp/gpiopin
		echo "$GPIOPIN" > /sys/class/gpio/export
		echo "out" > /sys/class/gpio/gpio$GPIOPIN/direction
		if [ -z $GPIOPIN2 ]; then
			echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
			waitfor
			echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
		else
			echo "$GPIOPIN2" > /sys/class/gpio/export
			echo "out" > /sys/class/gpio/gpio$GPIOPIN2/direction
			if [ $MODE = 1 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
				waitfor
				echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
			fi
			if [ $MODE = 2 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN2/value
				waitfor
				echo 1 > /sys/class/gpio/gpio$GPIOPIN2/value
			fi
			if [ $MODE = 3 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
				echo 0 > /sys/class/gpio/gpio$GPIOPIN2/value
				waitfor
				echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
				echo 1 > /sys/class/gpio/gpio$GPIOPIN2/value
			fi
			sleep 2
		fi
		rm -f /tmp/modgone
	fi
}

power_toggle $1