#!/bin/bash

# journal.sh: command line wrapper for bullet journaling in text editor

# globals

# set default editor for journal
# vim is go to default
EDITOR=vim; export EDITOR

JOURNALS_FOLDER="$HOME/journal"
DATA_FOLDER="$JOURNALS_FOLDER/data"

KEY_FILE="$DATA_FOLDER/key.txt"
HABITS_FILE="$DATA_FOLDER/habits.txt"

# get todays date as file name
todays_date=$(date +"%Y-%m-%d")

add_defaults () {
    echo "Writing defaults to new file"
    # add heading
    # by 1st line address
    sed -i "1s/^/Task Journal $todays_date\n-----------------------\n\n/" $filepath
    cat <<- _EOF_ >> $filepath

tasks
-----

notes
-----
_EOF_
    return
}

# check if a folder named journal exists
# if not make it
if [ ! -d "$JOURNALS_FOLDER" ]; then
    echo "Deafult journal folder not found."
    echo "Creating $JOURNALS_FOLDER"
    mkdir "$JOURNALS_FOLDER"
fi

year=$(date +"%Y")
year_folder="$JOURNALS_FOLDER/$year"

if [ ! -d "$year_folder" ]; then
    echo "Creating year folder for: $year"
    mkdir "$year_folder"
fi

# month as short string
month=$(date +"%b")
month_folder="$year_folder/$month"

# folder structure by year then month
# $Home/notes/journals/2023/jun/
if [ ! -d "$month_folder" ]; then
    echo "Creating month folder for: $month"
    mkdir "$month_folder"
fi

# format will be yyyy-mm-dd-jrnl.txt
filename="$todays_date-jrnl.txt"

filepath="$month_folder/$filename"

# check if the today's date txt file exists
# if not exists make it

# if today file doesn't exist and habits file does
# copy habits file to todays file
if [ ! -e "$filepath" ] && [ -e "$HABITS_FILE" ]; then
    echo "Creating todays date file with habits"
    cat "$HABITS_FILE" > "$filepath"
    add_defaults
    "$EDITOR" "$filepath"

# if today file does not exist and habits does not exist
# just create today file
elif [ ! -e "$filepath" ] && [ ! -e "$HABITS_FILE" ]; then
    touch "$filepath"
    add_defaults
    "$EDITOR" "$filepath"

else
    # open file in edtior
    "$EDITOR" "$filepath"
fi
