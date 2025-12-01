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

;==========================================================
; Read KeyBoard 
;==========================================================
paddleMove: 
        pusha
        push ds
        push es
        mov ax,0xb800
        mov es,ax

        in al,0x60
        cmp al,0x01
        je esccode

        cmp al, 4Bh        ; Left Arrow
        je  key_left

        cmp al, 4Dh        ; Right Arrow
        je  key_right
        jne nomatch

    key_left:
        call erasePaddle
        mov di, [paddlePos]
        sub di, 4
        mov [paddlePos], di
        call CheckBoundaryforPaddle
        cmp word[paddleY],2
        jle skipforme
        sub word [paddleY],2
        skipforme:
        call printPaddle
        jmp nomatch

    key_right:
        call erasePaddle
        mov di, [paddlePos]
        add di, 4
        mov [paddlePos], di
        call CheckBoundaryforPaddle
        cmp word[paddleY],78
        jge exitforyou
        add word [paddleY],2
        exitforyou:
        call printPaddle
        jmp nomatch
    esccode:
        mov byte[escCheckflag],1
        nomatch: 
        pop es
        pop ds
        popa
        jmp far [oldIsr]

readKeyBoard:
        push bp
        mov bp,sp
        xor ax,ax
        mov es,ax
        mov ax,[es:9*4]
        mov word[oldIsr],ax
        mov ax,[es:9*4+2]
        mov word[oldIsr+2],ax
        cli
        mov word[es:9*4],paddleMove
        mov [es:9*4+2],cs
        sti
        pop bp
        ret


;============================================================
UpwardDownWardPrintBall:
        push bp
        mov bp, sp

        ; Angle = 90 (Straight Up)
        cmp word[ballAngle], 90
        jne nextCmp45
        sub word[ballPos], 160
        jmp exit1

    nextCmp45:
        ; Angle = 45 (Up-Right)
        cmp word[ballAngle], 45
        jne newCmp135
        sub word[ballPos], 158
        jmp exit1

    newCmp135:
        ; Angle = 135 (Up-Left)
        cmp word[ballAngle], 135
        jne nextCmpfor270
        sub word[ballPos], 162
        jmp exit1

    nextCmpfor270:
        ; Angle = 270 (Straight Down)
        cmp word[ballAngle], 270
        jne nextcmp225
        add word[ballPos], 160
        jmp exit1

    nextcmp225:
        ; Angle = 225 (Down-Left)
        cmp word[ballAngle], 225
        jne nextCmp315
        add word[ballPos], 158
        jmp exit1

    nextCmp315:
        ; Angle = 315 (Down-Right)
        cmp word[ballAngle], 315
        jne exit1
        add word[ballPos], 162

    exit1:
        pop bp
        ret

cornerCollisionAngleUpdate:
        push bp
        mov bp,sp
        push ax
        
        mov ax, [ballAngle]   ; AX = angle
        add ax, 180           ; AX = angle + 180
        cmp ax, 360
        jb storeangle      
        sub ax, 360           ; subtract 360 to wrap
    storeangle:
        mov [ballAngle], ax  
        pop ax
        pop bp
        ret

;=====================================================
ballAngleUpdate:
        push bp
        mov bp, sp
        push ax
        mov ax,360
        sub ax,word[ballAngle]
        mov word[ballAngle],ax
        pop ax
        pop bp
        ret
    wallAngleUpdate:
        push bp
        mov bp, sp
        push ax
        mov ax,180
        sub ax,word[ballAngle]
        cmp word[ballAngle], 180
        jl exitWall
        jg check225
    check225:
        add ax,360
        jmp exitWall
    exitWall:
        mov word[ballAngle],ax
        pop ax
        pop bp
        ret


;=====================================================
ballAngleUpdate:
        push bp
        mov bp, sp
        push ax
        mov ax,360
        sub ax,word[ballAngle]
        mov word[ballAngle],ax
        pop ax
        pop bp
        ret
    wallAngleUpdate:
        push bp
        mov bp, sp
        push ax
        mov ax,180
        sub ax,word[ballAngle]
        cmp word[ballAngle], 180
        jl exitWall
        jg check225
    check225:
        add ax,360
        jmp exitWall
    exitWall:
        mov word[ballAngle],ax
        pop ax
        pop bp
        ret

