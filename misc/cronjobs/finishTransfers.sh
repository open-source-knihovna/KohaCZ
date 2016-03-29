#!/bin/bash

# include helper functions
if [ -f "/usr/share/koha/bin/koha-functions.sh" ]; then
    . "/usr/share/koha/bin/koha-functions.sh"
else
    echo "Error: /usr/share/koha/bin/koha-functions.sh not present." 1>&2
    exit 1
fi

usage()
{
    local scriptname=$(basename $0)
    cat <<EOF
$scriptname
This script automatically finishes transfers - use it in your cron
Usage:
$scriptname instancename

EOF
}

if [ $# -gt 0 ]; then
  name=$1;
else
  echo "Error: Missing instance name"
  exit 1
fi

sql="UPDATE branchtransfers SET datearrived = NOW() WHERE datearrived IS NULL AND DATE(datesent) <= CURRENT_DATE();";

if is_instance $name; then
  echo "$sql" > koha-mysql $name
else
  echo "Error: Invalid instance name $name"
  exit 1
fi

