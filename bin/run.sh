#!/bin/bash
#
## This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; only version 2 of the License is applicable.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#
# Script to run the full testsuite in the ceph-perf package.
#
# Example:
#   GRAPHITE=http://graphitehost/events/ FIOCMD=../fio/fio ./run.sh <engine> <metadata> <testpattern>
#
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
#
engine=$1
desc=$2
pattern=$3

resultsdir=results/${engine}/$(date +%s)
if [ ! -d $resultsdir ]; then
  mkdir $resultsdir -p
fi

if [ ! -d /tmp/${engine} ]; then
  mkdir /tmp/${engine}
fi

if [[ -z $pattern ]]; then
  tests=$(ls ${engine}/env-*.fio)
else
  tests=$(ls $pattern)
fi

echo "Running tests: ${tests}"

for envtest in $tests
do

  echo "Running test: ${envtest}"

  if [ -f ${envtest}.cmd ]; then
  	cmd=$(cat ${envtest}.cmd)
  fi

  while read line
  do

    if [ -n "$cmd" ]; then
      sh -c "$cmd"
    fi

    jobfile=/tmp/${engine}/job-$(date +%s).fio
    cat ${engine}/global.fio ${envtest} > $jobfile

    export ${line}
    for param in 'BS' 'RW' 'IODEPTH'
    do
      sed -i -e "s/\${${param}}/${!param}/g" $jobfile
    done

    if [ -z "$GRAPHITE" ]; then
      echo "Not sending graphite data"
    else
      curl -X POST "${GRAPHITE}" -d "{\"what\": \"Desc: ${desc} Env: ${line} File: ${envtest}\", \"tags\": \"fio\", \"data\": \"$(sed ':a;N;$!ba;s/\n/\\n/g' $jobfile)\"}"
    fi

    jobname=$(grep '^name' $jobfile | sed -e 's/name=//g')
  	${FIOCMD:-fio} --output $resultsdir/${jobname}.log $jobfile 

    mv *.log $resultsdir
  done < ${envtest}.env

done

