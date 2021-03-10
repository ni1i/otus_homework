#!/bin/bash

#Объявляем значение X и Y
X=10
Y=10

#Указываем когда сгенерирован запрос и когда начинается log
echo "Request generated:" && date && echo "Log started:" && cat access.log | awk '{print $4$5}' | head -n 1
echo " *** *** *** "

#Выбираем X IP, которые сформировали наибольшее количество запросов
echo $X "most requests from:" && cat access.log | awk -F" " '{print $1}' | sort | uniq -c | sort -rn | head -n $X | awk '{print $1 " requests from " $2}'
echo " *** *** *** "

# Y cамых популярных запросов
echo $Y "most requested URLs:" && cat access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -n $Y | awk '{print $2 " requested " $1 " times. "}' | column -t
echo " *** *** *** "

#Ошибки HTTP
echo "HTTP errors:" && cat access.log | awk '{print $9}' | grep ^4 | sort | uniq -c | sort -rn | awk '{print $2 " - "  $1 " times."}' && cat access.log | awk '{print $9}' | grep ^5 | sort | uniq -c | sort -rn | awk '{print $2 " - "  $1 " times."}'
echo " *** *** *** "

#Все коды HTTP и их количество
echo "HTTP statuses:" && cat access.log | awk '{print $9}'| grep -v "-" | sort | uniq -c | sort -rn | awk '{print $2 " - "  $1 " times."}'