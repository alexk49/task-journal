#!/bin/bash

# task-journal.sh: command line wrapper for bullet journaling in text editor

# globals
tj_dir_loc="$(dirname "$0")"

TJ_CFG_FILE="$tj_dir_loc/tj.cfg"

if [[ -f "$TJ_CFG_FILE" ]]; then
    source "$TJ_CFG_FILE"
else
    echo "No config file found. Please create config file named tj.cfg"
    exit
fi


# unused colours kept in case of change
# thanks - https://stackoverflow.com/questions/4332478/read-the-current-text-color-in-a-xterm/4332530#4332530
# and thanks - https://unix.stackexchange.com/questions/269077/tput-setaf-color-table-how-to-determine-color-codes
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
GREY=$(tput setaf 8)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
UNDERLINE=$(tput smul)

# get todays date as file name
today=$(date +"%Y-%m-%d")
yesterday=$(date -d '-1 day' '+%Y-%m-%d')

TOP_HEADING="/^# task journal [0-9]{4}-[0-9]{2}-[0-9]{2}$"

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

# to add to current file
tj -a "text for task to add"
tj add "text for task to add"

# add to alternate file
tj [alt-file] add "text to add"

Alternate files can be defined via:

# alternate date entry:
tj -d yyyy-mm-dd

# habits file
tj -hab
tj -habits

# key file
tj -k
tj -key

# reminders file
tj -rem
tj -reminders

# entry for yesterday
# or previous entry if yesterday file does not exist
tj -y
tj -yesterday

Any of the below actions can be mixed with any of the alternate files.

# mark item as complete by line number
tj -do ITEM#

# open file in specified editor
tj -e

# move item from one file to another
tj -mv source-file ITEM# [OPT destfile]
tj -mv source-file ITEM# [OPT destfile]

Move allows you to move task from todo to today file. Or from today to todo.

Move from today file to todo file:
tj -mv today item#

Move from todo file to today file:
tj -mv -td item#

If source is todo then destination is today file. If today file is source then todo is destination."

# search file
tj ls "search term"
tj search "search term"

The following are one off actions:

# open today entry alongside todo list
tj -dr
tj -dayreview

# open today entry, todo.txt, projects file, and someday file in editor
tj -wr
tj -weekreview

# show any uncompleted task items in today file
tj -std
tj stilltd

# view all tasks completed within past week
# this will output to terminal as well as creating a file in the reviews folder
tj -r
tj -review

_EOF_
}


check_valid_date () {
    # if invalid date or no entry date set
    # then entry date is today

    entry_date="$1"
    
    # check valid format
    if [[ ! "$entry_date" =~ ^[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}$ ]]; then 
        echo "Invalid format date given. Format must be: yyyy-mm-dd"
        return 1
    fi

    # redirect date check stderr and stdout to dev/null
    date -d "$entry_date" 2>&1>/dev/null

    # if exit code is 1 invalid date otherwise fine
    if [[ "$?" -eq 1 ]]; then
        echo "Invalid date"
        return 1
    fi
}


add_defaults () {
    # add default headings and undone tasks from previous day

    if [[ "$#" != 1 ]]; then
        entry_date="$today"
    else
        entry_date="$1"
    fi

    echo "Writing defaults to new file"

    get_previous_entry "$entry_date"

    echo "Previous entry found: $(basename $previous_filepath)"
    
    if [[ -e "$previous_filepath" ]]; then
        # inverse grep done tasks, headings, and blank lines
        remainingtasks=$(grep -Ev "^-+|^#+|^x\s|^-\s|^$|^o\s|^~\s" "$previous_filepath") 

        echo "adding outstanding tasks from previous entry"
        # this uses a here switch
        # to pass the remaining tasks variable to standard input
        # this is then added in after the match
        sed -i -E "/^# task journal [0-9]{4}-[0-9]{2}-[0-9]{2}$/r/dev/stdin" "$filepath" <<<"$remainingtasks"

        check_reminders_file_exists
        check_for_reminders

    else
        :
    fi
}


check_for_reminders () {
    # loop through reminders file
    # if due date is today, then add to newly created file
    echo "checking for reminders"

    linecount=0

    while IFS="" read -r line || [[ -n "$line" ]]
    do
        linecount=$((++linecount))

        if [[ "$line" =~ due:$today ]]; then
            # item due today
            item="$linecount"

            sed -i -E "$TOP_HEADING/a $line" "$filepath"
            
            # delete from original
            sed -i "$item"d "$REMINDERS_FILE"
        fi
    done < "$REMINDERS_FILE"
}


add_to_file () {
    addition="$1"
    echo "adding $addition to $filepath"
    echo "$addition" >> "$filepath"
    return

}

