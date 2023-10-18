#!/bin/bash

# sysinfo - Script correspondiente a Practica de BASH Procesos de Ususarios:
# Grupo: PE205
# Asignatura: Sistemas Operativos (2º curso)
# Grado: Ingenieria Informatica
# Fecha: 22-11-2021
# Autor: Rodrigo García Jiménez
# Correo de contacto: alu0101154473@ull.edu.es

# DOCUMENTACION DE ERRORES

# exit 1: Opcion soportada. (Caso general)
# exit 2: Ningun usuario cumple con el parametro tiempo indicados.
# exit 3: Incompatibilidad de comandos.
# exit 4: Opciones con parametros vacios.
# exit 5: Opciones con parametros no aceptados.


##### Estilos

TEXT_BOLD=$(tput bold)		# Texto negrita
TEXT_ULINE=$(tput sgr 0 1)	# Texto subrayado
TEXT_GREEN=$(tput setaf 2)	# Texto en verde
TEXT_RESET=$(tput sgr0)		# Texto por defecto

# CONSTANTES

PROGNAME=$0					# Antes de nada guardo el argumento 0 en una constante

# VARIABLES

time_select=1				# Tiempo en sg mayor que
ord=1						# Ordenación por defecto user(col1).
vect_user[0]=0				# Array que si es 0 el primer elemento, es que no contiene filtro de usuarios
							# y si es un 1, luego le siguen los usuarios deseados

#------------------------------------------------------------------------------

# PROGRAMA

# Mostrar la salida del comando

subfuncion()
{
if [[ ${vect_user[0]} -eq 0 ]]; then	# Si no está activada la opcion de filtro por usuarios, muestra la linea correspondiente al usuario.	#[Caso no filtrar por -usr,o]
	echo "$1"	""$(id -gn "$2")"	"$(ps --no-header -u "$2" | wc -l)""
else																																			# [Caso opcion de filtro por usuario activada]
	for var in ${vect_user[@]:1}; do	# Recorro el vector de usuarios indicados
		if [[ "$var" == "$2" ]];then	# Si el usuario de de la linea ps coincide con algun usuario de mi vector, muestra la linea.			# [Caso usuarios de mi vector coinciden con el usuario de la linea]
			echo "$1"	""$(id -gn "$2")"	"$(ps --no-header -u "$2" | wc -l)""
		fi
	done
fi
# $1 = $line
# $2 = $usuario
}

error_exit()
{
        echo "${PROGNAME}: Error: ${1:-"Error desconocido"}" 1>&2
		usage
        exit $2
}

usage()
{
	echo
	echo "Modo de uso: $0 [-c xor -pid] [-inv] [-u user_name [username_2] ... xor -usr] [(-t | --time) N]
Para más información: $0 (-h | --help)"
}

help()
{
cat << _EOF_

${TEXT_ULINE}Modo de uso${TEXT_RESET}: $0 [(-t | --time) N] [-inv] [-pid | -c]

${TEXT_BOLD}OPCIONES:${TEXT_RESET}

-c 		la ordenación se realizará por el número total de 
		procesos de usuario. Incompatible con -pid
-inv 		Muestra los procesos de forma inversa.(Z-A),(9-0).
-pid		la ordenación se realizará por el pid. Incompatible con -c
-u		Ordenar por usuario. Minimo un usuario. En caso de ser más 
		de un usuario, irán separados por espacio. No se admite otro formato.
		Incompatible con -usr
-usr		Mostrar solo los usuarios que están conectados en el 
		sistema actualmente. Incompatible con -u
-t, --time 	N segundos a partir del que se mostrarán los procesos.

${TEXT_BOLD}CABECERA:${TEXT_RESET}

USER	Nombre de usuario del proceso.
UID	UID del usuario propietario del proceso.
PID	PID del proceso.
TIME	Tiempo de cpu consumido del proceso en formato hh:mm:ss.
GUSER	Grupo al que pertenece el usuario propietario del proceso.
PS	Numero de procesos totales del usuario, independientemente del 
	parametro tiempo
_EOF_

}

