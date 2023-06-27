# Task Journal 

A plain text bullet journal for tracking habits and tasks through bash and the editor of your choice.

## Intended usage once actually implemented

The default with no args passed will open a .txt file with today's date stamp:

```
journal.sh
```

If you need the day before or day after you can pass:

```
# open a file for yesterday
journal.sh yesterday
# open a file for tomorrow
journal.sh tomorrow
```

## Data files

If desired, you can create a key file and a habits file.

### Key file

This is a reminder for how to keep track of the status of tasks. The only markers are to display whether a task has been done or is in progress. This is kept track of with \ and x as markers for in progress and done. A task with no markers has not yet been actioned.

```
task with no status
x example done task
\ in progress task
```

### Habits file

If you want to track habits then under the data folder create a file called habits.txt. These will be automatically added to each new journal entry so they can be tracked every day.

The recommend structure should follow:

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

If a habits file is created then each journal entry will consist of three sections: habits, tasks, and notes.

### Tasks

These are to do items. Anything in the tasks section not marked as finished will be carried over to the next day on creation.

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

This project was mainly undertaken through wanting a project to learn bash. But, also as a way to implement a deliberately, simple and bare bones journal method for tracking habits, tasks, and quick notes about the day.

[How to Bullet Journal](https://www.youtube.com/watch?v=fm15cmYU0IM) video by "inventor" of the bullet journal method.

[todo.txt](https://github.com/todotxt/todo.txt)

[Plain text journaling vim](https://peppe.rs/posts/plain_text_journaling/) found via a [hackernews post](https://news.ycombinator.com/item?id=36390405).

[Bash Journaling](https://jodavaho.io/posts/bash-journalling.html) and [Bullet Journaling](https://jodavaho.io/posts/bullet-journalling.html).
