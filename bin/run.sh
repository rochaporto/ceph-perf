#!/bin/bash
#
# Script to run the full testsuite in the ceph-perf package.
#
# Example: GRAPHITE=http://graphitehost/events/ FIOCMD=../fio/fio ./run.sh
#
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
#
engine=$1

if [ ! -d /tmp/${engine} ]; then
  mkdir /tmp/${engine}
fi

resultsdir=results/$(date +%s)

if [ ! -d $resultsdir/${engine} ]; then
  mkdir $resultsdir/${engine} -p
fi

for envtest in $(ls ${engine}/env-*.fio)
do

  while read line
  do
    jobfile=/tmp/${engine}/job-$(date +%s).fio
    cat ${engine}/global.fio ${envtest} > $jobfile

    export ${line}
    for param in 'BS' 'RW'
    do
      sed -i -e "s/\${${param}}/${!param}/g" $jobfile
    done

    if [ -z "$GRAPHITE" ]; then
      echo "Not sending graphite data"
    else
      curl -X POST "${GRAPHITE}" -d "{\"what\": \"Env: ${line} File: ${envtest}\", \"tags\": \"fio\", \"data\": \"$(sed ':a;N;$!ba;s/\n/\\n/g' $jobfile)\"}"
    fi

    filename=$(grep '^name' $jobfile | sed -e 's/name=//g')
  	${FIOCMD:-fio} --output $resultsdir/${engine}/${filename}.log $jobfile 

    mv *.log $resultsdir/${engine}
  done < ${envtest}.env

done

