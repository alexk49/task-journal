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
    echo "# task journal $yesterday" >> "$JOURNALS_FOLDER/$yesterday-jrnl.txt"
    echo "outstanding task" >> "$JOURNALS_FOLDER/$yesterday-jrnl.txt"

    create_file "$today_filepath" "$today"

    result=$(grep "outstanding task" "$today_filepath")

    [[ "$result" == "outstanding task" ]]
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
