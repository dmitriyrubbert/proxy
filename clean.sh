#!/bin/bash

container="nginx"

testText="Welcome to nginx"
pidGrep="nginx"
appDir="usr/local/bin"
testCommand="/etc/init.d/nginx start && curl 127.0.0.1 &> $appDir/cleanContainer.log &"


# Защита от случайной ошибки
if [ "$container" == "" ] || [ ! -d "$container" ]; then exit; fi

echo "df" | sed -e 's/\(.\)/\1\n/g' | while read letter; do
 if [ "$letter" == "" ]; then continue; fi
 find $container/ -type $letter | while read dir; do

  if [ ! -d $dir ] && [ ! -f $dir ]; then continue; fi
  if [ "$dir" == "$container/$appDir" ] || [ "$dir" == "$container/" ] || [ "$dir" == "$container/bin" ] || [ "$dir" == "$container/bin/bash" ]; then continue; fi

  mv "$dir" "$dir.bak"

  rm -f "$container/$appDir/cleanContainer.log" &> /dev/null
  chroot $container /bin/bash -c "$testCommand"

  if [ "$?" -eq "0" ]; then
    i=0
    while [ ! -f $container/$appDir/cleanContainer.log ] && [ $i -lt 20 ]; do 
      sleep 0.1
      i=$(( $i + 1 ))
    done

    oldSize="None"
    size=$(stat --printf="%s" $container/$appDir/cleanContainer.log)
    while [ "$oldSize" != "$size" ]; do
      sleep 1
      oldSize=$size
      size=$(stat --printf="%s" $container/$appDir/cleanContainer.log)    
    done
  fi

  if [ `cat $container/$appDir/cleanContainer.log | grep "$testText" -c` -ne 0 ]; then
    echo "Удалено: $dir"
    rm -fR "$dir.bak"
  else
    echo "Оставлено: $dir"
    mv "$dir.bak" "$dir"
  fi


  ps -ax | grep "$pidGrep" | grep -v grep | awk '{print $1}'| xargs kill -9 &> /dev/null
  while [ `ps -ax | grep "$pidGrep" | grep -v grep -c` -ne 0 ]; do sleep 0.1; done

 done
done

echo "Готово, протестируйте командой:"
echo `echo $testCommand | cut -d'&' -f1`