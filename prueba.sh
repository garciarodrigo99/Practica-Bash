strace pene > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    #error_exit "${prog[0]} no es un archivo o directorio existente" 2
    echo exito
else 
    echo error
fi