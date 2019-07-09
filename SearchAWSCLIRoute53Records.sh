#!/bin/bash

while getopts "p:r:l:h" arg; do
    case $arg in
        p)
          profileName=${OPTARG}
          ;;
        r)
          recordForQuery=${OPTARG}
          ;;
        l)
          lineCount=${OPTARG}
          ;;
        h)
          cat <<- EOF
          [HELP]: ### SearchAWSRoute53Records. Go find Route53 Records. ###

          [EXAMPLE]: scriptname -r graylog -p my-amazon-profile -m 2" # search for a record with graylog as the name, and give me up to 2 matches.

          [REQUIREMENTS]: This script requires only two arguments -r and -p, and requires the user to have setup aws profiles setup in
		  order to use this tool.

         [REQUIRED ARGUMENTS]:
            -r) [record to query] [STRING] This option refers to the R53 Record name to search for. The search will match any correctly spelled approxmation.
            -p) [profile] [STRING] This option refers to the profile to be used for AWS. This should exist in $HOME/.aws/credentials.

         [OPTIONAL ARGUMENTS]:
            -l) [lines] [INTEGER] This option sets the amount of lines on a match to return.
            -h) [HELP] [takes no arguements] Print this dialog to the screen.
EOF
         exit 0
         ;;
      *)
         printf %"%s\n" "Incorrect syntax, try -h for help"
         exit 0
         ;;
    esac
done

trap ctrl_c INT

if [[ -z $lineCount ]]; then
        lineCount=7
fi
if [[ -z $profileName ]] || [[ -z $recordForQuery ]]; then
        printf "%s\n" "Missing required arguements, please see -h for help"
        exit 1
fi

function ctrl_c() {
        echo "** Caught SIGINT: CTRL-C **"
        exit 1
}
function getRecords() {
        zones=$(aws route53 list-hosted-zones --profile $profileName --output text | grep hostedzone | awk {'print $3'} | sed -e s'/hostedzone//g;s/\///g')
        for zone in $zones
            do 
                    printf "%s\n" "[INFO]: Checking $zone in $profileName :"
                    aws route53 list-resource-record-sets --page-size 500  --hosted-zone-id $zone \
                    --profile $profileName | grep -A $lineCount -i $recordForQuery >> /tmp/$zone.result
                    if [[ -s /tmp/$zone.result ]]; then
                        zoneCommonName=$(aws route53 list-hosted-zones --profile $profileName --output text | grep -i $zone | awk {'print $4'})
                        echo -e "\033[33;5;7m[INFO]: Success, found record(s):\033[0m"
			printf "%s\n" "    ~ ZONE COMMON NAME: $zoneCommonName" "    ~ Zone: $zone"
                        cat /tmp/$zone.result
                        rm -f /tmp/$zone.result
                    else
                        printf "%s\n" "[INFO]: Nothing to report for this zone."
                        rm -f /tmp/$zone.result
                    fi
        done
}
getRecords
