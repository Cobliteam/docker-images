#!/bin/sh

gen_config() {
    local tmp_file
    tmp_file=$(mktemp) || return $?
    cat > "$tmp_file" <<EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
CN = Squid Proxy CA

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = cRLSign, keyCertSign
EOF
    echo "$tmp_file"
}


dir="$1"
shift

if [ ! -d "$dir" ]; then
    echo "Error: directory '$dir' does not exist" >&2
    exit 1
fi

if [ -f "$dir/ca.pem" -a -f "$dir/ca.key" ]; then
    exit 0
fi

config=$(gen_config) || exit 1
trap "rm -f '$config'" EXIT

openssl req \
  -config "$config" \
  -new -nodes -x509 -extensions v3_ca \
  -newkey rsa:4096 -sha256 -days 365 \
  -keyout "$dir/ca.key" -out "$dir/ca.pem"
