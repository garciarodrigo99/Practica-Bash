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
# exit 3: Los argumentos de prog no son válidos

### Estilos

TEXT_BOLD=$(tput bold)		# Texto negrita
TEXT_ULINE=$(tput sgr 0 1)	# Texto subrayado
TEXT_GREEN=$(tput setaf 2)	# Texto en verde
TEXT_RESET=$(tput sgr0)		# Texto por defecto

### CONSTANTES

PROGNAME=$0					# Antes de nada guardo el argumento 0 en una constante
INVALID_OPTION=2            # Argumento a PROGNAME no válido
INVALID_PROGRAM=3           # El programa no existe
INVALID_PROGRAM_OPTION=4    # Las opciones del programa a seguir no son válidas

# VARIABLES
stoString=
vallOption=0
attachVector=()
prog=()
progToTest=

#------------------------------------------------------------------------------
### PROGRAMA

### Funciones 
error_exit()
{

        lastValue="${!#}"   # Guarda el último argumento pasado por parámetro
        echo "${PROGNAME}: Error: ${1:-"Error desconocido"}" 1>&2
        usage
        echo 
        echo "Saliendo con ${lastValue}"
        exit $lastValue
}

checkProgramEntry()
{
    # Condicional para que si prog no existe se acabe el programa
    strace $progToTest > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        error_exit "${progToTest} no es un programa válido" ${INVALID_PROGRAM}
    fi

    # Comprobar argumentos correctos para programa a seguir
    strace ${prog[@]} > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        error_exit "${prog[*]}: argumentos inválidos para ${progToTest}" ${INVALID_PROGRAM_OPTION}
    fi
}

createFolders()
{
    # Crear directorio .scdebug
    if [[ ! -e "${HOME}/.scdebug" ]]; then
    mkdir "${HOME}/.scdebug"
    fi

    # Crear directorio con el nombre del programa
    if [[ ! -e "${HOME}/.scdebug/${progToTest}" ]]; then
    mkdir ${HOME}/.scdebug/${progToTest}
    fi
}

usage()
{
	echo
	echo "Modo de uso: $0 [-sto arg]  [-v | -vall] [-nattch progtoattach] prog [arg1...]

Para más información: $0 (-h | --help)"
}

help()
{
cat << _EOF_

${TEXT_ULINE}Modo de uso${TEXT_RESET}: $0 [-sto arg]  [-v | -vall] [-nattch progtoattach] prog [arg1...]

Las opciones referidas a ${PROGNAME} deberán ir antes de indicar el nombre del programa que se quiere analizar.
En el caso de que indiquen después, se tomarán argumentos del programa a analizar.

${TEXT_BOLD}OPCIONES:${TEXT_RESET}

-sto        Añade opciones al comando strace. Los argumentos han 
            de ir entre comillas simples 'arg1 arg2 ... argn'. En caso de que 
            no sea así se tomará como opción del programa ${PROGNAME}.
-v, -vall   No implementada todavía
-nattch		Monitorizar otros procesos que ya están en ejecución. Se opta por 
            el proceso del usuario cuya ejecución se inició más recientemente 
            con ese comando.
prog        Programa a evaluar. [arg1...] argumentos cuando se llama al programa.


_EOF_

}

### Main

# While para leer primero todas las opciones
while [ "$1" != "" ]; do
	case $1 in
        -h | --help )
            help
            exit 1
            ;;
        -sto )
            # sto no se pasa a strace, solo lo que viene después, no hace falta
            # guardarlo
            echo "Opcion -sto"
            shift
            stoString=$1
            ;;

        -v | -vall )
            echo "Opcion -vall"
            shift
            ;;
        -nattch )
            echo "Opcion -nattch"
            # La opcion -nattch llama al argumento -p de strace, por eso 
            # ocupará la primera posicion en el vector, que deja de ser vacio
            attachVector[0]="-p"
            # Se obtendrá el id del proceso + reciente más tarde
            shift
            ;;
        -* )
            error_exit "$1 no es una opción válida de ${PROGNAME}" ${INVALID_OPTION}
            ;;
        * )
            echo "Opcion prog"
            # Añadir los argumentos al vector prog
            #while [ "$1" != "" ] && [[ "$1" != "-"* ]]; do
            while [ "$1" != "" ]; do
                prog+=("$1")
                shift
            done
            ;;
    esac
done

# Guardar el nombre del programa a seguir sin argumentos
progToTest=${prog[0]}   

# # Varios if para no anidar bucles

checkProgramEntry

createFolders

filename="trace_$(uuidgen).txt"
route=${HOME}/.scdebug/${prog[0]}/${filename}

# Si no hago esta línea puede que salte un error de que no hay ningun proceso
# anterior ejecutandose
if [[ ${attachVector[0]} == "-p" ]]; then
    echo "Checking newest process"
    attachVector[1]=$(pgrep -u ${USER} -n ${progToTest})    # -u: usuario 
                                                            # -n: FLAG + reciente
fi

aux="${stoString} ${attachVector[@]} -o ${route} ${prog[@]} : ejecutado"
echo $aux
# stoString y attachVector pueden estar vacios ya que almacena un simbolo vacio
# y a la hora de pasarselo a un comando lo tomará como un espacio.
strace ${stoString} ${attachVector[@]} -o ${route} ${prog[@]}

# Preguntar(¿?)
# En el caso de que en cualquier ejecución del script que requiera la monitorización de procesos,
# un lanzamiento de strace produzca un error el script debe terminar con un error indicado
# también por un mensaje en la salida de error. Este error también deberá quedar reflejado en el
# archivo de salida.