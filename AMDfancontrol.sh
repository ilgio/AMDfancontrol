#!/bin/bash

#============================================================
#= fancontrol.sh v0.2 created by ilgio                        =
#============================================================

# Adjust AMD GPU fan speeds according to card temperatures.
# Note that this script is intended to be run routinely from root's crontab.

# Set your TARGET temperature for all GPUs. If mining, this will realistically be on a scale from
# 50 to 70 degrees Celcius according to the temperatures you will put up with and the noise you
# will put up with.


# SET CLOCK AMDGPU
function progr_bar()
{
    MAX=$1
    PERCENT=0
    FOO=""
    BAR=""

    while [ $PERCENT -lt $(($MAX+1)) ]
    do
        echo -en "\033[3;5f";
        #echo -ne "\r"
        echo -ne "$BAR$FOO "
        BAR="${BAR}__________"

        let PERCENT=$PERCENT+1
        sleep 1
    done

    echo -e " Done.\n"
}

set_clock (){
if [ "$1" -ge "0" ] && [ "$1" -le "7" ] && [ "$2" -ge "0" ] && [ "$2" -le "20" ]; then
    echo "OC values ok"
else
    /root/utils/oc_dpm2.sh "$1" "$2"
    exit
fi




x=0;
while [ $x -le 7 ]; do
    if [ -e "/sys/class/drm/card$x/device/power_dpm_force_performance_level" ]
    then
        mem_states=`cat /sys/class/drm/card$x/device/pp_dpm_mclk | wc -l`
        dpm_mem=$(($mem_states-1))
        echo "manual" > /sys/class/drm/card$x/device/power_dpm_force_performance_level
        echo $1 > /sys/class/drm/card$x/device/pp_dpm_sclk
        #echo $dpm_mem > /sys/class/drm/card$x/device/pp_dpm_mclk
        #echo "primo"
    fi
    x=$[x + 1]
done

sleep 1

x=0;
while [ $x -le 7 ]; do
    if [ -e "/sys/class/drm/card$x/device/power_dpm_force_performance_level" ]
    then
        mem_states=`cat /sys/class/drm/card$x/device/pp_dpm_mclk | wc -l`
        dpm_mem=$(($mem_states-1))
        #echo $2 > /sys/class/drm/card$x/device/pp_mclk_od
        echo "manual" > /sys/class/drm/card$x/device/power_dpm_force_performance_level
        echo $1 > /sys/class/drm/card$x/device/pp_dpm_sclk
        #echo $dpm_mem > /sys/class/drm/card$x/device/pp_dpm_mclk
        #echo "secondo"
    fi
    x=$[x + 1]
done
}



function red {
        echo -e "$(tput bold; tput setaf 1)$1$(tput sgr0)"
}

# Menu
show_menus() {
clear
tput bold; tput setaf 7
echo
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "                   AMDPRO FANCONTROL RX                "
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "\e[97m\e[1mTARGET: $TARGET\xc2\xb0C \e[0m \e[97m      \e[5m `date +%H:%M:%S`\e[25m           refresh (10sec)"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        i=$(($i+1))

        for ((n=0;n<N_GPU;n++)); do
                #[ -r /sys/class/drm/card$n/device/hwmon/hwmon$n/temp1_input ] && [ -w /sys/class/drm/card$n/device/hwmon/hwmon$n/pwm1 ] && \
                FAN=`cat /sys/class/drm/card$n/device/hwmon/hwmon$n/pwm1`
                TMP=$((`cat /sys/class/drm/card$n/device/hwmon/hwmon$n/temp1_input`/1000))
                FANP=`bc <<< "scale=2; ($FAN/255)*100"`
                TMPP=$(checkgputemp "$TMP" "$TARGET")
                NEWFAN=$(decidefanspeed "$TMPP" "$FAN")
                NFANP=`bc <<< "scale=2; ($NEWFAN/255)*100"`
                tput sgr0
                echo
                #echo -n "                 "
                if [ $TMP -gt $TARGET ]; then
                        echo -ne "\e[93m\e[21m--GPU #$n: \e[1m$TMP"
                elif [ $TMP -gt 75 ]; then
                        echo -ne "\e[91m\e[21m--GPU #$n: \e[1m$TMP"
                else
                        echo -ne "\e[96m\e[21m--GPU #$n: \e[1m$TMP"
                fi
                echo -n $'\xc2\xb0'C
                #echo -e "\e[0m \e[38;5;244m($TMPP%); set fan speed from $FAN/255 ($FANP%) to $NEWFAN/255 \e[92m\e[1m($NFANP%)"
                echo -e " \e[92m\e[1m($NFANP%)"
                echo -e "\e[0m\e[38;5;244m"
                cat /sys/class/drm/card$n/device/pp_dpm_sclk
                tput sgr0
                echo "$NEWFAN" > /sys/class/drm/card$n/device/hwmon/hwmon$n/pwm1
        done;
	tput bold; tput setaf 3
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "            1. Preference        	    q. Exit           "
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo
	tput sgr0
	local choice
	read -t 10 -n1 choice
	if [ -n "$choice" ]; then
	
		#read -n1 choice
		case $choice in
			1) sub_menu ;;
			q) exit 0;;
			*) echo -e "$(red "             Incorrect option!")" && sleep 1
		esac
	fi
}


