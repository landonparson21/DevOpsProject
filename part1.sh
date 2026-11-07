#!/bin/bash


# Function to take the data gained from scraping and creating users from it
# WARNING - This will create new users in the system running this ( I think this is the req )
create_users() {
   names=$(cat names.txt)
   echo "Creating Users"
   while [[ "$names" == *$'\n'* ]]; do
      fullN="${names%%$'\n'*}"
      names="${names#*$'\n'}"
      firstN="${fullN%% *}"
      lastN="${fullN#* }"
      # TODO Decapitalize firstN and lastN
      username="$firstN.$lastN"
      password="$firstN""$lastN""HALBERD"
      add_user "$username" "$password"
   done
   firstN="${names%% *}"
   lastN="${names#* }"
   # TODO Decapitalize firstN and lastN
   username="$firstN.$lastN"
   password="$firstN""$lastN""HALBERD"
   add_user "$username" "$password"
   echo ""
}

#Function to add a new user
# Takes 2 arguments: username and password
add_user() {
if [ -z "$1" ]; then
   return 1
fi
if [ -z "$2" ]; then
   return 1
fi
# This adds the user and sets password
sudo useradd -m "$1"
echo "$1:$2" | sudo chpasswd
}

# Main Loop
source ./part3.sh
choice=0
while [[ $choice != 3 ]]; do
	echo "1. Add Users Automatically"
	echo "2. Add a User Manually"
	echo "3. Exit"
	read -p  "Please select an option(1, 2, or 3): " choice
	# TODO Validate that choice is an integer
	while [[ $choice -lt 1 || $choice -gt 3 ]]; do
		read -p "Please select a valid option(1, 2, or 3): " choice
	done
	if [[ $choice == 1 ]]; then
		echo "Running Web Scraper"
		curl -so faculty.txt https://www.tntech.edu/engineering/programs/csc/faculty-and-staff.php
		grep "<h4>" faculty.txt | sed 's/<[^>]*>//g' | sed 's/, Ph\.D\.//' | sed 's/&nbsp;//'| sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//' > names.txt
		create_users
	elif [[ $choice == 2 ]]; then
		echo "Adding user manually"
		add_user_manually
	elif [[ $choice == 3 ]]; then
		exit 0
	fi
done

