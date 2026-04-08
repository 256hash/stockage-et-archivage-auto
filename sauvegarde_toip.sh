#!/bin/bash

# ==============================================================================
# Nom du script : sauvegarde_toip.sh
# Description    : Archivage, compression et transfert FTP des logs TOIP
# Auteur         : Bona Luca - BTS SIO SISR
# Date           : 26/11/2024
# ==============================================================================

# --- 1. CONFIGURATION DES VARIABLES ---
# Chemins locaux (À ADAPTER)
BASE_DIR="/home/user/owncloud-data"
SOURCE_DIR="$BASE_DIR/toip"
ARCHIVE_DIR="$BASE_DIR/archive"
LOG_FILE="/var/log/transfert_toip.log"

# Paramètres FTP (OMV)
FTP_HOST="192.168.20.36"
FTP_USER="votre_utilisateur"
FTP_PASS="votre_mot_de_passe"
REMOTE_DIR="archives_toip"

# Formatage de la date demandé dans le sujet
DATE_STR=$(date +%d-%m-%Y_%H:%M:%S)
NOM_FICHIER="sio2-$DATE_STR"

# --- 2. PRÉ-REQUIS ---
# Création du dossier archive et du fichier de log s'ils n'existent pas
mkdir -p "$ARCHIVE_DIR"
touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1 # Redirige toute la sortie vers le fichier log

echo "--- Début du script : $(date) ---"

# --- 3. VÉRIFICATION DU RÉPERTOIRE SOURCE ---
if [ ! -d "$SOURCE_DIR" ] || [ -z "$(ls -A "$SOURCE_DIR"/*.csv 2>/dev/null)" ]; then
    echo "[ERREUR] Aucun fichier CSV trouvé dans $SOURCE_DIR. Fin du script."
    exit 1
fi

# --- 4. TRAITEMENT ---
echo "[1/3] Sauvegarde locale du CSV..."
cp "$SOURCE_DIR"/*.csv "$ARCHIVE_DIR/$NOM_FICHIER.csv"

echo "[2/3] Compression du répertoire TOIP..."
# -j ignore la structure des dossiers pour ne mettre que le fichier dans le zip
zip -j "$ARCHIVE_DIR/$NOM_FICHIER.zip" "$SOURCE_DIR"/*.csv

if [ $? -eq 0 ]; then
    echo "[SUCCÈS] Compression terminée : $NOM_FICHIER.zip"
else
    echo "[ERREUR] Échec de la compression."
    exit 1
fi

echo "[3/3] Transfert FTP vers OMV..."
# Utilisation de curl pour le transfert
curl --ftp-create-dirs -T "$ARCHIVE_DIR/$NOM_FICHIER.zip" \
     ftp://$FTP_HOST/$REMOTE_DIR/ \
     --user $FTP_USER:$FTP_PASS --silent --show-error

if [ $? -eq 0 ]; then
    echo "[SUCCÈS] Fichier transféré sur le serveur FTP."
else
    echo "[ERREUR] Le transfert FTP a échoué."
    exit 1
fi

echo "--- Fin du script : $(date) ---"
