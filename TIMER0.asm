;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                   C�DIGO FONTE P/ DATAPOLL PIC-2377                     *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; Projeto: Lab 7 - Timer 0 e LED.
; Aluno: Juliano Rodrigues Dourado
; Data:	17/04/2017

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                             DESCRI��O GERAL                             *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;Deve ser comandado o LED 1, ligando-o e desligando-o, 
;alternadamente. A temporiza��o deve ser realizada pelo 
;Timer 0, sem o uso de interrup��o.
;Dever� seguir a seguinte temporiza��o:
;Por 30 segundos, dever� permanecer 250 ms ligado e 250 ms 
;desligado;
;Nos 30 segundos seguintes: 500 ms ligado e 500 ms desligado;
;Nos 30 s seguintes: 1 s ligado e 1 s desligado;
;Ent�o reinicia o ciclo: 250/250 ms, 500/500 ms e 1/1 s..

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      CONFIGURA��O DOS JUMPERS DE PLACA                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

;Habilitar CH4,1 (posi��o ON para cima);
;Desabilitar as demais chaves DIP;
;Manter o jumper J3 e J4 na posi��o A (1 e 2).

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                         CONFIGURA��ES PARA GRAVA��O                     *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

__config  _WDT_OFF & _HS_OSC & _LVP_OFF & _DEBUG_ON & _BODEN_OFF 


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                          ARQUIVOS DE DEFINI��ES                          *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#INCLUDE <P16F877.INC>		;ARQUIVO PADR�O MICROCHIP PARA 16F877 

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                					MACROS   		      				    *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#define LIGA_LED1    bcf PORTD,1         ; Cria uma macro para ligar o LED 1
#define DESLIGA_LED1 bsf PORTD,1         ; Cria uma macro para desligar o LED 1 

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  *
;*                     DEFINI��O DAS VARI�VEIS                             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

CBLOCK	0X20		    ;POSI��O INICIAL DA RAM
	Contador			;Vari�vel para auxiliar na contagem de tempo
	Auxiliar1			;vari�vel para auxiliar na contagem de tempo
	Auxiliar2			;Vari�vel para auxiliar na contagem de tempo	
	Auxiliar3			;Vari�vel para auxiliar na contagem de tempo	
 	
ENDC

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                       DEFINI��O DAS CONSTANTES                          *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      DEFINI��O DOS BANCOS DA RAM 		      		    *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

bank0  MACRO 							;Cria uma macro para o banco 0 de mem�ria.
				bcf STATUS,RP0              
				bcf STATUS,RP1
	   ENDM		                        ;Fim da macro para o banco 0.
	   
bank1  MACRO							;Cria uma macro para o banco 1 de mem�ria.
				bsf STATUS,RP0	
				bcf STATUS,RP1
	   ENDM								;Fim da macro para o banco 1.
	   

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                               ENTRADAS                                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


 								
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                                SA�DAS                                   *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#define	LED1		PORTD,1 	;Sa�da para LED 1  	 


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                   VETOR DE RESET DO MICROCONTROLADOR                    *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
	ORG	0x00			;ENDERE�O INICIAL DE PROCESSAMENTO.
	goto	Inicio

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *               VETOR DE INTERRUP��O DO MICROCONTROLADOR                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x04			;ENDERE�O INICIAL DA INTERRUP��O.
Interrupcao:			;FUN��O PARA TRATAMENTO DA INTERRUP��O

	retfie
	
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *              CONFIGURA��ES INICIAIS DE HARDWARE E SOFTWARE              *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; Nesta rotina s�o inicializadas as portas de I/O do microcontrolador, os
; perif�ricos que ser�o usados e as configura��es dos registradores 
; especiais (SFR)	  

Inicio:
    
    bank1					;Seleciona o banco 1 de mem�ria.
	movlw	B'11111101'		;Move para w o valor 11111101
    movwf	TRISD           ;Move o valor de w para TRISD, DEFININDO RD1 COMO SA�DA.
    
    movlw   B'11010101'	    ;Move para w o valor '11010101'
    
    movwf   OPTION_REG		;Move o valor de w para o registrador OPTION_REG, definindo:	
    						;Clock interno para o timer, Contagem na borda de subida, Prescaler
    						;dessassociado ao WDT, com uma taxa de 1:64.
 
    bank0                   ;Seleciona o banco 0 de mem�ria.
    clrf	PORTD		    ;Limpa todos os bits do PORTD.     						


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     	   REINICIALIZA��O DA RAM 	                       *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;  LIMPA TODA A RAM DO BANC0 0, INDO DE 0X20 A 0X7F.
	
	movlw	0x20
	movwf	FSR				;APONTA O ENDERE�AMENTO INDIRETO PARA
							;A PRIMEIRA POSI��O DA RAM.
LIMPA_RAM
	clrf	INDF			;LIMPA A POSI��O ATUAL.
	incf	FSR,F			;INCREMENTA PONTEIRO P/ A PR�X. POS.
	movf	FSR,W
	xorlw	0x80			;COMPARA PONTEIRO COM A �LT. POS. +1.
	btfss	STATUS,Z		;J� LIMPOU TODAS AS POSI��ES?
	goto	LIMPA_RAM		;N�O, LIMPA A PR�XIMA POSI��O.
							;SIM, CONTINUA O PROGRAMA. 

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	              				ROTINA PRINCIPAL                            *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *	

