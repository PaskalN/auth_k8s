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

# Returns the base of the floating number: 123.123 -> 123
# ====================================================
math_floor() {
    awk -v n="$1" 'BEGIN { printf("%d", int(n)) }'
}

# Returns the next whole number of the floating number: 123.123 -> 124
# ====================================================
math_ceil() {
    expr="$1"
    awk "BEGIN { result = $expr; printf \"%d\n\", (result == int(result)) ? result : int(result)+1 }"
}

# Returns the min value from a set with numbers
# ====================================================
get_min() {
    min=""
    for n in $(printf '%s\n' "$1"); do
        [ -z "$min" ] && min=$n
        [ "$n" -lt "$min" ] && min=$n
    done
    echo "$min"
}

# Returns the max value from a set with numbers
# ====================================================
get_max() {
    max=""
    for n in $(printf '%s\n' "$1"); do
        [ -z "$max" ] && max=$n
        [ "$n" -gt "$max" ] && max=$n
    done
    echo "$max"
}