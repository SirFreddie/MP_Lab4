;
; Menejo de display;
; Created: 29/9/2021 19:12:24
; Author: Microprocesadores
; En este programa vamos a poner el número 0 en dígito display de más a la derecha

.ORG 0x001C 
	jmp		_tmr0_int	;salto atención a rutina de comparación A del timer 0

; acá empieza el programa
start:
;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
;	PB0 es SD (serial data) para el display 7seg
;	PD7 es SCLK, el reloj de los shift registers del display 7seg
;	PD4 es LCH, transfiere los datos que ya ingresaron en serie, a la salida del registro paralelo 
;   PC son entradas para los botones
    ldi		r16,	0b00111101	
	out		DDRB,	r16			;4 LEDs del shield son salidas
	out		PORTB,	r16			;apago los LEDs
	ldi		r16,	0b00000000	
	out		DDRC,	r16			;3 botones del shield son entradas
	ldi		r16,	0b10010000
	out		DDRD,	r16			;configuro PD.4 y PD.7 como salidas
	cbi		PORTD,	7			;PD.7 a 0, es el reloj serial, inicializo a 0
	cbi		PORTD,	4			;PD.4 a 0, es el reloj del latch, inicializo a 0

;-------------------------------------------------------------------------------------

;Configuro el TMR0 y su interrupcion.
	ldi		r16,	0b00000010	
	out		TCCR0A,	r16			;configuro para que cuente hasta OCR0A y vuelve a cero (reset on compare), ahí dispara la interrupción
	ldi		r16,	0b00000101	
	out		TCCR0B,	r16			;prescaler = 1024
	ldi		r16,	125
	out		OCR0A,	r16			;comparo con 125
	ldi		r16,	0b00000010	
	sts		TIMSK0,	r16			;habilito la interrupción (falta habilitar global)

;-------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------
;Inicializo algunos registros que voy a usar como variables.
	LDI r24, 0x00 ; incremento de segundos en interrupcion timer
	LDI r27, 0x00 ; display 1
	LDI r28, 0x00 ; display 2
	LDI r29, 0x00 ; display 3
	LDI r30, 0x00 ; display 4
	LDI r31, 0x00 
	
	ldi r16, 0b00000011
	ldi r17, 0b11110000
;-------------------------------------------------------------------------------------

apagar:		; apaga todo el display de 7 segmentos

	sei
	;call sacanum

;-------------------------------------------------------------------------------------
; Observar la rutina sacanum, utiliza r16 para los LEDs del numero que quiero mostar, r17 para indicar dónde lo quiero mostrar
; En main: cargo en r16 los leds a encender para formar el '0', y en r17 indico es el primero de los 4 dígitos. 
; Luego se llama la rutina de sacar la iformación serial.
;
; En el ejemplo para ver el numero 0, r16 debe ser 0b00000011 (orden de segmentos es abcdefgh, h es el punto)
; y r17 debe ser 0b00010000 (dígito display de más a la derecha)

; 0b00010000 Display de mas a la derecha (1)
; 0b00100000 Display (2)
; 0b01000000 Display (3)
; 0b10000000 Display de mas a la izquierda (4)

; 0b00000011 NUM_0
; 0b10011111 NUM_1
; 0b00100101 NUM_2
; 0b00001101 NUM_3
; 0b10011001 NUM_4
; 0b01001001 NUM_5
; 0b01000001 NUM_6
; 0b00011111 NUM_7
; 0b00000001 NUM_8
; 0b00011001 NUM_9

main:
	CALL change1
	LDI r17, 0b10000000
	CALL sacanum
	CALL change2
	LDI r17, 0b01000000
	CALL sacanum
	CALL change3
	LDI r17, 0b00100000
	CALL sacanum
	CALL change4
	LDI r17, 0b00010000
	CALL sacanum
	RJMP main

change1:
	CALL num_0
	RET	

change2: 
	CALL num_1
	RET	

num_0:
	ldi r16, 0b00000011		
	RET
num_1:
	ldi r16, 0b10011111		
	RET
num_2:
	ldi r16, 0b00100101		
	RET
num_3:
	ldi r16, 0b00001101		
	RET
num_4:
	LDI r16, 0b10011001
	RET
num_5:
	LDI r16, 0b01001001
	RET
num_6:
	LDI r16, 0b01000001
	RET
num_7:
	LDI r16, 0b00011111
	RET
num_8:
	LDI r16, 0b00000001
	RET
num_9:
	LDI r16, 0b00001001
	RET

change3: 
	CALL num_2
	RET	

change4: 
	CALL num_3
	RET	

;-------------------------------------------------------------------------------------
; La rutina sacanum, envía lo que hay en r16 y r17 al display de 7 segmentos
; r16 - contiene los LEDs a prender/apagar 0 - prende, 1 - apaga
; r17 - contiene el dígito: r17 = 1000xxxx 0100xxxx 0010xxxx 0001xxxx del dígito menos al más significativo.
sacanum: 
	call	dato_serie
	mov		r16, r17
	call	dato_serie
	sbi		PORTD, 4		;PD.4 a 1, es LCH el reloj del latch
	cbi		PORTD, 4		;PD.4 a 0, 
	ret
	;Voy a sacar un byte por el 7seg
dato_serie:
	ldi		r18, 0x08 ; lo utilizo para contar 8 (8 bits)
loop_dato1:
	cbi		PORTD, 7		;SCLK = 0 reloj en 0
	lsr		r16				;roto a la derecha r16 y el bit 0 se pone en el C
	brcs	loop_dato2		;salta si C=1
	cbi		PORTB, 0		;SD = 0 escribo un 0 
	rjmp	loop_dato3	
loop_dato2:
	sbi		PORTB, 0		;SD = 1 escribo un 1
loop_dato3:
	sbi		PORTD, 7		;SCLK = 1 reloj en 1
	dec		r18
	brne	loop_dato1		; cuando r17 llega a 0 corta y vuelve
	ret

_tmr0_out:
		OUT SREG, r31				;carga el estado de los flags luego de la interrupcion
	    RETI						;retorno de la rutina de interrupción del Timer0

_tmr0_int:
		IN r31, SREG			;guarda el estado de los flags previo a la interrupcion		
		INC	r24					;cuento cuántas veces entré en la rutina.
		CPI r24, 125				;un segundo
		BRNE _tmr0_out
		SBI	PINB, 2				;toggle LED	
		LDI r24, 0x00
		INC r27
		JMP _tmr0_out
