#!/usr/bin/env bats

# all tests written using bats test framework
# only bats core has been used
# https://github.com/bats-core/bats-core

setup() {
    source task-journal.sh  >/dev/null 2>&1 || source ../task-journal.sh >/dev/null 2>&1

    source test.cfg  >/dev/null 2>&1 || source test/test.cfg >/dev/null 2>&1
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    TEST_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in dir below test dir visible to PATH
    PATH="$TEST_DIR/../:$PATH"
}

setup_file() {
    test_journal="test-journal"
    # this is run at the start of all tests
    TEST_DIR=$(dirname "$BATS_TEST_FILENAME")
    cd "$TEST_DIR"
    echo "# making $test_journal" >&3
    mkdir "$test_journal"
}

@test "Check help message" {
    result=$(help)
    [[ "$result" == *"Task Journal example usage"* ]]
}

@test "check valid date function with valid date" {
    result=$(check_valid_date 2023-08-22)
    [[ "$result" -eq 0 ]]
}

@test "check valid date function with invalid date" {
    # as per https://stackoverflow.com/questions/68853013/bats-assert-failure-test-not-recognising-exit-1
    # expected failure not work when running a function
    # have to run through a different shell to make sure error message
    # doesn't trigger failed test
    run bash -c "source task-journal.sh && check_valid_date fake-date"
    [[ "$status" -eq 1 ]]
}

@test "check if arg is number with valid number" {
    result=$(check_if_number 2)
    [[ "$result" -eq 0 ]]
}

@test "test file does not exist message" {
    result=$(file_does_not_exist 1800-12-25-jrnl.txt)
    [[ "$result" == "Error: 1800-12-25-jrnl.txt does not exist" ]]
}

@test "test creating new file" {
    create_file "$today_filepath" "$today_entry_date"

    [[ -e "$today_filepath" ]]

    result=$(cat "$today_filepath")
    [[ "$result" == "# task journal $today" ]]

    rm "$today_filepath"

}

@test "testing check_todo_exists" {
    # this should make test_journal/todo.txt
    check_todo_exists

    [[ -e "test-journal/todo.txt" ]]
}

@test "testing adding defaults passes over outstanding values" {

    yesterday_filepath="$JOURNALS_FOLDER/$yesterday-jrnl.txt"

    echo "# task journal $yesterday" >> "$yesterday_filepath"
    echo "outstanding task" >> "$yesterday_filepath"

    create_file "$today_filepath" "$today"

    result=$(grep "outstanding task" "$today_filepath")

    [[ "$result" == "outstanding task" ]]

    rm "$yesterday_filepath"
}

@test "testing check_reminders_file_exists" {
    check_reminders_file_exists

    [[ -e "test-journal/reminders.txt" ]]
}

@test "testing check_for_reminders" {
    test_rem="reminder due today due:$today"
    echo "$test_rem" >> "$REMINDERS_FILE"

    check_for_reminders "$today_filepath"

    result=$(grep -E "reminder due today due:[0-9]{4}-[0-9]{2}-[0-9]{2}" "$today_filepath")

    [[ "$result" == "$test_rem" ]]
}

@test "testing add to file" {
    create_file "$today_filepath" "$today_entry_date"

    test_entry="new entry"
    add_to_file "$test_entry"

    result=$(grep -E "$test_entry" "$today_filepath")

    [[ "$result" == "$test_entry" ]]

    rm "$today_filepath"
}

@test "testing check_if_number works with numbers" {
    check_if_number 2

    [[ "$status" -eq 0 ]]
}

@test "testing check_if_number fails with text" {
    # see comment for check_valid_date_function with invalid date
    run bash -c "source task-journal.sh && check_if_number should-fail"

    [[ "$status" -eq 1 ]]
}

@test "testing complete_task function" {
    create_file "$today_filepath" "$today_entry_date"

    test_entry="new entry"
    add_to_file "$test_entry"

    run bash -c "source task-journal.sh && complete_task $today_filepath 2"

    completed_entry="x $test_entry"

    result=$(grep -E "$completed_entry" "$today_filepath")

    [[ "$result" == "$completed_entry" ]]

    rm "$today_filepath"

}

@test "testing complete_task function on already completed task" {
    create_file "$today_filepath" "$today_entry_date"

    completed_entry="x new entry"
    add_to_file "$completed_entry"
    run bash -c "source task-journal.sh && complete_task $today_filepath 2"

    [[ "$status" -eq 1 ]]

    rm "$today_filepath"
}

@test "testing moving task from today file to todo file" {
    create_file "$today_filepath" "$today_entry_date"

    test_task="test task"

    echo "$test_task" >> "$today_filepath"

    run bash -c "source task-journal.sh && move_task today 2 td"

    result=$(grep -E "$test_task" "$TODO_FILE")

    [[ "$result" == "$test_task" ]]

    rm "$today_filepath"

    rm "$TODO_FILE"
}


@test "testing get_previous_entry gets previous entry" {
    create_file "$today_filepath" "$today_entry_date"

    previous_entry=$(date -d '-4 day' '+%Y-%m-%d')

    previous_filename="$previous_entry-jrnl.txt"
    test_previous_filepath="$JOURNALS_FOLDER/$previous_filename"

    create_file "$test_previous_filepath" "$previous_entry"

    get_previous_entry "$today"

    [[ "$previous_filepath" == "$test_previous_filepath" ]]

    rm "$test_previous_filepath"
    rm "$today_filepath"
}

teardown_file () {
    # this will be run at the end of all tests
    TEST_DIR=$(dirname "$BATS_TEST_FILENAME")
    cd "$TEST_DIR"
    rm -r "test-journal"
}

teardown() {
    # this will be run at the end of each test
    :
}
