#!/bin/bash

# task-journal.sh: command line wrapper for bullet journaling in text editor

# thanks - https://stackoverflow.com/questions/4332478/read-the-current-text-color-in-a-xterm/4332530#4332530
# and thanks - https://unix.stackexchange.com/questions/269077/tput-setaf-color-table-how-to-determine-color-codes
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
GREY=$(tput setaf 8)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

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

task-journal.sh [file] [action] [parameters]

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

If no destination file is given then defaults are only set for the todo file and the today file.

If source is todo then destination is today file. If today file is source then todo is destination.

# Move from today file to todo file:
tj -mv today item#

# Move from todo file to today file:
tj -mv -td item#

# open all tj files in editor:
tj -r
tj -rev
tj -review

# search file
tj -s "search term"
tj ls "search term"
tj search "search term"

# search reminder file
tj -rem -s "search term"

# show any outstanding task items in today file
tj -o
tj -std
tj stilltd

# view finished tasks for past 7 days
tj -f 7
tj -finished 7

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

    if [[ -e "$previous_filepath" ]]; then

        echo "Previous entry found: $(basename $previous_filepath)"
        # inverse grep done tasks, headings, and blank lines
        remainingtasks=$(grep -Ev "^-+|^#+|^x\s|^-\s|^$|^o\s|^~\s" "$previous_filepath")

        echo "adding outstanding tasks from previous entry"
        # this uses a here switch
        # to pass the remaining tasks variable to standard input
        # this is then added in after the match
        sed -i -E "/^# task journal [0-9]{4}-[0-9]{2}-[0-9]{2}$/r/dev/stdin" "$filepath" <<<"$remainingtasks"

        check_reminders_file_exists
        check_for_reminders "$filepath"
    fi
}


