;
; sort.asm - qsort_asm, a recursive quicksort callable from C.
;
; This is your starting point: it assembles and links as-is, so the build
; works before you write any code. Right now it does nothing, which makes
; the benchmark print "NOT SORTED" and "Match: NO". Your job is to replace
; that with the sort described below.
;
; The contract, from bench.c:
;
;       int n                     [ebp+12]
;       int *arr                  [ebp+8]
;
; Sort n 32-bit signed integers in place, ascending. This is the C-facing
; routine. It must obey cdecl (prologue, args at [ebp+8]+, return in eax,
; preserve ebx/esi/edi/ebp, clean arguments after every call it makes). The
; manual lets you use any convention you document for the internal recursive
; routine, but the outer one is fixed.
;
; Requirements from the manual:
;
;   * Recursive. An iterative sort with an explicit stack array does not
;     satisfy the activity.
;   * Lomuto partition with the last element as pivot (the manual's scheme).
;   * No calls into the C standard library.
;   * Clean the arguments off the stack after each call. The next pop
;     otherwise loads an argument into a register you promised to
;     preserve, and the outer call's array base is gone.
;
; The manual's pseudocode:
;
;   qsort(arr, lo, hi):
;       if lo >= hi: return
;       p = partition(arr, lo, hi)
;       qsort(arr, lo, p - 1)
;       qsort(arr, p + 1, hi)
;
;   partition(arr, lo, hi):
;       pivot = arr[hi]
;       i = lo - 1
;       for j = lo to hi - 1:
;           if arr[j] <= pivot:
;               i = i + 1
;               swap arr[i], arr[j]
;       swap arr[i + 1], arr[hi]
;       return i + 1
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _qsort_asm qsort_asm
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .text
        global  _qsort_asm
_qsort_asm:
        enter   0,0
        pusha

        mov     eax, [ebp+12]       ; length of the array 
        dec     eax                 ; hi = n - 1, n = 0 gives -1, inner returns at once
        push    eax                 ; hi - the last element
        push    dword 0             ; lo - the first element
        push    dword [ebp+8]       ; the first argument
        call    qsort_inner
        add     esp, 12             ; caller removes 3 args x 4 bytes

        popa
        mov     eax, 0
        leave
        ret

qsort_inner:
        enter   4, 0                ; 4 bytes of local space for p
        push    ebx
        push    esi
        push    edi
        mov     esi, [ebp+8]        ; esi = arr
        mov     ebx, [ebp+12]       ; ebx = lo
        mov     edi, [ebp+16]       ; edi = hi
        cmp     ebx, edi
        jge     .done               ; signed: lo >= hi, nothing to sort

        push    edi                 ; partition(arr, lo, hi)
        push    ebx
        push    esi
        call    partition
        add     esp, 12
        mov     [ebp-4], eax        ; p lives on the stack across the recursion

        dec     eax                 ; left half: lo .. p-1
        push    eax
        push    ebx
        push    esi
        call    qsort_inner
        add     esp, 12

        mov     eax, [ebp-4]
        inc     eax                 ; right half: p+1 .. hi
        push    edi
        push    eax
        push    esi
        call    qsort_inner
        add     esp, 12
.done:
        pop     edi
        pop     esi
        pop     ebx
        leave
        ret

; esi = arr, ebx = i, ecx = j, edi = hi, edx = pivot
partition:
        enter   0, 0
        push    ebx
        push    esi
        push    edi
        mov     esi, [ebp+8]
        mov     edi, [ebp+16]
        mov     edx, [esi+edi*4]    ; pivot = arr[hi]
        mov     ebx, [ebp+12]
        dec     ebx                 ; i = lo - 1
        mov     ecx, [ebp+12]       ; j = lo
.loop:
        cmp     ecx, edi
        jge     .end                ; j runs lo .. hi-1
        mov     eax, [esi+ecx*4]    ; eax = arr[j]
        cmp     eax, edx
        jg      .next               ; signed jump, so negatives sort right
        inc     ebx                 ; i = i + 1
        xchg    eax, [esi+ebx*4]    ; eax = old arr[i], arr[i] = arr[j]
        mov     [esi+ecx*4], eax    ; arr[j] = old arr[i]
.next:
        inc     ecx
        jmp     .loop
.end:
        inc     ebx                 ; i + 1
        mov     eax, [esi+ebx*4]
        mov     ecx, [esi+edi*4]
        mov     [esi+ebx*4], ecx    ; swap arr[i+1] and arr[hi]
        mov     [esi+edi*4], eax
        mov     eax, ebx            ; return p = i + 1
        pop     edi
        pop     esi
        pop     ebx
        leave
        ret