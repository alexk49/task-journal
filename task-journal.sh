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
yesterday=$(date -d '-1 day' '+%Y-%m-%d')
tomorrow=$(date -d "+1 day" "+%Y-%m-%d")

add_defaults () {
    echo "Writing defaults to new file"
    # add heading
    # by 1st line address
    sed -i "1s/^/task journal $todays_date\n-----------------------\n\n/" "$filepath"
    cat <<- _EOF_ >> "$filepath"

tasks

notes
*
_EOF_
    if [ -e "$yesterdaypath" ]; then
        if [ -e "$HABITS_FILE" ]; then
            # get line number of notes
            # to then cut off anything after the notes heading
            notes_line_number=$(sed -n '/^notes$/=' "$yesterdaypath")
            # inverse grep contents of habits file
            # inverse grep done tasks, headings, and blank lines
            echo "cutting off notes from previous entry"
            remainingtasks=$(sed ${notes_line_number}q "$yesterdaypath" | grep -v -f "$HABITS_FILE" | grep -v -e "--*" -e "^tasks$" -e "^x\s" -e "^notes$" -e "^$") 
            echo "adding outsanding tasks from previous entry"
            # this uses a here switch
            # to pass the remaining tasks variable to standard input
            # this is sub in after the match
            sed -i -e "/^tasks$/r/dev/stdin" "$filepath" <<<$remainingtasks
        fi
    fi
    return
}


get_done_tasks () {
    echo "Getting all completed tasks"
    grep -e "^x\s" "$filepath"
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

yesterdayfile="$yesterday-jrnl.txt"
yesterdaypath="$month_folder/$yesterdayfile"
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
