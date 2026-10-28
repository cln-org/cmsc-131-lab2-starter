;
; search.asm - bsearch_asm, a recursive binary search callable from C.
;
; This is your starting point: it assembles and links as-is, so the build
; works before you write any code. Right now it always returns 0, which
; makes the benchmark report a match at index 0 for any key. Your job is to
; replace that with the search described below.
;
; The contract, from bench.c:
;
;       int key                    [ebp+16]
;       int n                      [ebp+12]
;       int *arr                   [ebp+8]
;
; Return the index of key in the sorted array, or -1 if it is absent.
; Preserve ebx/esi/edi/ebp, return in eax, and obey cdecl for the outer
; routine (the internal recursive one may use any convention you document).
;
; Requirements from the manual:
;
;   * Recursive.
;   * Compute the midpoint as lo + (hi - lo) / 2, never (lo + hi) / 2.
;     The sum can overflow 32 bits on large arrays. The difference cannot.
;     This exact bug lived in the Java standard library for nine years.
;   * An absent key returns -1.
;   * An empty array and a single-element array must behave.
;   * No calls into the C standard library.
;
; The manual's pseudocode:
;
;   bsearch(arr, lo, hi, key):
;       if lo > hi: return -1
;       mid = lo + (hi - lo) / 2
;       if arr[mid] == key: return mid
;       if arr[mid] < key:  return bsearch(arr, mid + 1, hi, key)
;       else:               return bsearch(arr, lo, mid - 1, key)
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _bsearch_asm bsearch_asm
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .text
        global  _bsearch_asm
_bsearch_asm:
        ;
        ; TODO: search.
        ;
        ; n is a count, so the search range is lo=0, hi=n-1. An empty array
        ; has n=0, which makes hi=-1 before the first comparison. That case
        ; must return -1 immediately.
        ;
        ; For the midpoint, compute hi - lo first, halve it, then add lo.
        ; The base case runs before the midpoint, so hi - lo is never
        ; negative there and a shift halves it. If you reach for idiv
        ; instead, sign-extend with cdq. mov edx, 0 is right only for a
        ; dividend that cannot be negative.
        ;

        enter   0,0
        mov     eax, [ebp+12]            ; eax = n
        dec     eax                     ; eax = hi = n - 1
        push    dword[ebp+16]           ; key (pushing from right to left) 
        push    eax                     ; hi
        push    dword 0                 ; lo = 0
        push    dword [ebp+8]           ; arr (pushing from right to left; top of stack)
        call    bsearch_inner
        add     esp, 16                 ; remove 4 args x 4 bytes
        leave
        ret

bsearch_inner:
;       bsearch(arr, lo, hi, key):
;       mid = lo + (hi - lo) / 2
;       if arr[mid] == key: return mid
;       if arr[mid] < key:  return bsearch(arr, mid + 1, hi, key)
;       else:               return bsearch(arr, lo, mid - 1, key)

        enter   0,0
        mov     eax, -1                 ; an absent key returns -1 (base case)
        leave
        ret
