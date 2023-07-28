#!/bin/bash

#================================================================
# Création de compte Voucher pour le portail captif d'OPNsense
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
  echo -e "${BLANC}Usage : $0 [-c,-d,-e,-g]\n\n-c --> Nombre de compte à créer $VERT(Defaut 1)$NEUTRE"
  echo -e "${BLANC}-d --> temps d'activité en minute $VERT(Defaut 240)$NEUTRE"
  echo -e "${BLANC}-e --> temps de validité en minute $VERT(Defaut 1440)$NEUTRE"
  echo -e "${BLANC}-g --> groupe associé $VERT(Defaut CristolAPI)$NEUTRE"
  exit
}

if [ ! $(which curl) ]; then
  error "CURL ne semble pas installé, merci de l'installer avant de relancer ce script"
  exit 1
fi

if [ ! $(which jq) ]; then
  error "JQ ne semble pas installé, merci de l'installer avant de relancer ce script"
  exit 1
fi

if [ ! -f $CONF_FILE ]; then
  echo -e "${ROUGE}Le fichier $CONF_FILE n'existe pas !\n$NEUTRE"
  echo -e "Ce fichier doit contenir :"
  echo -e "${BLEU}OPNSENSE_API_KEY=${BLANC}VotreKey $VERT(System -> Access -> Users -> API keys)$NEUTRE"
  echo -e "${BLEU}OPNSENSE_API_SECRET=${BLANC}VotreSecret $VERT(System -> Access -> Users -> API keys)$NEUTRE"
  echo -e "${BLEU}OPNSENSE_IP=${BLANC}IPDeVotreOPNsense$NEUTRE"
  echo -e "${BLEU}OPNSENSE_PORT=${BLANC}PortDeVotreOPNsense$NEUTRE"
  echo -e "${BLEU}OPNSENSE_VOUCHER_PROVIDER=${BLANC}NomDuProviderVoucher $VERT(System -> Access -> Servers -> Voucher)$NEUTRE"
  echo -e "${BLEU}DEFAULT_COUNT=${BLANC}1$NEUTRE"
  echo -e "${BLEU}DEFAULT_DURATION=${BLANC}240$NEUTRE"
  echo -e "${BLEU}DEFAULT_EXPIRE=${BLANC}1440$NEUTRE"
  echo -e "${BLEU}DEFAULT_GROUPE=${BLANC}FromAPI$NEUTRE"
  exit 1
fi

source $CONF_FILE

while getopts ":c:d:e:g:" option; do
  case "${option}" in
    c)
      c=${OPTARG}
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

COUNT=${c:-$DEFAULT_COUNT}
DURATION=$((${d:-$DEFAULT_DURATION}*60))
EXPIRE=$((${e:-$DEFAULT_EXPIRE}*60))
GROUPE=${g:-$DEFAULT_GROUPE}

if [ $DURATION -gt $EXPIRE ]; then
  warn "La durée de connexion depasse l'expiration"
fi

DATA="{
  \"count\": \"$COUNT\",
  \"validity\": \"$DURATION\",
  \"expirytime\": \"$EXPIRE\",
  \"vouchergroup\": \"$GROUPE\"
}"

echo -e "Création de $VERT$COUNT$NEUTRE user(s) dans le groupe $VERT$GROUPE$NEUTRE pour une connexion limitée à $VERT$(($DURATION/60))$NEUTRE minute(s), et expirant dans $VERT$(($EXPIRE/60))$NEUTRE minute(s)"

curl --connect-timeout 5 -s -k \
-H "Content-Type: application/json" \
-u $OPNSENSE_API_KEY:$OPNSENSE_API_SECRET \
-d "$DATA" https://$OPNSENSE_IP:$OPNSENSE_PORT/api/captiveportal/voucher/generateVouchers/$OPNSENSE_VOUCHER_PROVIDER \
| jq -r ' .[] | ["Utilisateur: \"" + .username + "\", ", "Mot de passe: \"" + .password + "\""] | join ("")'

if [ $? -ne 0 ]; then
  error "Un problème s'est produit durant la demande auprès d'OPNsense --> https://$OPNSENSE_IP:$OPNSENSE_PORT"
  exit 1
fi

exit
