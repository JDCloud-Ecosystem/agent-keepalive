#!/bin/bash
# The startup file of the terminal that the menu opens: the person's usual login shell, plus `menu` (or a bare
# `keepalive`) to leave it and go back to the menu. `keepalive` with an action still runs that action.
# shellcheck disable=SC1090,SC1091
[[ -f /etc/profile ]] && . /etc/profile
if [[ -f "$HOME/.bash_profile" ]]; then
    . "$HOME/.bash_profile"
elif [[ -f "$HOME/.bash_login" ]]; then
    . "$HOME/.bash_login"
elif [[ -f "$HOME/.profile" ]]; then
    . "$HOME/.profile"
fi

menu() { builtin exit 0; }
keepalive() {
    if (( $# == 0 )); then builtin exit 0; fi
    command keepalive "$@"
}
