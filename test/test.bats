#!/usr/bin/env bats

# all tests written using bats test frame work
# only bats core has been used
# https://github.com/bats-core/bats-core

setup() {
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    source task-journal.sh  >/dev/null 2>&1 || source ../task-journal.sh >/dev/null 2>&1
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

teardown() {
    # this will be run at the end of each test
    :
}
