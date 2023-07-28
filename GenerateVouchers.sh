#!/bin/bash

#================================================================
# Create user(s) for Captive Portal (Voucher)
# @author Cristol Bardou
#================================================================

set -o pipefail

REPSCRIPT=$(cd $(dirname $0); pwd)
CONF_FILE=$REPSCRIPT/config.cfg

ROUGE='\e[1;31m'
ROUGEUNDERLINED='\e[4;31m'
VERT='\e[1;32m'
VERTUNDERLINED='\e[4;32m'
JAUNE='\e[1;33m'
BLEU='\e[1;34m'
BLANC='\e[1;37m'
GRIS='\e[2;37m'
NEUTRE='\e[0;m'

function info { echo -e "\e[32m[Info] $*\e[39m"; }
function warn  { echo -e "\e[33m[Warn] $*\e[39m"; }
function error { echo -e "\e[31m[Error] $*\e[39m"; }
function debug { echo -e "\e[34m[Debug] $*\e[39m"; }

function usage {
  echo -e "${BLANC}Usage : $0 [-u,-d,-e,-g]\n\n"
  echo -e "${BLANC}-u --> Number of users to create $VERT(Default 1)$NEUTRE"
  echo -e "${BLANC}-d --> Active time in minutes $VERT(Default 240)$NEUTRE"
  echo -e "${BLANC}-e --> Validity time in minutes $VERT(Default 1440)$NEUTRE"
  echo -e "${BLANC}-g --> Name of the group $VERT(Default FromAPI)$NEUTRE"
  exit
}

if [ ! $(which curl) ]; then
  error "Please install CURL first"
  exit 1
fi

if [ ! $(which jq) ]; then
  error "Please install JQ first"
  exit 1
fi

if [ ! -f $CONF_FILE ]; then
  echo -e "${ROUGE}The file $CONF_FILE does not exist !\n$NEUTRE"
  echo -e "This file must contain :"
  echo -e "${BLEU}OPNSENSE_API_KEY=${BLANC}Your Key $VERT(System -> Access -> Users -> API keys)$NEUTRE"
  echo -e "${BLEU}OPNSENSE_API_SECRET=${BLANC}Your Secret $VERT(System -> Access -> Users -> API keys)$NEUTRE"
  echo -e "${BLEU}OPNSENSE_IP=${BLANC}IP of your OPNsense instance$NEUTRE"
  echo -e "${BLEU}OPNSENSE_PORT=${BLANC}Port of your OPNsense instance$NEUTRE"
  echo -e "${BLEU}OPNSENSE_VOUCHER_PROVIDER=${BLANC}Name of your Voucher provider $VERT(System -> Access -> Servers -> Voucher)$NEUTRE"
  echo -e "${BLEU}DEFAULT_COUNT=${BLANC}1$NEUTRE"
  echo -e "${BLEU}DEFAULT_DURATION=${BLANC}240$NEUTRE"
  echo -e "${BLEU}DEFAULT_EXPIRE=${BLANC}1440$NEUTRE"
  echo -e "${BLEU}DEFAULT_GROUPE=${BLANC}FromAPI$NEUTRE"
  exit 1
fi

source $CONF_FILE

while getopts ":u:d:e:g:" option; do
  case "${option}" in
    u)
      u=${OPTARG}
      ;;
    d)
      d=${OPTARG}
      ;;
    e)
      e=${OPTARG}
      ;;
    g)
      g=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

NBRACCOUNT=${u:-$DEFAULT_NBRACCOUNT}
DURATION=$((${d:-$DEFAULT_DURATION}*60))
EXPIRE=$((${e:-$DEFAULT_EXPIRE}*60))
GROUPE=${g:-$DEFAULT_GROUPE}

if [ $DURATION -gt $EXPIRE ]; then
  warn "Login time exceeds timeout"
fi

DATA="{
  \"count\": \"$NBRACCOUNT\",
  \"validity\": \"$DURATION\",
  \"expirytime\": \"$EXPIRE\",
  \"vouchergroup\": \"$GROUPE\"
}"

echo -e "Creation of $VERT$NBRACCOUNT$NEUTRE user(s) in the group $VERT$GROUPE$NEUTRE for a connection limited to $VERT$(($DURATION/60))$NEUTRE minute(s), and expiring in $VERT$(($EXPIRE/60))$NEUTRE minute(s)"

curl --connect-timeout 5 -s -k \
-H "Content-Type: application/json" \
-u $OPNSENSE_API_KEY:$OPNSENSE_API_SECRET \
-d "$DATA" https://$OPNSENSE_IP:$OPNSENSE_PORT/api/captiveportal/voucher/generateVouchers/$OPNSENSE_VOUCHER_PROVIDER \
| jq -r ' .[] | ["Login: \"" + .username + "\", ", "Password: \"" + .password + "\""] | join ("")'

if [ $? -ne 0 ]; then
  error "Fail to create user --> https://$OPNSENSE_IP:$OPNSENSE_PORT"
  exit 1
fi

exit
