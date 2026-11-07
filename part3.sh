#!/bin/bash

add_user_manually() {
	echo "Add User Manually"
	
	read -p "Enter first name: " first_name
	read -p "Enter last name: " last_name

	#validate input
	if [[ -z "$first_name" || -z "last_name" ]]; then
		echo "Error: First name and last name are required."
		return 1
	fi

	#generate username and password
	username="$(echo "${first_name}.${last_name}" | tr '[:upper:]' '[:lower:]')"
	password="$(echo "${first_name}${last_name}" | tr '[:upper:]' '[:lower:]')HALBERD"

	echo ""
	echo "Generated User Information: "
	echo "Username: $username"
	echo "Password: $password"
	echo ""
	echo "User credentials generated successfully!"
}
	

add_user_manually
