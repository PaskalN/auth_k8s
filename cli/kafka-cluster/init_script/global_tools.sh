#!/bin/sh

set -e

# Green Printer
# =============
print_green() {
    TEXT=$1
    BORDER=${2:-0}

    if [ "$BORDER" -eq 1 ]; then
        printf "\n" >&2
        printf "\033[0;32m %s \033[0m" "=====================================" >&2
        printf "\n" >&2
        printf "\033[0;32m %s \033[0m" "$TEXT" >&2
        printf "\n" >&2
        printf "\033[0;32m %s \033[0m" "=====================================" >&2
        printf "\n" >&2
    else
        printf "\n" >&2
        printf "\033[0;32m %s \033[0m" "$TEXT" >&2
        printf "\n" >&2
    fi
}

# Yellow Printer
# =============
print_yellow() {
    TEXT=$1
    BORDER=${2:-0}

    if [ "$BORDER" -eq 1 ]; then
        printf "\n" >&2
        printf "\033[0;33m %s \033[0m" "=====================================" >&2
        printf "\n" >&2
        printf "\033[0;33m %s \033[0m" "$TEXT" >&2
        printf "\n" >&2
        printf "\033[0;33m %s \033[0m" "=====================================" >&2
        printf "\n" >&2
    else
        printf "\n" >&2
        printf "\033[0;33m %s \033[0m" "$TEXT" >&2
        printf "\n" >&2
    fi
}

# Red Printer
# =============
print_red() {
    TEXT=$1
    BORDER=${2:-0}

    if [ "$BORDER" -eq 1 ]; then
        printf "\n" >&2
        printf "\033[0;31m %s \033[0m" "=====================================" >&2
        printf "\n" >&2
        printf "\033[0;31m %s \033[0m" "$TEXT" >&2
        printf "\n" >&2
        printf "\033[0;31m %s \033[0m" "=====================================" >&2
        printf "\n" >&2
    else
        printf "\n" >&2
        printf "\033[0;31m %s \033[0m" "$TEXT" >&2
        printf "\n" >&2
    fi
}

split_string() {
    input="$1"
    separator="$2"
    old_IFS="$IFS"
    IFS="$separator"
    set -- $input
    IFS="$old_IFS"

    # Print space-separated items
    for s in "$@"; do
        echo "$s"
    done
}