check_if_number () {
    # check arg is number
    if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Task must be passed as a number" >&2
        usage
        exit 1
    else
        return 0
    fi
}

complete_task () {
    # check args have been passed
    if [[ "$#" != 1 ]]; then
        echo "Invalid usage. Must provide line number of task to complete"
        usage
        exit 1
    fi
    
    check_if_number "$1"

    echo "Completing item number: $item from $filepath"
    
    task=$(sed -n "${item}p;" "$filepath")
    # check if task already done
    check=$(echo "$task" | grep -E "^x .*")
    
    echo "Task: $task"

    if [[ -n "$check" ]]; then
        echo "already marked as complete"
        return 1
    else
        echo "marked as complete"
        # taken from todo.txt
        # | used as variable contains /
        sed -i "${item}s|^|x |" "$filepath" 
        return 0
    fi
}

move_task () {

    #  move_task "$sourcefile" "$item" "$destfile"

    if [[ "$sourcefile" == "td" ]] || [[ "$sourcefile" == "todo" ]]; then
        sourcefile="$TODO_FILE"
        entry_date="$today"
        check_paths "$entry_date"
        destfile="$filepath"
    elif [[ "$sourcefile" == "reminders" ]]; then        
        sourcefile="$REMINDERS_FILE"
        entry_date="$today"
        check_paths "$entry_date"
        destfile="$filepath"
    elif [[ "$sourcefile" == "today" ]] || [[ "$sourcefile" == "$today" ]]; then        
        entry_date="$today"
        check_paths "$entry_date"
        sourcefile="$filepath"
        destfile="$TODO_FILE"
    else
        move_task_usage="Invalid options. Move allows you to move task from todo to today file. Or from today to todo.

    Move usage: tj -mv source item#

    Move from today file to todo file:
    tj -mv today item#
    
    Move from todo file to today file:
    tj -mv bl item#
    
If source is todo then destination is today file. If today file is source then todo is destination."

        echo "$move_task_usage"
        exit 1
    fi

    check_if_number "$item"

    echo "moving item number: $item from ${sourcefile##*/} to ${destfile##*/}"
    
    task=$(sed -n "${item}p;" "$sourcefile")
        
    echo "Task: $task"
    
    if [[ "$destfile" == "$TODO_FILE" ]]; then
        echo "$task" >> "$destfile"
    else
        # destfile is today file
        add_to_file "$task"
    fi

    # delete moved task from original
    sed -i "$item"d "$sourcefile"
}

