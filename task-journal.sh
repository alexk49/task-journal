#!/bin/bash

# journal.sh: command line wrapper for bullet journaling in text editor

# globals

# set default editor for journal
# vim is go to default
EDITOR=vim; export EDITOR

JOURNALS_FOLDER="$HOME/task-journal"
DATA_FOLDER="$JOURNALS_FOLDER/data"
REVIEW_FOLDER="$JOURNALS_FOLDER/reviews"

KEY_FILE="$DATA_FOLDER/key.md"
HABITS_FILE="$DATA_FOLDER/habits.md"

# unused colours kept in case of change
# thanks - https://stackoverflow.com/questions/4332478/read-the-current-text-color-in-a-xterm/4332530#4332530
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
UNDERLINE=$(tput smul)

# get todays date as file name
today=$(date +"%Y-%m-%d")
yesterday=$(date -d '-1 day' '+%Y-%m-%d')


usage () {
    echo "Usage: $(basename "$0") [options] [date]"
    echo "See help for more details"
}


help () {

cat << _EOF_
--------------------------
Task Journal example usage
--------------------------

It is recommended to create an alias for ./task-journal.sh to tj
alias tj="path-to-task-journal.sh"

This will allow the following usage:

# to view/create an entry for today:
tj

# to edit today's entry:
tj -edit
tj -e

# to add to current file
tj -a "text for task to add"
tj add "text for task to add"

# add to notes from command line
tj -a "text for note to add" n
tj -a "text for note to add" notes

# view/create given entry date
tj -d yyyy-mm-dd
tj date yyyy-mm-dd

# mark task as complete
tj do line-number-of-task-to-complete
For example: tj do 10

# edit habits file, note this may require a manual edit to your next entry file-habits | habits)
tj -habits

# view key file
tj -k
tj --key

# view and create a review file of all done tasks in past week
tj -r 
tj -review
tj review

# search for a term in today's entry
tj ls "search term"
tj -s "search term"

# search for a term across specific entry
tj ls "search term" "yyyy-mm-dd"
tj -s "search term" "yyyy-mm-dd"

# view yesterday's file
tj -y
tj yesterday

# edit yesterday's file
tj -edit yesterday
tj -e -y

_EOF_
}


# if invalid date or no entry date set
# then entry date is today
check_valid_date () {
    entry_date="$1"
    
    # check valid format
    if [[ ! "$entry_date" =~ ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ ]]; then 
        echo "Invalid format date given. Format must be: yyyy-mm-dd"
        echo "Reseting date to $today"
        entry_date=$today
    fi

    # redirect date check stderr and stdout to dev/null
    date -d "$entry_date" 2>&1>/dev/null
    # if exit code is 1 invalid date otherwise fine
    if [[ "$?" == 1 ]]; then
        echo "Invalid date"
        echo "Reseting date to $today"
        entry_date="$today"
    fi
}



# add default headings and undone tasks from previous day
add_defaults () {
    if [ "$#" != 1 ]; then
        entry_date=$today
    else
        entry_date=$1
    fi

    echo "Writing defaults to new file"
    # add heading by 1st line address
    sed -i "1s/^/# task journal $entry_date\n\n/" "$filepath"
    # indention deliberate got rid of
    # as tab characters break <<- switch
    # write defaults to file
    cat <<- _EOF_ >> "$filepath"

## tasks

## notes

_EOF_

    get_previous_entry "$entry_date"
    echo "Previous entry found: $(basename $previous_filepath)"
    
    if [ -e "$previous_filepath" ] && [ -e "$HABITS_FILE" ]; then
        # get line number of notes
        # to then cut off anything after the notes heading
        notes_line_number=$(sed -n '/^## notes$/=' "$previous_filepath")
        # inverse grep contents of habits file
        # inverse grep done tasks, headings, and blank lines
        echo "cutting off notes from previous entry"
        remainingtasks=$(sed "${notes_line_number}"q "$previous_filepath" | grep -v -f "$HABITS_FILE" | grep -v -e "--*" -e "^## tasks$" -e "^x\s" -e "^## notes$" -e "^$") 
        echo "adding outstanding tasks from previous entry"
        # this uses a here switch
        # to pass the remaining tasks variable to standard input
        # this is then added in after the match
        sed -i -e "/^## tasks$/r/dev/stdin" "$filepath" <<<"$remainingtasks"
    else
        :
    fi
}


