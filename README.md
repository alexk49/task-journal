# Task Journal 

A plain text bullet journal for tracking habits, tasks and note taking through bash and the editor of your choice.

## Basic Usage 

The default with no args passed will open a .md file with today's date stamp, and all the default headings added.

```
task-journal.sh
```

If you need the day before/the previous entry, you can pass:

```
# open a file for yesterday
journal.sh yesterday
```

## Data files

### Key file

This is a reminder for how to keep track of the status of tasks. The only markers are to display whether a task has been done or is in progress. This is kept track of with \ and x as markers for in progress and done. A task with no markers has not yet been actioned.

```
task with no status is to do
x example done task
\ in progress task
```

### Habits file

A habits file is created by default. This is used to track every day tasks. The recommend structure should follow:

``` example habits file
habits
Main habit
Main habit 2
* sub habit of habit 2
* another sub habit of habit 2
```

Sub habits are for if you have more detailed instructions for your habit. For example, your main habit might be "Play the piano", with a sub habit of "Practice Scales".

The habits you list in this file will be added into every entry of your journal.

## Journal Entries

Each journal entry will consist of three sections: habits, tasks, and notes.

### Tasks

These are to do items. Anything in the tasks section not marked as finished will be carried over to the next day on creation.

Using +tags at the end of the task, priority ratings like (A), and due dates like due:2023-05-01, can make the tasks section easier to search. See the [todo.txt primer](https://github.com/todotxt/todo.txt) for more details. Only a very basic implementation of some of the features has been done for task journal.

### Notes

The notes section is free form, and is used for jotting down anything you like. Anything in this section will not carry over, so the notes section will display as blank for each newly created journal entry. 

## Longer term aims

### Review features

The eventual plan is to create a review features that will display entries from over a given time period, for example:

```
# see whole week
journal.sh week

# see whole month
journal.sh
```

Ideally, this display will also have a calendar embedded.

### Statistics

Gets stats for completed tasks and or habits with:

```
# get stats for tasks completed over week 
journal.sh stats week
```

## Inspirations/alternative projects

This project was mainly undertaken through wanting a project to learn bash. But, also as a way to implement a deliberately, simple and bare bones journal method for tracking habits, tasks, and quick notes about the day. The task section takes a lot of inspiration (steals) from the todo.txt format.

[How to Bullet Journal](https://www.youtube.com/watch?v=fm15cmYU0IM) video by "inventor" of the bullet journal method.

[todo.txt](https://github.com/todotxt/todo.txt)

[Plain text journaling vim](https://peppe.rs/posts/plain_text_journaling/) found via a [hackernews post](https://news.ycombinator.com/item?id=36390405).

[Bash Journaling](https://jodavaho.io/posts/bash-journalling.html) and [Bullet Journaling](https://jodavaho.io/posts/bullet-journalling.html).