Main:
	
	movlw  D'60'			;Move para W o valor 60 em decimal
	movwf  Auxiliar1		;Move para a vari�vel Auxiliar1 o valor 60, pois cada ciclo da rotina 250 ms
							;gasta 500 ms. Ent�o, 60*500 ms = 30 s.
	call   Alterna250		;Chama a rotina para alternar o estado do LED1 a cada 250 ms.		
	
	movlw  D'30'			;Move para W o valor 30 em decimal
	movwf  Auxiliar2 	 	;Move para a vari�vel Auxiliar1 o valor 30, pois cada ciclo da rotina 500 ms
							;gasta 1 s. Ent�o, 30*1s = 30 s.
	call   Alterna500		;Chama a rotina para alternar o estado do LED1 a cada 500ms.
	
	movlw  D'15'			;Move para W o valor 15 em decimal
	movwf  Auxiliar3 	 	;Move para a vari�vel Auxiliar1 o valor 15, pois cada ciclo da rotina 1 s
							;gasta 2 s. Ent�o, 15*2s = 30 s.
	call   Alterna1		    ;Chama a rotina para alternar o estado do LED1 a cada 500ms.
	
	  	
	
goto Main

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	               ROTINA PARA ALTERNAR O LED A CADA 250 ms                 *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Alterna250:
		
	LIGA_LED1				;Liga o LED1

	movlw  D'61'			;|Move para W o valor 61 em decimal
	movwf  Contador			;|Move para o contador o valor armazenado em w, ou seja, 61, pois com prescale
							;|de 1:64, cada estouro do timer equivale � 4,096 ms. Multiplicando por 61, gera 249,856 ms.
							;|A rotina complementar inicia com 247, gerando mais 9 incrementos no timer0. Pois cada incremento
							;|leva 0,016 ms. 250 - 249,856 = 0,144 ms. Ent�o, 9 * 0,016 ms = 0,144 ms. Somando com 249,856 = 250 ms.	
								
	call   Conta250			;Chama a rotina para aguardar 250 ms 	
	DESLIGA_LED1			;Desliga o LED1
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms			
	decfsz Auxiliar1		;Decrementa 1 da vari�vel Auxiliar1 e pula se for zero
	goto   Alterna250		;Retorna para a fun��o Alterna250		

return						;Retorna da fun��o.

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	               ROTINA PARA ALTERNAR O LED A CADA 500 ms                 *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Alterna500:
		
	LIGA_LED1				;Liga o LED1
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms 
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms	
	DESLIGA_LED1			;Desliga o LED1
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms				
	decfsz Auxiliar2		;Decrementa 1 da vari�vel Auxiliar2 e pula se for zero
	goto   Alterna500		;Retorna para a fun��o Alterna500		

return						;Retorna da fun��o.	

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	               ROTINA PARA ALTERNAR O LED A CADA 1 s                    *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Alterna1:
		
	LIGA_LED1				;Liga o LED1
    movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms 
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms	
	DESLIGA_LED1			;Desliga o LED1
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms
	movlw  D'61'			;Move para W o valor 61 em decimal
	movwf  Contador			;Move para o contador o valor armazenado em w, ou seja, 61.
	call   Conta250			;Chama a rotina para aguardar 250 ms				
	decfsz Auxiliar3		;Decrementa 1 da vari�vel Auxiliar3 e pula se for zero
	goto   Alterna1	     	;Retorna para a fun��o Alterna1		

return						;Retorna da fun��o.	

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	              	         ROTINA PARA CONTAR 250 ms                      *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Conta250:
	
	nop						;Instru��o para peder um ciclo de m�quina (N�o necess�ria)
	btfss   INTCON,2		;Houve overflow no timer0?
	goto    Conta250	    ;N�o, ent�o retorna para a fun��o Conta250
	bcf		INTCON,2		;Sim. Ent�o Limpa o bit de estouro do flag do timer0	
	decfsz  Contador		;Decrementa um do contador, e pula instru��o posterior se for zero.
	goto	Conta250		;Retorna para a fun��o Conta250
	
	movlw	D'247'			;Move para W o valor 247
	movwf	TMR0			;Move o valor de w, que � 247 para o registrador TMR0, para dar os 9 incrementos restantes
							;para completar os 250ms.
	movlw   B'11010101'	    ;Move para w o valor '11010101'
    
    movwf   OPTION_REG		;Move o valor de w para o registrador OPTION_REG, redefinindo o prescaler em 1:64.
    
    call    Complementar	;Chama a fun��o complementar.	

return

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	              	          FUN��O COMPLEMENTAR                           *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;Fun��o para contar um tempo complementar, para chegar aos 250 ms da fun��o Conta250.

Complementar:
	
	nop						;Instru��o para perder um ciclo de m�quina
	btfss	INTCON,2		;Houve overflow no timer0?
	goto 	Complementar	;N�o, ent�o retorna para a fun��o complementar.
	bcf     INTCON,2		;Limpa o bit de flag do estouro do timer0
	
return						;Sim, ent�o retorna da fun��o Complementar.

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                          	FIM DO PROGRAMA                             *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

END				; FIM DO PROGRAMA  						