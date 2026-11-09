#!/bin/bash
choice=0
while [[ $choice != 3 ]]; do
	echo "1. Add Users Automatically"
	echo "2. Add a User Manually"
	echo "3. Exit"
	read -p  "Please select an option(1, 2, or 3): " choice 
	while [[ $choice -lt 1 || $choice -gt 3 ]]; do
		read -p "Please select a valid option(1, 2, or 3): " choice
	done
	if [[ $choice == 1 ]]; then
		echo "Running Web Scraper"
		curl -so faculty.txt https://www.tntech.edu/engineering/programs/csc/faculty-and-staff.php
		grep "<h4>" faculty.txt | sed 's/<[^>]*>//g' | sed 's/, Ph\.D\.//' | sed 's/&nbsp;//'| sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//' > names.txt
	elif [[ $choice == 2 ]]; then
		echo "Adding user manually"
	elif [[ $choice == 3 ]]; then
		exit 0
	fi
done

