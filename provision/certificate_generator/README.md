# certificate_generator
Generate and Sign SSL certificates (for use with WiFi-WASP EAP_TLS)

Run these scripts on Linux only. Ubuntu 16.04 LTS was used to create/test this repository.

OpenSSL must be installed.

Scripts must be executed as root user, from the certificate_generator root directory.

Run ./scripts/restore.sh first, followed by ./scripts/init.sh and finally ./scripts/make_clients.sh

Options exist for init.sh and make_clients.sh. Read the scripts for details.

TODO
Update README with script options.
Update scripts to provide -h|-help output.
Consider converting options from single - to double -- 'eg -help to --help'