#!/bin/bash
# Shared license functions; executed directly, builds an encrypted Bash script.

LICENSE_MAGIC='HALBERD-LICENSE-V1'
PAYLOAD_MAGIC='HALBERD-AES256-CBC-HMAC-SHA256-V1'

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

configure_openssl() {
    command -v openssl >/dev/null 2>&1 || die 'OpenSSL is required (sudo apt install openssl).'
    cipher_options=(-aes-256-cbc -pbkdf2 -iter 200000 -md sha256)
    local help_text
    help_text=$(openssl enc -help 2>&1)
    # OpenSSL 3.2+ exposes salt length; older versions always use 8 bytes.
    # Fix it explicitly where available so bundles work across Ubuntu versions.
    if [[ $help_text == *-saltlen* ]]; then
        cipher_options+=(-saltlen 8)
    fi
}

load_license() {
    local path=$1
    local -a lines=()
    [[ -f $path && -r $path ]] || die "Cannot read license file: $path"
    mapfile -t lines < "$path"
    [[ ${#lines[@]} -eq 3 ]] || die "Invalid license file: $path"
    [[ ${lines[0]} == "$LICENSE_MAGIC" &&
       ${lines[1]} =~ ^[0-9a-f]{64}$ &&
       ${lines[2]} =~ ^[0-9a-f]{64}$ ]] || die "Invalid license file: $path"
    license_password=${lines[1]}
    authentication_key=${lines[2]}
}

authentication_tag() {
    local digest
    # Bind both license secrets and the format to the ciphertext. A damaged
    # encryption password must fail authentication before any decryption.
    digest=$(
        { printf '%s\n%s\n' "$PAYLOAD_MAGIC" "$license_password"; cat -- "$1"; } |
            openssl dgst -sha256 -mac HMAC -macopt "hexkey:$authentication_key"
    ) || return 1
    printf '%s\n' "${digest##* }"
}

encrypt_main() {
    set -euo pipefail
    umask 077
    local script_dir source_file output_file='' license_file='' source_set=0
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
    source_file=$script_dir/UserManager.sh
    while (( $# )); do
        case $1 in
            --output|--license)
                [[ $# -ge 2 && -n $2 ]] || die "$1 requires a path."
                if [[ $1 == --output ]]; then output_file=$2; else license_file=$2; fi
                shift 2 ;;
            -h|--help)
                printf 'Usage: bash licensing.sh [SOURCE] [--output FILE] [--license FILE]\n'
                return 0 ;;
            -*) die "Unknown option: $1" ;;
            *)
                (( source_set == 0 )) || die 'Only one source script may be supplied.'
                source_file=$1
                source_set=1
                shift ;;
        esac
    done
    output_file=${output_file:-$source_file.enc}
    license_file=${license_file:-$(dirname -- "$output_file")/license.dat}
    source_file=$(realpath -m -- "$source_file")
    output_file=$(realpath -m -- "$output_file")
    license_file=$(realpath -m -- "$license_file")
    [[ $source_file != "$output_file" && $source_file != "$license_file" &&
       $output_file != "$license_file" ]] || die 'Source, output, and license must be different files.'
    [[ -f $source_file && -r $source_file && -s $source_file ]] || die "Cannot read nonempty source: $source_file"
    [[ ! $source_file -ef $license_file ]] || die 'Source and license must be different files.'
    [[ ! $output_file -ef $license_file ]] || die 'Output and license must be different files.'
    configure_openssl

    # These variables stay in scope until encrypt_main returns and its EXIT trap runs.
    build_directory=$(mktemp -d -- "$(dirname -- "$output_file")/.halberd-build.XXXXXXXX")
    license_temporary=''
    trap 'trap "" INT TERM HUP; rm -rf -- "$build_directory"; if [[ -n $license_temporary ]]; then rm -f -- "$license_temporary"; fi' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    if [[ ! -e $license_file && ! -L $license_file ]]; then
        license_temporary=$(mktemp -- "$(dirname -- "$license_file")/.halberd-license.XXXXXXXX")
        {
            printf '%s\n' "$LICENSE_MAGIC"
            openssl rand -hex 32
            openssl rand -hex 32
        } > "$license_temporary"
        # A hard link publishes the complete license without overwriting an existing one.
        if ! ln -- "$license_temporary" "$license_file" 2>/dev/null; then
            [[ -f $license_file ]] || die "Cannot create license file: $license_file"
        fi
        rm -f -- "$license_temporary"
        license_temporary=''
    fi
    load_license "$license_file"
    openssl enc "${cipher_options[@]}" -salt -in "$source_file" \
        -out "$build_directory/ciphertext" -pass fd:3 3<<< "$license_password"
    local tag
    tag=$(authentication_tag "$build_directory/ciphertext")
    {
        printf '%s\n%s\n' "$PAYLOAD_MAGIC" "$tag"
        cat -- "$build_directory/ciphertext"
    } > "$build_directory/package"
    # Build on the destination filesystem so a failed rebuild leaves the old file intact.
    mv -f -- "$build_directory/package" "$output_file"
    printf 'Encrypted script: %s\nLicense file: %s\n' "$output_file" "$license_file"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    encrypt_main "$@"
fi
