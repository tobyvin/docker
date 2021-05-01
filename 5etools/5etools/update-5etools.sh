#!/bin/sh
set -e

# Set the path below to the base directory for your site, the webroot will be in a `html` directory below this path.
TARGETPATH="/usr/share/nginx"

# --- Do not modify below this line -- #

htmlpath="${TARGETPATH}/html"
tmppath="${TARGETPATH}/tmp"
mkdir -p "${htmlpath}" || true
mkdir -p "${tmppath}" || true

echo >&3 "$0: Checking for updates..."

for asset in "release" "img"; do
    filename=$(curl -s -I "https://get.5e.tools/${asset}/" | grep filename | cut -d"=" -f2 | awk '{print $1}' | sed -e 's#["\t\r\n]##g')
    localversion="$(cat ${TARGETPATH}/.${asset}-version || true)"
    if [ "$filename" != "$localversion" ]; then
        echo >&3 "$0: Update found. Updating to newest version ($filename)..."
        echo -n "$filename" >"${TARGETPATH}/.${asset}-version"
        cd "$tmppath"
        curl -O -J "https://get.5e.tools/${asset}/"
        mkdir -p "${tmppath}/${asset}"
        cd "${tmppath}/${asset}"
        unzip -q -o -u "${tmppath}/${filename}"
        if [ "$asset" = "release" ]; then
            rsync -a --delete --exclude="img" --exclude=".well-known" "${tmppath}/${asset}/" "${htmlpath}/"
            echo "User-agent: *\nDisallow: /" | tee "${htmlpath}/robots.txt" >/dev/null
            ln -sf "${htmlpath}/5etools.html" "${htmlpath}/index.html"
            sed -i 's#navigator.serviceWorker.register("/sw.js#navigator.serviceWorker.register("sw.js#g' "${htmlpath}/5etools.html"
        elif [ "$asset" = "img" ]; then
            rsync -a --delete "${tmppath}/${asset}/tmp/5et/img/" "${htmlpath}/img/"
        fi
        rm -rf "${tmppath}/${asset}"
        rm -f "${tmppath}/${filename}"
    else
        echo >&3 "$0: No updates found. Currently on the newest version ($localversion)."
    fi
done
