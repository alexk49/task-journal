# Task Journal 

A plain text bullet journal for tracking habits, tasks and note taking through bash and the editor of your choice.

The app itself is still a work in a progress so changes are being made and some of the documentation is not yet complete or fully up to date.

## First time setup

Before use the example-tj.cfg must be edited to tj.cfg and updated with the desired filepaths for key files.

## Basic Usage 

Expected usage is:
```
task-journal.sh [file] [action] [parameters]
```

The default file is the current day's entry. The default action is to view the view in your terminal.

```
task-journal.sh
```

For ease of use you can set an alias for task-journal.sh:

```
alias tj="PATH/TO/task-journal.sh"
```

The file and action can be customised, for example, the following will open the last entry in your task journal in your defined editor:
```
# open a file for yesterday
task-journal.sh yesterday -e
```

Further usage examples can be viewed by:
```
tj -help
```

Further examples are also included [below](##Further).


## Data files

### Key file

Task journal uses similar keys to markdown, todo.txt, and the bullet journal method. To quickly review the keys in use run:

```
tj -key
```

These are the defaults that are in use. You can customise this as much as you want and use whatever feels most natural to you for your notes.
```
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

```

## Journal Entries

Upon creation you will get a date stamped file. Any outstanding tasks from the previous entry will be passed across to the new file.

If you have daily notes to make, they should be prepended with a dash ("-"), as these will not pass over.

Tasks that have been completed should be marked with an x ("x "), these will also not pass over.

Using +tags and @context markers at the end of the task, priority ratings like (A), can make the tasks section easier to search. See the [todo.txt primer](https://github.com/todotxt/todo.txt) for more details. Only a very basic implementation of some of the features has been done for task journal.

## todo file

You should keep a todo file. This should only contain actionable tasks intended to be carried out within the next month.

This should just be your regular todo.txt file, except it should not contain any tasks with due dates which should instead go into the reminders file.

## Reminders file

The reminders file works the same as a todo.txt file so all the same markers should be used. However, anything put into the reminders file should contain a due date. Using the format due:yyyy-mm-dd

Upon creation of your daily task-journal entry, any reminder tasks due for that day will be passed across.

Tasks with due dates are deliberately seperated from the todo.txt file as it helps keep the file smaller and more manageable, and means that anything that doesn't need to be done until a particular date can be completely forgotten about until that date.

## Other files

Links for a projects file and someday file are optional. These can be opened as part of a weekly or daily review, and are recommended ways of structuring notes used in the Getting Things Done (GTD) method.

These are incorporated as part of the weekly review which opens:
* The current day's task journal entry
* todo.txt file
* Projects file
* Someday file

## Review

You can view all tasks done over the past week by running:
```
# see whole week
task-journal.sh review
```

Review files are kept in a seperate folder called reviews and are datestamped with the day they are run.

### Habits file

A habits file can used for quick reference via:

```
tj -habits
```

This is not incorporated into the daily logs but is just made to be easily accessible.

``` example habits file
habits
Main habit
Main habit 2
* sub habit of habit 2
* another sub habit of habit 2
```

## Inspirations/alternative projects

This project was mainly undertaken through wanting a project to learn/practise bash. But, also as a way to implement a deliberately, simple and bare bones journal method for tracking habits, tasks, and quick notes about the day. The task section takes a lot of inspiration (steals) from the todo.txt format.

[How to Bullet Journal](https://www.youtube.com/watch?v=fm15cmYU0IM) video by "inventor" of the bullet journal method.

[todo.txt](https://github.com/todotxt/todo.txt)

[Plain text journaling vim](https://peppe.rs/posts/plain_text_journaling/) found via a [hackernews post](https://news.ycombinator.com/item?id=36390405).

[Bash Journaling](https://jodavaho.io/posts/bash-journalling.html) and [Bullet Journaling](https://jodavaho.io/posts/bullet-journalling.html).

[Getting things done](https://gettingthingsdone.com/)

## Further Usage Examples

All given examples, assume an alias has been made as tj.

```
# to add to current file
tj -a "text for task to add"
tj add "text for task to add"

# add to alternate file
tj [alt-file] add "text to add"
```

Alternate files can be defined via:
```
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
```

Any of the below actions can be mixed with any of the alternate files.

```
# mark item as complete by line number
tj -do ITEM#

# open file in specified editor
tj -e

# move item from one file to another
tj -mv source-file ITEM# [OPT destfile]
tj -mv source-file ITEM# [OPT destfile]
```

Move allows you to move task from todo to today file. Or from today to todo.

```
Move from today file to todo file:
tj -mv today item#

Move from todo file to today file:
tj -mv -td item#
```  

If source is todo then destination is today file. If today file is source then todo is destination."

```
# search file
tj ls "search term"
tj search "search term"
```

The following are one off actions:

```
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
```
