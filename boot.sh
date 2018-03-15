#!/usr/bin/env bash
#
# PHP Box v1.0
#
# Copyright (C) 2018 Filis Futsarov
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

# be relative to location and not current working directory

# paths
system_path=$( cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P )
root_path=$( dirname "$system_path" )
app_path=$root_path/app

# be relative to system path
cd "$system_path"

function get_free_port() {
    ss -tln |
      awk 'NR > 1{gsub(/.*:/,"",$4); print $4}' |
      sort -un |
      awk -v n=1080 '$0 < n {next}; $0 == n {n++; next}; {exit}; END {print n}'
}

function get_lang() {
    echo $(locale | grep LANGUAGE | cut -d= -f2 | cut -d_ -f1)
}

lang_content=$(cat "$system_path/lang/$(get_lang).json")
function trans() {
    key=$1
    echo "$lang_content" | jq -rcM ".$key"
}

# config
config=$(jq -rcMs '.[0] * .[1]' $system_path/origin.json $root_path/config.json)
app_title=$(echo "$config" | jq -rcM '.title')
app_width=$(echo "$config" | jq -rcM '.width')
app_height=$(echo "$config" | jq -rcM '.height')
app_fullscreen=$(echo "$config" | jq -rcM '.fullscreen')
app_resizable=$(echo "$config" | jq -rcM '.resizable')
app_maximized=$(echo "$config" | jq -rcM '.maximized')
app_icon_path=$root_path/$(echo "$config" | jq -rcM '.icon')
# app_icon_path=../$(echo "$config" | jq -rcM '.icon')
app_requires_admin_privileges=$(echo "$config" | jq -rcM '.requiresAdminPrivileges')


# ask for privileges if app requires them, but the user does not have them
if [[ "$app_requires_admin_privileges" == 'true' ]]; then
    if [ $EUID != 0 ]; then
        userPassword=$(
            yad --center --fixed --borders=10 --entry \
                --window-icon="$app_icon_path" \
                --width=350 \
                --title="$app_title" \
                --text="$(trans 'APP_REQUIRES_ADMIN_PRIVILEGES')" \
                --hide-text \
                --button="$(trans 'EXIT')!gtk-no":1 \
                --button="$(trans 'PROCEED')!gtk-yes":0 \
                --image=gtk-dialog-authentication
        )

        if [ $? -eq 0 ]; then
            # used to check whether the entered password is wrong or not
            echo "$userPassword" | sudo -S echo -n ""

            # if s is wrong
            if [ $? -eq 1 ]; then
                yad --center --fixed --borders=10 \
                --image=gtk-dialog-warning \
                --width=350 \
                --window-icon="$app_icon_path" \
                --title="$app_title" \
                --text="$(trans 'WRONG_PASSWORD')" \
                --button="$(trans 'CANCEL')!gtk-no:1" \
                --button="$(trans 'RETRY')!gtk-refresh:0"

                # if user decided to reopen
                if [ $? -eq 0 ]; then
                    # reopen application to re-enter user password
                    "./boot.sh" &
                fi
            else
                # open application with admin privileges
                echo "$userPassword" | sudo -S "./boot.sh" &
            fi
        fi

        exit $?
    fi
fi

port=$(get_free_port)
address="localhost:$port"
app_url="http://$address"

php -S "$address" -t $app_path &
php_pid=$!
trap "kill $php_pid" EXIT

# start browser
$system_path/browser.py \
--title="$app_title" \
--url="$app_url" \
--width=$app_width \
--height=$app_height \
--fullscreen=$app_fullscreen \
--resizable=$app_resizable \
--maximized=$app_maximized \
--icon="$app_icon_path"
