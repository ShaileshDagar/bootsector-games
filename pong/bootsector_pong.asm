use16

org 8000h

mov ax, 0003h               ; AL = 03H text mode 80x25 characters, 16 color VGA
int 10h

;; Set up video memory
mov ax, 0B800h
mov es, ax

game_loop:

    ;; Clear screen to black every loop
;    xor ax, ax
;    xor di, di
;    mov cx, 80*25
;    rep stosw

    xor di, di
    mov ax, 0F41h
    stosw

;; Draw stuff to screen

;; Player Input

;; CPU Input

jmp game_loop

;; Win/Lose condition

times 510 -($-$$) db 0      ;; Bootsector padding
dw 0AA55h                   ; Bootsector Signature