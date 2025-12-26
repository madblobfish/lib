;; SOURCE: http://www.muppetlabs.com/~breadbox/software/tiny/
;; BUILD: nasm -f bin -o a.out test.asm; chmod +x a.out

BITS 32
		org	0x05430000

		db	0x7F, "ELF"
		dd	1
		dd	0
		dd	$$
		dw	2
		dw	3
		dd	_start
		dw	_start - $$
_start:		inc	ebx			; 1 = stdout file descriptor
		add	eax, strict dword 4	; 4 = write system call number
		mov	ecx, msg		; Point ecx at string
		mov	dl, 13			; Set edx to string length
		int	0x80			; eax = write(ebx, ecx, edx)
		and	eax, 0x10020		; al = 0 if no error occurred
		xchg	eax, ebx		; 1 = exit system call number
		int	0x80			; exit(ebx)
msg:		db	'hello, world', 10


;;BITS 32
;;            org     0x00010000
;;
;;            db      0x7F, "ELF"             ; e_ident
;;            dd      1                                       ; p_type
;;            dd      0                                       ; p_offset
;;            dd      $$                                      ; p_vaddr
;;            dw      2                       ; e_type        ; p_paddr
;;            dw      3                       ; e_machine
;;            dd      _start                  ; e_version     ; p_filesz
;;            dd      _start                  ; e_entry       ; p_memsz
;;            dd      4                       ; e_phoff       ; p_flags
;;_start:
;;            mov     bl, 42                  ; e_shoff       ; p_align
;;            xor     eax, eax
;;            inc     eax                     ; e_flags
;;            int     0x80
;;            db      0
;;            dw      0x34                    ; e_ehsize
;;            dw      0x20                    ; e_phentsize
;;            dw      1                       ; e_phnum
;;                                            ; e_shentsize
;;                                            ; e_shnum
;;                                            ; e_shstrndx
