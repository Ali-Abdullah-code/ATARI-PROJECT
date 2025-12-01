[org 0x100]

jmp main

;===========Global veriable===========
paddlePos: dw 3760 ;row 23 col 40
paddleY: dw 40
ballPos: dw 3604
ballAngle: dw 90 ;135 90 45 225 270 315
oldIsr: dd 0
escCheckflag: db 0
BrickerCounter: dw 0
healthcounter: db 3
gameOverFlag: db 0
score: dw 0

enterMessage: db 'Press Enter to Continue',0
scoreLine: db 'Your Score: '

flagEsc: db 0
flagEnter: db 0


clrscr:
        push bp
        mov bp,sp
        push ax
        push es
        push di
        push cx
        xor di,di
        mov ax,0xb800
        mov es,ax
        mov ax,0x0720
        mov cx,2000
        cld
        rep stosw
        pop cx
        pop di
        pop es
        pop ax
        pop bp
        ret 

strlen: 
        push bp
        mov bp,sp
        push es
        push si
        push cx
        les di,[bp+4]
        mov cx,0xffff
        xor ax,ax
        cld
        repne scasb
        mov ax,0xffff
        sub ax,cx
        dec ax
        pop cx
        pop di
        pop es
        pop bp
        ret 4

printBoundaries:
        push ax
        push es
        push cx
        push di
        mov cx, 23
        mov ax, 0xb800
        mov es, ax
        mov di, 160
        mov ax, 0x60B3

    sideWallsLoop:
        cmp di, 320
        jae notCorners
        mov word [es:di], 0x60DA
        add di, 158
        mov word [es:di], 0x60BF
        add di, 2
        dec cx
        jmp sideWallsLoop
    notCorners:
        mov [es:di], ax
        add di, 158
        mov [es:di], ax
        add di, 2
        loop sideWallsLoop
        mov word [es:di], 0x60C0
        add di, 158
        mov word [es:di], 0x60D9

        mov cx, 78
        mov di, 162
        mov ax, 0x60C4
    upperWallLoop:
        mov [es:di], ax
        add di, 2
        loop upperWallLoop

        mov cx, 78
        mov di, 3842
        mov ax, 0x6078
    lowerWallLoop:
        mov [es:di], ax
        add di, 2
        loop lowerWallLoop

        pop di
        pop cx
        pop es
        pop ax
        ret
    MakingBricks:
        push bp
        mov bp,sp
        pusha
        mov word[BrickerCounter],0
        mov ax,0xb800
        mov es,ax
        mov di,644
        mov ax,0x07DB
        mov dx,4
    loopforprintBricks:
        cmp dx,4
        jne Redcolor
        mov ax,0x04DB  ;red color
        inc word[BrickerCounter]
        jmp okdireport
    Redcolor:
        cmp dx,3
        jne yellowcolor
        mov ax,0x0CDB  ;red color
        inc word[BrickerCounter]
        jmp okdireport
    yellowcolor:
        cmp dx,2
        jne greencolor
        mov ax,0x0EDB
        inc word[BrickerCounter]
        jmp okdireport
    greencolor:
        cmp dx,1
        jne okdireport
        mov ax,0x0ADB
        inc word[BrickerCounter]
    okdireport:
        mov cx,76
        cld
        rep stosw
        add di,168
        dec dx
        cmp dx,0
        jne loopforprintBricks
        mov ax,76
        mul word[BrickerCounter]
        mov [BrickerCounter],ax
        popa
        pop bp
        ret

    printNumber:
        push bp
        mov bp, sp

        push ax
        push bx
        push cx
        push dx
        push di
        mov di,[bp+6]
        mov ax,[bp+4]
        mov bx, 10       ; base 10
        mov cx, 0        ; digit count
    convert_loop:
        xor dx, dx       ; clear DX before div
        div bx           ; AX / 10 → AX=quotient, DX=remainder

        add dl, '0'      ; convert remainder to ASCII
        push dx          ; store ASCII character
        inc cx           ; count digit

        cmp ax, 0
        jne convert_loop

    print_loop:
        pop dx           ; get ASCII digit
        mov dh, 0Ch      ; attribute
        mov [es:di], dx  ; print character
        add di, 2        ; move to next cell
        loop print_loop

        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 4

;====================================================================

erasePaddle:
        push bp
        mov bp, sp
        push ax
        push es
        push cx
        push di

        mov ax, 0xb800
        mov es, ax
        mov ax, 0x0720
        mov di, [paddlePos]
        mov cx, 6

        paddleLoop:
        sub di, 2
        mov [es:di], ax
        loop paddleLoop
        mov [paddlePos], di

        pop di
        pop cx
        pop es
        pop ax
        pop bp
        ret

printPaddle:
        push bp
        mov bp, sp
        push ax
        push es
        push cx
        push di

        mov ax, 0xb800
        mov es, ax
        mov ax, 0x07DF
        mov di, [paddlePos]
        mov cx, 6

        cld
        rep stosw
        mov [paddlePos], di

        pop di
        pop cx
        pop es
        pop ax
        pop bp
        ret
    
CheckBoundaryforPaddle:
        push bp
        mov bp,sp
        push di
        mov di,[paddlePos]
        cmp di,3682
        ja newCmp
        mov word [paddlePos], 3682
        jmp exit

    newCmp:
        cmp di,3826
        jb exit
        mov word [paddlePos], 3826    

        exit:
        pop di
        pop bp
        ret

;==============================================


eraseBall:
        push bp
        mov bp,sp
        push ax
        push es
        push di
        mov ax,0xb800
        mov es,ax
        mov di,[ballPos]
        mov ax,0x0720
        mov [es:di],ax
        pop di
        pop es
        pop ax
        pop bp
        ret

PrintBall:
        push bp
        mov bp,sp
        push ax
        push es
        push di
        mov ax,0xb800
        mov es,ax
        mov di,[ballPos]
        mov ax,0x07F8
        mov [es:di],ax
        pop di
        pop es
        pop ax
        pop bp
        ret


main:
        call clrscr
        cmp byte[flagEnter],1
        je exitToplayGame
        cmp byte[flagEsc],1
        je excloop1
    exitToplayGame:
        cmp byte[flagEnter],1
        je EnjoyTheRide
        cmp byte[flagEsc],1
        je excloop1
    EnjoyTheRide:
        call clrscr
        call MakingBricks
        call printBoundaries
    excloop: 
        mov ah, 0 ; service 0 – get keystroke
        int 0x16 ; call BIOS keyboard service
        cmp al, 27 ; is the Esc key pressed
    jne excloop
    excloop1:
    mov ax,0x1
    int 21h
    mov ax,0x4c00
    int 21h
