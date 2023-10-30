#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    int segundos = 0;

    while (1) {
        //printf("Segundos transcurridos: %d\n", segundos);
        segundos++;
        sleep(1); // Espera 1 segundo
    }

    return 0;
}
