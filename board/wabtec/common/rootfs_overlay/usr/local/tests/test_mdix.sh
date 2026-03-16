#!/usr/bin/env bash
# Test du lien Ethernet pour differents modes MDI/MDIX via ethtool
# - Applique les modes mdix : on, off, auto
# - Verifie "Link detected:" et compare au resultat attendu
# - Affiche PASS/FAIL pour chaque test
#
# Usage : sudo ./test_mdix.sh [interface] [switch_mode] [cable_type]
# interface: eth0/eth1
# switch_mode: yes/no
# cable_type: crossed/straight
# Exemple : sudo ./test_mdix.sh eth1 no
#
# Prerequis :
# - ethtool installe
# - droits suffisants pour ethtool -s (root)

set -euo pipefail

INTERFACE="${1:-eth0}"
MODE_SWITCH="${2:-no}"
CABLE_TYPE="${3:-straight}"

if [ "$MODE_SWITCH" = "yes" ]; then
  ETH_PORT="eth0"
else
  ETH_PORT=$INTERFACE
fi

# --------------------------------------------------------------------
# Verifications prealables
# --------------------------------------------------------------------
if ! command -v ethtool >/dev/null 2>&1; then
  echo "Erreur : 'ethtool' n'est pas installe." >&2
  exit 1
fi

if ! ip link show "$ETH_PORT" >/dev/null 2>&1; then
  echo "Erreur : l'interface '$ETH_PORT' est introuvable." >&2
  exit 1
fi

# ethtool -s necessite des privilèges (CAP_NET_ADMIN)
if [ "$(id -u)" -ne 0 ]; then
  echo "Attention : ce script doit être execute en root (ou via sudo) pour 'ethtool -s'." >&2
  exit 1
fi

# --------------------------------------------------------------------
# Fonction : get_link_status
# Retourne "yes" ou "no" selon le champ "Link detected:"
# --------------------------------------------------------------------
get_link_status() {
  local iface="$1"
  local status=""

  # Extraction du champ "Link detected" (yes/no)
  # Tolère la casse et les espaces
  status="$(ethtool "$iface" 2>/dev/null | awk -F': *' 'tolower($1) ~ /link detected/ {print tolower($2)}')"

  if [ "$status" = "yes" ]; then
    echo "yes"
  else
    echo "no"
  fi
}

# --------------------------------------------------------------------
# Tableau des tests : "mode:expected"
# Ajustez les attentes suivant votre environnement
# --------------------------------------------------------------------
if [ "$CABLE_TYPE" == "crossed" ]; then
    tests=(
      "off:yes"
      "on:no"
      "auto:yes"
    )
else
    tests=(
      "on:yes"
      "off:no"
      "auto:yes"
    )
fi

# --------------------------------------------------------------------
# Boucle de tests
# --------------------------------------------------------------------
echo "Interface : $INTERFACE"
echo "Use switch : $MODE_SWITCH"
echo "Cable type : $CABLE_TYPE"

echo "Start MDIX tests..."
echo
if [ "$MODE_SWITCH" = "yes" ]; then
  if [ "$INTERFACE" = "eth1" ]; then
    echo 1 > /sys/class/net/eth0/ethtool_port
  else
    echo 0 > /sys/class/net/eth0/ethtool_port
  fi
fi

for entry in "${tests[@]}"; do
  mode="${entry%%:*}"     # partie avant ':'
  expected="${entry##*:}" # partie après ':'

  echo "------------------------------------------------------------"
  echo "MDIX = ${mode} | Attendu : ${expected}"

  # Appliquer le mode MDIX (si non supporte, ethtool retournera une erreur)
  if ! ethtool -s "$ETH_PORT" mdix "$mode" 2>/dev/null; then
    echo "FAIL : Impossible to set mdix=${mode} (potentially not supported by interface)" >&2
    continue
  fi

  # Laisser le temps à la negociation de lien (adapter si besoin)
  sleep 10

  actual="$(get_link_status "$ETH_PORT")"
  echo "Link detected: ${actual}"

  if [ "$actual" = "$expected" ]; then
    echo "Result : PASS (conform to expected)"
  else
    echo "Result : FAIL (real = ${actual}, expected = ${expected})"
  fi
done

echo "------------------------------------------------------------"
echo "End MDIX tests"
