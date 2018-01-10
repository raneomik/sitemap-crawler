#!/bin/bash

Color_Off='\033[0m'       # Text Reset
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
Bold='\033[1m'            # Bold text
Underline='\033[4m'       # Underline text

result_dir='results'

# credits : https://github.com/fearside/ProgressBar
# $1 : current value
# $2: max. value
# $3: additional info
progress_bar() {
    # Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    # Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
    [[ -n "$3" ]] && extra=" | ${3}"

    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%% ( checked: ${1}/${2} | elapsed time: $(convertsecs ${SECONDS}) ${extra} )"
}

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

# print seconds passed in $1 in human readable h:m:s format
convertsecs() {
    printf $(date -d@${1} -u +%H:%M:%S)
}

usage(){
    echo -e "./crawl.sh <option>"
    echo -e "-a|--all : \t\t\t crawl all websites defined in conf.yml properties (listed in 'website_list')"
    echo -e "-w|--website=<website_conf_name> :  crawl a website defined in conf.yml properties"
}

check_conf(){
    conf+=(websites_${1}_domain)
    conf+=(websites_${1}_sitemap)
    conf+=(websites_${1}_output_file)
    for i in ${conf[*]}; do
        if [ -z ${!i} ];then
        printf "\t${Red}'${i}' is unset or doesn't exist.
            Please check its existence and provide it in 'conf.yml' file.
            Quitting...${Color_Off}\n"
            exit 1
        fi;
    done
}

# crawl website's sitemap
# $1 : site name in conf.yml
crawl_site(){
    domain=websites_${1}_domain
    sitemap=websites_${1}_sitemap
    output=websites_${1}_output_file
    output="${result_dir}/${!output}"

    only_404=websites_${1}_404_only
    crawl_sitemap="${!domain}/${!sitemap}"

    echo "crawling ${crawl_sitemap}"
    [[ "${!only_404}" == 'true' ]] && errored_only=0
    [ $errored_only ] \
        && echo "checking only for 404 error pages" \
        || echo "checking all sitemap"

    echo "fetching page list..."
    site_list=$(curl -s ${crawl_sitemap} | grep -Po 'http(s?)://[^ \"()\<>]*')
    site_count=$(echo "$site_list" | wc -l)
    time=$({ time curl "${site_list[0]}" -s -o /dev/null -w "%{url_effective},%{http_code}\n" 1>&3 2>&4;} 2>&1 | awk -F'[sm]' '/user/{print $3}')
    estimated=$(echo ${site_count}*${time}*10 | bc)
    SECONDS=0
    counter=1
    count_404=0
    rm ${output} 2> /dev/null

    echo "Number of pages to crawl : ${site_count}"
    echo "Estimated time : $(convertsecs $estimated)"
    for i in ${site_list};do
        [ $errored_only ] \
            && curl ${i} -s -o /dev/null -w "%{url_effective},%{http_code}\n" | grep ",404" >> ${output} \
            || curl ${i} -s -o /dev/null -w "%{url_effective},%{http_code}\n" >> ${output}

        tail -1 ${output} | grep ",404" &> /dev/null
        [ $? == 0 ] && count_404=$((count_404 + 1))
        progress_bar ${counter} ${site_count} "found ${count_404} 404errors"
        counter=$((counter + 1))
    done
    echo
    echo "Crawl finished! see results in '${result_dir}/${!output}'"
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
        -h|--help)
        usage
        exit
        ;;
        *)
        usage
        exit
        ;;
    esac
done


create_variables conf.yml
mkdir ${result_dir} 2> /dev/null

if [ $ALL ];then
    for i in ${websites_list[*]};do
        check_conf $i
        crawl_site $i
    done
else
    check_conf ${WEB}
    crawl_site ${WEB}
fi
