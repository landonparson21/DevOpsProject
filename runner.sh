#!/bin/bash
# Authenticate, decrypt, and run the licensed script using Ubuntu shell utilities.
set -euo pipefail
umask 077

runner_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$runner_directory/licensing.sh"

encrypted_file=$runner_directory/UserManager.sh.enc
license_file=''
while (( $# )); do
    case $1 in
        --script|--license)
            [[ $# -ge 2 && -n $2 ]] || die "$1 requires a path."
            if [[ $1 == --script ]]; then encrypted_file=$2; else license_file=$2; fi
            shift 2 ;;
        --) shift; break ;;
        -h|--help)
            printf 'Usage: bash runner.sh [--script FILE] [--license FILE] [-- SCRIPT_ARGUMENTS...]\n'
            exit 0 ;;
        *) die "Unknown option: $1 (put script arguments after --)." ;;
    esac
done
encrypted_file=$(realpath -m -- "$encrypted_file")
[[ -f $encrypted_file && -r $encrypted_file ]] || die "Cannot read encrypted script: $encrypted_file"
if [[ -z $license_file ]]; then
    for candidate in "$(dirname -- "$encrypted_file")/license.dat" \
        "$runner_directory/license.dat" "$PWD/license.dat"; do
        if [[ -f $candidate ]]; then
            license_file=$candidate
            break
        fi
    done
    [[ -n $license_file ]] || die 'license.dat was not found. Place it beside the payload or runner, in the current directory, or use --license PATH.'
fi
configure_openssl
load_license "$license_file"

temporary_directory=''
child_pid=''
cleanup() {
    local status=$? attempt
    trap - EXIT
    trap '' INT TERM HUP
    if [[ -n $child_pid ]] && kill -0 "$child_pid" 2>/dev/null; then
        kill -TERM "$child_pid" 2>/dev/null || :
        for attempt in {1..50}; do
            kill -0 "$child_pid" 2>/dev/null || break
            sleep 0.1
        done
        if kill -0 "$child_pid" 2>/dev/null; then kill -KILL "$child_pid" 2>/dev/null || :; fi
        wait "$child_pid" 2>/dev/null || :
    fi
    if [[ -n $temporary_directory ]]; then rm -rf -- "$temporary_directory"; fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
temporary_directory=$(mktemp -d -- "${TMPDIR:-/tmp}/halberd-run.XXXXXXXX")

{
    IFS= read -r header || die 'Invalid encrypted script header.'
    IFS= read -r expected_tag || die 'Missing authentication tag.'
    [[ $header == "$PAYLOAD_MAGIC" && $expected_tag =~ ^[0-9a-f]{64}$ ]] || die 'Invalid encrypted script format.'
    # Authenticate and decrypt this same private snapshot, even if the input changes.
    cat > "$temporary_directory/ciphertext"
} < "$encrypted_file"
actual_tag=$(authentication_tag "$temporary_directory/ciphertext")
[[ $actual_tag == "$expected_tag" ]] || die 'License does not match the script, or the encrypted script was modified.'
if ! openssl enc -d "${cipher_options[@]}" -in "$temporary_directory/ciphertext" \
    -out "$temporary_directory/protected.sh" -pass fd:3 3<<< "$license_password"; then
    die 'Script decryption failed; check the matching license and encrypted file.'
fi

# An asynchronous child makes wait interruptible; explicitly preserve terminal input.
bash "$temporary_directory/protected.sh" "$@" <&0 &
child_pid=$!
status=0
wait "$child_pid" || status=$?
child_pid=''
exit "$status"
