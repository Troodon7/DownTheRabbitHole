#!/bin/bash

HN="Wake Up Script 1"

intertube=0
echo -e "\n\e[1;4;34mStarting test for $HN\e[0m\n"
while [ $intertube -ne 1 ]; do
        ping -c 3 1.1.1.1
#must be the IP of the device ^^^^
        if [ $? -eq  0 ]; then
                echo -e "\n\e[46;5m$HN Online\e[0m\n";
                intertube=1;
        else
                echo -e "\n\e[101;1;4m$HN offline\e[0m  \e[5;91mQUICK!\e[0m \e[1;4;91mGet the paddles!!!\e[0m\n"
		echo -e "\e[1;4;91mPress CTRL+Z to let the patient die\e[0m\n"
	for i in {1..3}; do wakeonlan FF:FF:FF:FF:FF:FF; done
					#^^^^^^Subject to change with new one
        fi
done

sleep 10
