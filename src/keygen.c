/*
 *  keygen.c
 *  Plexer
 *
 *  Created by David Owens II on 8/1/09.
 *  Copyright 2009 Kiad Software. All rights reserved.
 *
 */


// All serial keys are in the form:
//   XXXX-XXXX-XXXX-XXXX where X {0..9,A-F}, base 16
//   0123-4567-89AB-CDEF designates the position

// Randomly generate positions 0, 5, A, and F
// [1] = [0] * 7 - 2
// [2] = [0] + [5]
// [3] = [A]
// [4] = [F] - [A] - [0]
// [6] = Random
// [7] = [F] * [A] * [5]
// [8] = [F] + 1
// [9] = [A] - [0] + 3
// [B] = Random
// [C] = 17 * [5]
// [D] = [0] / 3
// [E] = [F] / 3 + 8

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
    char* query;
    unsigned int key[16];
    
    printf("Content-Type: text/plain;charset=us-ascii\n\n");
    query = getenv("QUERY_STRING");
    
    if (query == 0 || strcmp(query, "oUedfe839320dk44iIEDKJFE492") != 0)
        return 0;
    
    // We need to generate positions 0, 5, A, and F.
    srand(time(0));
    
    key[0x0] = rand() % 16;
    key[0x5] = rand() % 16;
    key[0xA] = rand() % 16;
    key[0xF] = rand() % 16;
    
    key[0x1] = (key[0x0] * 7 - 2) % 16;
    key[0x2] = (key[0x0] + key[0x5]) % 16;
    key[0x3] = (key[0xA]) % 16;
    key[0x4] = (key[0xF] - key[0xA] - key[0x0]) % 16;
    key[0x6] = rand() % 16;
    key[0x7] = (key[0xF] * key[0xA] * key[0x5]) % 16;
    key[0x8] = (key[0xF] + 1) % 16;
    key[0x9] = (key[0xA] - key[0x0] + 3) % 16;
    key[0xB] = rand() % 16;
    key[0xC] = (17 * key[0x5]) % 16;
    key[0xD] = (key[0x0] / 3) % 16;
    key[0xE] = (key[0xF] / 3 + 8) % 16;
    
    int i;
    for (i = 0; i < 16; ++i) {
        if (i % 4 == 0 && i != 0)
            printf("-");
        
        if (key[i] == 15)
            printf("F");
        else if (key[i] == 14)
            printf("E");
        else if (key[i] == 13)
            printf("D");
        else if (key[i] == 12)
            printf("C");
        else if (key[i] == 11)
            printf("B");
        else if (key[i] == 10)
            printf("A");
        else
            printf("%c", key[i] + '0');
    }
    
    return 0;
}
