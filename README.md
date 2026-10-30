# StarFORMAT

An extended ZX microdrive cartridge formatter
updated to support optional number of sectors

## Versions

v1d	february 2021

v1c	september/october/november 2020

v1b	circa 2005


## What's new for v1d?

StarFORMAT has been optimized and enhanced to interoperate with other IF1 BASIC extensions, e.g. vDrive toolkit, EXA-BASIC etc


## Optimization
	
Adopted a shorter relocation routine posted by pgimeno at the [MSX Resource Center](https://www.msx.org/forum/msx-talk/development/glass-z80-assembler?page=13)

Replaced custom code with calls to ROM subroutines, specifically:

  [DIFFER](https://web.archive.org/web/20150825085532/http://www.wearmouth.demon.co.uk:80/zx82.htm#L19DD)
  The 'length' between two 'starts' is formed in the BC register pair. The pointers are reformed but returned exchanged. For my purposes, a great substitute for CP HL,DE

  [NUMBER](https://web.archive.org/web/20150825085532/http://www.wearmouth.demon.co.uk:80/zx82.htm#L18B6)
  If the A register holds the 'number marker' then the HL register pair is advanced past the floating-point form. For my purposes, increments HL at least 4 times
  
 Replaced two instances of 8 bit register loads into a single 16 bit load

 Simplified the mechanism for checking execution of an extended command

 Realized a register was needlessly reset

 Replaced 16 bit loop counter with 8 bit

## Interoperability

 StarFORMAT is 503 bytes in length and relocatable, and within reason, can reside anywhere in RAM

 With the bytes saved by optimization StarFORMAT will now check, as part of execution, how the system variable [VECTOR](https://web.archive.org/web/20150815035617/http://www.wearmouth.demon.co.uk/if1_2.htm#L01EC) has been configured

 If VECTOR has been set to something non-standard (i.e. is not the system default, or is not the StarFORMAT syntax handler) then patch StarFORMAT to offload control to *that existing* address

 Typically loading StarFORMAT *after* another 3rd party program will pick up any changes to VECTOR

 Further interoperability can be achieved by customizing the default token (*) that invokes StarFORMAT


## Examples

[vDrive Toolkit](https://vdrivezx.com/vdrivezx/)

The vDrive toolkit resides in memory at 63280 and the command extensions are invoked by either the !.* tokens

With StarFORMAT loaded at 32768, and the stack set at 32767, then the two programs can co-exist

With the default configuration StarFORMAT will trigger with the * token, and the two remaining tokens will invoke the vDrive toolkit


[EXA-BASIC](https://spectrumcomputing.co.uk/entry/35105/ZX-Spectrum/EXA-BASIC)

EXA-BASIC resides in memory at 57600 and has graphic and toolkit extensions invoked by the tokens * and .

Again, with StarFORMAT loaded at 32768, and the stack set at 32767, then the two programs can co-exist

With the default configuration StarFORMAT is triggered by the * token and will block access to the EXA-BASIC graphic commands

StarFORMAT can be altered to change it's invoking token to something else, for example @

    POKE 32768+VAL "138", CODE "@"+VAL "50"

The EXA-BASIC graphic commands will now work



## Notes

Some 15 years ago(!) I'd written an extended microdrive cartridge formatter - very niche
  
The main purpose of the utility is to insert arbitrary values into sector headers and "watermark" your cartridge
  
Using specific values will provide a rudimentary form of protection against the intro cartridge copier
  
I've had an opportunity to revisit and update it - fix a bug, improve unsupported hardware detection and provide some new functionality
  
The original source was lost to the mists of time so the starting point was to reverse engineer and re-comment it
  
The utility will work with a 16K models upwards and is relocatable - as long as the screen is not cleared, it can run from the display file, e.g.
  
    CLEAR X-1: LOAD *"m";1;"*FORMAT" CODE X: RANDOMIZE USR X
  
On the supplied cartridge is a RUN bootstrap that will help you out with this - based on the model, an upper memory location will be suggested (32264/65032)

With the code executed, the * FORMAT command is now available: 

	; usage:
	; 
	; 	* FORMAT "m";d;"name";s;h;u1;u2
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
	; 	* FORMAT "m";1;"*FORMATv1c";181; CODE "!" ; CODE "A" ; CODE "P"
	;
	; drive and name parameters are required
	;      remaining parameters are optional

The new functionality allows you to specify the number of sectors you'd like to attempt to create

Why would you want to do that? So you can artificially limit your cartridge images to 180 sectors and experience the authentic joy of just ~90K of storage

Using [Max Desktop](https://spectrumcomputing.co.uk/entry/8406/ZX-Spectrum/Max_Desktop)  to examine the cartridge, what does this look like?

Sectors 1-180 are unused, 181 is marked as unreliable, and the remaining sectors are missing

How about the watermark? Yup, it's there

There are a couple of caveats to consider

Use a new un-formatted cartridge image for best results

If you * FORMAT an existing cartridge with a reduced number of sectors you'll see a "partition" like effect -

a CAT of the drive will show the old [higher-numbered] sectors

and another CAT, will show the new [lower-numbered] sectors and so on
