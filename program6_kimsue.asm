TITLE Designing LowLevel IO Procedures   (program6_kimsue.asm)

; Author: Sue Kim
; Last Modified: 9 Jun 2020
; OSU email address: kimsue@oregonstate.edu
; Course number/section: CS271-400C
; Project Number: Program 6               Due Date:7 Jun 2020
; Description: This program gets 10 signed integers from the user and stores the values in an array. The program
;				then displays the integers, their sum, and their average

INCLUDE Irvine32.inc

ARRAYSIZE = 10
LO_STRING = 48
HI_STRING = 57
PLUS = 43
MINUS = 45

;----------------------------------------------------------------------------
getString	MACRO	prompt, input 
; displays a prompt and gets user's keyboard input into a memory location
; preconditions: prompt and input must be passed as the OFFSET of the data label
; receives: 
;	prompt = prompt to be displayed to user
;	input = where user's string will be stored
; returns: string entered is in memory, length of string in eax
;-----------------------------------------------------------------------------
	push	ecx
	push	edx
	mov		edx, prompt
	call	WriteString			; display prompt
	mov		edx, input			 
	mov		ecx, 12
	call	Readstring			; store input into memory location input
	pop		edx
	pop		ecx

ENDM

;---------------------------------------------------------------------------------------
displayString	MACRO   memory_location
; prints the string which is stored in a specified memory location 
; preconditions: memory_location must be passed as the OFFSET of that location
; receives:
;	memory_location = OFFSET of where the string is stored
; postconditions: string is displayed
	push	edx
	mov		edx, memory_location
	call	WriteString
	pop		edx

ENDM
;--------------------------------------------------------------------------------------

.data

intro_1				BYTE		"Designing Low-Level I/O procedures			By: Sue Kim", 0
intro_2				BYTE		"Please provide 10 signed decimal integers.", 0dh, 0ah
					BYTE		"Each number needs to be small enough to fit inside a 32 bit register.", 0dh, 0ah
					BYTE		"After you have finished inputting the raw numbers I will display a list", 0dh, 0ah
					BYTE		"of the integers, their sum, and their average value", 0dh, 0ah, 0
integer_prompt		BYTE		"Please enter a signed number: ", 0
integer_input		BYTE		30 DUP(0)	
error_message		BYTE		"You did not enter a signed number or your number was too big.", 0
tryAgain_prompt		BYTE		"Please try again: ", 0
numbers_display		BYTE		"You entered the following numbers: ", 0
fill_counter		DWORD		?
list_numbers		SDWORD		ARRAYSIZE	DUP(?)		; list of 10 signed integers
comma_space			BYTE		", ", 0
output				BYTE		12  DUP(0)		
reversed_output		BYTE		12  DUP(0)
sum					SDWORD		?				; calculated sum
sum_display			BYTE		"The sum of these numbers is: ", 0
average_display		BYTE		"The rounded average is: ", 0
goodbye				BYTE		"Thanks for playing!", 0

	
.code
main PROC
	; display introduction
	push	OFFSET intro_1
	push	OFFSET intro_2
	call	introduction

	; get integers from user, validate input, and store in an array
	push	OFFSET ARRAYSIZE
	push	OFFSET fill_counter
	push	OFFSET tryAgain_prompt
	push	OFFSET error_message
	push	OFFSET integer_prompt
	push	OFFSET integer_input
	push	OFFSET list_numbers
	call	ReadVal
	call	CrLf

	; display list of numbers entered by user
	push	OFFSET comma_space
	push	OFFSET reversed_output
	push	OFFSET output
	push	OFFSET list_numbers
	push	OFFSET numbers_display
	push	OFFSET ARRAYSIZE
	call	displayList
	call	CrLf

	; display sum of numbers
	push	OFFSET output
	push	OFFSET reversed_output
	push	OFFSET ARRAYSIZE	
	push	OFFSET sum
	push	OFFSET sum_display
	push	OFFSET list_numbers
	call	displaySum
	call	CrLf

	; display average of numbers
	push	OFFSET output
	push	OFFSET reversed_output
	push	OFFSET ARRAYSIZE
	push	OFFSET sum
	push	OFFSET average_display
	call	displayAverage
	call	CrLf

	; display goodbye message
	call	CrLf
	push	OFFSET goodbye
	call	farewell

	exit	; exit to operating system
main ENDP


;---------------------------------------------------------------------------
introduction		PROC
; displays the program name, name of programmer, and function of program
; receives: 
;	[ebp+12] = program name, name of programmer
;	[ebp+8] = function of program
; registers changed: edx
;---------------------------------------------------------------------------
	push	ebp
	mov		ebp, esp
	mov		edx, [ebp+12]		
	call	WriteString			; display program name and programmer
	call	CrLf
	call	CrLf
	mov		edx, [ebp+8]
	call	WriteString			; display functionality of program
	call	CrLf

	; restore ebp
	pop		ebp
	
	ret		8
introduction		ENDP