check_for_reminders () {

    # loop through reminders file
    # if due date is today, then add to newly created file
    # filepath is file reminderes will be moved to
    filepath="$1"
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
    if [[ "$#" != 2 ]]; then
        echo "Invalid usage. Must provide line number of task to complete"
        usage
        exit 1
    fi

    filepath="$1"
    item="$2"

    check_if_number "$item"

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

assign_dest_file () {
    # check destination file used in
    # move task function is valid
    # destfile will either be:
    # REMINDERS_FILE TODO_FILE TODAY_FILE
    destfile="$1"
    default_destfile="$2"


    if [[ "$destfile" == "reminders" ]] || [[ "$destfile" == "rem" ]]; then
        destfile="$REMINDERS_FILE"
    elif [[ "$destfile" == "todo" ]] || [[ "$destfile" == "td" ]]; then
        destfile="$TODO_FILE"
    elif [[ "$destfile" == "today" ]] || [[ "$destfile" == "$today" ]]; then
        entry_date="$today"
        check_paths "$entry_date"
        destfile="$filepath"
    else
        destfile="$default_destfile"
    fi

}

move_task () {

    #  move_task "$sourcefile" "$item" "$destfile"

    sourcefile="$1"
    item="$2"
    destfile="$3"

    if [[ "$sourcefile" == "td" ]] || [[ "$sourcefile" == "todo" ]]; then
        sourcefile="$TODO_FILE"
        entry_date="$today"
        check_paths "$entry_date"
        default_destfile="$filepath"
    elif [[ "$sourcefile" == "reminders" ]] || [[ "$sourcefile" == "rem" ]]; then
        sourcefile="$REMINDERS_FILE"
        entry_date="$today"
        check_paths "$entry_date"
        default_destfile="$filepath"
    elif [[ "$sourcefile" == "today" ]] || [[ "$sourcefile" == "$today" ]]; then
        entry_date="$today"
        check_paths "$entry_date"
        sourcefile="$filepath"
        default_destfile="$TODO_FILE"
    else
        move_task_usage="Invalid options. Move allows you to move task from todo to today file. Or from today to todo.

    Move usage: tj -mv source item#

    Move from today file to todo file:
    tj -mv today item#

    Move from todo file to today file:
    tj -mv td item#

If source is todo then default destination is today file. If today file is source then todo is default destination.

Valid args for files are:

today or yyyy-mm-dd for today file

rem or reminders for reminders file

td or todo for todo file
    "

        echo "$move_task_usage"
        exit 1
    fi

    assign_dest_file "$destfile" "$default_destfile"

    check_if_number "$item"

    echo "moving item number: $item from ${sourcefile##*/} to ${destfile##*/}"

    task=$(sed -n "${item}p;" "$sourcefile")

    echo "Task: $task"

    echo "$task" >> "$destfile"

    # delete moved task from original
    sed -i "$item"d "$sourcefile"
}

edit_file () {
    filepath="$1"
    "$EDITOR" "$filepath"
    return 0
}


view_file () {
    # loop throuh file to allow colour highlighting
    filepath="$1"
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
       elif [[ "$line" =~ ^o[[:space:]] ]]; then
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
    filepath="$2"

    grep --color='auto' "$search_term" "$filepath"
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
another task

statuses:

(A) prioritied task with priority levels
! prioritised task
x done task
~ no longer needed task
task with tags +project @context
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


get_previous_entry () {

    # takes entry date as arg
    # and gives back last entry
    current_entry=$1
    count=1
    while [[ "$count" -le 21 ]]; do
        previous=$(date --date="${current_entry} -${count} day" "+%Y-%m-%d")

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
}


show_still_todos () {
    # get oustanding tasks
    entry_date="$today"

    check_paths "$entry_date"

    if [[ "$?" -eq 1 ]]; then
        file_does_not_exist "$filename"
        return 1
    fi

    printf "%s%soutstanding tasks:%s\n" "$BOLD" "$RED" "$NORMAL"

    grep -n -Ev "^x\s.*$|^#+.*$|^-.*$|^$|^o\s$|^~\s$" "$filepath"
}


check_paths () {

    # check all paths of given date work

    # set todays today if no args passed
    if [[ "$#" != 1 ]]; then
        entry_date=$today
    else
        entry_date=$1
    fi

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


create_file () {
    # used to create files after check paths run
    filepath="$1"
    entry_date="$2"
    echo "# task journal $entry_date" > "$filepath"
    add_defaults "$entry_date"
    return 0
}

file_does_not_exist () {
    # filename might be unassigned
    # when running tests
    if [[ -z "$filename" ]]; then
        filename="$1"
    fi

    echo "Error: $filename does not exist"

    if [[ "$entry_date" == "$today" ]]; then
        echo "To make today file run task-journal.sh with no args"
    fi
}


check_todo_exists () {
    if [[ ! -e "$TODO_FILE" ]]; then
        echo "Creating $TODO_FILE"
        touch "$TODO_FILE"
    fi
    return
}


view_finished_tasks () {
    num_days="$1"

    if [[ -z "$num_days" ]]; then
        num_days=1
    fi

    check_if_number "$num_days"

    # change dir to JOURNALS_FOLDER first
    # so that grep output only includes base file names
    cd "$JOURNALS_FOLDER"
    find . -type f -iname "*-jrnl.txt" -mtime -$num_days -print0 | xargs -0 grep --color=auto -E "^x\s"

}


run_main () {

    tj_dir_loc="$(dirname "$0")"

    TJ_CFG_FILE="$tj_dir_loc/tj.cfg"

    if [[ -f "$TJ_CFG_FILE" ]]; then
        source "$TJ_CFG_FILE"
    else
        echo "No config file found. Please create config file named tj.cfg"
        exit
    fi

    # handle args
    # loop continues whilst $1 is not empty

    # expected usage:
    # tj file action parameters

    while [[ -n "$1" ]]; do
        case "$1" in
            -a | -add | --add | add)
                action="add"
                addition="$2"
                ;;
            -d | --date | -date | date)
                # usage: tj --date yyyy-mm-dd
                # view given entry
                entry_date="$2"
                ;;
            do | --do | -do)
                action="complete"
                item="$2"
                ;;
            -e | -edit | --edit | edit)
                action="edit"
                ;;
            -f | -finished | --finished)
                action="finished"
                num_days="$2"
                view_finished_tasks "$num_days"
                exit
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
            -rem | -reminders)
                filepath="$REMINDERS_FILE"
                check_reminders_file_exists
                ;;
            -r | -rev | -review)
                action="review"
                ;;
            -s | ls | -ls | -search)
                action="search"
                search_term="$2"
                ;;
            -o | -std | -stilltd)
                show_still_todos "$2"
                exit
                ;;
            -td | -todo)
                check_todo_exists
                filepath="$TODO_FILE"
                ;;
            -y | yesterday | -yesterday)
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
            file_does_not_exist "$filename"
            exit
        fi
    else
        entry_date="$today"
        check_paths "$entry_date"

        if [[ "$?" -eq 1 ]]; then
            create_file "$filepath" "$entry_date"
            echo
        fi
    fi

    # actions = add, do, edit, search, view

    if [[ "$action" == "add" ]]; then
        add_to_file "$addition"
        exit
    elif [[ "$action" == "complete" ]]; then
        complete_task "$filepath" "$item"
        exit
    elif [[ "$action" == "edit" ]]; then
        edit_file "$filepath"
        exit
    elif [[ "$action" == "search" ]]; then
        search_entry "$search_term" "$filepath"
        exit
    elif [[ "$action" == "move" ]]; then
        move_task "$sourcefile" "$item" "$destfile"
        exit
    elif [[ "$action" == "review" ]]; then
        "$EDITOR" -O "$filepath" "$TODO_FILE" -c "split $REMINDERS_FILE" -c 'wincmd l' -c "split $KEY_FILE"
        exit
    else
        # default is view file
        view_file "$filepath"
        exit
    fi

}

# only run main function if running script directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  run_main "$@"
fi
