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
today=$(date +"%Y-%m-%d")
yesterday=$(date -d '-1 day' '+%Y-%m-%d')


usage () {
    echo "Usage: $(basename "$0") [options] [date]"
}


help () {
    usage
    echo
    echo "If date not passed then date default is today"
    echo "Usage: $(basename "$0") to view file"
    echo "Usage: $(basename "$0") [-e] to edit file"
    echo "Usage: $(basename "$0") [-k] to view key view"
}


# add default headings and undone tasks from previous day
add_defaults () {
    if [ "$#" != 1 ]; then
        entry_date=$today
    else
        entry_date=$1
    fi

    echo "Writing defaults to new file"
    # add heading
    # by 1st line address
    sed -i "1s/^/task journal $today\n-----------------------\n\n/" "$filepath"
    # indention deliberate got rid of
    # as tab characters break <<- switch
    # write defaults to file
    cat <<- _EOF_ >> "$filepath"

tasks

notes
*
_EOF_

    get_previous_entry "$entry_date"
    echo "Previous entry found: $(basename $previous_filepath)"
    
    if [ -e "$previous_filepath" ] && [ -e "$HABITS_FILE" ]; then
        # get line number of notes
        # to then cut off anything after the notes heading
        notes_line_number=$(sed -n '/^notes$/=' "$previous_filepath")
        # inverse grep contents of habits file
        # inverse grep done tasks, headings, and blank lines
        echo "cutting off notes from previous entry"
        remainingtasks=$(sed "${notes_line_number}"q "$previous_filepath" | grep -v -f "$HABITS_FILE" | grep -v -e "--*" -e "^tasks$" -e "^x\s" -e "^notes$" -e "^$") 
        echo "adding outsanding tasks from previous entry"
        # this uses a here switch
        # to pass the remaining tasks variable to standard input
        # this is then added in after the match
        sed -i -e "/^tasks$/r/dev/stdin" "$filepath" <<<"$remainingtasks"
    else
        :
    fi
}


edit_file () {
    "$EDITOR" "$filepath"
    return
}


view_file () {
    echo 
    cat -n "$filepath"
    return
}


view_key_file () {
    cat "$KEY_FILE"
    return
}


# takes entry date as arg
# and gives back last entry
get_previous_entry () {
    current_entry=$1
    count=1
    while [[ "$count" -le 7 ]]; do
        previous=$(date --date="${current_entry} -${count} day" "+%Y-%m-%d")

        previous_year=${previous:0:4}
        previous_month=$(date --date="$previous" '+%b')

        previous_year_folder="$JOURNALS_FOLDER/$previous_year"
        previous_month_folder="$previous_year_folder/$previous_month"
        # format will be yyyy-mm-dd-jrnl.txt
        previous_filename="$previous-jrnl.txt"

        previous_filepath="$previous_month_folder/$previous_filename"
        
        if [ -f "$previous_filepath" ]; then
            return 
        else
            count=$((count + 1)) 
        fi
    done

    # if no file found return nothing
    echo "No previous entry found within last week"
    return
}


get_done_tasks () {
    echo "Getting all completed tasks"
    grep -e "^x\s" "$filepath"
    return
}


# function to check all paths of given date work
check_paths () {
    if [ "$#" != 1 ]; then
        entry_date=$today
    else
        entry_date=$1
    fi
    year=${entry_date:0:4}
    month=$(date --date="$entry_date" '+%b')
    # check if a folder named journal exists
    # if not make it
    if [ ! -d "$JOURNALS_FOLDER" ]; then
        echo "Deafult journal folder not found."
        echo "Creating $JOURNALS_FOLDER"
        mkdir "$JOURNALS_FOLDER"
    fi

    year_folder="$JOURNALS_FOLDER/$year"

    if [ ! -d "$year_folder" ]; then
        echo "Creating year folder for: $year"
        mkdir "$year_folder"
    fi

    # month as short string
    month_folder="$year_folder/$month"

    # folder structure by year then month
    # $Home/notes/journals/2023/jun/
    if [ ! -d "$month_folder" ]; then
        echo "Creating month folder for: $month"
        mkdir "$month_folder"
    fi

    # format will be yyyy-mm-dd-jrnl.txt
    filename="$entry_date-jrnl.txt"

    filepath="$month_folder/$filename"

    # if today file doesn't exist and habits file does
    # copy habits file to todays file
    if [ ! -e "$filepath" ] && [ -e "$HABITS_FILE" ]; then
        echo "Creating new file with habits"
        cat "$HABITS_FILE" > "$filepath"
        add_defaults "$entry_date"

    # if file does not exist and habits does not exist
    # just create file
    elif [ ! -e "$filepath" ] && [ ! -e "$HABITS_FILE" ]; then
        touch "$filepath"
        add_defaults "$entry_date"
    else
        :
    fi

    return
}


# handle args
# loop continues whilst $1 is not empty
while [[ -n "$1" ]]; do
    case "$1" in
        -e | --edit) 
            edit=1
            ;;
        -h | --help)
            help
            exit
            ;;
        -k | --key)
            echo "Key file: "
            view_key_file
            exit
            ;;
        -y | yesterday)
            entry_date=$yesterday
            ;;
        ?) 
            usage
            exit 1
            ;;
    esac
    shift
done

# if invalid date or no entry date set
# then entry date is today
if [[ ! "$entry_date" =~ ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ ]]; then 
    entry_date=$today
fi

# check if edit or view
if [[ -n "$edit" ]]; then
    check_paths "$entry_date"
    edit_file
else
    check_paths "$entry_date"
    view_file
fi