;-----------------------------------------------------------------------------
ReadVal				PROC
; gets user's string of digits, converts to numeric, while validating input, and
;	stores results in an array
; receives:
;	[ebp+32] = size of list
;	[ebp+28] = loop counter for list size
;	[ebp+24] = prompt to try again after entering invalid integer
;	[ebp+20] = error message for invalid input
;	[ebp+16] = prompt to enter integer
;	[ebp+12] = integer to be inputted by user
;	[ebp+8]  = empty list to be filled 
; returns: list of integers entered by user in numeric in variable list_numbers 
; registers changed: edi, esi, eax, ebx, ecx, edx
;-------------------------------------------------------------------------------------

	push		ebp
	mov			ebp, esp
	mov			edi, [ebp+8]		; @ list_numbers
	mov			ecx, [ebp+32]		; list size 
			
getInput:	
	getString	[ebp+16], [ebp+12]	; prompts for digits, gets string of digits from user
	mov			[ebp+28], ecx		; save list counter

; validate user's input to make sure it is a signed integer
validate:
	mov			ecx, eax			; set counter to number of characters
	mov			esi, [ebp+12]		; @ user's string input to esi
	cld								; set to forward direction
	lodsb							

; check if first character is a sign (+ or -)	
	cmp			al, PLUS			; if first character +
	je			sign				
	cmp			al, MINUS			; if first character -    
	je			sign
	mov			edx, 0				; initialize accumulator x = 0
	
; check if character is a digit
checkDigit:
	push		ecx
	cmp			al, LO_STRING		; str[k] < 48
	jl			invalid
	cmp			al, HI_STRING		; str[k] > 57
	jg			invalid

; convert string digit to integer 
; equation: x = 10*x + (str[k] - 48) where x = integer
	sub			al, LO_STRING		; subtract 48 from character
	movzx		ecx, al				; result (str[k]-48) in ecx
	mov			eax, edx			; current value of x
	mov			ebx, 10				
	imul		ebx					; multiply  x by 10 
	jo			invalid				; check overflow
	add			eax, ecx			; 10*x + (str[k] - 48)
	jo			invalid				; check overflow
	mov			edx, eax			; move result to edx
	pop			ecx					; restore counter for number of characters
	lodsb							; get next character
	loop		checkDigit			; validate rest of characters

; if string is negative, negate final result
	mov			esi, [ebp+12]		; start from beginning
	lodsb
	cmp			al, MINUS			; check if first character is a - 
	jne			write
	neg			edx					; negate x if negative string digit

; write valid input to list of numbers
write:
	mov			ecx, [ebp+28]		; restore list counter
	mov			[edi], edx			; add result to list_numbers
	add			edi, 4				; move to next element
	loop		getInput			; get next number
	jmp			done
	
; if first character is a sign, move to next character to validate if its a digit
sign:
	dec			ecx				
	lodsb							; next character
	mov			edx, 0
	jmp			checkDigit					

; displays an error message and prompts the user for another input
invalid:
	pop			ecx
	mov			edx, [ebp+20]
	call		WriteString			; display error message
	call		CrLf
	getString	[ebp+24], [ebp+12]	; displays prompt to try again, gets user input
	jmp			validate

done:
	pop			ebp
	ret			28

ReadVal			ENDP


;------------------------------------------------------------
displayList		PROC
; displays a list of valid user inputs
; receives:
;	[ebp+8] = ARRAYSIZE (size of list)
;	[ebp+12] = title of list
;	[ebp+16] = list of numbers to be displayed
;	[ebp+20] = string output
;   [ebp+24] = temporary reversed string
; postconditions: displays list title, array of valid numbers as string digits
; registers changed: eax, ecx, esi
;----------------------------------------------------------
	push			ebp
	mov				ebp, esp
	mov				esi, [ebp+16]			; @ list_numbers in esi
	mov				ecx, [ebp+8]			; set loop counter to list size
	
	displayString	[ebp+12]				; displays title of list
	call			CrLf
	
; displays the list of integer values as string digits
display:
	mov				eax, [esi]				; value in integer list 
	push			[ebp+20]				; string output 
	push			[ebp+24]				; temp reversed string
	call			WriteVal				; display number as string
	cmp				ecx, 1
	je				done
	displayString	[ebp+28]				; add comma if unfinished
	add				esi, 4					; next element	
	loop			display

done:

	; restore ebp
	pop				ebp
	
	ret				24
displayList		ENDP

;--------------------------------------------------
displaySum		PROC
; calculate sum of an array of numbers
; receives:
;	[ebp+8] = list of numbers
;	[ebp+12] = title of sum
;	[ebp+16] = sum variable
;	[ebp+20] = size of list
;	[ebp+24] = temp reversed string
;	[ebp+28] = string output
; returns: calculated sum in sum variable
; postconditions: displays sum
; registers changed: eax, ebx, ecx, esi
;----------------------------------------------------
	
	push			ebp
	mov				ebp, esp
	mov				esi, [ebp+8]			; @ list_numbers 
	mov				ecx, [ebp+20]			; list size
	mov				eax, 0					; initialize accumulator to 0

