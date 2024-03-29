#!./ptbash

# Grupo: PE203
# Asignatura: Sistemas Operativos (2º curso)
# Grado: Ingenieria Informatica
# Fecha: 30-10-2023
# Autor: Rodrigo García Jiménez
# Correo de contacto: alu0101154473@ull.edu.es

# DOCUMENTACION DE ERRORES

# exit 1: Caso general
# exit 2: Prog no es un programa válido
# exit 3: Los argumentos de prog no son válidos
# exit 3: Los argumentos de prog no son válidos
# exit 5: Hay opciones incompatibles

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
INCOMPATIBLE_OPTIONS=5      # Opciones incompatibles

### OPCIONES 
PROGRAM_OPTIONS=("-g" "-h" "-k" "-S" "-v" "-gc" "-ge" "-inv" "-sto" "-vall" "-nattch" "-pattch")

## VARIABLES
sto_option=
kill_option=
v_option=()
n_attach_vector=()
p_attach_vector=()
prog_vector=()
stop_vector=()
resume_option=
resume_inv=

# -----------------------------------------------------------------------------
### PROGRAMA

#### Funciones genéricas
usage()
{
	echo
	echo "Modo de uso: $0 [-sto arg]  [-v | -vall] [-nattch progtoattach] prog [arg1...]

Para más información: $0 (-h | --help)"
}

help()
{

cat << _EOF_

${TEXT_ULINE}Modo de uso${TEXT_RESET}: $0 [-h] [-k] [[-sto arg] [(-v | -vall) prog1 ... ] [prog [arg …] ] [-nattch progtoattach …] [-pattch pid1 … ] | -S commName prog [arg...]]

Las opciones referidas a ${PROGNAME} deberán ir antes de indicar el nombre del programa que se quiere analizar.
En el caso de que indiquen después, se tomarán argumentos del programa a analizar.

${TEXT_BOLD}OPCIONES:${TEXT_RESET}

-k          Trata de terminar todos los procesos trazadores del
            usuario, así como todos los procesos trazados.
-nattch		Monitorizar otros procesos que ya están en ejecución. Se opta por 
            el proceso del usuario cuya ejecución se inició más recientemente 
            con ese comando.
-pattch		Monitorizar otros procesos. Se pasan los números de los procesos.
-sto        Añade opciones al comando strace. Los argumentos han 
            de ir entre comillas simples 'arg1 arg2 ... argn'. En caso de que 
            no sea así se tomará como opción del programa ${PROGNAME}.
-v          Se volcará la información del archivo de depuración más reciente en la salida estándar.
-vall       Se volcará la información de todos los archivos de depuración en la salida estándar.

_EOF_

}

error_exit()
{

        lastValue="${!#}"   # Guarda el último argumento pasado por parámetro
        echo "${PROGNAME}: Error: ${1:-"Error desconocido"}" 1>&2
        usage
        echo 
        echo "Saliendo con ${lastValue}"
        exit $lastValue
}

is_option()
{
    #echo "Llamada is_option con argumento "$1""
    for elemento in "${PROGRAM_OPTIONS[@]}"; do
        if [ "$elemento" == "$1" ]; then
            return 0  # Retorna 0 para indicar éxito (cadena encontrada)
        fi
    done

    return 1  # Retorna 1 para indicar que la cadena no fue encontrada

}

#### Funciones para modularizar el programa

