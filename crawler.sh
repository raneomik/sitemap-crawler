#!/bin/bash

# usage: test_url.sh www.site.com/sitemap.xml
#curl -s $1 | grep -Po 'http(s?)://[^ \"()\<>]*' | xargs -n 1 curl -s -o /dev/null -w "%{url_effective},%{http_code}\n"
#grep -Po 'http(s?)://[^ \"()\<>]*' sitemap.xml | xargs -n 1 curl -s -o /dev/null -w "%{url_effective},%{http_code}\n"

# credits : https://github.com/jasperes/bash-yaml

parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"

    (
        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/\s*$//g;' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e  "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

        awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |

        sed -e 's/_=/+=/g' \
            -e '/\..*=/s|\.|_|' \
            -e '/\-.*=/s|\-|_|'

    ) < "$yaml_file"
}

# Create vars from yml file ($1)
create_variables() {
    local yaml_file="$1"
    eval "$(parse_yaml "$yaml_file")"
}

usage(){
    echo "TO DO usage"
}

if [ "$#" -eq 0 ]; then
    usage
    exit
fi


for i in "$@";do
    case $i in
        -w=*|--website=*)
        WEB="${i#*=}"
        ;;
        -a|--all)
        ALL=0
        ;;
        *)
        usage
        exit
        ;;
    esac
done


create_variables conf.yml
domain=websites_${WEB}_domain
sitemap=websites_${WEB}_sitemap
output=websites_${WEB}_output_file

for i in ${!websites_i};do
    echo $i
done

crawl_sitemap="${!domain}/${!sitemap}"

echo ${crawl_sitemap}
echo ${!output}
exit 1
#curl -s http://www.hec.$1/sitemap-fr.xml
#$1 | grep -Po 'http(s?)://[^ \"()\<>]*' > 30-10-2017-hec.edu-sitemap.txt

curl -s ${crawl_sitemap} | grep -Po 'http(s?)://[^ \"()\<>]*' | xargs -n 1 curl -s -o /dev/null -w "%{url_effective},%{http_code}\n" | grep ",404" > `date +%d-%m-%Y`-404bis-hec.fr-sitemap.txt
