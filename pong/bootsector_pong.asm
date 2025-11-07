use16

org 07C00h

jmp setup_game

;; CONSTANTS -----------------
VIDMEM              equ 0B800h                          ; color text mode VGA memory location
ROWLEN              equ 160                             ; 80 character row * 2 bytes each
PLAYERX             equ 4
CPUX                equ 154                             ; Keyboard scancodes
KEY_W               equ 11h
KEY_S               equ 1Fh
KEY_C               equ 2Eh
KEY_R               equ 13h
SCREENW             equ 80
SCREENH             equ 25
PADDLEHEIGHT        equ 5
PLAYERBALLSTARTX    equ 66
CPUBALLSTARTX       equ 90
BALLSTARTY          equ 7
WINCOND             equ 3

;; Variables -----------------
drawColor:      db 0F0h
playerY:        dw 10
cpuY:           dw 10
ballX:          dw 66
ballY:          dw 7
ballVelX:       db -2
ballVelY:       db 1
playerScore:    db 0
cpuScore:       db 0
cpuTimer:       db 0
cpuDifficulty:  db 1

setup_game:
    mov ax, 0003h                           ; AL = 03H text mode 80x25 characters, 16 color VGA
    int 10h

    ;; Hide Cursor
    inc ah
    mov ch, SCREENH
    int 10h                                 ; int 10h AH 01h set cursor shape; CH is starting line, CL is ending line

    ;; Set up video memory
    mov ax, VIDMEM
    mov es, ax