add_to_file () {
    entry_date="$today"
    check_paths "$today"
    
    addition="$1"

    if [[ "$#" == 2 ]]; then
        heading="$2"
        # heading has to be notes or tasks
        # handling for n or t
        if [[ "$heading" == "n" ]]; then
            heading="notes"
        elif [[ "$heading" != "notes" ]]; then
            heading="tasks"
        else
            # assigned heading is fine
            # so do nothing
            :
        fi
    else
        # default heading is tasks
        heading="tasks"
    fi

    echo "adding $addition under the heading: $heading"
    sed -i -e "/^## $heading$/a $addition" $filepath 
    view_file
    return

}


complete_task () {
    # check args have been passed
    if [[ "$#" != 1 ]]; then
        echo "Invalid usage. Must provide line number of task to complete"
        usage
        exit 1
    fi
    # check arg is number
    if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Task to complete must be passed as a number" >&2
        usage
        exit 1
    fi

    item="$1"
    
    # assign standard entry dates
    entry_date="$today"
    check_paths "$today"

    echo "Completing item number: $item"
    echo "Task: "
    
    task=$(sed -n "${item}p;" "$filepath")
    # check if task already done
    check=$(echo "$task" | grep -E "^x .*")
    
    echo "$task"

    if [[ -n "$check" ]]; then
        echo "already marked as complete"
        exit
    else
        echo "marked as complete"
        # taken from todo.txt
        # no idea why | works instead of /
        sed -i "${item}s|^|x |" "$filepath" 
        return
    fi
}


edit_file () {
    "$EDITOR" "$filepath"
    return
}


view_file () {
    # loop throuh file to allow colour highlighting 
    # set internal field seperator to blank
    # this avoids stripping of whitespace at beginning or end of lines
    # colorized text taken from https://stackoverflow.com/questions/5412761/using-colors-with-printf/5413029#5413029
    
    # spaces in printf to match cat output
    # line numbers added manually

    linecount=0

    while IFS="" read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^# ]]; then
            # output has been fixed with this stupid way
            if [[ "$linecount" -lt 9 ]]; then
                printf "    %s%s%s %s%s\n" " $((++linecount))" "$BOLD" "$RED" "$line" "$NORMAL"
            else
                # put headings in bold and colour red
                # must reset to normal at end
                printf "    %s%s%s %s%s\n" "$((++linecount))" "$BOLD" "$RED" "$line" "$NORMAL"
            fi
        elif [[ "$line" =~ ^x ]]; then
            # mark done tasks in yellow
            # must reset to normal at end
            if [[ "$linecount" -lt 9 ]]; then
                printf "    %s%s %s%s\n" " $((++linecount))" "$YELLOW" "$line" "$NORMAL"
            else
                printf "    %s%s %s%s\n" "$((++linecount))" "$YELLOW" "$line" "$NORMAL"
            fi
        else
            if [[ "$linecount" -lt 9 ]]; then
                printf '    %s %s\n' " $((++linecount))" "$line"
            else
                # print line as normal
                printf '    %s %s\n' "$((++linecount))" "$line"
            fi
        fi
    done < "$filepath"
    return
}


search_entry () {
    # usage: search-term entry-date
    search_term="$1"
    # entry date is optional
    # if not given assign to today
    if [[ "$2" == "week" ]]; then
        search_past_week "$search_term"
        exit
    elif [[ -n "$2" ]]; then
        check_valid_date "$2" 
    else
        entry_date="$today"
    fi
    # check paths and assign filepath
    check_paths "$entry_date"
    printf "$BOLD"
    head -n1 "$filepath"
    printf "$NORMAL"
    echo
    grep --color='auto' "$search_term" "$filepath"
    return
}


search_past_week () {
    search_term="$1"
    # loop through past 7 days
    for (( i=0; i<7; i=i+1 )); do
        entry_date=$(date -d "-$i day" "+%Y-%m-%d")

        check_paths "$entry_date"
        printf "$BOLD"
        head -n1 "$filepath"
        printf "$NORMAL"
        echo
        grep --color='auto' "$search_term" "$filepath"
    done

    return
}


