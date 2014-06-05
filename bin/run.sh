#!/bin/sh
for fiotest in $(ls fio/*.fio)
do
  if [ -z "$GRAPHITE" ]; then
    echo "Not sending graphite data"
  else
    curl -X POST "http://${GRAPHITE}/events/" -d "{\"what\": \"File: ${fiotest}\", \"tags\": \"fio\", \"data\": \"$(sed ':a;N;$!ba;s/\n/\\n/g' $fiotest)\"}"
  fi
${FIOCMD:-fio} $fiotest
done
