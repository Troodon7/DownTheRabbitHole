#!/bin/bash

echo -e "\e[34mAre you sure you want to continue?\e[0m \e[91mThis will overwrite all files ending in .caf and convert them to .wav!\e[0m \e[32m[y/n] \e[0m"
read response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
for file in *.caf; do mv "$file" "$(basename "$file" .caf).wav"
done

else
echo -e "\e[34mAre you sure you want to continue?\e[0m \e[91mThis will overwrite all files ending in .wav and convert them to .caf!\e[0m \e[32m[y/n] \e[0m"
read response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
for file in *.wav; do
mv "$file" "$(basename "$file" .wav).caf"
done
#else
#echo "Hashtag canceled"
fi
