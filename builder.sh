#!/bin/bash
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

# paths
system_path=$( cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P )
source_path=$( dirname "$system_path" )
root_path=$( dirname "$source_path" )
dist_path=$( echo $root_path/dist )
dist_files_path=$( echo $dist_path/files )

# be relative!
cd "$system_path"

# remove dist folder
rm -rf $dist_path

# config
config=$(jq -rcMs '.[0] * .[1]' ./origin.json ../config.json)

# check that all needed fields are present
required_fields=(
    '.title' '.package.id' '.package.version' '.package.author.name'
    '.package.author.email' '.package.description' '.package.section'
    '.package.priority' '.package.architecture' '.package.categories'
)

for field in "${required_fields[@]}"
do
    if [[ $(echo $config | jq -rcMe "$field") == 'null' ]]; then
        echo "Field '"$field"' is missing"
        exit 1
    fi
done

# app config
app_title=$(echo "$config" | jq -rcM '.title')
app_icon_path=$(echo "$config" | jq -rcM '.icon')
app_package_id=$(echo "$config" | jq -rcM '.package.id')
app_package_version=$(echo "$config" | jq -rcM '.package.version')
app_package_author_name=$(echo "$config" | jq -rcM '.package.author.name')
app_package_author_email=$(echo "$config" | jq -rcM '.package.author.email')
app_package_description=$(echo "$config" | jq -rcM '.package.description')
app_package_section=$(echo "$config" | jq -rcM '.package.section')
app_package_priority=$(echo "$config" | jq -rcM '.package.priority')
app_package_architecture=$(echo "$config" | jq -rcM '.package.architecture')
app_package_dependencies=$(echo "$config" | jq -rcM '.package.systemDependencies + .package.dependencies | join(", ")')
app_package_categories=$(echo "$config" | jq -rcM '.package.categories | join(";")')";"


# generate basic folders structure
mkdir -p "$dist_files_path/DEBIAN"
cat > "$dist_files_path/DEBIAN/control" <<EOL
Package: $app_package_id
Version: $app_package_version
Section: $app_package_section
Priority: $app_package_priority
Architecture: $app_package_architecture
Depends: $app_package_dependencies
Maintainer: $app_package_author_name <$app_package_author_email>
Description: $app_package_description
EOL

mkdir -p "$dist_files_path/usr/share/applications"
cat > "$dist_files_path/usr/share/applications/$app_package_id.desktop" <<EOL
[Desktop Entry]
Encoding=UTF-8
Exec=/usr/share/$app_package_id/init.sh
Icon=/usr/share/$app_package_id/$app_icon_path
Type=Application
Terminal=false
Name=$app_title
Categories=$app_package_categories
EOL

mkdir -p "$dist_files_path/usr/share/$app_package_id"
cp -aR $source_path/* "$dist_files_path/usr/share/$app_package_id"

dpkg-deb --build "$dist_files_path" "$dist_path/$app_package_id.deb"

sudo apt autoremove -y $app_package_id
sudo dpkg -i "$dist_path/$app_package_id.deb"