;==============================================
PaddleCollisionwithBall:
        push bp
        mov bp,sp
        push ax
        push bx
        push cx

        mov bx,[ballPos]
        add bx,2

        ; AX = paddle start position
        mov ax,80
        mov cl,23
        mul cl
        add ax,word[paddleY]
        shl ax,1          ; AX = paddlePos start

        ; CX = paddle start
        mov cx,ax
        add ax,4         ;2 cell
        cmp bx,ax
        je middle
        jl left
        add ax,4
        cmp bx,ax
        jge right

    middle:
        mov word[ballAngle],90
        jmp done

    left:
        mov word[ballAngle],135
        jmp done

    right:
        mov word[ballAngle],45

    done:
        pop cx
        pop bx
        pop ax
        pop bp
        ret
;======================================================
CollisionBallCheckForEveryDirection:
        push bp
        mov bp, sp
        push ax
        push bx
        push di
        pusha

        mov ax, 0xb800
        mov es, ax
        mov di, [ballPos]

        mov bx, 0x60C4
        cmp bx, [es:di]
        jne checkSideWalls
        call ballAngleUpdate
        call UpwardDownWardPrintBall
        jmp exitCollision

    checkSideWalls:
        mov bx, 0x60B3
        cmp bx, [es:di]
        jne checkPaddle
        call wallAngleUpdate
        call UpwardDownWardPrintBall
        jmp exitCollision

    checkPaddle:
        mov bx, 0x07DF        ;paddle code
        cmp bx, [es:di]
        jne checkCorners
        call PaddleCollisionwithBall
        call UpwardDownWardPrintBall
        mov ax,800
        push ax
        call soundeffect
        jmp exitCollision
    checkCorners:
        mov bx, 0x60DA        ; top-left corner

        cmp bx, [es:di]
        je isCorner

        mov bx, 0x60BF        ; top-right corner
        cmp bx, [es:di]
        je isCorner

        mov bx, 0x60C0        ; bottom-left corner
        cmp bx, [es:di]
        je isCorner

        mov bx, 0x60D9     
        cmp bx, [es:di]
        je isCorner

        jmp checkLastRow    

    isCorner:
        call cornerCollisionAngleUpdate
        call UpwardDownWardPrintBall
        mov ax,900
        push ax
        call soundeffect
        jmp exitCollision
    checkLastRow:
        mov bx,0x6078  ;last row
        cmp bx,[es:di]
        jne CheckBrick
        call startGame
        call UpwardDownWardPrintBall
        jmp exitCollision
    CheckBrick:
        mov bx,0x04DB ;red color check
        cmp bx,[es:di]
        jne nextColorRed
        mov ax,0x0CDB
        mov [es:di],ax
        call ballAngleUpdate
        call UpwardDownWardPrintBall
        mov ax,1300
        push ax
        call soundeffect
        inc word[score]
        jmp exitCollision
    
    nextColorRed:
        mov bx,0x0ADB ;green color check
        cmp bx,[es:di]
        jne nextcolorTry
        mov ax,0x0720
        mov [es:di],ax
        call ballAngleUpdate
        call UpwardDownWardPrintBall
        dec word[BrickerCounter]
        mov ax,1000
        push ax
        call soundeffect
        inc word[score]
        jmp exitCollision
    nextcolorTry:
        mov bx,0x0EDB
        cmp bx,[es:di]
        jne lastcolortry
        mov ax,0x0ADB
        mov [es:di],ax
        call ballAngleUpdate
        call UpwardDownWardPrintBall
        mov ax,1100
        push ax
        call soundeffect
        inc word[score]
        jmp exitCollision
    lastcolortry:
        mov bx,0x0CDB
        cmp bx,[es:di]
        jne exitCollision
        mov ax,0x0EDB
        mov [es:di],ax
        call ballAngleUpdate
        call UpwardDownWardPrintBall
        mov ax,1200
        push ax
        call soundeffect
        inc word[score]
        jmp exitCollision


    exitCollision:
        popa
        pop di
        pop bx
        pop ax
        pop bp
        ret

BallMovement:
        push bp
        mov bp,sp
    GameLoop:
        call Timer
        call Timer
        call Timer
        call Timer
        call eraseBall
        call UpwardDownWardPrintBall
        call CollisionBallCheckForEveryDirection
        call CollisionBallCheckForEveryDirection  ; for error handlings
        call PrintBall
        call PrintScoreAndLife
        call isGameOver
        cmp byte[gameOverFlag],1
        je ezit
        cmp byte[escCheckflag],1
        je ezit
        jmp GameLoop
        ezit:
        pop bp
        ret

;=====================================================
Timer:
        push bp
        mov bp,sp
        push cx
        mov cx,10000
        l98:
        add cx,3
        dec cx
        cmp cx,0
        jne l98
        
        pop cx
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