# Funcion para pasar el tiempo en formato hh:mm:ss a segundos
time_to_s()
{
    h=$(echo $1 | cut -d: -f1)
    m=$(echo $1 | cut -d: -f2)
    s=$(echo $1 | cut -d: -f3)
    echo $(((10#$h * 3600) + (10#$m * 60) + 10#$s))	# #10$x para que sepa que es en base 10 y no 8, que es por defecto cuando ponemos nn
}

mostrar(){
while IFS= read -r line
do
	proc_time=$(echo $line | tr -s ' ' '_' | cut -d_ -f4)								# Almaceno el tiempo de un proceso en una variable para poder comparar.
	proc_time=$(time_to_s "$proc_time")													# Funcion para pasar hh:mm:ss a segundos
    if [[ "$proc_time" -gt "$time_select" ]]; then										# Para comparar el tiempo del proceso con el tiempo establecido. 	#[Caso ps cumple con parametro tiempo]
		# "Repito" codigo porque quiero saber cuando user esta vacio o no, y luego dentro de "no vacio" porque quiero saber cuando es igual al anterior y cuando no.
		# No uso subfunciones 
		if [[ ! $usuario ]]; then														# Si esta vacio, relleno con el primer usuario. 					# [Caso variable usuario vacio]
			usuario=$(echo $line | tr -s ' ' '_' | cut -d_ -f1)
			subfuncion "$line" $usuario
		else																			# [Caso usuario no vacio]
    		if [[ "$usuario" != $(echo $line | tr -s ' ' '_' | cut -d_ -f1) ]]; then	# Comprobar que el usuario distinto para asignar el nuevo usuario.	#[Caso usuario distinto al anterior]
				usuario=$(echo $line | tr -s ' ' '_' | cut -d_ -f1)
				subfuncion "$line" $usuario
			#else
				# count=$((count + 1))
			fi
		fi
    fi
done <<< $(ps --no-headers -eo user:20,uid,pid,time --sort user,-time)					# Sirve tambien done < <(cmd)
																						# -time porque como la ordenacion es en modo diccionario[0-9], quiero que me la muestre al revés

if [[ ! $usuario ]]; then																# Si no se encontro ningun usuario, muestra un texto.				#[Caso ningun usuario encontrado]
	error_exit	"No se ha encontrado ningun usuario con los parametros indicados." 2
fi
}

# Pongo shift en cada case porque al comparar en el caso de los usuarios, paro cuando "" o -opt, y al tener ya -opt en el parametro tengo que pasar al caso siguiente.
# Si lo pusiera tambien fuera adelantaría dos parametros y no me interesa
while [ "$1" != "" ]; do
	case $1 in
		-c )
			if [[ $ord -ne 3 ]]; then	# Hacer incompatible con ordenación con pid.	# [Caso -c]
				ord=6					# Ordenación por ps(col6).
				shift
			else
				error_exit "Incompatibilidad de comandos: -pid,-c" 3					# [Caso -pid,-c]
			fi
			;;
		-count )
			echo "-count"
			exit 1
			shift
			;;
		-h | --help )
			help
			exit 1
			;;
		-inv )
			inv=-r			# Si no se especifica nada, inv es vacio.
			shift
			;;
		-pid )
			if [[ $ord -ne 6 ]]; then # Hacer incompatible con ordenación con -c	# [Caso -pid]
				ord=3			# Ordenación por pid(col3).
				shift
			else																	# [Caso -c,-pid]
				error_exit "Incompatibilidad de comandos: -c,pid" 3
			fi
			;;
		-t | --time )
			shift
			re_time='^[0-9]*$'												# Expresion regular que solo acepta numeros. * en vez + para mejor documentacion de errores
			if [[ $1 != '' ]];then											# Comprobar que $1 no es vacio, mejor documentacion de errores. [Caso -t con tiempo especifico]
				if  [[ "$1" =~ $re_time ]] ; then							# [Caso parametro es un numero]
						time_select=$1
				else 
					error_exit	"El parametro no es un numero natural" 5	# [Caso parametro no es num > 0]
				fi
			else															# [Caso -t con tiempo especifico]
				error_exit "No ha introducido ningun tiempo como parametro" 4
			fi
			shift
			;;
		-u )
			if [[ ${vect_user[0]} -ne 2 ]];then				# [Caso -u]
				shift
				vect_user[0]=1
				count=1
				re_opt='^[^-][[:alnum:]]*$'					# Elementos que no empiecen por - y que solo contengan valores alfa numericos.
				if [[ $1 != '' ]];then						# Comprobar que al menos se ha elegido un usuario.[Caso lista de usuarios no vacía]
					while [[ $1 =~ $re_opt ]];do			# Mientras que no empiecen por - y sean caracteres alfanumericos, sigue leyendo usuarios. [Caso palabras que no empiezan por -]
						if id -nu $1 >/dev/null 2>&1; then	# [Caso usuario existe]
							vect_user[$count]=$1
							count=$((count + 1))
							shift
						else 								# [Caso usuario no existe]
							error_exit "Algun(os) usuario(s) introducido(s) no existen" 5
						fi
					done
				else										# [Caso lista de usuarios vacia]
					error_exit "Ningun usuario introducido" 4
				fi
			else											# [Caso -usr -u x...]
				error_exit "Incompatibilidad de comandos: -usr, -u" 3
			fi
			;;
		-usr )
			if [[ ${vect_user[0]} -ne 1 ]]; then		# [Caso -usr]
				shift
				vect_user[0]=2
				count=1
				# Como ya me va a dar una lista de usuarios que estan en el sistema no compruebo si existen
				for var in $(who | cut -d' ' -f1); do
					vect_user[$count]=$var
				done
			else										# [Caso -u[] -usr]
				error_exit "Incompatibilidad de comandos: -u, -usr" 3
			fi
			;;
		* )
			error_exit	"Opcion no soportada" 1
	esac
done

echo "${TEXT_ULINE}$(ps -eo user:20,uid,pid,times | head -n 1)"" GUSER	PS${TEXT_RESET}"	# Mostrar encabezado de ps
mostrar | sort -k $ord $inv | uniq															# Por defecto ord=1(columna usuario), y en el caso de que el usuario indique pid o c se cambia a col 3 o col 6
																							# Si inv es vacio el comando lo lee como si fuera un espacio, que viene a ser lo mismo que no poner nada
																							# Uniq por si se da "-u root rodrigo root" solo me muestre una linea por usuario

exit 0

# VSC : 209
# Terminal: 198
# history | cut -d' ' -f5 | grep ./userProc.sh | wc -l