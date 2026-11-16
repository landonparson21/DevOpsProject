# User Migration for hAlberd Technologies

This software creates Linux user accounts automatically from the Tennessee Tech
Computer Science faculty page, or manually from names you enter. Account creation
requires sudo access. Automatic creation also requires internet access.

## Requirements

The licensing tools use Bash, OpenSSL 1.1.1 or later, and standard GNU utilities
such as `mktemp`, `realpath`, and `rm`, available on Ubuntu. Check OpenSSL and curl with:

```sh
openssl version
curl --version
```

If OpenSSL or curl is missing, install the missing package:

```sh
sudo apt install openssl curl
```

Curl is used by the automatic account creation option.

## Quick Start

1. Clone the repository:
```sh
git clone https://github.com/landonparson21/DevOpsProject.git
```
2. Move the license.dat file into the cloned project directory.
3. Run the program (license.sh is not the program, that script is the license encryption engine):
```sh
bash runner.sh
```

## Build the licensed version

The maintainer runs this command in the project folder:

```sh
bash licensing.sh
```

This encrypts `UserManager.sh` into `UserManager.sh.enc` and creates `license.dat`. Encryption
uses AES-256-CBC with PBKDF2-SHA256 (200,000 iterations) and a fresh random salt for
every build. A separate random key authenticates the ciphertext with HMAC-SHA256.
The runner verifies this HMAC before decrypting or executing anything.

The OpenSSL `enc` command does not support GCM; see the
[OpenSSL encryption documentation](https://docs.openssl.org/3.0/man1/openssl-enc/).
An 8-byte salt is used consistently across older and newer OpenSSL releases.
The encryption password is passed through a file descriptor rather than a
command-line argument. The HMAC key is passed to OpenSSL's MAC option.

## Run the licensed version

Open a terminal in the distribution folder and run:

```sh
bash runner.sh
```

The runner loads `UserManager.sh.enc` beside itself and finds `license.dat` in this order:

1. Beside the encrypted script.
2. Beside `runner.sh`.
3. In the current working directory.

The first file found is used. To specify paths explicitly:

```sh
bash runner.sh --script /path/to/UserManager.sh.enc --license /path/to/license.dat
```

An explicitly supplied license does not fall back to another file. Pass arguments
to the protected script after `--`.

The runner checks the license and HMAC, decrypts into a private temporary directory
(`0700`) with an owner-only script (`0600`), and executes it with Bash. Terminal
input, arguments, and the working directory are preserved. The temporary files and
directory are removed after success, script errors, Ctrl+C, SIGTERM, or SIGHUP.
If interrupted, the runner terminates the protected shell before cleanup. The
license and encrypted file remain available for later runs. SIGKILL, power loss,
or a system crash can prevent cleanup; deletion does not guarantee forensic erasure.

The runner returns the script's exit status, `1` for license or decryption errors,
or `128 + signal number` when interrupted.

## Menu

After license verification, the script displays:

1. **Add Users Automatically** — fetch the faculty page with curl and create accounts.
2. **Add a User Manually** — prompt for a first and last name and create an account.
3. **Exit** — end the program.

You may be asked for your sudo password when creating accounts. Automatic creation
writes `faculty.txt` and `names.txt` in the current working directory.

## Troubleshooting and tests

- **License not found:** put `license.dat` next to the encrypted file or runner,
  or specify its location with `--license`.
- **Invalid license:** restore the original license file without editing its contents.
- **License mismatch or modified script:** restore the matching encrypted file and
  license, or ask the maintainer to rebuild the pair.
- **Missing OpenSSL:** install it with `sudo apt install openssl`.
