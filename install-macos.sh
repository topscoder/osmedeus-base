#!/usr/local/bin/bash

# global stuff
BASE_PATH="$HOME/osmedeus-base"
BINARIES_PATH="$BASE_PATH/binaries"
DATA_PATH="$BASE_PATH/data"
TMP_DIST="/tmp/tmp-binaries"
BAK_DIST="/tmp/bak-osm"
DEFAULT_SHELL="$HOME/.bashrc"
CWD=$(pwd)
PACKGE_MANAGER="apt-get"

SUDO="sudo"
if [ "$(whoami)" == "root" ]; then
    SUDO=""
fi
[ -x "$(command -v apt)" ] && PACKGE_MANAGER="apt"
if [ -f "$HOME/.zshrc" ]; then
    DEFAULT_SHELL="$HOME/.zshrc"
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
    PACKGE_MANAGER="brew"
else
    PACKGE_MANAGER="apt"
fi

install_banner() {
    echo -e "\033[1;37m[\033[1;34m+\033[1;37m]\033[1;32m Installing $1 \033[0m"
}

announce() {
    echo -e "\033[1;37m[\033[1;31m+\033[1;37m]\033[1;32m $1 \033[0m"
}

download() {
    wget -q -O $1 $2
    if [ ! -f "$1" ]; then
        wget -q -O $1 $2
    fi
}

extractZip() {
	unzip -q -o -j $1 -d $BINARIES_PATH/
	rm -rf $1
}

extractGz() {
	tar -xf $1 -C $BINARIES_PATH/
	rm -rf $1
}

announce "NOTE that this installation only works on\033[0m Linux (x86) and MacOS Intel chip (and experimental on Apple Silicon chip)"
if [[ "$OSTYPE" == "linux"* ]]; then
    $SUDO $PACKGE_MANAGER update -qq > /dev/null 2>&1
    touch /var/lib/cloud/instance/locale-check.skip > /dev/null 2>&1
    install_banner "wget, git, make, nmap, masscan, chromium, golang"
    [ -x "$(command -v wget)" ] || $SUDO $PACKGE_MANAGER install wget -y >/dev/null 2>&1
    [ -x "$(command -v curl)" ] || $SUDO $PACKGE_MANAGER install curl -y >/dev/null 2>&1
    [ -x "$(command -v tmux)" ] || $SUDO $PACKGE_MANAGER install tmux -y >/dev/null 2>&1
    [ -x "$(command -v git)" ] || $SUDO $PACKGE_MANAGER install git -y >/dev/null 2>&1
    [ -x "$(command -v nmap)" ] || $SUDO $PACKGE_MANAGER install nmap -y >/dev/null 2>&1
    [ -x "$(command -v masscan)" ] || $SUDO $PACKGE_MANAGER install masscan -y >/dev/null 2>&1
    [ -x "$(command -v chromium)" ] || $SUDO $PACKGE_MANAGER install chromium -y >/dev/null 2>&1
    [ -x "$(command -v make)" ] || $SUDO $PACKGE_MANAGER install build-essential -y >/dev/null 2>&1
    [ -x "$(command -v rg)" ] || $SUDO $PACKGE_MANAGER install ripgrep -y >/dev/null 2>&1
    [ -x "$(command -v unzip)" ] || $SUDO $PACKGE_MANAGER install unzip -y >/dev/null 2>&1
    [ -x "$(command -v chromium-browser)" ] || $SUDO $PACKGE_MANAGER install chromium-browser -y >/dev/null 2>&1
    [ -x "$(command -v make)" ] || $SUDO $PACKGE_MANAGER install build-essential -y >/dev/null 2>&1
else
    PACKGE_MANAGER="brew"
    [ -x "$(command -v wget)" ] || $PACKGE_MANAGER install wget -q >/dev/null 2>&1
    [ -x "$(command -v curl)" ] || $PACKGE_MANAGER install curl -q >/dev/null 2>&1
    [ -x "$(command -v tmux)" ] || $PACKGE_MANAGER install tmux -q >/dev/null 2>&1
    [ -x "$(command -v git)" ] || $PACKGE_MANAGER install git -q >/dev/null 2>&1
    [ -x "$(command -v nmap)" ] || $PACKGE_MANAGER install nmap -q >/dev/null 2>&1
    [ -x "$(command -v masscan)" ] || $PACKGE_MANAGER install masscan -q >/dev/null 2>&1
    [ -x "$(command -v chromium)" ] || $PACKGE_MANAGER install chromium -q >/dev/null 2>&1
    [ -x "$(command -v make)" ] || $PACKGE_MANAGER install build-essential -q >/dev/null 2>&1
    [ -x "$(command -v rg)" ] || $PACKGE_MANAGER install ripgrep -q >/dev/null 2>&1
    [ -x "$(command -v unzip)" ] || $PACKGE_MANAGER install unzip -q >/dev/null 2>&1
    [ -x "$(command -v chromium-browser)" ] || $PACKGE_MANAGER install chromium-browser -q >/dev/null 2>&1
    [ -x "$(command -v timeout)" ] || $PACKGE_MANAGER install coreutils -q >/dev/null 2>&1
