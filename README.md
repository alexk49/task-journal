# Task Journal 

A plain text journal for tracking habits and tasks through bash and the editor of your choice.

## Why plain text?

Plain text is as simple as it gets. It is portable and will always work. The .txt format has been chosen as opposed to say markdown as it allows you to be more expressive.

The journal is only for your personal use and reference, and .txt follows no rules so allows you to follow your instincts and personal preferences for formatting.

## Intended Usage Once actually implemented

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

This can be as simple or complex as you like. It should just explain how you intend to mark a task's status. For my personal use, I only want to track whether a task has been done or is in progress. And, I keep track of this with \ and x as markers for in progress and done.

```
task with no status
x example done task
\ in progress task
```

### Habits file

If you want to track habits then under the data folder create a file called habits.txt. These will be automatically added to each new journal entry so they can be tracked every day.

The structure should follow:

``` example habits file
Main habit
Main habit 2
* sub habit of habit 2
* another sub habit of habit 2
```

Sub habits are for if you have more detailed instructions for your habit. For example, your main habit might be "Play the piano", with a sub habit of "Practice Scales".

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

This project was mainly undertaken through wanting a project to learn bash. But, also as a way to implement a deliberately, simple and bare bones journal method for tracking habits and tasks.

[How to Bullet Journal](https://www.youtube.com/watch?v=fm15cmYU0IM) video by "inventor" of the bullet journal method.

[Plain text journaling vim](https://peppe.rs/posts/plain_text_journaling/) found via a [hackernews post](https://news.ycombinator.com/item?id=36390405).

[Bash Journaling](https://jodavaho.io/posts/bash-journalling.html) and [Bullet Journaling](https://jodavaho.io/posts/bullet-journalling.html).