sub_menu() {
	clear
	tput bold; tput setaf 7
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "       S E L E C T   Y O U R   P R E F E R E N C E  "
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo
	echo "     1. Target  2. Clock  3. Numer of GPU   q. Quit "
	echo
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo
	tput sgr0
	local choice
	read -n1 choice
        #read -p "        Enter choice [1 - 2], [q for exit]: " choice
        case $choice in
                1) one ;;
                2) two ;;
		3) tree ;;
                q) show_menus;;
                *) echo -e "$(red "             Incorrect option!")" && sleep 1
        esac
}

one(){
	local choice
	echo
	echo "Insert temperature to target and press ENTER"
	read -p "Enter choice [50 - 80], [q for exit]: " choice
	if [[ $choice -ge 50 && $choice -le 80 ]]; then
		echo "$choice"
		TARGET=$choice
		show_menus
		
	else
	        case $choice in
        	      	q) show_menus;;
                	*) echo -e "$(red "             Incorrect option!")" && sleep 1
        	esac
	fi
}
two(){
	local choice
	echo
	read -p "        Enter choice [0 - 7], [q for exit]: " choice
        if [[ $choice -ge 0 && $choice -le 7 ]]; then
		set_clock $choice 0
	else
                case $choice in
                        q) show_menus;;
                        *) echo -e "$(red "             Incorrect option!")" && sleep 1
                esac
        fi
}

tree() {
	local choice
        echo
        read -p "        Enter choice [1 - 6], [q for exit]: " choice
        if [[ $choice -ge 1 && $choice -le 6 ]]; then
                N_GPU=$choice
	sleep 5
        else
                case $choice in
                        q) show_menus;;
                        *) echo -e "$(red "             Incorrect option!")" && sleep 1
                esac
        fi
}

function checkgputemp {
        THERMOSTAT=$(($2-3));
        TEMP=$1;
        PERCENT=`bc <<< "scale=2; ($TEMP/$THERMOSTAT)*100"`;
        echo "$PERCENT";
}


# Note, TARGET temperature, not maximum temperature. Suggest setting this as one of 50, 60, or 70,
# because what we want is to permit about three different levels of fan speed responses according
# to whether we're a degree or two above the target, 10% above target or 15-20% above the target.

# Our fan speed (a value from 0-255) can sensibly be adjusted within a range of 50-250, where 50
# is all but silent (20% of fan capacity) and 250 is full blast (air and noise alike). Under the
# normal case, we'd like it to be between 100 and 200 (40% to 80%) of fan capacity while mining.

# 

function decidefanspeed {
        TMPP=$1;
        TMPI=`echo $1 | cut -d \. -f 1| bc`;
        FAN=$2
        NEWFAN="$FAN";
        [ "$TMPI" -lt 90 ] && NEWFAN=`expr "$FAN" - 30`;
        [ "$TMPI" -lt 92 ] && NEWFAN=`expr "$FAN" - 20`;
        [ "$TMPI" -lt 96 ] && NEWFAN=`expr "$FAN" - 10`;
        [ "$TMPI" -gt 103 ] && NEWFAN=`expr "$FAN" + 10`;
        [ "$TMPI" -gt 106 ] && NEWFAN=`expr "$FAN" + 30`;
        [ "$TMPI" -gt 108 ] && NEWFAN=`expr "$FAN" + 40`;
        [ "$TMPI" -gt 110 ] && NEWFAN=200;
        [ "$TMPI" -gt 120 ] && NEWFAN=250;
        [ "$NEWFAN" -gt 250 ] && NEWFAN=250;
        [ "$NEWFAN" -lt 50 ] && NEWFAN=50;
        echo "$NEWFAN";
}

# PREFERENCE

TARGET=65
N_GPU=2



################


tput civis


while true; do

        show_menus
	#progr_bar 10

	#sleep 10
done


