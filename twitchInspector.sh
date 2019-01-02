#!/bin/bash

echo Importing client id...
while read STRING
do
	        clientid=$STRING
done < clientID.txt

arg=0

while [ $arg -lt 2 ]; do

	if [ $arg -eq 0 ]
	then
		id="$(curl -s -H 'Client-ID: '$clientid'' -X GET 'https://api.twitch.tv/helix/users?login='$1'' | jq -r '.data[] | .id')"
		username=$1
	else
		id="$(curl -s -H 'Client-ID: '$clientid'' -X GET 'https://api.twitch.tv/helix/users?login='$2'' | jq -r '.data[] | .id')"
		username=$2
	fi

	FOLLOWCOUNT="$(curl -s -H 'Client-ID: '$clientid'' -X GET 'https://api.twitch.tv/helix/users/follows?from_id='$id'' | jq .total)"

	echo Populating following information for $username who is following $FOLLOWCOUNT accounts

	((n = $FOLLOWCOUNT / 100))
	((H = $n / 2))
	
	COUNTER=0
	LIMIT=0
	
	curl -s -H 'Client-ID: '$clientid'' -X GET 'https://api.twitch.tv/helix/users/follows?from_id='$id'&first=100' | jq -r '.data[] | .to_id' | tee inspect$username.txt > /dev/null

	page="$(curl -s -H 'Client-ID: '$clientid'' -X GET 'https://api.twitch.tv/helix/users/follows?from_id='$id'&first=100' | jq -r '.pagination.cursor')"

	while [ $COUNTER -lt $n ]; do
	
		curl -s -H 'Client-ID: '$clientid'' -X GET 'https://api.twitch.tv/helix/users/follows?from_id='$id'&first=100&after='$page'' | jq -r '.data[] | .to_id' | tee -a inspect$username.txt > /dev/null
		page="$(curl -s -H 'Client-ID: '$clientid'' -X GET 'https://api.twitch.tv/helix/users/follows?from_id='$id'&first=100&after='$page'' | jq -r '.pagination.cursor')"
		sleep 4
		
		let COUNTER=COUNTER+1
	done

	let arg=arg+1
done

echo Comparing Data between $1 and $2...

declare -a arrayOne
declare -a arrayTwo

let x=0
let y=0
let i=0
let match=0
let arg=0

while [ $arg -lt 2 ]; do
	if [ $arg -eq 0 ]
	then
		while IFS=$'\n' read -r line_data; do
			arrayOne[i]="${line_data}"
			((++i))
		done < inspect$1.txt
	else
		while IFS=$'\n' read -r line_data; do
			arrayTwo[i]="${line_data}"
			((++i))
		done < inspect$2.txt
	fi
	
	let arg=arg+1
	let i=0
done

while [ $x -lt "${#arrayOne[@]}" ]; do
	while [ $y -lt "${#arrayTwo[@]}" ]; do
		let i=i+1
		if [ "${arrayOne[$x]}" = "${arrayTwo[$y]}" ]
		then
			let match=match+1
			let y=y+1
			break
		else
			let y=y+1
		fi
	done
	let x=x+1
	let y=0
done
echo Number of Matches between $1 and $2: $match
