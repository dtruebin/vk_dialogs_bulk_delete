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

### FUNCTIONS ###

function usage() {
  echo -e "Usage: $(basename $0) [FILE]\nIf FILE is omitted, vk_users_from_dialogs.csv will be processed."
}

#######################################
# Delete dialog with the specified user
# Globals:
#   ACCESS_TOKEN
# Arguments:
#   $1 - user_id of the user
# Returns:
#   None
#######################################
function delete_dialog() {
  local user_id="$1"
  local user_name="$(grep -oP "(?<=^${user_id},).*" $src_csv)"

  echo -n "$user_name (id: $user_id)... "

  response=$(
  curl "https://api.vk.com/method/messages.deleteDialog?access_token=${ACCESS_TOKEN}&v=5.76&user_id=${user_id}" 2>/dev/null \
    | jq .response
  )

  if [ $response = "1" ]; then
    echo "success"
  else
    echo "fail"
  fi
}

#######################################
# Cleanup files from the backup dir
# Globals:
#   src_csv
# Arguments:
#   None
# Returns:
#   None
#######################################
function delete_dialogs() {
  local user_id

  while read user_id; do
    delete_dialog $user_id
  done < <(grep -oE '^[0-9]*' ${src_csv}) # Iterate over numeric user_ids from the 1st column of source CSV
}

### MAIN ###

if [ -n "$1" ]; then
  src_csv="$1"
else
  src_csv="vk_users_from_dialogs.csv"
fi

if [ ! -f "${src_csv}" ]; then
  usage
  echo "File \"${src_csv}\" was not found, quitting."
  exit 1
fi

# Remove Windows line endings (CR) for compatibility
sed -i -r 's/\r//g' ${src_csv}

users_count=$(cat ${src_csv} | wc -l)
{
  echo "Going to delete dialogs with ${users_count} users:"
  awk -F, '{print $2 " (id: " $1 ")"}' ${src_csv}
} | more

# Ask for confirmation before proceeding
echo
read -p "Continue? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  delete_dialogs 2070642
fi

exit 0
