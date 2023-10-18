#!/bin/bash

# Grupo: PE203
# Asignatura: Sistemas Operativos (2º curso)
# Grado: Ingenieria Informatica
# Fecha: 16-10-2023
# Autor: Rodrigo García Jiménez
# Correo de contacto: alu0101154473@ull.edu.es

# DOCUMENTACION DE ERRORES

# exit 1: Caso general
# exit 2: Prog no es un programa válido

### Estilos

TEXT_BOLD=$(tput bold)		# Texto negrita
TEXT_ULINE=$(tput sgr 0 1)	# Texto subrayado
TEXT_GREEN=$(tput setaf 2)	# Texto en verde
TEXT_RESET=$(tput sgr0)		# Texto por defecto

### CONSTANTES

PROGNAME=$0					# Antes de nada guardo el argumento 0 en una constante

# VARIABLES
stoOption=
vallOption=0
nattch=0
prog=()

#------------------------------------------------------------------------------
### PROGRAMA

### Funciones 
error_exit()
{
        lastValue="${!#}"
        echo "${PROGNAME}: Error: ${1:-"Error desconocido"}" 1>&2
        exit $lastValue
}

### Main

# While para leer primero todas las opciones
while [ "$1" != "" ]; do
	case $1 in
        -h | --help )
            echo help
            exit 1
            ;;
        -sto )
            echo "Opcion -sto"
            shift
            stoOption[0]=$1
            ;;

        -v | -vall )
            echo "Opcion -vall"
            shift
            ;;
        -nattch )
            echo "Opcion -nattch"
            ;;
        * )
            echo "Opcion prog"
            # Añadir los argumentos al vector prog
            while [ "$1" != "" ] && [[ "$1" != "-"* ]]; do
                prog+=("$1")
                shift
            done
            ;;
    esac
done

progToTest=${prog[0]}

# Varios if para no anidar bucles
# Condicional para que si prog no existe se acabe el programa
strace ${prog[0]} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    error_exit "${prog[*]} no es un programa válido" 2
fi

# # Crear directorio .scdebug
if [[ ! -e "${HOME}/.scdebug" ]]; then
   mkdir "${HOME}/.scdebug"
fi

# Crear directorio con el nombre del programa
if [[ ! -e "${HOME}/.scdebug/${progToTest}" ]]; then
   mkdir ${HOME}/.scdebug/${progToTest}
fi

filename="trace_$(uuidgen).txt"
route=${HOME}/.scdebug/${prog[0]}/${filename}

echo "$filename"
echo "$route"
echo ${progToTest[@]}
strace $stoOption -o $route ${progToTest[@]}

#ps -u $USER -o pid,command --sort=-start_time | grep -v "ps -u" | head -n 2 | tail -n 1 | tr -s ' ' | cut -d ' ' -f2

# Preguntar(¿?)
# En el caso de que en cualquier ejecución del script que requiera la monitorización de procesos,
# un lanzamiento de strace produzca un error el script debe terminar con un error indicado
# también por un mensaje en la salida de error. Este error también deberá quedar reflejado en el
# archivo de salida.

# echo "${prog[@]}"