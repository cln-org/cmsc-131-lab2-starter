;
; util.asm - gcd_asm and sum_range_asm, both recursive, callable from C.
;
; Implements recursive GCD and range-sum routines callable from C.
;
; The contracts, from bench.c:
;
;       int b                       [ebp+12]
;       int a                       [ebp+8]
;       int gcd_asm(int a, int b)   returns the greatest common divisor
;
;       int hi                      [ebp+12]
;       int lo                      [ebp+8]
;       int sum_range_asm(lo, hi)   returns the sum of lo..hi inclusive
;
; Both are C-facing and must obey cdecl: prologue, args at [ebp+8]+, return
; in eax, preserve ebx/esi/edi/ebp, clean arguments after every call.
;
; gcd_asm also sets the global `gcd_depth` to the recursion depth of its
; most recent call. The depth is the number of gcd calls on the stack at
; the deepest point, the first call counted as 1. gcd(1071, 462) makes
; four calls, so it reaches 4. bench.c declares the global extern and
; prints it after --gcd:
;
;       int gcd_depth               (in .bss, exported, one int)
;
; The manual's requirements:
;
;   * Both recursive (Euclid's algorithm for gcd).
;   * sum_range_asm must be reentrant. It has to stay correct when a second
;     call begins before the first has finished. That means no .data or
;     .bss storage that changes during execution. Everything lives on the
;     stack and in registers. The static gcd_depth global is gcd's, not
;     sum_range's, and it is diagnostic rather than part of a result.
;   * sum_range_asm calls the C function bench_callback(void) once each
;     time C calls it, which is how bench makes one call overlap another.
;     The recursive calls must not call it again. bench counts the calls.
;     Declare it extern and call it with cdecl. It is not in the manual's
;     pseudocode, but it is what the reentrancy demo runs on.
;   * No calls into the C standard library.
;
; Euclid:
;
;   gcd(a, b):
;       if b == 0: return a
;       return gcd(b, a % b)
;
; sum_range, written so that nothing lives outside the stack:
;
;   sum_range(lo, hi):
;       if lo > hi: return 0
;       return lo + sum_range(lo + 1, hi)
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _gcd_asm gcd_asm
  %define _sum_range_asm sum_range_asm
  %define _gcd_depth gcd_depth
  %define _bench_callback bench_callback
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .bss
        global  _gcd_depth
_gcd_depth      resd    1

segment .text
        global  _gcd_asm
        extern  _bench_callback

; int gcd_asm(int a, int b): cdecl, called from C
_gcd_asm:
        enter   0,0
        ; Start counting calls at one, then pass b and a to the worker.
        push    dword 1                 ; depth = 1 (first call)
        push    dword [ebp+12]          ; b
        push    dword [ebp+8]           ; a
        call    gcd_inner
        add     esp, 12                 ; remove 3 args x 4 bytes
        leave
        ret

; gcd_inner(a, b, depth)   internal, recursive
; frame after enter 0,0:
;       [ebp+16] depth
;       [ebp+12] b
;       [ebp+ 8] a
;       [ebp+ 4] return address
;       [ebp+ 0] saved ebp
; caller removes the 3 args (add esp, 12); returns gcd in eax
; registers: uses only eax and edx (caller-saved), nothing to preserve
gcd_inner:
        enter   0,0
        mov     eax, [ebp+12]           ; b
        cmp     eax, 0
        je      .base_case              ; if b == 0: return a

        ; Continue with b and the remainder of a divided by b; add one call.
        mov     eax, [ebp+16]           ; depth
        add     eax, 1                  ; depth + 1
        push    eax

        mov     eax, [ebp+8]            ; a
        cdq                             ; sign-extend eax into edx:eax
        mov     ecx, dword[ebp+12]      ; b
        idiv    ecx                     ; a / b
        push    edx                     ; remainder, result of a % b
        push    dword[ebp+12]           ; b
        call    gcd_inner
        add     esp, 12                 ; remove 3 args x 4 bytes
        leave
        ret

.base_case:
        ; Save how many calls it took to reach b = 0.
        mov     eax, [ebp+16]           ; depth
        mov     [_gcd_depth], eax       ; write depth in global
        mov     eax, [ebp+8]            ; return a
        leave
        ret
        
        

        global  _sum_range_asm
_sum_range_asm:
        enter   0,0
        push    ebx
        push    esi
        push    edi

        ; The callback can start another sum before this call begins recursing.
        call    _bench_callback

        push    dword [ebp+12]          ; hi
        push    dword [ebp+8]           ; lo
        call    sum_range_inner
        add     esp, 8

        pop     edi
        pop     esi
        pop     ebx
        leave
        ret

; Each call keeps its lo and hi on the stack, so nested calls keep their own values.
sum_range_inner:
        enter   0,0
        mov     eax, [ebp+8]            ; lo
        cmp     eax, [ebp+12]           ; lo > hi?
        jg      .empty

        ; Add lo to the sum of the rest of the range.
        inc     eax
        push    dword [ebp+12]          ; hi
        push    eax                     ; lo + 1
        call    sum_range_inner
        add     esp, 8
        add     eax, [ebp+8]            ; add this frame's lo
        leave
        ret

.empty:
        ; An empty range has a sum of zero.
        xor     eax, eax
        leave
        ret