edit_file () {
    "$EDITOR" "$filepath"
    return 0
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

        linecount=$((++linecount))

        # apply colour codings
        # must reset to normal at end

        if [[ "$line" =~ ^# ]]; then
            # put headings in bold and colour red
            output_line="$BOLD$RED$line$NORMAL"
        elif [[ "$line" =~ ^x ]]; then
            # mark done tasks in bold grey
            output_line="$BOLD$GREY$line$NORMAL"
        elif [[ "$line" =~ ^~ ]]; then
            # mark no longer needed tasks in grey
            output_line="$GREY$line$NORMAL"
       elif [[ "$line" =~ ^! ]]; then
            # set marker of priority task in bold green
            marker="${line:0:1}"
            remainder="${line:1}"
            output_line="$BOLD$GREEN$marker$NORMAL$remainder"
       elif [[ "$line" =~ ^\* ]]; then
            # set task bullet point in green
            marker="${line:0:1}"
            remainder="${line:1}"
            output_line="$GREEN$marker$NORMAL$remainder"
       elif [[ "$line" =~ ^- ]]; then
            # put note marker in magenta/purple
            marker="${line:0:1}"
            remainder="${line:1}"
            output_line="$BOLD$MAGENTA$marker$NORMAL$remainder"
       elif [[ "$line" =~ ^o ]]; then
            marker="${line:0:1}"
            remainder="${line:1}"
            output_line="$YELLOW$marker$NORMAL$remainder"
        elif [[ "$line" =~ ^\([Aa]\) ]]; then
            output_line="$BOLD$BLUE$line$NORMAL"
        else
            output_line="$line"
        fi

        # adjust line length for single digits
        # and indent lines for better display
        if [[ "$linecount" -lt 10 ]]; then
            output_line="      $linecount $output_line"
        else
            output_line="     $linecount $output_line"
        fi

        printf "%s\n" "$output_line"

    done < "$filepath"
    return 0
}


search_entry () {
    # usage: search-term entry-date
    search_term="$1"

    printf "$BOLD"
    head -n1 "$filepath"
    printf "$NORMAL"
    echo
    grep --color='auto' "$search_term" "$filepath"
    return 0
}


search_past_week () {
    search_term="$1"
    # loop through past 7 days
    for (( i=0; i<7; i=i+1 )); do
        entry_date=$(date -d "-$i day" "+%Y-%m-%d")

        check_paths "$entry_date"

        if [[ "$?" -eq 1 ]]; then
            echo "No file found for: $entry_date"
            continue
        else
            printf "$BOLD"
            head -n1 "$filepath"
            printf "$NORMAL"
            echo
            grep --color='auto' "$search_term" "$filepath"
        fi
    done

    return 0
}


# quicky view key file
check_key_file_exists () {
    if [[ ! -e "$KEY_FILE" ]]; then
        # indentation deliberately removed
        # to avoid breaking here switch
        cat << _EOF_ >> "$KEY_FILE" 
classifications:

# heading
## sub heading
* task
- note
o event 

statuses:

(A) * prioritied task with priority levels
! * prioritised task
> * task to be moved to futurelog/todo
x * done task
~ * no longer needed task
* task with tags +project @context
/ on hold task

todo specific:

* daily task rec:+1d
* every weekday task rec:+1b
* recurring task rec:+1w due:2023-04-13
* task with due date due:2023-08-09
_EOF_
    else
        return 0
    fi
}


# takes entry date as arg
# and gives back last entry
get_previous_entry () {
    current_entry=$1
    count=1
    while [[ "$count" -le 21 ]]; do
        previous=$(date --date="${current_entry} -${count} day" "+%Y-%m-%d")

        previous_year=${previous:0:4}
        previous_month=$(date --date="$previous" '+%b')

        # format will be yyyy-mm-dd-jrnl.txt
        previous_filename="$previous-jrnl.txt"

        previous_filepath="$JOURNALS_FOLDER/$previous_filename"

        if [ -f "$previous_filepath" ]; then
            return 0
        else
            count=$((count + 1)) 
        fi
    done

    # if no file found return nothing
    echo "No previous entry found within last week"
    return 1
}


review_past_week () {
    # create review file of done tasks from past week
    # loop through past 7 days

    seven_days_ago=$(date -d '-7 day' '+%Y-%m-%d')
    
    month=$(date --date="$seven_days_ago" '+%b')
    
    if [[ ! -d "$REVIEW_FOLDER" ]]; then
        mkdir -p "$REVIEW_FOLDER"
    fi
    
    review_file_name="$today-review.txt"
    review_filepath="$REVIEW_FOLDER/$review_file_name"
    
    echo "Tasks completed between $seven_days_ago and $today"

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
    return 0

}


get_done_tasks () {
    if [[ "$#" != 1 ]]; then
        entry_date="$today"
    else
        entry_date="$1"
    fi

    check_paths "$entry_date"

    if [[ "$?" -eq 1 ]]; then
        return 1
    fi

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

# get oustanding to do tasks
show_still_todos () {
    entry_date="$today"
    
    check_paths "$entry_date"

    if [[ "$?" -eq 1 ]]; then
        file_does_not_exist
        return 1
    fi

    head -n1 "$filepath"
    echo
    printf "%s%stodo:%s\n" "$BOLD" "$RED" "$NORMAL"

    #grep --color='auto' -n -Ev "^[0-9]+:x\s.*$|^[0-9]+#+.*$|^[0-9]+:-.*$|^[0-9]+:$|^[0-9]+:o\s$|^[0-9]+:~\s$" "$filepath"
    grep -n -Ev "^x\s.*$|^#+.*$|^-.*$|^$|^o\s$|^~\s$" "$filepath"
    return
}

# function to check all paths of given date work
check_paths () {

    # set todays today if no args passed
    if [[ "$#" != 1 ]]; then
        entry_date=$today
    else
        entry_date=$1
    fi
    year=${entry_date:0:4}
    month=$(date --date="$entry_date" '+%b')
    # check if a folder named journal exists
    # if not make it
    if [ ! -d "$JOURNALS_FOLDER" ]; then
        echo "Default journal folder not found."
        echo "Creating $JOURNALS_FOLDER"
        mkdir -p "$JOURNALS_FOLDER"
    fi

    # format will be yyyy-mm-dd-jrnl.txt
    filename="$entry_date-jrnl.txt"

    filepath="$JOURNALS_FOLDER/$filename"
    
    if [[ ! -e "$filepath" ]]; then
        # if file does not exist return 1
       return 1
    else
       return 0
    fi
}


check_reminders_file_exists() {
    if [[ ! -e "$REMINDERS_FILE" ]]; then
        touch "$REMINDERS_FILE"
    fi
}


check_habits_file_exists () {
    # if habits file doesn't exist
    # create empty habits file
    if [[ ! -e "$HABITS_FILE" ]]; then
        echo "Creating new habits file"
        touch "$HABITS_FILE"
        echo -e "## habits\n" > "$HABITS_FILE"
    fi
}


create_file () {
    # used to create files after check paths run
    filepath="$1"
    echo "# task journal $entry_date" > "$filepath"
    add_defaults "$entry_date"
    return
}

file_does_not_exist () {
    echo "Error: $filename does not exist"

    if [[ "$entry_date" == "$today" ]]; then
        echo "To make today file run task-journal.sh with no args"
    fi
    return
}


check_todo_exists () {
    if [[ ! -e "$TODO_FILE" ]]; then
        echo "Creating $TODO_FILE"
        touch "$TODO_FILE"
    fi
    return
}

# handle args
# loop continues whilst $1 is not empty

# ideal usage:
# tj file action parameters

while [[ -n "$1" ]]; do
    case "$1" in
        -a | -add | --add | add)
            action="add"
            addition="$2"
            ;;
        -dr | -dayreview)
            action="review"
            review_type="day"
            ;;
        -d | --date | -date | date)
            # usage: tj --date yyyy-mm-dd
            # view given entry
            entry_date="$2"
            ;;
        do | --do | -do)
            action="complete"
            item="$2"
            #complete_task "$2"
            ;;
        -e | -edit | --edit | edit) 
            action="edit"
            edit=1
            ;;
        -habits | -hab | habits)
            filepath="$HABITS_FILE"
            check_habits_file_exists
            ;;
        -h | --help | -help)
            help
            exit
            ;;
        -k | -key | key)
            filepath="$KEY_FILE"
            check_key_file_exists
            ;;
        -mv | -m | --move)
            # usage:
            # tj -m source-file item# destfile 
            # tj -m bl 5 today
            # tj -m today 5 bl
           action="move" 
           sourcefile="$2"
           item="$3"
           destfile="$4"
           ;;
        -qr | -quickreview)
            action="review"
            review_type="quick"
            ;;
        -rem | -reminders)
            filepath="$REMINDERS_FILE"
            check_reminders_file_exists
            ;;
        -r | -review | review)
            review_past_week
            exit
            ;;
        -s | ls | -ls | search)
            action="search"
            search_term="$2"
            ;;
        -std | stilltd)
            show_still_todos "$2"
            exit
            ;;
        -td | -todo)
            check_todo_exists
            filepath="$TODO_FILE"
            ;;
        -weekreview | -wr)
            action="review"
            review_type="week"
            ;; 
        -y | yesterday)
            entry_date="$yesterday"
            ;;
    esac
    shift
