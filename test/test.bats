#!/usr/bin/env bats

setup() {
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/../src:$PATH"
}


@test "Check help message" {
    result=$(./task-journal.sh -h)
    [[ "$result" == *"Task Journal example usage"* ]]
}

@test "check valid date function" {
    run check_valid_date
}

teardown() {
    # this will be run at the end of each test
    :
}
