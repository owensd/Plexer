//
//  KSRegistration.m
//  Plexer
//
//  Created by David Owens II on 7/20/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSRegistration.h"

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


// We only validate 6 of the above rules. This allows us to change the verification
// if a key-gen is found.

int intValueForChar(char c) {
    if (c == 'F' || c == 'f') return 15;
    if (c == 'E' || c == 'e') return 14;
    if (c == 'D' || c == 'd') return 13;
    if (c == 'C' || c == 'c') return 12;
    if (c == 'B' || c == 'b') return 11;
    if (c == 'A' || c == 'a') return 10;
    
    int temp = (c - '0');
    return temp;
}

int isValidSerialNumber(const char* key) {
    if (key == NULL) return -100;
    
    unsigned int keys[16];
    
    // let's make our life a little easier and store the int values in the array.
    for (int idx = 0, c = 0; key[c] != '\0'; ++c) {
        if (key[c] != '-') {
            keys[idx] = intValueForChar(key[c]);
            ++idx;
        }   
    }
    
    // Validate rule: [1] = [0] * 7 - 2
    if (keys[1] != (keys[0] * 7 - 2) % 16) return -1;
    
    // Validate rule: [2] = [0] + [5]
    if (keys[2] != (keys[0] + keys[5]) % 16) return -2;
    
    // Validate rule: [4] = [F] - [A] - [0]
    if (keys[4] != (keys[15] - keys[10] - keys[0]) % 16) return -3;
    
    // Validate rule: [7] = [F] * [A] * [5]
    if (keys[7] != (keys[15] * keys[10] * keys[5]) % 16) return -4;
    
    // Validate rule: [8] = [F] + 1
    if (keys[8] != (keys[15] + 1) % 16) return -5;
    
    // Validate rule: [9] = [A] - [0] + 3
    if (keys[9] != (keys[10] - keys[0] + 3) % 16) return -6;
    
    return 0;
}