; calculates the sum of numbers by adding first number to next until end of list
;	is reached
calculate:
	mov				ebx, [esi]				; number at list position
	add				eax, ebx				; add to accumulator
	add				esi, 4					; move to next element
	loop			calculate				; repeat until end of list
	mov				ebx, [ebp+16]			; @ sum variable to ebx
	mov				[ebx], eax				; save sum to sum variable

	displayString	[ebp+12]				; display title of sum
	
	push			[ebp+28]				; @ output
	push			[ebp+24]				; @ temp reversed string
	call			WriteVal				; calculated sum in eax register
	
	; restore ebp
	pop				ebp
	

	ret				24
displaySum			ENDP
	
;-----------------------------------------------------------------------------
displayAverage		PROC
; calculates the average of a list of numbers given the sum and list size
; receives:
;	[ebp+8] = title of average
;	[ebp+12] = calculated sum
;	[ebp+16] = list size
;	[ebp+20] = reversed temp string
;	[ebp+24] = string output
; preconditions: displays title of average and calculated average
; registers changed: eax, ebx, edx
;-------------------------------------------------------------------------------
	push			ebp
	mov				ebp, esp
	mov				ebx, [ebp+12]		; @ sum of list 
	mov				eax, [ebx]
	mov				ebx, [ebp+16]		; size of list
	cdq	
	idiv			ebx					; divide sum by number of integers (list size)
	
	displayString	[ebp+8]				; display "average of numbers is: "

	push			[ebp+24]			; string output
	push			[ebp+20]			; reversed temp string
	call			WriteVal			

	; restore ebp
	pop				ebp

	ret				20
displayAverage		ENDP
;-------------------------------------------------------------------
WriteVal			PROC
; converts numeric value to a string of digits and prints the string
; receives: 
;	[ebp+8]: address of temporary reversed string
;	[ebp+12]: address of final output
; preconditions: number to be converted in eax register
; registers changed: eax, ebx, ecx, edx, esi, edi
;-------------------------------------------------------------------------
	push			ebp
	mov				ebp, esp
	
	; save registers from called procedure
	push			ecx
	push			esi

	mov				edi, [ebp+8]		; @ temporary reversed string
	mov				ecx, eax
	mov				ebx, 0				; initialize counter for number of characters
	push			eax					; save original signed value
	cmp				eax, 0		
	jge				convert				; skip if number is positive
	neg				ecx					; change number to positive 
	cld									; set to forwards direction

; converts an integer to string by converting each string starting from 1s 
;	then 10s, then 100s, ... adds 48 to digit to convert to ASCII character
;	string is stored in reverse order
convert:
	push			ebx					; save counter for number of characters
	mov				eax, ecx			
	mov				ebx, 10	
	cdq
	idiv			ebx					; divide number by 10	
	mov				ecx, eax			; save quotient
	mov				al, dl				; move remainder to al
	add				al, LO_STRING		; add 48 to digit to convert to ASCII
	stosb
	pop				ebx					; restore character counter
	inc				ebx					
	cmp				ecx, 10				; if there's more digits, repeat
	jge				convert				
	cmp				ecx, 0				
	je				sign				; if quotient is 0, no more digits, check if its a sign
	mov				al, cl				
	add				al, LO_STRING		; convert quotient
	stosb			
	inc				ebx
; checks if entered number is negative, if so, adds a minus character 
sign:
	pop				eax					; restore original number
	cmp				eax, 0								
	jge				continue			; if positive, skip
	mov				al, MINUS			; if negative, add - 
	stosb	
	inc				ebx
	
continue:
; writes the temporary reversed string to output string in reversed order	
	mov				esi, [ebp+12]		; @ output list in esi
	mov				ecx, ebx			; set counter
	dec				edi				
reverse:
	mov				al, [edi]			; move element to eax
	mov				[esi], al			
	dec				edi					; move backwards from reversed string
	inc				esi					; move to next element in output
	loop			reverse			
; displays contents of the output string	
done:	
	mov				esi, [ebp+12]		; move to beginning of list
	displayString	esi 				; display final output
	mov				ecx, ebx			; set character length as loop counter
	mov				edi, [ebp+8]		; move to beginning of list

; clear the temp reversed string and output string
clearArrays:
	mov				al, 0
	mov				[esi], al
	mov				[edi], al
	inc				esi
	inc				edi
	loop			clearArrays

	; restore registers from calling function
	pop				esi
	pop				ecx

	; restore ebp
	pop				ebp
	
	ret				8		
WriteVal			ENDP


;--------------------------------------
farewell			PROC
; displays farewell message
; receives: 
;	[ebp+8]: farewell message
; registers changed: edx
;--------------------------------------
	push			ebp
	mov				ebp, esp
	displayString	[ebp+8]			; display farewell message
	call	CrLf

	; restore ebp
	pop		ebp
	
	ret		4
farewell			ENDP


END main
