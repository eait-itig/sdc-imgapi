#!/bin/bash
#
# Remove the test data.
#

if [[ -n "$TRACE" ]]; then
    export PS4='[\t] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi
set -o errexit
set -o pipefail


TOP=$(unset CDPATH; cd $(dirname $0)/; pwd)


function fatal
{
    echo "$(basename $0): fatal error: $*"
    exit 1
}

function cleanup () {
    local status=$?
    if [[ $status -ne 0 ]]; then
        echo "error $status (run 'TRACE=1 $0' for more info)"
    fi
}
trap 'cleanup' EXIT


#---- mainline

# Luke's created datasets.
dns=$($TOP/sdc-ldap s -b 'ou=images, o=smartdc' '(&(objectclass=sdcimage)(owner=91ba0e64-2547-11e2-a972-df579e5fddb3))' \
    | (grep '^dn' || true) | cut -d' ' -f2- | sed 's/, /,/g' | xargs)
# All the test-data.ldif dns.
dns+=" $(grep '^dn' $TOP/test-data.ldif | cut -d' ' -f2- | sed 's/, /,/g' | xargs)"

for dn in $dns; do
    if [[ -n "$($TOP/sdc-ldap search -b "$dn")" ]]; then
        echo "Deleting '$dn'."
        $TOP/sdc-ldap rm "$dn"
    fi
done
