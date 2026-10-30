;
; star format 
;
; 	an extended microdrive cartridge formatter
; 	updated to support optional number of sectors
; 
; v1d february 2021  
;
;	reworked with new relocation routine by pgimeno
;	https://www.msx.org/forum/msx-talk/development/glass-z80-assembler?page=13
;
;	new functionality added to allow star format to coexist
;	with other extended basic routines, e.g. vDrive toolkit, EXA-BASIC etc
;
;	further optimizations marked with #
;
; v1c september/october/november 2020
;
; usage:
; 
; * FORMAT "m";d;"name";s;h;u1;u2
;
; where:
;
;       d: drive number to format
;    name: cartridge name
;       s: number of sectors to create (255)
;       h: 'M' channel HDFLAG  (!)
;      u1: 'M' channel UNUSED1 (A)
;      u2: 'M' channel UNUSED2 (P)
;
; example:
;
; * FORMAT "m";1;"jpnz2021";180;CODE "!"; CODE "A"; CODE "P"
;
; drive and name parameters are required
;      remaining parameters are optional
;
; for optional number of sectors use a new microdrive image
;
; some code commented out to reduce overall
; size to fit into a single cartridge sector
;
; other relocation routines
; 	https://www.tim-mann.org/trs80/doc/ldosq1-3.txt
;
; 	and hisoft devpac
; 	https://spectrumcomputing.co.uk/entry/8091/ZX-Spectrum/HiSoft_Devpac
;
; error trapping adapted from jgh
; 	http://mdfs.net/Info/Comp/Spectrum/ProgTips/Interface1/detect.htm
;
		org &0000
;
token		equ '*'		; token to invoke extended command(s)
keyword		equ &d0		; format keyword
vector		equ &5cb7
sector		equ &5cc9
romerr		equ &0028
err6		equ &01f0
calbas		equ &10
nextchar	equ &0020
exptexpr	equ &06a3
testmnam	equ &0685
separator	equ &05b1
end1		equ &05c1
chksyntax	equ &18
err_nr		equ &5c3a
err_sp		equ &5c3d
unpage		equ &0700
stend		equ &05b7
expt1num	equ &1c82
findint1	equ &1e94
oreport1	equ &04b2
hd_11		equ &5ced
prmcnt		equ &04
d_str2		equ &5cde
s_str2		equ &5ce0
differ		equ &19dd
rom3cat		equ &1c54
rom3fmt		equ &1b5d
;
main	exx			; exchange registers
	push hl			; preserve hl' for return to basic
	exx			; exchange registers back
;
fixup	ld hl,fixtab		; fetch offset to fixup table #
	add hl,bc		; add offset to entry point held in bc
	ex de,hl		; exchange
fixnext	ld a,(de)
	inc de			; advance
	ld l,a			; fetch next entry into hl
	ld a,(de)
	ld h,a
	or l
	jr z,fixdone		; 0 indicates end of fixup table, relocation is complete
	inc de			; advance
	add hl,bc		; add correct offset
	ld a,(hl)		; fixup by adding bc to (hl)
	add a,c
	ld (hl),a
	inc hl			; advance
	ld a,(hl)
	adc a,b
	ld (hl),a
	jr fixnext		; next fixup

fixdone	ld hl,(control-fixup-2) * 256 + &18	; prepare offset (&27) to control routine, and jr op-code #
reloc01	ld (fixup),hl		; insert, execution is now forced to control routine
;
control	ld hl,(err_sp)		; fetch current error return
	push hl			; and preserve
reloc02	call detect		; attempt to detect the interface one
	pop hl			; restore error return
	ld (err_sp),hl		; and update
	ld (err_nr),a		; update error code
;
	exx			; exchange registers
	pop hl			; restore hl' for return to basic
	exx			; exchange registers back
	ret			; and return to basic
;
detect	ld (err_sp),sp		; setup error pointer
	ld a,&12		; prepare error j - invalid i/o device
	rst &08         	; error-1
	defb &31        	; create extra system variables
isifone	ld hl,unpage		; prepare unpage
	ld a,&12		; prepare error j once again
	call differ		; call main rom routine to compare #
	ret nz			; return if de != &0700
reloc03	ld hl,copyfmt		; fetch address of copy format routine
	ld (hd_11),hl		; and insert
	rst &08			; error-1
	defb &32		; execute arbitary code with interface one paged in
	ld hl,(vector)		; fetch the existing vector
reloc04	ld de,syntax		; point to starformat syntax routine
	call differ		; and compare - hl and de will be exchanged
	ret z			; return if vector is already set
	ld (vector),hl		; insert starformat vector
reloc05	ld hl,(synerr+1)	; fetch the syntax error handler
	call differ		; and compare
	ret z			; return if already set