show_user_processes() 
{
    #echo "Showing user processes"
    # Recogida de procesos en el vector user_process_aux
    output=$(ps -u "${USER}" -o pid= --sort=-start_time)
    while read -r pid; do
        user_process_aux+=("$pid")
    done <<< "$output"

    printf "%-*s" 9 "PID"
    printf "%-*s" 19 "COMMAND"
    printf "%-*s" 14 "START_TIME"
    printf "%-*s" 14 "TRAZER_PID"
    printf "%s\n" "COMMAND"

    # Se imprimen traceados y los no traceados se guardan en un vector
    pid_no_traced=()    # Vector de pids de procesos no traceados
    for pid in "${user_process_aux[@]}"; do
        proc_folder="/proc/"$pid""
        if [[ ! -d "${proc_folder}" ]];then 
            continue
        fi
        # PID del proceso trazador
        tracer_pid=$(cat "${proc_folder}/status" | grep "TracerPid" | cut -d ':' -f 2 | tr -d '[:space:]')
        # Si el proceso es trazado, se imprime por pantalla 
        if [ "$tracer_pid" != 0 ]; then
            process_name=$(ps -p $pid -o comm=) # Nombre del proceso
            process_time=$(ps -p $pid -o start=)
            tracer_name=$(ps -p $tracer_pid -o comm=)   # Nombre del proceso trazador
            # Ejemplo 
            printf "%-*s" 9 "$pid"
            printf "%-*s" 19 "$process_name"
            printf "%-*s" 14 "$process_time"
            printf "%-*s" 14 "$tracer_pid"
            printf "%s\n" "$tracer_name"
        # Si no es trazado, se guarda en un vector que se imprimirá más tarde
        else 
            pid_no_traced+=("$pid")
        fi
    done

    # Imprimir los procesos no trazados
    for pid in "${pid_no_traced[@]}"; do
        process_name=$(ps -p $pid -o comm=) # Nombre del proceso
        process_time=$(ps -p $pid -o start=)
        printf "%-*s" 9 "$pid"
        printf "%-*s" 19 "$process_name"
        printf "%s\n" "$process_time"
    done
    
}

