        .file ""
        .section __TEXT,__literal16,16byte_literals
        .align  4
_caml_negf_mask:
        .quad   0x8000000000000000
        .quad   0
        .align  4
_caml_absf_mask:
        .quad   0x7fffffffffffffff
        .quad   -1
        .data
        .globl  _camlConftest.data_begin
_camlConftest.data_begin:
        .text
        .globl  _camlConftest.code_begin
_camlConftest.code_begin:
        nop
        .data
        .align  3
        .data
        .align  3
        .quad   768
        .globl  _camlConftest
_camlConftest:
        .data
        .align  3
        .globl  _camlConftest.gc_roots
_camlConftest.gc_roots:
        .quad   _camlConftest
        .quad   0
        .data
        .align  3
        .quad   2044
_camlConftest.1:
        .ascii  "test"
        .space  3
        .byte   3
        .text
        .align  4
        .globl  _camlConftest.entry
_camlConftest.entry:
        .cfi_startproc
        leaq    -328(%rsp), %r10
        cmpq    40(%r14), %r10
        jb      L101
L102:
        subq    $8, %rsp
        .cfi_adjust_cfa_offset 8
L100:
        movq    _camlConftest.1@GOTPCREL(%rip), %rax
        call    _camlStdlib.print_endline_369
L103:
        movl    $1, %eax
        addq    $8, %rsp
        .cfi_adjust_cfa_offset -8
        ret
        .cfi_adjust_cfa_offset 8
L101:
        push    $34
        .cfi_adjust_cfa_offset 8
        call    _caml_call_realloc_stack
        popq    %r10
        .cfi_adjust_cfa_offset -8
        jmp     L102
        .cfi_adjust_cfa_offset -8
        .cfi_endproc
        .data
        .align  3
        .text
        nop
        .globl  _camlConftest.code_end
_camlConftest.code_end:
        .data
                                /* relocation table start */
        .align  3
                                /* relocation table end */
        .data
        .quad   0
        .globl  _camlConftest.data_end
_camlConftest.data_end:
        .quad   0
        .align  3
        .globl  _camlConftest.frametable
_camlConftest.frametable:
        .quad   1
        .quad   L103
        .word   17
        .word   0
        .align  2
        .set L$set$1, (L104 - .) + 0
        .long   L$set$1
        .align  3
        .align  2
L104:
        .set L$set$2, (L106 - .) + 1342177280
        .long   L$set$2
        .long   4096
L105:
        .ascii  "conftest.ml\0"
        .align  2
L106:
        .set L$set$3, (L105 - .) + 0
        .long   L$set$3
        .ascii  " 