reloc06	ld (synerr+1),hl	; insert the pre-existing syntax handler
	ret			; and return to main routine
;
copyfmt	ld hl,(oreport1-2)	; point to cat-run address handler #
	inc hl			; advance
	ld e,(hl)		; fetch low byte of cat routine
	inc hl			; advance
	ld d,(hl)		; fetch high byte of cat routine
	push de			; preserve cat routine for later
;
	rst calbas		; call a main rom routine to advance hl forward #
	defw &18bb		; by 4 - also corrupts a register
;
	ld e,(hl)		; fetch low byte of format routine
	inc hl			; advance
	ld d,(hl)		; fetch high byte of format routine
	pop hl			; restore address of cat routine
;
	rst calbas		; call a main rom routine to calculate the offset #
	defw differ		; between format and cat into bc register pair
;
reloc07	ld de,format		; point to address to create a copy of format routine
	ldir			; copy
reloc08	ld hl,format+&35	; prepare a call to patch
	ld (hl),&cd		; insert call op-code
reloc09	ld hl,patch		; fetch patch address
reloc10	ld (format+&36),hl	; and insert
	ld a,&ff		; prepare error 0 - ok
	ret
;
syntax	; add a,&ce		; expand tokens
	cp (token - &ce) & &ff	; is this the token? #
synerr	jp nz,err6		; no, throw an error
	rst calbas		; call a main rom routine
	defw nextchar		; fetch the next character
	cp keyword		; format keyword?
	jp nz,romerr		; no, throw an error
	rst chksyntax		; z=syntax, nz=runtime
	jr z,cont		; syntax? contine forward and skip defaults
default	ld hl,&21ff		; insert default values
	ld (d_str2),hl		; if using 'a' register then you
	ld hl,'PA'		; *must* preserve with push and pop
	ld (s_str2),hl		; "A"ndrew "P"ennell
cont	call exptexpr		; evaluate "x";n;"name"
	call separator		; z=comma or semi-colon
	jr nz,done		; no parameters supplied
param	push ix			; preserve registers
	ld ix,d_str2		; point to variables
	ld b,prmcnt		; setup loop with a count of parameters #
params	push bc			; preserve registers
	rst calbas		; call a main rom routine
	defw nextchar		; fetch the next character
	rst calbas		; call a main rom routine
	defw expt1num		; fetch single numeric expression
	rst chksyntax		; z=syntax, nz=runtime
	jr z,nextprm		; jump to next parameter
	push af			; preserve registers
	rst calbas		; call a main rom routine
	defw findint1		; find single 8-bit integer
	ld (ix+&00),a		; insert parameter variable
	inc ix			; increment to next variable
	pop af			; restore registers
	pop bc			; restore registers
nextprm	call separator		; separator token?
	jr nz, prmdone		; jump, if there are no further parameters
	djnz params		; fetch the remaining parameters
prmdone	pop ix			; restore registers
done	call stend		; end of statement?
	call testmnam		; check "m" parameters and filename
	ld a,(d_str2)		; fetch the sector count parameter
	or a			; is it 0?
	jr z,sectdec		; yes, skip forward and decrease sector count
	inc a			; increase sector count
	or a			; is it 0?
	jr nz,isector		; no, skip forward 
sectdec	dec a			; decrease sector count
isector	ld (format+&1d),a	; insert sector count into the copy of format routine
reloc12	call format		; and execute the custom format
	jp end1			; return to the main interpreter
;
patch	ld (ix+&47),a		; set first character of recnam to zero
	ld a,(d_str2+1)		; fetch variable
	ld (ix+&28),a		; and insert into hdflag
	ld hl,(s_str2)		; fetch variable
	ld (ix+&2a),l		; and insert into unused1
	ld (ix+&2b),h		; and insert into unused2
;	xor a			; reset #
	ret			; return to the copy of the format routine
;
format	equ $			; copy of the format routine resides here
;
fixtab	equ $-main		; table of addresses to relocate
	defw (reloc01+1)-main	; making a copy of the rom format routine
	defw (reloc02+1)-main	; will overwrite this table
	defw (reloc03+1)-main
	defw (reloc04+1)-main
	defw (reloc05+1)-main
	defw (reloc06+1)-main
	defw (reloc07+1)-main
	defw (reloc08+1)-main
	defw (reloc09+1)-main
	defw (reloc10+1)-main
	defw (isector+1)-main
	defw (reloc12+1)-main
	defw &0000		; end of fixups
;
ftablen	equ $-fixtab		; length of fixup table
;
	defs (rom3cat-rom3fmt)-ftablen	; space for copy of format routine #
;
;	defb &7f		; (c) - debug marker #
;
	end
;
