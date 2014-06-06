#!/bin/bash
#
# Script to run the full testsuite in the ceph-perf package.
#
# Example: GRAPHITE=http://graphitehost/events/ FIOCMD=../fio/fio ./run.sh
#
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
#
if [ ! -d /tmp/fio ]; then
  mkdir /tmp/fio
fi

resultsdir=results/$(date +%s)

if [ ! -d $resultsdir/fio ]; then
  mkdir $resultsdir/fio -p
fi

for envtest in $(ls fio/env-*.fio)
do

  while read line
  do
    jobfile=/tmp/fio/job-$(date +%s).fio
    cat fio/global.fio ${envtest} > $jobfile

    export ${line}
    for param in 'BS' 'RW'
    do
      sed -i -e "s/\${${param}}/${!param}/g" $jobfile
    done

    if [ -z "$GRAPHITE" ]; then
      echo "Not sending graphite data"
    else
      curl -X POST "${GRAPHITE}" -d "{\"what\": \"Env: ${line} File: ${envtest}\", \"tags\": \"fio\", \"data\": \"$(sed ':a;N;$!ba;s/\n/\\n/g' $envtest)\"}"
    fi

  	${FIOCMD:-fio} --output $resultsdir/fio/$(grep '^name' $jobfile | sed -e 's/name=//g').log $jobfile 
  done < ${envtest}.env

  mv *.log $resultsdir/fio
done

