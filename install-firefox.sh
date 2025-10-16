#!/usr/bin/env bash

# create /etc/apt/keyrings
echo "Creating the required /etc/apt/keyrings directory..."
if [[ ! -d /etc/apt/changes ]]; then
    sudo install -d -m 0755 /etc/apt/keyrings
else
    echo "...skipping...already exists"
fi

# download Mozilla repo signing key
KEY_EXISTS="0"
if [[ ! -f "/etc/apt/keyrings/packages.mozilla.org.asc" ]]; then
    echo "Downloading the Mozilla repository signing key..."
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    KEY_EXISTS="1"
else
    echo "...skipping...already exists"
fi

# check fingerprint
echo "Verifying the downloaded key's fingerprint..."
if [[ "KEY_EXISTS" -eq "1" ]]; then 
    gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
fi

# create Mozilla APT repo file
echo "Creating the Mozilla APT repository source file..."
if [[ ! -f "/etc/apt/sources.list.d/mozilla.sources" ]]; then
    cat <<EOF | sudo tee /etc/apt/sources.list.d/mozilla.sources
    Types: deb
    URIs: https://packages.mozilla.org/apt
    Suites: mozilla
    Components: main
    Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF
else
    echo "...skipping...already exists"
fi

# create APT pin file to prefer Firefox from Mozilla repo
echo "Creating the APT preference (pinning) file..."
if [[ ! -f "/etc/apt/preferences.d/mozilla" ]]; then
    echo '
    Package: *
    Pin: origin packages.mozilla.org
    Pin-Priority: 1000
    ' | sudo tee /etc/apt/preferences.d/mozilla 
else
    echo "...skipping...already exists"
fi

# install Firefox
echo "Running 'sudo apt-get update' and installing Firefox..."
echo
sudo apt-get update && sudo apt-get install firefox
