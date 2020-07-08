#!/bin/bash -e
# Partitions
# 1024M efi /boot/efi
# 16G Swap same size as Arbeitsspeicher
# 50G ext4 /
# Rest ext4 /home

if [[ $(id -u) -ne 0 ]]; then
	echo 'Script can only be run as root'
	exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tags=*)
      tags="-t ${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done

readonly BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null 2>&1 && pwd )"

function printMessage () {
	printf "$1\n----------------\n"
}

function prepareHostname () {
	local newHostname=$1
	local currentHostname=$(uname -n)

	if [[ -z ${newHostname} ]]; then
		read -r -p "Enter hostname to use or leave empty to use already set (${currentHostname}) and press [ENTER]: " newHostname
		if [[ -z ${newHostname} ]]; then
			newHostname=${currentHostname}
		fi
		if [[ -z ${newHostname} ]]; then
			echo 'WARNING: The hostname was neither entered nor determined'
			exit 1
		fi
	fi
	echo "Use ${newHostname} as machine name"
	hostname ${newHostname}

	printMessage 'Prepared hostname'
}

function prepareGitConfiguration () {
	gitPath='/root/.git/'
	if [[ ! -d ${gitPath} ]]; then
		mkdir ${gitPath}
	fi
	if [[ ! -f "${gitPath}config" ]]; then
		touch "${gitPath}config"
	fi

	apt install git -y

	printMessage 'Prepared GIT config'
}

function prepareAnsibleRepository () {
	if ! grep -rq 'ansible' '/etc/apt/sources.list.d/'; then
		sudo apt-add-repository ppa:ansible/ansible -y
	fi

	printMessage 'Added Ansible repository'
}

function installAnsible () {
	if ! dpkg -l | grep -q ansible; then
		apt update -y && apt install ansible -y
	fi

	printMessage 'Installed Ansible'
}

function checkoutRepositories () {
	readonly SSH_HOST='github.com'
	readonly SSH_USER='git'

	if [[ ! -d "${BASE_DIR}" ]]; then
		git clone ${SSH_USER}@${SSH_HOST}:evoWeb/ansible-inventory.git "${BASE_DIR}"
		ACTION='cloned'
	else
		git -C "${BASE_DIR}" pull
		ACTION='updated'
	fi

	printMessage "Ansible repository ${ACTION}"
}

function runPlaybook () {
	local host=$(uname -n)

	ansible-playbook -c "local" -i "${BASE_DIR}/hosts" -l "${host}" "${BASE_DIR}/site.yml" -e "username=$(logname)" ${tags}
}

function main () {
	prepareHostname
	prepareGitConfiguration
	#prepareAnsibleRepository
	installAnsible
	checkoutRepositories
	runPlaybook
}
main
