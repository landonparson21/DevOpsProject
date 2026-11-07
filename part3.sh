#!/bin/bash

add_user_manually() {
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

	sudo useradd -m "$username"
	echo "$username:$password" | sudo chpasswd
	echo "User created with username $username"
}

add_user_manually
>>>>>>> 0f8ec279de8fac8c96caa17334ace741e037a273
