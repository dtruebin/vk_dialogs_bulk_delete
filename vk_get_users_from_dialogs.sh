#!/bin/bash

### INITIALIZATION ###

# List of dependencies
DEPS="jq"

# VK-related 
echo -n "Reading config... "
source vk.conf && echo "done"

echo "Checking dependencies... "
for dep in $DEPS; do
  if ! command -v $dep 2>&1 >/dev/null; then
    echo "$dep not found, quitting."
    exit 1
  fi
done

echo -e "Initialization completed.\n"

### MAIN ###

## Get the total count of dialogs
dialogs_count=$(
curl "https://api.vk.com/method/messages.getDialogs?access_token=${ACCESS_TOKEN}&v=5.76&count=0" 2>/dev/null \
  | jq '.response.count'
)

## Extraxt user_ids belonging to people we talked to (i.e., no group chats, no bots, no special users)
echo "Extracting personal user_ids from $dialogs_count dialogs..."

# To get the list of users who we talked with, we'll be iterating over the list of dialogs with the increment
# defined in GET_DIALOGS_STEP variable. Don't set it higher than 200.
# https://vk.com/dev/messages.getDialogs - 200 is max value 'count' parameter
GET_DIALOGS_STEP=150

offset=0
unset dialog_user_ids

while [ $offset -lt $dialogs_count ]; do
  offset_after=$((offset + GET_DIALOGS_STEP))
  if [ $offset_after -lt $dialogs_count ]; then
    echo "Dialogs $offset-$offset_after..."
  else
  	echo "Dialogs $offset-$dialogs_count..."
  fi
  dialog_user_ids="$dialog_user_ids $(
  curl "https://api.vk.com/method/messages.getDialogs?count=${GET_DIALOGS_STEP}&offset=${offset}&access_token=${ACCESS_TOKEN}&v=5.76" 2>/dev/null \
    | jq '.response.items[].message | select(has ("users_count") | not) | .user_id' \
    | grep -vE "^${MY_USER_ID}$|^-"
  )"
  offset=$offset_after
done

echo "Extracted $(echo $dialog_user_ids | wc -w) user_ids."

# https://vk.com/dev/users.get - 1000 is max value for 'user_ids'
if [ $(echo $dialog_user_ids | wc -w) -gt 1000 ]; then
  echo "Warning: working only with the first 1000 user_ids due to API limitation"
  dialog_user_ids="$(echo $dialog_user_ids | tr ' ' '\n' | head -n1000 | paste -sd' ')"
fi

## Create a CSV
echo "Getting names for the users"
user_ids="$(echo $dialog_user_ids | sed 's/ /,/g')"
csv_name="vk_users_from_dialogs.csv"

curl "https://api.vk.com/method/users.get?access_token=${ACCESS_TOKEN}&v=5.76&user_ids=${user_ids}" 2>/dev/null \
  | jq -r '.response[] | [.id,(.first_name + " " + .last_name)] | @csv' > ${csv_name}

echo "Finished! Result saved in ${csv_name}"

exit 0
