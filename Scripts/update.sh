#!/bin/bash -e

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
	checkoutRepositories
	runPlaybook
}
main
