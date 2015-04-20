#!/bin/bash -e

[ "$GEOIP_LICENSE_KEY" == "" ] && exit 0

DIR="/tmp/geoip"
mkdir $DIR

curl "https://download.maxmind.com/app/geoip_download?edition_id=106&suffix=tar.gz&license_key=${GEOIP_LICENSE_KEY}" \
  |tar -xz --strip-components 1 -C $DIR

cp $DIR/Geo*.dat db/GeoIP.dat

rm -rf $DIR