# bring habits file up for editing
edit_habits () {
    if [[ -e "$HABITS_FILE" ]]; then
        "$EDITOR" "$HABITS_FILE"
    else
        touch "$HABITS_FILE"
        "$EDITOR" "$HABITS_FILE"
    fi
}

# quicky view key file
view_key_file () {
    if [[ -e "$KEY_FILE" ]]; then
        cat "$KEY_FILE"
        return
    else
        # indentation deliberately removed
        # to avoid breaking here switch
        cat << _EOF_ >> "$KEY_FILE" 
## habits
tasks you do everyday

## tasks
task with no status is to do
x example done task
\ in progress task
task with context tag +context
(A) task with priority tag +context

## notes
notes will be made blank at the start of each day
_EOF_
        cat "$KEY_FILE"
        return
    fi
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
        # format will be yyyy-mm-dd-jrnl.md
        previous_filename="$previous-jrnl.md"

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


review_past_week () {
    # loop through past 7 days

    seven_days_ago=$(date -d '-7 day' '+%Y-%m-%d')
    
    month=$(date --date="$seven_days_ago" '+%b')
    
    if [[ ! -d "$REVIEW_FOLDER" ]]; then
            mkdir "$REVIEW_FOLDER"
    fi
    
    review_file_name="$today-review.md"
    review_filepath="$REVIEW_FOLDER/$review_file_name"
    
    echo "# Tasks completed between $seven_days_ago and $today"

    for (( i=0; i<7; i=i+1 )); do
        entry_date=$(date -d "-$i day" "+%Y-%m-%d")

        get_done_tasks "$entry_date"
        
        if [[ -n "$completed_tasks" ]]; then
            head -n 1 "$filepath" >> "$review_filepath"
            printf "%s" "$completed_tasks" >> "$review_filepath"
            printf "\n\n" >> "$review_filepath"
        fi
    done

    echo
    echo "Review written to: $review_filepath"

}

get_done_tasks () {
    if [[ "$#" != 1 ]]; then
        entry_date="$today"
    else
        entry_date="$1"
    fi
    check_paths "$entry_date"
    completed_tasks=$(grep -e "^x\s" "$filepath")
    
    if [[ -n "$completed_tasks" ]]; then
        echo
        printf "$BOLD"
        head -n 1 "$filepath"
        printf "$NORMAL"
        echo $completed_tasks
    fi
    return
}


# function to check all paths of given date work
check_paths () {

    # set todays today if no args passed
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

    # if data folder doesn't exist then make it
    if [[ ! -d "$DATA_FOLDER" ]]; then
        echo "Creating data folder"
        mkdir "$DATA_FOLDER"
    fi

    # if habits file doesn't exist
    # create empty habits file
    if [[ ! -e "$HABITS_FILE" ]]; then
        echo "Creating new habits file"
        touch "$HABITS_FILE"
        echo -e "## habits\n" > "$HABITS_FILE"
    fi

    # format will be yyyy-mm-dd-jrnl.md
    filename="$entry_date-jrnl.md"

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
        -a | -add | --add | add)
            add_to_file "$2" "$3"
            exit
            ;;
        -d | --date | -date | date)
            # usage: tj --date yyyy-mm-dd
            # view given entry
            entry_date="$2"
            ;;
        do | --do | -do)
            complete_task "$2"
            exit
            ;;
        -e | -edit | --edit | edit) 
            edit=1
            ;;
        -habits | habits | --habits)
            edit_habits
            exit
            ;;
        -h | --help | -help)
            help
            exit
            ;;
        -k | --key)
            echo "Key file: "
            view_key_file
            exit
            ;;
        -r | -review | review)
            review_past_week
            exit
            ;;
        -s | ls | -ls | search)
            # expected usage is
            # tj search-term optional-date-to-search
            search_entry "$2" "$3"
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

if [[ -n "$entry_date" ]]; then
    check_valid_date "$entry_date"
else
    entry_date="$today"
fi

# check if edit or view
if [[ -n "$edit" ]]; then
    check_paths "$entry_date"
    edit_file
else
    check_paths "$entry_date"
    view_file
fi