fi

announce "\033[1;34mSet Data Directory:\033[1;37m $DATA_PATH \033[0m"
announce "\033[1;34mSet Binaries Directory:\033[1;37m $BINARIES_PATH \033[0m"

announce "Clean up old stuff first"
rm -rf $BINARIES_PATH/* && mkdir -p $BINARIES_PATH >/dev/null 2>&1
mkdir -p "$GO_DIR" >/dev/null 2>&1

if [ -d "$HOME/osmedeus-base/data" ]; then
    announce "Backup old osmedeus custom data. If you want a fresh install please run the command: \033[0mrm -rf $HOME/osmedeus-base $HOME/.osmedeus\033[0m"
    rm -rf $BAK_DIST
    mv $HOME/osmedeus-base $BAK_DIST
fi

announce "Cloning Osmedeus base repo:\033[0m https://github.com/osmedeus/osmedeus-base"
rm -rf $BASE_PATH && git clone --quiet --depth=1 https://github.com/osmedeus/osmedeus-base $BASE_PATH
# retry to clone in case of anything wrong with the connection
if [ ! -d "$BASE_PATH" ]; then
    git clone --quiet --depth=1 https://github.com/osmedeus/osmedeus-base $BASE_PATH
fi

[ -z "$(which osmedeus)" ] && osmBin=/usr/local/bin/osmedeus || osmBin=$(which osmedeus)
announce "Setup Osmedeus Core Engine:\033[0m $osmBin"
if [[ "$OSTYPE" == "darwin"* ]]; then
    unzip -q -o -j $BASE_PATH/dist/osmedeus-macos.zip -d $BASE_PATH/dist/
else
    unzip -q -o -j $BASE_PATH/dist/osmedeus-linux.zip -d $BASE_PATH/dist/
fi
rm -rf $osmBin && cp $BASE_PATH/dist/osmedeus $osmBin && chmod +x $osmBin
if [ ! -f "$osmBin" ]; then
    echo "[!] Unable to copy the Osmedeus binary to: $osmBin"
    osmBin="$BINARIES_PATH/osmedeus"
    announce "Copying Osmedeus binary to $osmBin instead"
fi

######## Start to install binaries

mkdir -p $BINARIES_PATH >/dev/null 2>&1

install_banner "massdns"
cd $BINARIES_PATH
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install massdns -q
    cp $(which massdns) $BINARIES_PATH/massdns
else
    git clone --quiet --depth=1 https://github.com/blechschmidt/massdns build-massdns
    rm -rf build-massdns/.git
    cd build-massdns
    make 2>&1 > /dev/null
    cp bin/massdns /usr/local/bin/
    cp bin/massdns $BINARIES_PATH/massdns
fi
cd $BASE_PATH

install_banner "findomain"
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install findomain -q
    cp $(which findomain) $BINARIES_PATH/findomain
else
    download $TMP_DIST/findomain.zip https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux.zip
    extractZip $TMP_DIST/findomain.zip
fi
chmod +x $BINARIES_PATH/findomain

install_banner "semgrep"
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install semgrep -q
else
    python3 -m pip -q install semgrep
fi
cp $(which semgrep) $BINARIES_PATH/semgrep

install_banner "packer"
rm -rf $TMP_DIST/packer.zip
PACKER_VERSION=1.8.6
if [[ "$OSTYPE" == "darwin"* ]]; then
    download $TMP_DIST/packer.zip https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_darwin_amd64.zip
else
    download $TMP_DIST/packer.zip https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip
fi
extractZip $TMP_DIST/packer.zip

install_banner "csvtk"
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install csvtk -q
    cp $(which csvtk) $BINARIES_PATH/csvtk
else
    download $TMP_DIST/csvtk.gz https://github.com/shenwei356/csvtk/releases/download/v0.22.0/csvtk_linux_amd64.tar.gz
    extractGz $TMP_DIST/csvtk.gz
fi

install_banner "rustscan"
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install rustscan -q
else
    wget -q -O /tmp/rustscan.deb https://github.com/RustScan/RustScan/releases/download/2.0.1/rustscan_2.0.1_amd64.deb
    dpkg -i /tmp/rustscan.deb 2>&1 > /dev/null
    rm -rf /tmp/rustscan.deb
fi
cp $(which rustscan) $BINARIES_PATH/rustscan

cd $CWD

# update golang version
install_banner "Golang latest version"

# delete old go binaries if it detect
if [ -d "$HOME/.go/bin/" ]; then
    rm -rf $HOME/.go/
fi

GO_BIN=$(which go)

if [ -f "$GO_BIN" ]; then
    echo -e "\033[1;32m[+] Detected go binary: $GO_BIN \033[0m"
    brew uninstall golang -q
fi

# (re)install fresh golang
brew install golang -q 2>&1 > /dev/null
export GO_LATEST_VERSION=$(curl -s 'https://go.dev/VERSION?m=text'|grep 'go'|sed 's/go//g')
if [ -z "$(command -v go)" ]; then 
    install_banner "latest go version: $GO_LATEST_VERSION"
    wget -q -O - https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash -s -- --version $GO_LATEST_VERSION
fi


# Go is installed via Brew, so GOROOT, GOPATH are set
export GOPATH=$(go env GOPATH)
export GO_BIN=$(which go)
export GO_DIR="$GOPATH/bin"

echo -e "\033[1;32m[+] Detected go binary: $GO_BIN \033[0m"
echo -e "\033[1;32m[+] Detected go tools: $GO_DIR \033[0m"
CURRENT_GO=$(go version)
echo -e "\033[1;32m[+] Required golang verion >= v1.17 \033[0m"
echo -e "\033[1;32m[+] Detected current golang version: $CURRENT_GO \033[0m"

cd $CWD

##
# Install go stuff
##
install_banner "goaltdns"
$GO_BIN install github.com/subfinder/goaltdns@latest 2>&1 > /dev/null
install_banner "goaltdns"
$GO_BIN install github.com/subfinder/goaltdns@latest 2>&1 > /dev/null
install_banner "assetfinder"
$GO_BIN install github.com/tomnomnom/assetfinder@latest 2>&1 > /dev/null
install_banner "httprobe"
$GO_BIN install github.com/tomnomnom/httprobe@latest 2>&1 > /dev/null
install_banner "unfurl"
$GO_BIN install github.com/tomnomnom/unfurl@latest 2>&1 > /dev/null
$GO_BIN install github.com/tomnomnom/anew@latest 2>&1 > /dev/null
install_banner "go cli-utils"
$GO_BIN install github.com/shenwei356/rush@latest/ 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/go-auxs/chrunk@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/cinfo@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/cdnstrip@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/str-replace@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/go-auxs/eip@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/go-auxs/durl@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/go-auxs/ourl@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/go-auxs/urp@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/go-auxs/cleansub@latest 2>&1 > /dev/null
$GO_BIN install github.com/j3ssie/go-auxs/junique@latest 2>&1 > /dev/null
$GO_BIN install github.com/theblackturtle/ptools/wurl@latest 2>&1 > /dev/null
install_banner "aquatone"
$GO_BIN install github.com/michenriksen/aquatone@latest 2>&1 > /dev/null
install_banner "gowitness"
$GO_BIN install github.com/sensepost/gowitness@latest 2>&1 > /dev/null
install_banner "goverview"
$GO_BIN install github.com/j3ssie/goverview@latest 2>&1 > /dev/null
install_banner "github-endpoints"
$GO_BIN install github.com/gwen001/github-endpoints@latest 2>&1 > /dev/null
install_banner "github-subdomains"
$GO_BIN install github.com/gwen001/github-subdomains@latest 2>&1 > /dev/null
GO111MODULE=off $GO_BIN get -u github.com/Josue87/gotator 2>&1 > /dev/null
install_banner "puredns"
$GO_BIN install github.com/d3mondev/puredns/v2@latest 2>&1 > /dev/null

install_banner "amass"
$GO_BIN install github.com/owasp-amass/amass/v4/...@master > /dev/null
install_banner "gau"
$GO_BIN install github.com/lc/gau@latest 2>&1 > /dev/null
install_banner "shuffledns"
$GO_BIN install github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest 2>&1 > /dev/null
install_banner "dnsx"
$GO_BIN install github.com/projectdiscovery/dnsx/cmd/dnsx@latest 2>&1 > /dev/null
install_banner "tlsx"
$GO_BIN install github.com/projectdiscovery/tlsx/cmd/tlsx@latest 2>&1 > /dev/null
install_banner "alterx"
$GO_BIN install github.com/projectdiscovery/alterx/cmd/alterx@latest 2>&1 > /dev/null
install_banner "katana"
$GO_BIN install github.com/projectdiscovery/katana/cmd/katana@latest 2>&1 > /dev/null
install_banner "httpx"
$GO_BIN install github.com/projectdiscovery/httpx/cmd/httpx@latest 2>&1 > /dev/null
install_banner "nuclei"
$GO_BIN install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest 2>&1 > /dev/null
install_banner "subfinder"
$GO_BIN install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>&1 > /dev/null
install_banner "gospider"
$GO_BIN install github.com/jaeles-project/gospider@latest 2>&1 > /dev/null
install_banner "jaeles"
$GO_BIN install github.com/jaeles-project/jaeles@latest 2>&1 > /dev/null
install_banner "metabigor"
$GO_BIN install github.com/j3ssie/metabigor@latest 2>&1 > /dev/null
install_banner "trufflehog"
$GO_BIN install github.com/trufflesecurity/trufflehog@latest 2>&1 > /dev/null

echo -e "\033[1;32m[+] Copy all go tools from: $GO_DIR \033[0m"
cp $GO_DIR/* $BINARIES_PATH/ >/dev/null 2>&1
chmod +x $BINARIES_PATH/*
export PATH=$BINARIES_PATH:$PATH

###### done the binaries part

osmedeus config reload
install_banner "Osmedeus Web UI"
rm -rf $HOME/.osmedeus/server/* >/dev/null 2>&1
mkdir -p $HOME/.osmedeus/server >/dev/null 2>&1
cp -R $BASE_PATH/ui $HOME/.osmedeus/server/ui >/dev/null 2>&1

install_banner "Osmedeus Community Workflow:\033[0m https://github.com/osmedeus/osmedeus-workflow"
rm -rf $BASE_PATH/workflow >/dev/null 2>&1
git clone --quiet --depth=1 https://github.com/osmedeus/osmedeus-workflow $BASE_PATH/workflow
## retry to clone in case of anything wrong with the connection
if [ ! -d "$BASE_PATH/workflow" ]; then
    git clone --quiet --depth=1 https://github.com/osmedeus/osmedeus-workflow $BASE_PATH
fi

announce "Downloading Vulnerability templates"
jaeles config init >/dev/null 2>&1
rm -rf $HOME/nuclei-templates && git clone --quiet --depth=1 https://github.com/projectdiscovery/nuclei-templates.git $HOME/nuclei-templates >/dev/null 2>&1

if [ -d "$BAK_DIST/data" ]; then
    announce "Updating old data + cloud config ..."
    rm -rf $HOME/osmedeus-base/data && cp -R $BAK_DIST/data $HOME/osmedeus-base/data
fi
if [ -d "$BAK_DIST/cloud" ]; then
    rm -rf $HOME/osmedeus-base/cloud && cp -R $BAK_DIST/cloud $HOME/osmedeus-base/cloud
fi
if [ -d "$BAK_DIST/token" ]; then
    rm -rf $HOME/osmedeus-base/token && cp -R $BAK_DIST/token $HOME/osmedeus-base/token
fi
rm -rf $BAK_DIST >/dev/null 2>&1

###### Private installation for premium package

if [ -f "$BASE_PATH/secret/secret.sh" ]; then
    install_banner "private component"
    . $BASE_PATH/secret/secret.sh
fi

echo "---->>>"
osmedeus health
echo "---->>>"

announce "The installation is done..."
announce "Check here if you want to setup API & token:\033[0m https://docs.osmedeus.org/installation/token/"
announce "Run\033[0m source $DEFAULT_SHELL \033[1;32mto complete the install"
osmedeus config set --threads-hold=10
osmedeus config set --client-name PublicIP
announce "You can change the default Threads Hold with the command:\033[0m osmedeus config set --threads-hold=<number-of-threads> \033[1;32m"
