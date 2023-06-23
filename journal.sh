#!/bin/bash

# journal.sh: command line wrapper for bullet journaling in text editor


# globals

# set default editor for journal
# vim is go to default
EDITOR=vim; export EDITOR

# check if a folder named journal exists
# if not make it

# check if the today's date txt file exists
# format will be yyyy_mm_dd_jrnl.txt
# if not exists make it
# write defaults to it (headings and habits)

# if it exists just open in $EDITOR
