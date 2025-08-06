#!/bin/bash

echo -e "\e[34mAre you sure you want to continue?\e[0m \e[91mThis will open multiple windows!\e[0m \e[32m[y/n] \e[0m"
read response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
	gnome-terminal -x sh -c "./wakeup_script-1" &
	gnome-terminal -x sh -c "./wakeup_script-2" &
else
    echo -e "\n\e[34mOkay\e[0m \e[91;9mkilling\e[0m\e[34m the script :)\e[0m\n"
fi
