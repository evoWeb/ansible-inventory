#!/bin/bash -e

tags=''

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

function runPlaybook () {
	local host
	host="$(uname -n)"

	cd "${BASE_DIR}"
	ansible-playbook -c "local" -i "${BASE_DIR}/hosts" -l "${host}" "${BASE_DIR}/site.yml" -e "username=$(logname)" ${tags}
}

function main () {
	runPlaybook
}
main
