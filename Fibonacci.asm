LOCALS @@

;#####################################################################################
;Macros
;#####################################################################################

printString macro string
    mov ah, 09h
    mov dx, offset string
    int 21h
endm

exitProgram macro
	MOV	ah, 4Ch			
	MOV	al, 0			
	INT	21h			
endm

.model small

.stack 100h

;#####################################################################################
;Variables
;#####################################################################################

.data 

    ;Constant for max number length
    numSize EQU 250

    ;Text
    info1 db 'This program takes two files an input and an output file.', 13, 10, '$'
    info2 db 'A number is taken from the first file and the Fibonacci number is placed into output.', 13, 10, '$'
    info3 db 'The number can not exceed 6534', 13, 10, '$'
    
    ;Files and their handles, buffers
    inpHandle dw ?
    outHandle dw ?
    inpFile db 128 dup(0)
    outFile db 128 dup(0)
    rBuf	db 20 dup (0)	
	  oBuf	db numSize dup (0) 

    ;Numbers
    decimalNumber dw 0
    tempNum dw 0
    carryFlag db 0
    newLength dw 0

    ;Number arrays
    fiboNum1 db numSize dup('0'), '$'  
    fiboNum2 db numSize-1 dup('0'), '1', '$' 
    fiboResult db numSize dup('0'), '$'
  
.code

;#####################################################################################
;Checking command line for help
;#####################################################################################

main:

;Checking if command line is empty, if help was requested
  cmp byte ptr es:[82h], 0

  jne begin

  call needHelp
  jmp printInfo

;#####################################################################################
;Start
;#####################################################################################

begin:		

  ;Put command line address into cl for further reading
	mov	cl, es:[80h]	

  ;Skipping the whitespace
	mov	si, 81h		

  ;Load data with command line text
  mov	ax, @data		
	mov	es, ax	

  call jumpWhitespace

  ;Getting input file name
  mov di, offset inpfile
  call getFileName

  call jumpWhitespace

  ;Check if there is a second file
  cmp cx, 0
  jne further

  jmp printinfo

;Continue
further:

  ;Getting output file name
  mov di, offset outfile
  call getFileName

  ;Reloading data, now with filled file names
  mov	ax, @data		
  mov	ds, ax	

  ;Preparding input and output files
  call prepareInputFile
  call prepareOutputFile

  ;Reading from file
  mov bx, inphandle
  call readBuf

;#####################################################################################
;Fibonacci calculation
;#####################################################################################

  ;Convert file data to decimal format
  mov si, offset rBuf
  call turnToDec
  mov di, offset oBuf

  mov cx, decimalnumber ;CX now stores current Fibonacci number

  ;Special cases for 0th and 1st Fibonacci numbers
  ;0th fibonacci number
  mov ax, 0
  cmp cx, 0
  je writeZero

  ;1st fibonacci number
  mov bx, 1
  cmp cx, 1
  je writeone

  dec cx              ;Decriment by one since we just check for 1 case

;Fibonacci math
fiboLoop:
  call largeNumbers   ;This procedure adds the two fibonacci numbers and stores them in fiboResult

  push cx ;Pushing CX as to not lose it

  ;FiboNum1 = FiboNum2
  mov si, offset fiboNum2 
  mov di, offset fiboNum1
  mov cx, numSize
  call copyArray

  ;FiboNum2 = FiboResult
  mov si, offset fiboResult 
  mov di, offset fiboNum2
  mov cx, numSize
  call copyArray

  pop cx ;Restoring CX before looping

  loop fiboloop

  jmp write

;#####################################################################################
;*Special cases* 0th and 1st Fibonacci
;#####################################################################################

writeZero:
  mov ax, '0'
  mov [di], ax
  mov cx, 1
  mov bx, outhandle
  call outBuf
  jmp closeanswerfile

writeOne:
  mov ax, '1'
  mov [di], ax
  mov cx, 1
  mov bx, outhandle
  call outBuf
  jmp closeanswerfile

