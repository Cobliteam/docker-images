#!/bin/sh

subst_vars() {
    local file
    file="$1"
    shift

    eval "$(printf 'cat <<SQUID_TEMPLATE\n'; \
            sed -e 's/\\/\\\\/g' "$file"; \
            printf '\nSQUID_TEMPLATE\n')"

}

export squid_ssl_dir="${SQUID_SSL_DIR:-/etc/squid/ssl}"
export squid_ssl_db_dir="${SQUID_SSL_DB_DIR:-/var/cache/squid/ssl_db}"
export squid_ssl_db_mem_size="${SQUID_SSL_DB_MEM_SIZE:-4MB}"
export squid_ssl_db_disk_size="${SQUID_SSL_DB_DISK_SIZE:-16MB}"
export squid_cache_max_size_mb="${SQUID_CACHE_MAX_SIZE_MB:-1000}"
export squid_object_max_size="${SQUID_OBJECT_MAX_SIZE:-100 MB}"
export squid_port="${SQUID_PORT:-3128}"
squid_conf_dir=/etc/squid
squid_user=squid

mkdir -p "$squid_ssl_dir"
squid-gen-ca "$squid_ssl_dir"
chown -R "$squid_user:$squid_user" "$squid_ssl_dir"
chmod -R ug=rwX,o= "$squid_ssl_dir"

/usr/lib/squid/security_file_certgen -c -s "$squid_ssl_db_dir" -M "$squid_ssl_db_disk_size"
chown -R "$squid_user:$squid_user" "$squid_ssl_db_dir"
chmod -R ug=rwX,o= "$squid_ssl_db_dir"

if [ ! -f "${squid_conf_dir}/squid.conf" ] || \
   [ "${squid_conf_dir}/squid.conf.template" -nt "${squid_conf_dir}/squid.conf" ]
then
    subst_vars "${squid_conf_dir}/squid.conf.template" > "${squid_conf_dir}/squid.conf"
    cat "${squid_conf_dir}/squid.conf"
fi

exec "$@"
