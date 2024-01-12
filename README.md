# Task Journal

A plain text bullet journal for tracking habits, tasks and note taking through bash and the editor of your choice.

## First time setup

Before use the example-tj.cfg must be edited to tj.cfg and updated with the desired filepaths for key files.

## Basic Usage

Expected usage is:
```
task-journal.sh [file] [action] [parameters]
```

The default file is the current day's entry. The default action is to view the file in your terminal.

```
task-journal.sh
```

For ease of use you can set an alias for task-journal.sh:

```
alias tj="PATH/TO/task-journal.sh"
```

The file and action can be specified with args. For example:

```
# open a file for yesterday
task-journal.sh -y -e

task-journal.sh -yesterday -edit
```

Full usage examples can be viewed by:

```
tj -help
```

Further examples are also included [below](#Further).

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
another task

statuses:

(A) prioritied task with priority levels
!prioritised task
x done task
~ no longer needed task
task with tags +project @context
/ on hold task

todo specific:

* daily task rec:+1d
* every weekday task rec:+1b
* recurring task rec:+1w due:2023-04-13
* task with due date due:2023-08-09

```

## Journal Entries

Upon creation you will get a date stamped file. Any outstanding tasks from the previous entry will be passed across to the new file, everything else will remain as part of the original entry.

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

## Inspirations/alternative projects

This project was mainly undertaken through wanting a project to learn/practise bash. But, also as a way to implement a deliberately, simple and bare bones journal method for tracking tasks, and quick notes about the day. The task section takes a lot of inspiration (steals) from the todo.txt format.

[How to Bullet Journal](https://www.youtube.com/watch?v=fm15cmYU0IM) video by "inventor" of the bullet journal method.

[todo.txt](https://github.com/todotxt/todo.txt)

[Plain text journaling vim](https://peppe.rs/posts/plain_text_journaling/) found via a [hackernews post](https://news.ycombinator.com/item?id=36390405).

[Bash Journaling](https://jodavaho.io/posts/bash-journalling.html) and [Bullet Journaling](https://jodavaho.io/posts/bullet-journalling.html).

[Getting things done](https://gettingthingsdone.com/)

[Plain text productivity](https://plaintext-productivity.net/)

[Martin Pitt synced plaintext TODO notes](https://piware.de/post/2020-09-26-todo-notes/)

## Further Usage Examples

All given examples, assume an alias has been made as tj.

```
# to add to current file
tj -a "text for task to add"
tj -add "text for task to add"

# add to alternate file
tj [alt-file] -add "text to add"
```

Alternate files can be defined via:
```
# alternate date entry:
tj -d yyyy-mm-dd

# key file
tj -k
tj -key

# reminders file
tj -rem
tj -reminders

# todo file
tj -td
tj -todo

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

If no destination file is given then defaults are only set for the todo file and the today file.

If source is todo then destination is today file. If today file is source then todo is destination.

```
Move from today file to todo file:
tj -mv today item#

Move from todo file to today file:
tj -mv -td item#
```

Search will default to the today entry:

```
# search file
tj -s "search term"
tj ls "search term"
tj search "search term"
```

But a file can be specified with:

```
# search reminder file
tj -rem -s "search term"
```

```
# show any outstanding task items in today file
tj -o
tj -std
tj stilltd

# view finished tasks for past 7 days
tj -f 7
tj -finished 7

```

## Testing

All tests have been written using the [bats test framework](https://github.com/bats-core/bats-core). Only the bats-core module is required.

Tests can be run manually from the root dir with:
```
bats test/test.bat
```
