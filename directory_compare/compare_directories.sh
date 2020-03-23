#!/bin/bash
echo -ne "\033]11;#002266\007"
### Parameters for script to be passed to Python ###
script='directory_compare.py' # Name of general python script
dataset=${PWD##*/}
user=$(whoami)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
nr_processes=2 # Number of processes to parallelize across

PATH=/c/ProgramData/Anaconda3/:$PATH

### Create log for script ###
mkdir -p logs # create dir for logs if not already exist
startdatetime=`date +"%Y-%m-%d_%Hh%Mm"`
prefix="$( cut -d '.' -f 1 <<< "$script")"
exec 3>&1 1>> logs/$prefix"_"$startdatetime".txt" 2>&1

echo "This script will compare 'Date modified' between file contents in the PII repository directory " 1>&3
echo "//Isi/ida/Projects/PII Data Curation/ and the corresponding backup directory " 1>&3
echo "$DIR." 1>&3
echo "The end result will be a .json file organizing files that have been deleted from the repository " 1>&3
echo "directory, added to the repository directory, or altered in the repository since being uploaded." 1>&3
echo "" 1>&3

read -rsp $'Press enter to continue...\n' 2>/dev/tty
# sleep 5m
echo "Running script.." 1>&3

echo $"User name: $user" 1>&2
printf "\r\nScript name: $script\n\r" | tee /dev/fd/3
printf "\nStart date-time: $startdatetime\n\r" | tee /dev/fd/3
printf "\n-----------------------------\r\n" | tee /dev/fd/3
printf "Output from script:\r\n\r\n" | tee /dev/fd/3

python $script $nr_processes -u 2>&1 | tee /dev/fd/3
echo -ne "\033]11;#008800\007"
enddatetime=`date +"%Y-%m-%d_%Hh%Mm"`
printf "\n-----------------------------\r\n" | tee /dev/fd/3
printf "\nEnd date-time: $enddatetime\n" | tee /dev/fd/3

read -rsp $'\nPress any key to continue...\n' -n 1 2>/dev/tty