    .arch   armv8-a
//  Swap the chars in the word in pair
// Data
    .data
varname:
    .ascii  "LAB3_FILE_NAME\0"
    .equ    varnamelen, .-varname
msg1:
    .ascii  "File name: \0"
    .equ    msg1len, .-msg1
msg2:
    .ascii  "Can not open the file!\0"
    .equ    msg2len, .-msg2
msg3:
    .ascii  "Env var responsible for the file name not found!\0"
    .equ    msg3len, .-msg3
str:
    .skip   8
    .equ    strlen, .-str
newstr:
    .skip   9
    .equ    newstrlen, .-newstr
// Code
    .text
    .align  2
    .global _start
    .type   _start, %function
_start:
    adr x0, varname
    ldr x1, [sp]
    lsl x1, x1, #3
    add x1, x1, #16
    mov x2, sp
    add x1, x1, x2
    bl  pars_args
    cbz x0, ERR_1

    stp x0, xzr, [sp, #-16]!
    mov x29, sp
    adr x0, msg1
    bl  print_1
    ldr x0, [sp]
    bl  print_1
    bl new_line

    ldr x0, [sp]
    adr x1, str
    mov x2, strlen
    adr x3, newstr
    mov x4, newstrlen
    bl  solve
    cmp x0, #0
    bne ERR_0
    b   EXIT
EXIT:
    mov x0, #0
    mov x8, #93
    svc #0
ERR_0:
    adr x0, msg2
    mov x1, msg2len
    bl  print
    bl  new_line
    b   EXIT
ERR_1:
    adr x0, msg3
    mov x1, msg3len
    bl  print
    bl  new_line
    b   EXIT
    .size   _start, .-_start

// pars_args
// Args:
//  x0: [address] var name
//  x1: [address] start of env var addresses
// Returns:
//  x0: [address] file name or 0 if env var with that name dont exist
// Notes: Value in x0 - x19 can be deleted
    .type   pars_args, %function
pars_args:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x6, #0
1:
    ldr x2, [x1], #8
    cmp x2, xzr
    beq 5f
    mov x3, #0
2:
    ldrb    w4, [x2, x3]
    ldrb    w5, [x0, x3]
    cmp w4, wzr
    beq 3f
    cmp w4, w5
    bne 3f
    add x3, x3, #1
    b   2b
3:
    cmp w5, wzr
    bne 4f
    cmp w4, '='
    bne 4f
    mov x0, #0
    add x3, x3, #1
    add x0, x2, x3
    mov x6, #1
    b   5f
4:
    b   1b
5:
    cmp x6, #0
    bne 0f
    mov x0, #0
0:
    ldp x29, x30, [sp], #16
    ret
    .size   pars_args, .-pars_args

// solve
// Args:
//  x0: [address] file name
//  x1: [address] buffer
//  x2: buffer size (in bytes)
//  x3: [address] another buffer
//  x4: second buffer size (should be more then first buffer size)
// Returns:
//  x0: 0 - seccess, -1 - can not open the file
// Notes: Value in x0 - x19 can be deleted
    .type   solve, %function
    .equ    p_file_name, 40
    .equ    p_str, 32
    .equ    p_strlen, 24
    .equ    p_newstr, 16
    .equ    p_newstrlen, 8
    .equ    p_fd, 0
solve:
    stp x29, x30, [sp, #-16]!
    stp x1, x0, [sp, #-16]!
    stp x3, x2, [sp, #-16]!
    stp xzr, x4, [sp, #-16]!
    bl  open_file
    cmp x0, #0
    blt 17f
    str x0, [sp]
    mov x29, sp
    mov w4, #0
    mov x5, #1
    mov x6, #1
1:
    ldr x0, [sp, p_fd]
    ldr x1, [sp, p_str]
    ldr x2, [sp, p_strlen]
    sub x2, x2, #1
    stp x5, x4, [sp, #-16]!
    stp x6, xzr, [sp, #-16]!
    mov x8, #63
    svc #0
    ldr x6, [sp], #16
    ldp x5, x4, [sp], #16
    cmp x0, #0
    bgt 2f
    cbz w4, 16f
    ldr x0, [sp, p_newstr]
    mov w1, wzr
    strb    w4, [x0]
    strb    w1, [x0, #1]
    mov x1, #1
    bl  print
    b   16f
2:
    ldr x1, [sp, p_str]
    strb    wzr, [x1, x0]
    mov x0, x1
    ldr x1, [sp, p_newstr]
    cbz w4, 5f
    ldrb    w2, [x0], #1
    cmp w2, ' '
    bne 3f
    strb    w4, [x1], #1
    mov w4, #0
    mov x6, #0
    b   5f
3:
    cmp w2, '\n'
    bne 4f
    strb    w4, [x1], #1
    mov w4, #0
    sub x0, x0, #1
    b   5f
4:
    strb    w2, [x1], #1
    strb    w4, [x1], #1
    mov w4, #0
    b   9f
5:
    ldrb    w2, [x0], #1
    cmp w2, ' '
    bne 6f
    mov x6, #0
    b   5b
6:
    cmp w2, '\n'
    bne 7f
    strb    w2, [x1], #1
    mov x5, #1
    b   5b
7:
    cbz w2, 15f
    orr x3, x5, x6
    cmp x3, #0
    bne 8f
    mov w3, ' '
    strb    w3, [x1], #1
8:
    sub x0, x0, #1
    mov x6, #1
9:
    mov x7, #1
    mov x5, #0
10:
    ldrb    w2, [x0], #1
    cmp w2, ' '
    bne 12f
11:
    sub x0, x0, #1
    b   5b
12:
    cmp w2, '\n'
    beq 11b
    cbz w2, 14f
    cmp x7, #2
    bne 13f
    ldrb    w3, [x1, #-1]!
    strb    w2, [x1], #1
    strb    w3, [x1], #1
    mov x7, #1
    b   10b
13:
    strb   w2, [x1], #1
    mov x7, #2
    b   10b
14:
    cmp x7, #1
    beq 11b
    ldrb    w3, [x1, #-1]!
    mov w4, w3
    b   11b
15:
    ldr x0, [sp, p_newstr]
    stp x4, x5, [sp, #-16]!
    stp x6, xzr, [sp, #-16]!
    sub x1, x1, x0
    bl  print
    ldr x6, [sp], #16
    ldp x4, x5, [sp], #16
    b   1b
16:
    mov x0, #0
    b   0f
17:
    mov x0, #-1
    b   0f
0:
    stp x0, xzr, [sp, #-16]!
    ldr x0, [sp, p_fd]
    bl  close_file
    ldr x0, [sp], #16
    add sp, sp, #48
    ldp x29, x30, [sp], #16
    ret
    .size   solve, .-solve

// print_1
    .type   print_1, %function
print_1:
    stp x29, x30, [sp, #-16]!
    stp x0, xzr, [sp, #-16]!
    mov x29, x30
1:
    ldr x0, [sp]
    ldrb w1, [x0], #1
    str x0, [sp]
    cmp w1, wzr
    beq 0f
    mov x1, x0
    sub x1, x1, #1
    mov x0, #1
    mov x2, #1
    mov x8, #64
    svc #0
    b   1b
0:
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret
    .size   print_1, .-print_1

// print
// Args:
//  x0: [address] string
//  x1: len of x0 string
//  Notes: Value in x0 - x19 can be deleted
    .type   print, %function
print:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, x1
    mov x1, x0
    mov x0, #1
    mov x8, #64
    svc #0
    ldp x29, x30, [sp], #16
    ret
    .size   print, .-print

// open_file
// Args:
//  x0: [address] path to file
// Returns:
//  x0: file descriptor
// Notes: Value in x0 - x19 can be deleted
    .type   open_file, %function
open_file:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x1, x0
    mov x0, #-100
    mov x2, #0
    mov x8, #56
    svc #0
    ldp x29, x30, [sp], #16
    ret
    .size   open_file, .-open_file

// close_file
// Args:
//  x0: file descriptor
// Notes: Value in x0 - x19 can be deleted
    .type   close_file, %function
close_file:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x8, #57
    svc #0
    ldp x29, x30, [sp], #16
    ret
    .size   close_file, .-close_file

// print_file_name
// Args:
//  x0: [address] introduse message
//  x1: len of x0 string
//  x2: [address] file name
//  x3: len of x2 string
// Notes: Value in x0 - x19 can be deleted
    .type   print_file_name, %function
print_file_name:
    stp x29, x30, [sp, #-16]!
    stp x0, x1, [sp, #-16]!
    stp x2, x3, [sp, #-16]!
    mov x29, sp
    mov x0, #1
    ldr x1, [sp, #16]
    ldr x2, [sp, #24]
    mov x8, #64
    svc #0
    mov x0, #1
    ldr x1, [sp]
    ldr x2, [sp, #8]
    mov x8, #64
    svc #0
    add sp, sp, #32
    ldp x29, x30, [sp], #16
    ret
    .size   print_file_name, .-print_file_name

// new_line
// Notes: Value in x0 - x19 can be deleted
    .type   new_line, %function
new_line:
    stp x29, x30, [sp, #-16]!
    mov x0, '\n'
    mov x1, #1
    stp x0, x1, [sp, #-16]!
    mov x29, sp
    mov x0, #1
    mov x1, sp
    ldr x2, [sp, #8]
    mov x8, #64
    svc #0
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret
    .size   new_line, .-new_line