game_loop:

    ;; Clear screen to black every loop
    xor ax, ax
    xor di, di
    mov cx, 80*25
    rep stosw

    ;; Draw middle separating line
    mov ah, [drawColor]                     ; White bg, black fg
    mov di, 39*2                            ; 39th column, each column is 2 Bytes
    mov cx, 13                              ; Drawing every other row
    .draw_middle_loop:
        stosw
        add di, 2*ROWLEN - 2                ; Only drawing every other row, subtracting 2 to because loop increments
        loop .draw_middle_loop

    ;; Draw Player and CPU Paddles
    imul di, [playerY], ROWLEN              ; Y position is Y (# of rows) * length or row
    imul bx, [cpuY], ROWLEN
    mov cl, PADDLEHEIGHT
    .draw_player_loop:
        mov [es:di+PLAYERX], ax
        mov [es:bx+CPUX], ax
        add di, ROWLEN
        add bx, ROWLEN
        loop .draw_player_loop
    
    ;; Draw Scores
    mov ah, 0E0h
    mov cl, [playerScore]
    jcxz draw_cpu_score
    mov di, ROWLEN+66
    .playerScore_loop:
        stosw
        sub di, 6
        loop .playerScore_loop

    draw_cpu_score:
        mov cl, [cpuScore]
        jcxz get_player_input
        mov di, ROWLEN+90
        .cpuScoreloop:
            stosw
            inc di
            inc di
            loop .cpuScoreloop

    ;; Draw Scores is Digits
    ; mov di, ROWLEN+66
    ; mov bh, 0Eh
    ; mov bl, [playerScore]
    ; add bl, 30h                             ; To get the ASCII value of the digit
    ; mov [es:di], bx

    ; add di, 24
    ; mov bl, [cpuScore]
    ; add bl, 30h
    ; mov [es:di], bx         


    ;; Get Player Input
    get_player_input:
        mov ah, 1                               ; BIOS get keyboard status int 16h AH 01h
        int 16h
        jz move_cpu_up

        cbw                                     ; zero out AH if AL < 128 (single byte instruction)
        int 16h                                 ; Get keystroke in AX; AH = scancode; AL = ASCII value

        cmp ah, KEY_W
        je w_pressed
        cmp ah, KEY_S
        je s_pressed
        cmp ah, KEY_C
        je c_pressed
        cmp ah, KEY_R
        je r_pressed

        jmp move_cpu_up                         ; user pressed some other key, we'll ignore and move on


    ;; Move Player Paddle
    w_pressed:
        dec word [playerY]                  ; Move up 1 row
        jge move_cpu_up                        ; If playerY is greater than or equal to 0, then move on
        inc word [playerY]
        jmp move_cpu_up

    s_pressed:
        cmp word [playerY], SCREENH-PADDLEHEIGHT
        jge move_cpu_up
        inc word [playerY]                  ; Move down by 1 row
        jmp move_cpu_up

    r_pressed:
        ;; reset
        int 19h

    c_pressed:
        ;; Change color of the Middle line and Paddles
        add byte [drawColor], 10h           ; Move to next VGA color

    ;; Move CPU
    move_cpu_up:
        ;; CPU difficulty: Only move cpu paddle every cpuDifficutly # of game loop cycles
        mov bl, [cpuDifficulty]
        cmp [cpuTimer], bl
        jl inc_cpu_timer
        mov byte [cpuTimer], 0
        jmp move_ball

        inc_cpu_timer:
            inc byte [cpuTimer]

        mov bx, [cpuY]
        cmp bx, [ballY]
        jl move_cpu_down
        dec word [cpuY]
        jge move_ball
        inc word [cpuY]
        jmp move_ball

    move_cpu_down:
        add bx, PADDLEHEIGHT
        cmp bx, [ballY]
        jg move_ball
        cmp bx, SCREENH-1
        je move_ball
        inc word [cpuY]

    ;; Move Ball
    move_ball:
        ;; Draw Ball at current position
        imul di, [ballY], ROWLEN
        add di, [ballX]
        mov word [es:di], 2020h

        ;; Move ball to next value
        mov bl, [ballVelX]
        add [ballX], bl
        mov bl, [ballVelY]
        add [ballY], bl

    ;; Check collision
    check_hit_top:
        mov cx, [ballY]
        jcxz reverse_ball_Y
        cmp cx, SCREENH-1
        jne check_hit_player

    reverse_ball_Y:
        neg byte [ballVelY]

    check_hit_player:
        cmp word [ballX], PLAYERX
        jne check_hit_cpu
        mov bx, [playerY]
        cmp bx, [ballY]
        jg check_hit_cpu
        
        add bx, PADDLEHEIGHT
        cmp bx, [ballY]
        jl check_hit_cpu            ;; see if it should be jle

        jmp reverse_ball_X

    check_hit_cpu:
        cmp word [ballX], CPUX
        jne check_hit_left
        mov bx, [cpuY]
        cmp bx, [ballY]
        jg check_hit_left

        add bx, PADDLEHEIGHT
        cmp bx, [ballY]
        jl check_hit_left     ;; see if should be jle
    
    reverse_ball_X:
        neg byte [ballVelX]

    check_hit_left:
        cmp word [ballX], 0
        jg check_hit_right
        inc byte [cpuScore]
        mov bx, PLAYERBALLSTARTX
        jmp reset_ball

    check_hit_right:
        cmp word [ballX], ROWLEN
        jl end_collision_checks
        inc byte [playerScore]
        mov bx, CPUBALLSTARTX
    
    reset_ball:
        cmp byte [cpuScore], WINCOND
        je game_lost
        cmp byte [playerScore], WINCOND
        je game_won

        ;; Check/Change cpu difficulty for every player point scored
        imul cx, [playerScore], 10
        jcxz reset_ball_2
        mov [cpuDifficulty], cl

        ;; Randomize ball start X position a bit for variety
        cbw
        int 1Ah
        mov ax, dx
        xor dx, dx
        mov cx, 10
        div cx
        shl dx, 1
        add bx, dx
    
    reset_ball_2:
        mov [ballX], bx
        mov word [ballY], BALLSTARTY

    end_collision_checks:

    ;; Delay loop
    mov bx, [046Ch]
    inc bx
    ; inc bx
    .delay:
        cmp [046Ch], bx
        jl .delay


jmp game_loop

;; Win/Lose condition
; game_over:
;     cmp byte [playerScore], WINCOND
;     je game_won
;     jmp game_lost

game_won:
    mov dword [es:0000], 0F490F57h          ; WI
    mov dword [es:0004], 0F210F4Eh          ; N!
    cli
    hlt

game_lost:
    mov dword [es:0000], 0F4F0F4Ch          ; LO
    mov dword [es:0004], 0F450F53h          ; SE
    hlt

times 510 -($-$$) db 0                      ; Bootsector padding
dw 0AA55h                                   ; Bootsector Signature