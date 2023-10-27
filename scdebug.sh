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

## Estilos

TEXT_BOLD=$(tput bold)		# Texto negrita
TEXT_ULINE=$(tput sgr 0 1)	# Texto subrayado
TEXT_GREEN=$(tput setaf 2)	# Texto en verde
TEXT_RESET=$(tput sgr0)		# Texto por defecto

## CONSTANTES

PROGNAME=$0					# Antes de nada guardo el argumento 0 en una constante

### ERRORES

INVALID_OPTION=2            # Argumento a PROGNAME no válido
INVALID_PROGRAM=3           # El programa no existe
INVALID_PROGRAM_OPTION=4    # Las opciones del programa a seguir no son válidas

### OPCIONES 
PROGRAM_OPTIONS=("-h" "-k" "-v" "-sto" "-vall" "-nattch" "-pattch")

## VARIABLES
sto_option=
v_option=0
n_attach_vector=()
p_attach_vector=()
prog=()

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

is_option(){

    #echo "Llamada is_option con argumento "$1""
    for elemento in "${PROGRAM_OPTIONS[@]}"; do
        if [ "$elemento" == "$1" ]; then
            return 0  # Retorna 0 para indicar éxito (cadena encontrada)
        fi
    done

    return 1  # Retorna 1 para indicar que la cadena no fue encontrada

}

# Cambia el nombre de los programas por su proceso más reciente
fill_n_attach() {
    if [ "${n_attach_vector[0]}" == "" ]; then
        return 1
    fi

    for ((i = 1; i < ${#n_attach_vector[@]}; i++)); do
        nombre_programa="${n_attach_vector[i]}"
        pid=$(pgrep -u ${USER} -n ${nombre_programa})    # -u: usuario 
                                                    # -n: FLAG + reciente

        if [ -n "$pid" ]; then
            n_attach_vector[i]=$pid
        else
            n_attach_vector[i]=""       # Valor predeterminado si el programa no está en ejecución
        fi
    done

    # No es necesario devolver el vector actualizado ya que n_attach_vector es una variable global
    echo "Procesos más recientes: ${n_attach_vector[*]}"
}

# Cambia el numero de proceso por el nombre de su comando
fill_p_attch(){
    echo "Funcion fill_p_attch"
}

createFolders()
{
    # Crear directorio .scdebug
    if [[ ! -e "${HOME}/.scdebug" ]]; then
    mkdir "${HOME}/.scdebug"
    fi

    # Crear directorio con el nombre del programa
    if [ -n "${prog[0]}" ]; then
        if [[ ! -e "${HOME}/.scdebug/${prog[0]}" ]]; then
            mkdir ${HOME}/.scdebug/${prog[0]}
        fi
    fi

    # Crear directorio con el nombre del programa -nattch
    if [ - "${n_attach_vector[0]}" ]; then
        if [[ ! -e "${HOME}/.scdebug/${n_attach_vector[0]}" ]]; then
            mkdir ${HOME}/.scdebug/${n_attach_vector[0]}
        fi
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
-k          Opcion no implementada.
-v, -vall   Opcion no implementada.
-nattch		Monitorizar otros procesos que ya están en ejecución. Se opta por 
            el proceso del usuario cuya ejecución se inició más recientemente 
            con ese comando.
-pattch		Monitorizar otros procesos. Se pasan los números de los procesos.
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
            sto_option=$1
            ;;

        -v | -vall )
            echo "Opcion -v(all)"
            v_option="$1"
            shift
            ;;
        -nattch )
            echo "Opcion -nattch"
            # La opcion -nattch llama al argumento -p de strace, por eso 
            # ocupará la primera posicion en el vector, que deja de ser vacio
            n_attach_vector[0]="-p"
            # Se obtendrá el id del proceso + reciente más tarde
            shift
            while [ "$1" != "" ]; do
                is_option "$1"
                if [ "$?" == "0" ];then
                    break
                fi
                n_attach_vector+=("$1")
                shift
            done
            ;;
        -pattch )
            echo "Opcion -pattch"
            # La opcion -nattch llama al argumento -p de strace, por eso 
            # ocupará la primera posicion en el vector, que deja de ser vacio
            p_attach_vector[0]="-p"
            # Se obtendrá el id del proceso + reciente más tarde
            shift
            while [ "$1" != "" ]; do
                is_option "$1"
                if [ "$?" == "0" ];then
                    break
                fi
                p_attach_vector+=("$1")
                shift
            done
            # if [ "${p_attach_vector[1]}" == "" ]
            # ps -p 14574 -o comm=
            ;;
        -* )
            error_exit "$1 no es una opción válida de ${PROGNAME}" ${INVALID_OPTION}
            ;;
        * )
            echo "Opcion prog"
            # Añadir los argumentos al vector prog
            while [ "$1" != "" ]; do
                is_option "$1"
                if [ "$?" == "0" ];then
                    break
                fi
                prog+=("$1")
                shift
            done
            ;;
    esac
done   

# # Varios if para no anidar bucles

fill_n_attach
exit 1

createFolders

filename="trace_$(uuidgen).txt"
route=${HOME}/.scdebug/${prog[0]}/${filename}

aux="${sto_option} ${n_attach_vector[@]} -o ${route} ${prog[@]} : ejecutado"
echo $aux
# sto_option y attachVector pueden estar vacios ya que almacena un simbolo vacio
# y a la hora de pasarselo a un comando lo tomará como un espacio.
strace ${sto_option} ${n_attach_vector[@]} -o ${route} ${prog[@]}

# Preguntar(¿?)
# 1. ¿Con la opcion prog solo se puede ejecutar un programa con sus respectivos argumentos
#    o son varios programas?
# 2. ¿Con la opción -nattch serían válidos los argumentos ls -la, o es solo el nombre del programa?
# 3. Si con las opciones -(n | p)attch se introducen programas que no tienen procesos en ejecución,
# ¿qué pasa?
# 4. Si después de las opciones -(n | p)attch no se introduce ningún programa, ¿se lanza error o
# simplemente no pasa o se dejan los errores a bash?

#ps x --noheaders pid,comm