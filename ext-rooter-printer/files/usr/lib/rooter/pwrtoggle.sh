#!/bin/sh

power_toggle() {
	MODE=$1
	if [ -f "/tmp/gpiopin" ]; then
		source /tmp/gpiopin
		echo "$GPIOPIN" > /sys/class/gpio/export
		echo "out" > /sys/class/gpio/gpio$GPIOPIN/direction
		if [ -z $GPIOPIN2 ]; then
			echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
			sleep 20
			echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
		else
			echo "$GPIOPIN2" > /sys/class/gpio/export
			echo "out" > /sys/class/gpio/gpio$GPIOPIN2/direction
			if [ $MODE = 1 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
				sleep 20
				echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
			fi
			if [ $MODE = 2 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN2/value
				sleep 20
				echo 1 > /sys/class/gpio/gpio$GPIOPIN2/value
			fi
			if [ $MODE = 3 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
				echo 0 > /sys/class/gpio/gpio$GPIOPIN2/value
				sleep 20
				echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
				echo 1 > /sys/class/gpio/gpio$GPIOPIN2/value
			fi
			sleep 2
		fi
	fi
}

power_toggle $1