;#####################################################################################
;Write file answer (When Fibonacci isn't 0th or 1st)
;#####################################################################################

write:

  call ridOfZeros ;Procedure to get rid of any zeros infront for esthetic 

    ;Copying results to output file buffer and then
  mov si, offset [fiboResult] 
  mov di, offset oBuf
  mov cx, newlength

  rep stosb 

  mov di, offset oBuf
  mov cx, newlength  
  rep movsb            ; Copy each byte from fiboResult to oBuf

    ;Writing our output to file
  mov bx, outhandle
  mov cx, newlength
  call outBuf

;#####################################################################################
;Closing files, exiting, printing information
;#####################################################################################

;Closing files
closeAnswerFile:
  mov ah, 3Eh
  mov bx, outhandle
  int 21h

closeReadingFile:
  mov ah, 3Eh
  mov bx, inphandle
  int 21h

;Exiting with no issues
exit:
exitProgram

;Exiting with help requested, incorrect format
printInfo:
    mov	ax, @data		
    mov	ds, ax	

printstring info1
printstring info2
printstring info3
exitProgram

;#####################################################################################
;Procedures
;#####################################################################################

;Filling inputbuffer
proc readBuf

	  push	cx
	  push	dx
	
	  mov	ah, 3Fh			
	  mov	cx, 20		
	  mov	dx, offset rBuf	
	  int	21h			
	  jc	@@error		

  @@quit:
	  pop	dx
	  pop	cx
    xor bx, bx
	  ret

  @@error:
	  mov ax, 0			
	  jmp	@@quit

endp

;Filling output buffer
outBuf proc
    push ax
    push bx
    push dx

    mov ah, 40h          ; DOS function for writing to a file
    mov bx, outhandle    ; File handle
    mov dx, offset oBuf         ; Address of the output buffer
    int 21h              ; DOS interrupt

    ; Check for errors
    jc  @@WriteError

    pop dx
    pop bx
    pop ax
    ret

@@WriteError:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
outBuf endp	

;Preparing input file for handling
prepareInputFile proc

  push ax
  push dx

  mov ax, 3D00h
  mov dx, offset inpfile
  int 21h
  jnc @@success

  ;If we were unsuccessful
  @@failure:
  printString info1
  printString info2
  printString info3
  exitProgram

  ;ax now has inpfile handle
  @@success:
  mov [inphandle], ax
  pop dx
  pop ax
  ret

endp prepareInputFile

;Preparing output file for handling
prepareOutputFile proc 

;Pushing ax, cx, dx to preserve information
  push ax cx dx

  mov ah, 3Ch
  xor cx, cx
  mov dx, offset outfile
  int 21h
  jnc @@success

  @@failure:
  printString info1
  printString info2
  printString info3
  exitProgram

  ;ax now has outfile handle
  @@success:
  mov [outhandle], ax

  ;Popping information
  pop dx
  pop cx
  pop ax
  ret

endp

;Skipping whitespaces
jumpWhitespace proc 

;Skips whitespaces from command line
  @@spaceChecking:
  cmp byte ptr [si], ' '
  jne @@stop
  inc si
  loop @@spacechecking

  @@stop:
  ret

endp

;Reading commandline intputfile
getFileName proc 

;copying bytes from DS:[SI] to ES:[DI] while updating indexes until whitespace
  @@copyName:

  movsb
  cmp byte ptr [si], ' '
  loopne @@copyname

  ret 

endp

;Checking if help is required
needHelp proc 

;Loading info messages
  mov ax, @data
  mov ds, ax

;Loading command line text
  mov ch, 0
  mov cl, [es:0080h]

  cmp cx, 0
  je @@helpFound

  mov bx, 0081h

  @@checkIfHelp:
	cmp	[es:bx], '?/'		
	je	@@helpFound			
	inc	bx			
	loop @@checkIfHelp	

  jmp @@noHelp		

@@helpFound:
	  printString info1
    printString info2
    printString info3
    exitProgram

@@noHelp:
  xor bx, bx
  xor cx, cx
  ret

endp

;Turning input file values into decimal number format
turnToDec proc 

  @@decimalConversion:

  mov al,[si]

  ;Checking if exit character reached
  cmp al, 0
  je @@quit

  ;Converting to true decimal form
  sub al, '0'

  ;Checking if value is valid digit
  cmp al, 10
  jge @@error
  cmp al, 0
  jl @@error

  ;Performing incrementation operations
  mov bl, al

  mov ax, decimalnumber
  mov cx, 10  
  mul cx

  mov decimalnumber, ax
  add decimalnumber, bx

  ;Checking to see if decimalNumber doesn't exceed 24 limit
  cmp decimalnumber, 1987h
  jge @@error

  inc si

  jmp @@decimalconversion

  @@error:
	printString info1
  printString info2
  printString info3
  exitProgram

  @@quit:
  ret

endp

;Adding fibonacci numbers and storing them inside fibonacci results
largeNumbers proc

    ;Saving information to be restored later on
    push cx
    push dx
    push si
    push di 
    push bx 
    push ax

    mov cx, numSize              

    mov si, offset [fiboNum1 + numSize-1]  
    mov di, offset [fiboNum2 + numSize-1]  
    mov bx, offset [fiboResult + numSize-1] 

    mov carryflag, 0

@@myLoop:

    mov al, [si]           
    sub al, '0'            
    mov ah, 0               
    mov ah, [di]            
    sub ah, '0'            
    add al, ah              

@@back:
    add al, carryflag             
    cmp carryflag, 1
    je @@setFlag

    cmp al, 10             
    jb @@noOverflow
    sub al, 10            
    mov carryflag, 1
    jmp @@noOverflow

@@setFlag:
mov carryflag, 0
jmp @@back

@@noOverflow:
    add al, '0'            
    mov [bx], al            

    dec si                  
    dec di              
    dec bx           
    loop @@myLoop          

    ; Handle final carry
    cmp carryflag, 0
    je @@done
    mov al, '1'            
    mov [bx], al            
    jmp @@done

@@done:
    pop ax
    pop bx 
    pop di 
    pop si 
    pop dx 
    pop cx

    ret
endp

;Copy one arrays info onto another
copyArray proc
    push si    
    push di     
    push cx   

    cld   ;Clearing directional flag                  

@@copyLoop:
    movsb    ;Copy from DS:SI to ES:DI                 
    loop @@copyLoop          

    pop cx      
    pop di      
    pop si      
    ret

endp

;Getting rid of zeros in front of fiboResult
ridOfZeros proc 

push si 
push di
push cx
push ax

mov si, offset [fiboResult]
mov di, offset [fiboResult]
mov cx, numSize

@@giveMeAsec:
    mov al, [si]
    cmp al, '0'
    jne @@firstNonZero

    inc si
    loop @@givemeasec

@@firstNonZero:
mov newlength, cx

@@nonZero:
  mov al, [si]
  mov [di], al
  inc si
  inc di
  loop @@nonZero

pop si 
pop di
pop cx
pop ax

ret

endp

end main