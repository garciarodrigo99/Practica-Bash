#!/bin/bash

#------------------------------------------------------------------------------
# Maneras de ejecutar comandos guardados en variables
order=ls
order2=-l
order3=-a
ordera="$order $order2 $order3"

#$ordera                         # Linea a linea
#(echo $order $order2 $order3)  # Linea a linea
#echo $($order $order2 $order3)  # Linea unica
#echo "$($order $order2 $order3)" #  Linea a linea

#usuario=
#echo "$usuario"

#if [[ ! $usuario ]]; then
    #echo "SI"
#else 
    #echo "NO"
#fi

#cmd="ls -l"
#$cmd

#ls $var_
#ps -u $user_name
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#var_="rodrigo 1000 rodrigo 1454 0"
#if ("$($var_ tr -s ' ' '_' | cut -d_ -f5 | grep -v [0,1])" > "$proc_time")); then
#var2=| tr -s ' ' '_' | cut -d_ -f5

#echo "$var_" | tr -s ' ' '_' | cut -d_ -f5
#echo "$var_" $var2

#if ( ($var_ ) > "1"); then
    #echo "var mayor que uno"
#else
    #echo "var menor igual que uno"
#fi

#------------------------------------------------------------------------------

#user_=root
#echo ""${USER}"  "$(id -gn "$user_")""

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#foo()
# {
    #ls -l | wc -l
#}

#nm=$(foo)

#echo $nm

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#number=5

#ls -l | sort -r -k "$number"

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#opcion='^[^-][[:alnum:]]+$'
#variable=" "

#if [[ $variable =~ $opcion ]] ; then
    #echo "SI"
#else 
    #echo "NO" >&2; exit 1
#fi

#users[1]="alberto"
#users[2]='oscar'
#users[3]="-usr"
#count=1
#while [[ ${users[$count]} =~ $opcion ]];do
#if id -u ana >/dev/null 2>&1; then
    #echo "Si"
#else 
    #echo "No"
#fi
#echo ${users[$count]}
#count=$((count + 1))
#done

#re='^[0-9]+$'
#if ! [[ $variable =~ $re ]] ; then
#    echo "error: Not a number" >&2; exit 1
#else 
#    echo "SI"
#fi
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#time_to_s()
# {
    #h=$(echo $1 | cut -d: -f1)
    #m=$(echo $1 | cut -d: -f2)
    #s=$(echo $1 | cut -d: -f3)
    #echo $(((10#$h * 3600) + (10#$m * 60) + 10#$s))
# }

#for var in $(ps -e --no-headers | tr -s ' ' _);
#do
#time=$(echo $var | cut -d_ -f4)
#if [[ $time > 1 ]]; then
    #echo $time "SI"
#else
    #echo $time "No" 
#fi
#done

#segundos=$(time_to_s "09:09:09")
#echo $segundos

#if [[ "$segundos" -gt 180 ]]; then
    #echo "Si"
#else
    #echo "No"
#fi
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Comprobar si usuario existe

#if id -u ana >/dev/null 2>&1; then
    #echo "Si"
#else 
    #echo "No"
#fi

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

# ${vector[@]}          Lista con todos los elementos
# ${#vector[@]}         Tamaño del vector
#vector[1]=2
#echo ${vector[0]}

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#vector[0]=1
#vector[1]=2
#vector[2]=3
#vector[3]=4
#vector[4]=5


#for var in ${vector[@]:1}; do
    #echo $var
#done

#------------------------------------------------------------------------------

#if ls -l; then
#echo "Hola"
#fi

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#impr(){
    #echo "Funcion: "$@
    #shift
#}

#echo "Main: "$@
#impr $@
#echo "Main2: "$@

#------------------------------------------------------------------------------

var="rodrigo                    1000    3365    00:00:02        rodrigo     117"
var2=$var
echo "$var2"

#------------------------------------------------------------------------------