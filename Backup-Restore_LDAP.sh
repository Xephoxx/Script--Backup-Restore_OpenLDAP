#!/bin/bash

### Purpose: Backup and restore LDAP directory and datas
### Author: xephoxx

## Global variables declaration
REPLY=""
BACKUP_DIRECTORY="/root/"
DC_SUFFIX="search-ldap"                        ## Suffix given for backup tracking
DATA_DIR="/var/lib/ldap/"                        ## Directory containing the directory data
SETTINGS_DIR="/etc/openldap/"                    ## Directory containing configuration files
SETTINGS_DIR_PERMISSION="/etc/openldap/slap.d/"  ## Restoration of permission files

## Only root can run the script
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

echo ""
echo -e "\e[34m╔═╗┌─┐┌─┐┌┐┌╦  ╔╦╗╔═╗╔═╗  \e[97m╔╗ ┌─┐┌─┐┬┌─┬ ┬┌─┐  ╦═╗┌─┐┌─┐┌┬┐┌─┐┬─┐┌─┐  \e[31m╔╦╗┌─┐┌─┐┬"
echo -e "\e[34m║ ║├─┘├┤ │││║   ║║╠═╣╠═╝  \e[97m╠╩╗├─┤│  ├┴┐│ │├─┘--╠╦╝├┤ └─┐ │ │ │├┬┘├┤   \e[31m ║ │ ││ ││"
echo -e "\e[34m╚═╝┴  └─┘┘└┘╩═╝═╩╝╩ ╩╩    \e[97m╚═╝┴ ┴└─┘┴ ┴└─┘┴    ╩╚═└─┘└─┘ ┴ └─┘┴└─└─┘  \e[31m ╩ └─┘└─┘┴─┘"

echo ""
echo -e "\e[97m"
type tar >/dev/null 2>&1 && echo 'Tar command installed.' || echo 'Tar command not installed please install it.'
type chown >/dev/null 2>&1 && echo 'Chown command installed.' || { echo $'Chown command not installed please install it.\nAborting.'; exit 1; }

# Red pill or Bleu pill ?
echo -e "\e[97m"
echo "[*] What do you want to do ?"
echo ""
echo "[+] Backup ? Type b"
echo "[+] Restore ? Type r"
echo ""
read -p "$1[+] Your Choice ? : "
case $(echo "$REPLY" | tr '[A-Z]' '[a-z]') in
    b ) echo "[*] So you choose to save datas " ;;
    r ) echo "[*] So you choose to restore datas " ;;
    * ) echo "[!] Invalid choice "; exit 1 ;;
esac

# Backup and restore if statement
if [[ "b" == "$REPLY" ]]; then
    
    if [ ! -d $SETTINGS_DIR ]; then   # if directory doesn't exists we create it
        echo "Directory doesn't exists so we create it !!"
        mkdir -p $SETTINGS_DIR;
    else
        echo ""
        echo "[*] Directory /etc/openldap/ already exists !"
        echo ""
    fi

    echo "[*] Stopping the slapd service !"
    systemctl stop slapd
    sleep 5     ## We're waiting 5 second

    echo ""
    echo "[*] Configuration files backup in progress ..."
    cd /etc/openldap/ && tar -pzcvf $BACKUP_DIRECTORY/etc-openldap-$DC_SUFFIX.tar.gz .
    if [ -f "etc-openldap-$DC_SUFFIX.tar.gz" ]; then   # Simple check if the file exists
        echo "[!] New backup of configuration files made !"
        sleep 3
    fi

    if [ ! -d $DATA_DIR ]; then   # if directory doesn't exists we create it
        echo "Directory doesn't exists so we create it !!"
        mkdir -p $DATA_DIR;
    else
        echo ""
        echo "[*] Directory /var/lib/ldap/ already exists !"
        echo ""
    fi

    echo ""
    echo "[*] Datas directory backup in progress ..."
    cd /var/lib/ldap/ && tar -pzcvf $BACKUP_DIRECTORY/data-openldap-$DC_SUFFIX.tar.gz .
    if [ -f "data-openldap-$DC_SUFFIX.tar.gz" ]; then   # Another check if the file exists
        echo "[!] New backup of datas directory made !"
        sleep 3
    fi

    echo ""
    echo "[*] Restarting the slapd service !"
    systemctl start slapd
    sleep 5    ## We're waiting 5 seconds
    echo ""
    echo "[!] Backup completed !"

elif [[ "r" == "$REPLY" ]]; then
    
    echo ""
    echo "[*] Stopping the slapd service !"
    systemctl stop slapd
    sleep 5     ## We're waiting 5 second
    echo ""

    if [ -f "$BACKUP_DIRECTORY/etc-openldap-$DC_SUFFIX.tar.gz" ]; then   # Simple check if the file exists
        echo "[*] File etc-openldap-$DC_SUFFIX.tar.gz exists !"
    else
        echo "File etc-openldap-$DC_SUFFIX.tar.gz doesn't exists !"
        exit 1
    fi
    echo "[*] Restoring configuration files in progress ..."
    tar -zxvf $BACKUP_DIRECTORY/etc-openldap-$DC_SUFFIX.tar.gz -C $SETTINGS_DIR
    chown -R ldap:ldap $SETTINGS_DIR_PERMISSION
    echo "[!] Restoring configuration files success !"
    echo ""

    if [ -f "$BACKUP_DIRECTORY/data-openldap-$DC_SUFFIX.tar.gz" ]; then   # Another check if the file exists
        echo "[*] File data-openldap-ldap-easytrip.tar.gz exists !"
    else
        echo "[*] File data-openldap-$DC_SUFFIX.tar.gz doesn't exists !"
        exit 1
    fi
    echo "[*] Restoring datas in progress ..."
    tar -zxvf $BACKUP_DIRECTORY/data-openldap-$DC_SUFFIX.tar.gz -C $DATA_DIR
    chown -R ldap:ldap $DATA_DIR
    echo "[!] Restoring datas success !"

    echo ""
    echo "[*] Starting the slapd service !"
    systemctl start slapd
    sleep 5     ## We're waiting 5 second
    echo ""

    echo "[*] OpenLDAP restoration complete ! You can now go to drink a beer :D"
else
    echo "Error !"
    exit 1
fi
