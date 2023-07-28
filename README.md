# Generation de compte utilisateur pour le portail captif OPNsense <!-- omit in toc -->

- [GenerateVouchers.sh](#generatevoucherssh)
  - [Conf](#conf)
  - [Usage](#usage)
  - [Exemple](#exemple)


## GenerateVouchers.sh

Ce script permet de créer des utilisateurs temporaires pour le portail captif.

### Conf

Un fichier de conf **config.cfg** doit être initialisé à la racine de ce même script  
Vous pouvez vous referer au fichier **config_exemple.cfg**

### Usage

```bash
$ ./GenerateVouchers.sh
Usage : ./GenerateVouchers.sh [-c,-d,-e,-g]

-c --> Nombre de compte à créer (Defaut 1)
-d --> temps d'activité en minute (Defaut 240)
-e --> temps de validité en minute (Defaut 1440)
-g --> groupe associé (Defaut FromAPI)

```
> Les valeurs par défaut peuvent être modifiées dans le fichier **config.cfg**

### Exemple

```bash
$ ./GenerateVouchers.sh -c 6 -d 480 -e 960 -g Groupe_Exemple
Création de 6 user(s) dans le groupe Groupe_Exemple pour une connexion limitée à 480 minute(s), et expirant dans 960 minute(s)
Utilisateur: "hzsF", Mot de passe: "i7NcRf"
Utilisateur: "QSw8", Mot de passe: "RDNuLm"
Utilisateur: "JSnQ", Mot de passe: "UnG9gN"
Utilisateur: "kaHC", Mot de passe: "tt8Fm3"
Utilisateur: "Q5VW", Mot de passe: "eaYvNZ"
Utilisateur: "RkSg", Mot de passe: "bf47H5"
``````

![Alt text](../IMG/Vouche.png)