done


if [[ -n "$filepath" ]] && [[ -z "$entry_date" ]]; then
    # filepath assigned to global filepath
    # do nothing
    :
elif [[ -n "$entry_date" ]]; then
    check_valid_date "$entry_date"
    if [[ "$?" -eq 1 ]]; then
        exit
    fi

    check_paths "$entry_date"

    if [[ "$?" -eq 1 ]]; then
        file_does_not_exist
        exit
    fi
else
    entry_date="$today"
    check_paths "$entry_date"

    if [[ "$?" -eq 1 ]]; then
        create_file "$filepath"
        echo
    fi
fi

# actions = add, do, edit, review, search, view

if [[ "$action" == "add" ]]; then
    add_to_file "$addition" "$heading"
    exit
elif [[ "$action" == "complete" ]]; then
    complete_task "$item"
    exit
elif [[ "$action" == "edit" ]]; then
    edit_file
    exit
elif [[ "$action" == "search" ]]; then
    search_entry "$search_term"
    exit
elif [[ "$action" == "move" ]]; then
    move_task "$sourcefile" "$item" "$destfile"
    exit
elif [[ "$action" == "review" ]] && [[ "$review_type" == "quick" ]]; then
    # check if notes file exists
    # created by quick-note.sh script

    notes_filepath="$JOURNALS_FOLDER/$today-notes.txt"
    if [[ -e "$notes_filepath" ]]; then
        "$EDITOR" -O "$filepath" "$notes_filepath" -c "split $TODO_FILE"
    else
        "$EDITOR" -O "$filepath" "$TODO_FILE"
    fi
    exit
elif [[ "$action" == "review" ]] && [[ "$review_type" == "day" ]]; then
    "$EDITOR" -O "$filepath" "$TODO_FILE"
    exit
elif [[ "$action" == "review" ]] && [[ "$review_type" == "week" ]]; then
    "$EDITOR" -O "$filepath" "$TODO_FILE" -c "split $PROJECTS_FILE" -c 'wincmd l' -c "split $SOMEDAY_FILE"
    exit
else
    # default is view file
    view_file
    exit
fi