# Funcion para ejecutar la opción -v(all)
consult ()
{
    for ((i = 1; i < ${#v_option[@]}; i++)); do
        # Si es la primera posicion del vector es vacia salto a la siguiente iteración
        if [ -z "${v_option[i]}" ]; then
            continue
        fi
        # Si el directorio no existe salto a la siguiente iteración
        folder="${HOME}/.scdebug/${v_option[i]}/"
        if [[ ! -e "$folder" ]]; then
            continue
        fi
        # Nombre de comanda
        command="${v_option[i]}"
        # (Solo) programas ordenados mod más reciente
        output="ls -lt --time-style=long-iso "$folder""

        # Volcar las filas de la salida por pantalla al vector rows
        rows=()
        count=0
        while IFS= read -r linea; do
            # Salta primera linea(total n)
            if [ "$count" -eq 0  ]; then
                ((count++))
                continue
            fi
            rows+=("$linea")
            # Verificar si option es igual a -v y salir después de la primera línea
            if [ "${v_option[0]}" == "-v"  ]; then
                break
            fi
        done < <($output)

        # Recorrer vector el vector de filas
        for linea in "${rows[@]}"; do
            local_file_name=$(echo "$linea" | tr -s [:blank:] ';' | cut -d';' -f8)
            file_time=$(echo "$linea" | tr -s [:blank:] ';' | cut -d';' -f6,7 | tr ';' ' ')
            fixed_width=46
            printf "=============== COMMAND:    %-*s =======================\n" $fixed_width "$command"
            printf "=============== TRACE FILE: %-*s =======================\n" $fixed_width "$local_file_name"
            printf "=============== TIME:       %-*s =======================\n" $fixed_width "$file_time"
            echo
        done

    done

    exit 0
}

kill_function()
{
    #echo "Kill function"
    # Si no está activa la opción, salir de la funcion
    if [ -z "$kill_option" ]; then
        return 1
    fi
    # Obtener todos los procesos del usuario
    user_process=()
    output=$(ps -u "${USER}" -o pid=)
    while read -r pid; do
        user_process+=("$pid")
    done <<< "$output"

    tracer=()
    tracee=()
    for pid in "${user_process[@]}"; do
        proc_folder="/proc/"$pid""
        if [[ ! -d "${proc_folder}" ]];then 
            continue
        fi
        tracer_pid=$(cat "${proc_folder}/status" | grep "TracerPid" | cut -d ':' -f 2 | tr -d '[:blank:]')  # Cambiar por blank?
        # Si el proceso es trazado
        if [ "$tracer_pid" != 0 ]; then
            tracer+=("$tracer_pid")
            tracee+=("$pid")
            echo ""$pid": "$tracer_pid""
        fi
        
    done

    # echo "Vector tracer: ${tracer[@]}"
    # echo "Vector tracee: ${tracee[@]}"

    # Si no están vacíos los vectores, llamar a kill
    if [ -n "${tracer[0]}" ]; then
        kill "${tracer[@]}"
        kill "${tracee[@]}"
    fi

}

prog_function()
{
    # Si no está activa la opción, salir de la funcion
    if [ -z "${prog_vector[0]}" ]; then
        return 1
    fi
    if [[ ! -e "${HOME}/.scdebug/${prog_vector[0]}" ]]; then
        mkdir ${HOME}/.scdebug/${prog_vector[0]}
    fi
    # Evitar problemas con ejecutables del usuario y sus rutas a la hora de 
    # crear el directorio del programa
    foldername=$(basename "${prog_vector[0]}")
    filename="trace_$(uuidgen).txt"
    route=${HOME}/.scdebug/${foldername}/${filename}
    strace ${sto_option} -o ${route} ${prog_vector} > /dev/null 2>&1 &
}

n_attach_function()
{
    # Si no está activa la opción, salir de la funcion
    if [ -z "${n_attach_vector[0]}" ]; then
        return 1
    fi

    echo "Funcion n_attach_function"
    echo ${n_attach_vector[@]}

    for ((i = 1; i < ${#n_attach_vector[@]}; i++)); do

        # # Si la opcion es vacia saltar iteración
        # if [ -z "${n_attach_vector[i]}" ]; then
        #     continue
        # fi

        program_name="${n_attach_vector[i]}"
        # Obtener el proceso más reciente de cierto programa
        pid=$(pgrep -u ${USER} -n ${program_name})   # -u: usuario 
                                                        # -n: FLAG + reciente

        echo "$pid"
        n_attach_vector[i]=$pid
        # Si no existe el proceso, saltar a la siguiente ejecucion
        if [ -z "$pid" ]; then
            continue
        fi
        # Crear directorio con el nombre del programa -nattch
        if [[ ! -e "${HOME}/.scdebug/$program_name" ]]; then
            mkdir ${HOME}/.scdebug/$program_name
        fi

        local_file_name="trace_$(uuidgen).txt"
        route=${HOME}/.scdebug/$program_name/${local_file_name}
        # ! : Añadir sto 
        strace ${sto_option} -o ${route} -p ${pid} > /dev/null 2>&1 &
    done

}

p_attach_function()
{
    # Si no está activa la opción, salir de la funcion
    if [ -z "${p_attach_vector[0]}" ]; then
        return 1
    fi

    echo "Funcion p_attach_function"
    echo ${p_attach_vector[@]}
    # Cambiar el pid por el nombre de su programa
    for ((i = 1; i < ${#p_attach_vector[@]}; i++)); do

        # Si la opcion es vacia saltar iteración
        if [ -z "${p_attach_vector[i]}" ]; then
            continue
        fi

        pid="${p_attach_vector[i]}"
        program_name=$(ps -p $pid -o comm=)

        # Si no existe el proceso, saltar a la siguiente ejecucion
        if [ -z "$pid" ]; then
            continue
        fi
        # Crear directorio con el nombre del programa -pattch
        if [[ ! -e "${HOME}/.scdebug/$program_name" ]]; then
            mkdir ${HOME}/.scdebug/$program_name
        fi

        local_file_name="trace_$(uuidgen).txt"
        route=${HOME}/.scdebug/$program_name/${local_file_name}
        strace ${sto_option} -o ${route} -p ${pid} > /dev/null 2>&1 &
    done

}

print_traces()
{
    output=$(ls -lt ${HOME}/.scdebug/ --format=single-colum)
    folders=()
    while read -r pid; do
        folders+=("$pid")
    done <<< "$output"

    fixed_width=2
    printf "DIR:    %-*s" $fixed_width "$command"
    printf "NUM: %-*s" $fixed_width "$local_file_name"
    printf "FICHERO_MAS_RECIENTE: %-*s \n" $fixed_width "$file_time"

    # Recorrer vector el vector de directorios
    for dir in "${folders[@]}"; do
        files_number=$(ls -lt ${HOME}/.scdebug/${dir}/ --format=single-colum | wc -l)
        fixed_width=10
        file_time=$(ls -lt ${HOME}/.scdebug/${dir}/ | tr -s [:blank:] ';' | cut -d';' -f6,7,8,9 | tr ';' ' ' | head -n2 | tail -n1)
        printf "%-*s" $fixed_width "$dir"
        printf "%-*s" 7 "$files_number"
        printf "%s \n" "$file_time"
        #trace_2e9f7881-9937-4bfa-abfe-dcf0ceb29bba.txt
        echo
    done
}

stop_function()
{   
    commName=${stop_vector[1]}
    Launchprog=
    for word in "${stop_vector[@]:1}"; do
        Launchprog+="$word "
    done
    echo "$Launchprog"
    echo "$commName"

    echo -n "traced_"$commName"" > /proc/$$/comm
    kill -SIGSTOP $$

    exec $Launchprog > /dev/null 2>&1 &
}

resume_function()
{
    echo "Resume option"
    stopped_pid=()
    output=$(ps -u ${USER} -o pid,state | grep T | tr -s ' ' |  cut -d' ' -f2)
    while read -r pid; do
        stopped_pid+=("$pid")
    done <<< "$output"
    echo "${stopped_pid[@]}"

    for pid in "${stopped_pid[@]}"; do
        stopped_comm=$(cat /proc/$pid/comm)
        filename="trace_$(uuidgen).txt"
        route=${HOME}/.scdebug/$stopped_comm/${filename}
        if [[ ! -e "${HOME}/.scdebug/$stopped_comm" ]]; then
            mkdir ${HOME}/.scdebug/$stopped_comm
        fi
        echo $route
        strace -o ${route} ${stopped_comm} > /dev/null 2>&1 &
        # strace ${sto_option} -o ${route} -p ${pid} > /dev/null 2>&1 &
        sleep 0.5
        kill -SIGCONT $pid

    done

}

# -----------------------------------------------------------------------------

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
            shift   # fallo arreglado
            ;;

        -v | -vall )
            v_option[0]="$1"
            shift
            while [ "$1" != "" ]; do
                is_option "$1"
                if [ "$?" == "0" ];then
                    break
                fi
                v_option+=("$1")
                shift
            done
            consult
            # Aquí acaba el programa
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
            ;;
        -k )
            #echo "Opcion -k"
            kill_option="$1"
            shift
            ;;
        -S )
            shift
            while [ "$1" != "" ]; do
                is_option "$1"
                if [ "$?" == "0" ];then
                    break
                fi
                # Guardo el comando en forma de vector para quedarme con el nombre en la primero pos
                stop_vector+=("$1")
                shift
            done
            ;;
        -g | -gc | -ge )
            resume_option="$1"
            shift
            ;;
        -inv )
            resume_option="$1"
            shift
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
                prog_vector+=("$1")
                shift
            done
            ;;
    esac
done   


# Crear directorio .scdebug en cualquier caso si no existiera
if [[ ! -e "${HOME}/.scdebug" ]]; then
    mkdir "${HOME}/.scdebug"
fi

kill_function
show_user_processes
# print_traces

if [ "${prog_vector[0]}" ] || [ "${n_attach_vector[0]}" ] || [ "${p_attach_vector[0]}" ] || [ "$stop_vector"] || [ "$resume_option"] ;then 
    if [ -z "$stop_vector" ] && [ -z "$resume_option" ];then
        prog_function
        n_attach_function
        p_attach_function
    # Ya sabemos stop_vector no es vacia
    # Ahora comprobar que todas las demás son vacias
    elif [ -z "${prog_vector[0]}" ] && [ -z "${n_attach_vector[0]}" ] && [ -z "${p_attach_vector[0]}" ] && [ -z "$resume_option" ];then
        stop_function
    elif [ -z "${prog_vector[0]}" ] && [ -z "${n_attach_vector[0]}" ] && [ -z "${p_attach_vector[0]}" ] && [ -z "$stop_vector" ];then
        resume_function
    else
        error_exit "Opciones incompatibles: "${prog_vector[@]}" "${n_attach_vector[@]}" "${p_attach_vector[@]}" "${stop_vector[@]}" "${resume_option}" " $INCOMPATIBLE_OPTIONS
    fi
    echo "Opciones no vacias"
fi
# Preguntar(¿?)
# Si he activado alguna otra opción con -s sale con error: opciones incompatibles