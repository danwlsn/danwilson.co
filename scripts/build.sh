#!/usr/bin/env bash
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Build blog to public folder

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-u, --url       Base URL for zola build
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -u | --url)
      BASE_URL="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ -z "${BASE_URL-}" ]] && die "Missing required parameter: url"

  return 0
}

parse_params "$@"
setup_colors

DOCKER_WK_DIR="/app"
PWD=$(pwd)
APP_MOUNT="${PWD}:${DOCKER_WK_DIR}"

msg "${PURPLE}Building site:${NOFORMAT}"
msg "- url: ${GREEN}${BASE_URL}${NOFORMAT}"
msg "Mount point: ${APP_MOUNT}"

docker run -u "$(id -u):$(id -g)" \
    -v $APP_MOUNT --workdir $DOCKER_WK_DIR \
    ghcr.io/getzola/zola:v0.16.0 \
    build --base-url $BASE_URL
