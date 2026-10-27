<!--no-pdf-->
# CMSC 131 Lab 2 Starter

[![lab2-checks](https://github.com/WhiteLicorice/cmsc-131-lab2-starter/actions/workflows/test.yml/badge.svg)](https://github.com/WhiteLicorice/cmsc-131-lab2-starter/actions/workflows/test.yml)

A C-callable library of sort, search, and utility routines in assembly. The manual is the assignment. This file is the repository's own notes.

## Layout

```text
Makefile       platform preamble and build rules
bench.c        provided: file I/O, timing, the C-side comparison, the hostile caller
cdecl.h        provided: the calling-convention macros
LICENSE        provided
sort.asm       yours
search.asm     yours
util.asm       yours
run_tests.sh   provided: the correctness gate
tests/         provided: the test corpus
```

## What to Run

On Windows, run these commands in Git Bash, the shell from Block 1. In that
shell, `make` is your alias for `mingw32-make`. On Linux, use your terminal.

```bash
make
make check
```

`make` builds `bench`. `make check` builds, then runs `./run_tests.sh`,
which reports each check and exits nonzero when any of them fail. Each run
is captured first. Its exit status is read before its text is examined,
so a program that prints the right line and then crashes still fails.

## Reading a First Run

The assembly files ship as stubs that assemble and link as-is, so the build
works before you write any code. Right now they do nothing useful, and 19
of the 36 checks fail. The seventeen that pass prove little. Four are files
that arrive empty, single-element, or already sorted. `gcd(0, 0)` expects 0.
The hostile caller cannot be upset by a stub that touches no register. The
rest are argument and file refusals that the harness performs before any
assembly runs. That red run is the correct starting state for a starter. The
badge stays red until you implement the routines.

The provided files are fixtures. The grader compares your fork against the
starter. An edit to `bench.c`, `Makefile`, `run_tests.sh`, or a `tests/`
file appears as a diff in the open.

## Documentation

The three sections at the end of this file are yours. Complete Design Notes
and Subsystem Ownership before the Week 1 progress report. Complete Quirks
and Issues before the Week 3 progress report. Each section says what it
needs. Leave the rest of this file as it is.

---

## Design Notes

Complete this section before the Week 1 progress report and finish it by
Week 3. The syllabus asks for problem analysis, a solution architecture,
and an estimated timeline. The manual's Deliverables section lists what
this activity adds. Keep each part short. Update it when the plan changes.

### Problem analysis

The four routines `bench.c` expects and what each one returns. Which
registers you preserve and why.

**`qsort_asm(int *arr, int n)`**
* **Purpose:** Recursively sorts the first n signed 32-bit integers of arr in place, in ascending order, comparing values in a register
* **Return value:** None (void). The result is the rearranged array itself.
* **Registers:** esi (the array frame), ebx (the pivot), edi(hi), esp (stack pointer), ebp(frame pointer)

**`int bsearch_asm(int *arr, int n, int key)`**
* **Purpose:** Performs a recursive binary search for integer `key` within a sorted array `arr` of size `n`
* **Return Value:** Returns the 0-based array index of `key` if found, or `-1` if `key` is absent (returned in `eax`).

**`int gcd_asm(int a, int b)`**
* **Purpose**: Computes the greatest common divisor as a signed 32-bit integer in `eax`
* **Return Value:** Returns the greatest common divisor (in `eax`)
* **Side Effect:** Updates the global exported variable `gcd_depth` in `.bss` with the maximum recursion depth reached during the call (where the initial call counts as 1).

`sum_range_asm`

### Solution architecture

A stack frame diagram for one recursive call of `qsort_asm`, showing where
the arguments, the return address, saved `ebp`, and the saved registers
sit. Why `sum_range_asm` is reentrant.

one call of qsort_inner(arr, lo, hi)

higher addresses
  [ebp+16]  hi              argument 3 
  [ebp+12]  lo              argument 2
  [ebp+8]   arr             argument 1 
  [ebp+4]   return address  pushed by call
  [ebp+0]   saved ebp         <- ebp points here
  [ebp-4]   saved esi       
  [ebp-8]   saved ebx       
  [ebp-12]  saved edi         <- esp points here
lower addresses

### Measurements

The ratio `bench` reports on `random1000.txt`, `sorted1000.txt`,
`reverse1000.txt`, `duplicates.txt`, and `identical.txt`. Your worst case
and its cause. One improvement and its estimated effect.

| File | Ratio |
|---|---|
| `random1000.txt` | |
| `sorted1000.txt` | |
| `reverse1000.txt` | |
| `duplicates.txt` | |
| `identical.txt` | |

### Timeline

One line per week. Name the subsystem each week finishes and the member
who owns it.

| Week | Goal | Owner |
|---|---|---|
| 1 | Interface and Plan | |
| 2 | Sort and Search Working| Erine Lourdes Medalla, Ryona Cassandra Honrado |
| 3 | sum_range_asm, tests, and all checks passed| Adrienne Nicole Tipon, Jhon Chriztopher Nice |
| 4 | Defense | |

## Subsystem Ownership

Complete this section before the Week 1 progress report. The manual lists
the three subsystems. Each member owns one. In a group of four, two members
share one. The commit history must agree with this table.

| Subsystem | Owner |
|---|---|
| Sorting (`qsort_asm` and its partition) | Erine Lourdes Medalla |
| Searching (`bsearch_asm`, `gcd_asm`) | Ryona Cassandra Honrado |
| Convention and measurement (`sum_range_asm`, the benchmarks) | Adrienne Nicole Tipon, Jhon Chriztopher Nice |

## Quirks and Issues

Complete this section before the Week 3 progress report. The syllabus asks
for documentation of quirks and issues with the complete implementation.
One entry per item. State what happens, what causes it, and what the group
did about it.

### Known issues

- 

### Quirks

- 
