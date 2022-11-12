;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                   C�DIGO FONTE P/ DATAPOLL PIC-2377                     *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; Projeto: Lab 8 - Timer 1 e Interrup��o.
; Aluno: Juliano Rodrigues Dourado
; Data:	27/04/2017

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                             DESCRI��O GERAL                             *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;A cada 250 ms devem ser incrementados os 
;displays de 7 segmentos, simulando um 
;cron�metro. Come�ando em 00.00 (MM.SS), 
;chegando a 23.59;
;A temporiza��o deve ser realizada pelo Timer 1, 
;atrav�s do uso de interrup��o;

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      CONFIGURA��O DOS JUMPERS DE PLACA                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

;Habilitar todos os dips de CH4 (posi��o ON para 
;cima);
;Habilitar o dip CH6,1-4 (posi��o ON para cima);
;Desabilitar as demais chaves DIP;
;Manter o jumper J3 na posi��o B e J4 na posi��o A;

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                         CONFIGURA��ES PARA GRAVA��O                     *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

__config  _WDT_OFF & _HS_OSC & _LVP_OFF & _DEBUG_ON & _BODEN_OFF 

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                          ARQUIVOS DE DEFINI��ES                         *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#INCLUDE <P16F877.INC>		;ARQUIVO PADR�O MICROCHIP PARA 16F877 

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DEFINI��O DAS VARI�VEIS                             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

CBLOCK	0X20		    ;POSI��O INICIAL DA RAM
    
    Incremento			;Vari�vel para ser incrementada a cada 250 ms
    Auxiliar1			;Vari�vel Auxiliar para contagem do tempo. Ser� utilizada para
    					;contar 250 ms, a cada 2 estouros do timer1
    Auxiliar2			;Vari�vel para auxiliar na contagem do display3, pois quando a mesma tiver
     					;no valor, 23, ser� reiniciada.					
    PCLATH_TEMP			;Vari�vel utilizada no salvamento e recupera��o de contexto
    					;PCLATH tempor�rio.
    STATUS_TEMP			;Vari�vel utilizada no salvamento e recupera��o de contexto
    					;STATUS tempor�rio
    W_TEMP				;Vari�vel utilizada no salvamento e recupera��o de contexto
    					;W tempor�rio.
	DISP2				;Vari�vel para armazenar o conte�do a ser mostrado no display2
	DISP3				;Vari�vel para armazenar o conte�do a ser mostrado no display3
	DISP4				;Vari�vel para armazenar o conte�do a ser mostrado no display4

ENDC					;T�rmino da declara��o das vari�veis.

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      DEFINI��O DOS BANCOS DA RAM 		      		    *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

bank0  MACRO 							;Cria uma macro para o banco 0 de mem�ria.
				bcf STATUS,RP0              
				bcf STATUS,RP1
	   ENDM		                        ;Fim da macro para o banco 0.
	   
bank1  MACRO
				bsf STATUS,RP0	
				bcf STATUS,RP1
	   ENDM								;Fim da macro para o banco 1.	 							

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                   VETOR DE RESET DO MICROCONTROLADOR                    *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
	ORG	0x00				;ENDERE�O INICIAL DE PROCESSAMENTO.
	goto	Inicio			;Vai para o in�cio.
	
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *               VETOR DE INTERRUP��O DO MICROCONTROLADOR                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x04			    ;ENDERE�O INICIAL DA INTERRUP��O.
Interrupcao:				;FUN��O PARA TRATAMENTO DA INTERRUP��O
  
;Comandos para salvar contexto (W e os flags do registrador STATUS), conforme
   ;DATASHEET.
   
    movwf  W_TEMP 		    ;Copia o valor de W para o registrador TEMP
    swapf  STATUS,W 	    ;Troca o valor de STATUS para salvar em W
    clrf   STATUS 	    	;Limpa os bits IRP,RP1,RP0 do registrador STATUS
    movwf  STATUS_TEMP 		;Salva o STATUS para o registrador STATUS_TEMP 
    movf   PCLATH, W 		;Move o PCLath para W
    movwf  PCLATH_TEMP 		;Salva o PCLATH em W
    clrf   PCLATH 			;P�gina zero, independentemente da p�gina atual
;--------------------------------------------------------------------------------------------	
    bcf	   PIR1,0				;Limpa o flag de estouro do TIMER1
    
    movlw	B'00001011'			;|Esse conjunto de instru��es, move o valor 3096 para TMR1,				
	movwf   TMR1H           	;|isso para, parametrizar, Interrup��es a cada 125 ms. Pois, com					
    movlw	B'11011100'     	;|prescale de 1:8, cada incremento no registrador equivale a 0,002 ms.
    movwf	TMR1L				;|Logo, 62500*0,002 = 125 ms. Ent�o, 65536 - 62500 = 3096.
    
    movlw   B'00110101'			;Redefine o prescale ap�s carregar valores no TMR1H e TMR1L	
    movwf   T1CON				;Habilita o Timer1, clock interno como fonte e Prescale 1:8
    
    decfsz Auxiliar1			;Decrementa 1 da Auxiliar1, e pula se for zero, ou seja, se passaram 250 ms.
    goto   RecuperaContexto		;Pula para a label RecuperaContexto, ou seja, ainda n�o se passaram
    							;250ms para que seja realizada a opera��o de incremento.			
	movlw  D'2'					
	movwf  Auxiliar1			;Recarrega a vari�vel Auxiliar1 com '2', pois haver� um estouro no timer1,
								;a cada 125ms, ent�o 125ms * 2 = 250 ms.
	incf   Incremento			;Incrementa 1 � vari�vel Incremento		
    
;Comandos para recuperar contexto, conforme DATASHEET 
RecuperaContexto:
	
    movf   PCLATH_TEMP, W 		;Recupera o PCLATH
    movwf  PCLATH 				;Move w para o PCLATH 
    swapf  STATUS_TEMP,W 		;Troca o registrador STATUS_TEMP e salva em W 
                    			;(define o banco para o estado original)
    movwf  STATUS 				;Move W para o registrador STATUS
    swapf  W_TEMP,F 	    	;Troca W_TEMP
    swapf  W_TEMP,W 			;Troca W_TEMP com W
	
	
	retfie	            				;Retorna da interrup��o.
	
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  ROTINA TABELA                                 *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
ORG	 0x1E					;Endere�o inicial da tabela.
Tabela:
	
	addwf	PCL			    ;Recebe pelo w a posi��o da tabela que se deseja ler,
							;e soma ao PC.
 	retlw   B'00000011'     ;Retorna 1a posi��o (W = 0)
 	retlw	B'10011111'		;Retorna 2a posi��o (W = 1)	
 	retlw	B'00100101'     ;Retorna 3a posi��o	(W = 2)
 	retlw	B'00001101'	    ;Retorna 4a posi��o (W = 3)
 	retlw	B'10011001'		;Retorna 5a	posi��o (W = 4)
 	retlw	B'01001001'	    ;Retorna 6a posi��o	(W = 5)	
 	retlw	B'01000001'		;Retorna 7a posi��o (W = 6)
 	retlw	B'00011111'		;Retorna 8a posi��o	(W = 7)
 	retlw	B'00000001'		;Retorna 9a posi��o (W = 8)
 	retlw	B'00001001'		;Retorna 10a posi��o (W = 9)	

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *              CONFIGURA��ES INICIAIS DE HARDWARE E SOFTWARE              *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; Nesta rotina s�o inicializadas as portas de I/O do microcontrolador, os
; perif�ricos que ser�o usados e as configura��es dos registradores 
; especiais (SFR). 

Inicio: 

   bank1					;Seleciona o banco 1 de mem�ria.
  
   movlw   B'00000000'		;Move para w o valor 00000000.
   movwf   TRISD            ;Move o valor de w para TRISD, para definir todos os bits de PORTD como sa�das.
   movlw   B'00011111'		
   movwf   TRISA            ;Move pra TRISA o valor 00011111, para definir o bit RA5 como sa�da e acionar o display
   movlw   B'00000000'     
   movwf   TRISE 			;Move para TRISE o valor 00000000, para definir os bits RE2, RE1 e RE0 como sa�das e acionarem o display.
   movlw   B'00001111'	    
   movwf   ADCON1           ;Move para o registrador ADCON1 o valor armazenado em w, definindo RE0,RE1,RE2 e RA5 como sa�das DIGITAIS.
   movlw   B'00000101'			
   movwf   T1CON			;Habilita o Timer1, clock interno como fonte e Prescale 1:1	
   movlw   B'11000000'		
   movwf   INTCON			;Habilita as interrup��es gerais, e as interrup��es por perif�ricos. A interrup��o pelo Timer0 
   							;fica desativada.	
   movlw   B'00000001'	
   movwf   PIE1				;Habilita interrup��o para o Timer1.	
   
   movlw   B'11010101'		
   movwf   OPTION_REG		;Configura para o Timer0: Clock interno, incremento na borda de descida, prescaler dessaciado ao WDT
   							;e com taxa de 1:64. Ou seja, cada estouro equivale a 4,096 ms. Ser� usado para alternar entre displays.							
  
   bank0                    ;Seleciona o banco 0 de mem�ria 
   clrf	PORTD		        ;Limpa todos os bits de sa�da, do PORTD, que s�o sa�das para o LED.  
   
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

	movlw	B'11111111'		;Move para w o valor '11111111'
	movwf	PORTD			;Desliga as sa�das do PORTD para que os LEDs iniciem desligados
	movlw	D'2'			
	movwf   Auxiliar1		;A vari�vel Auxiliar1 inicia com o valor 2, pois dela ser� decrementado a cada
							;interrup��o, que acontecer� � cada 125ms. Ent�o, a mesma ter� valor 0 quando se 
							;passarem 250 ms, e ser� recarregada com o valor 2 dentro da rotina de Interrup��o.
	movlw	D'0'			
	movwf	Auxiliar2		;Inicia a vari�vel Auxiliar2 em 0, que servir� para contar at� 23, quando deve-se
							;reiniciar o ciclo de contagem, 23:59 -> 00:00.						
							
	clrf	TMR1L			;Limpa o registrador TMR1L para em seguida, escrever no mesmo.
	
	movlw	B'00001011'		;|Esse conjunto de instru��es, move o valor 3096 para TMR1,				
	movwf   TMR1H           ;|isso para, parametrizar, Interrup��es a cada 125 ms. Pois, com					
    movlw	B'11011100'     ;|prescale de 1:8, cada incremento no registrador equivale a 0,002 ms.
    movwf	TMR1L			;|Logo, 62500*0,002 = 125 ms. Ent�o, 65536 - 6250 = 3096.
    
    movlw   B'00110101'		;Redefine o prescale ap�s carregar valores no TMR1H e TMR1L	
    movwf   T1CON			;Habilita o Timer1, clock interno como fonte e Prescale 1:8	
    

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      ROTINA VARRER DISPLAYS                            *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   
VarrerDisplays:
    
    movf	Incremento,W	;Move o conte�do de Incremento para W
    sublw	D'10'			;Subtrai 10 da vari�vel W, ou seja se o resultado for zero, a vari�vel Incremento deve ser reiniciada e 
    						;deve incrementar 1 na vari�vel DISP2.
    btfsc	STATUS,Z		;O bit Z do resgistrador STATUS � zero? Ou seja, o resultado da opera��o anterior n�o foi zero?
    call	Muda1			;Chama a rotina Muda1, que incrementa 1 na vari�vel de "Dezenas de segundos (DISP2)" e reinicia a contagem
    						;de unidades de segundos na vari�vel Incremento.
    movf	Incremento,W    ;Passa o conte�do de incremento para W
    call    Tabela			;O conte�do de incremento ser� o valor a ser mostrado no display1, ent�o chama a rotina de tabela. 	
    	
	bcf     PORTE,0         ;Define n�vel baixo em RE0 para ativar o display 1
    bsf     PORTE,1			;Define n�vel alto em RE1 para desativar o display 2
    bsf		PORTE,2 	 	;Define n�vel alto em RE2 para desativar o display 3
    bsf		PORTA,5			;Define n�vel alto em RA5 para desativar o display 4
    movwf	PORTD			;Liga os LEDs de acordo com o valor retornado em W pela rotina de Tabela.
    call	Temporizacao	;Chama a rotina para aguardar 4,096 ms antes de escrever no pr�ximo display
    
    movf	DISP2,W			;Move o conte�do de DISP2 para W
    sublw	D'6'			;Subtrai 6 da vari�vel W, ou seja se o resultado for zero, a vari�vel DISP2 deve ser reiniciada, e deve ser incrementado
    						; 1 na vari�vel DISP3.
    btfsc	STATUS,Z		;O bit Z do registrador STATUS � zero? Ou seja, o resultado da opera��o anterior n�o foi zero?	
    call    Muda2			;N�o.Chama a rotina Muda2, que incrementa 1 na vari�vel "unidades de minutos(DISP3)" e reinicia a contagem
    						;de dezenas de segundos.
    movf	DISP2,W			;Sim.Move o conte�do de DISP2 para W
    call    Tabela			;O conte�do de DISP 2 ser� o valor a ser mostrado no display2, ent�o chama a rotina de tabela.							
    
    bsf     PORTE,0         ;Define n�vel baixo em RE0 para desativar o display 1
    bcf     PORTE,1			;Define n�vel alto em RE1 para ativar o display 2
    bsf		PORTE,2 	 	;Define n�vel alto em RE2 para desativar o display 3
    bsf		PORTA,5			;Define n�vel alto em RA5 para desativar o display 4y
    movwf	PORTD			;Liga os LEDs conforme valor retornado pela Tabela.
    call	Temporizacao	;Chama a rotina para aguardar 4,096 ms antes de escrever no pr�ximo display
    
    movf	Auxiliar2,W		;Move o conte�do de Auxiliar2 para W
	sublw	D'24'			;Subtrai 24 de W, pois, se o resultado for zero, significa que devemos reiniciar o cron�metro, pois 
							;chegamos ao valor m�ximo, 23:59. Essa vari�vel � incrementada a cada mudan�a da vari�vel DISP3.
	btfsc	STATUS,Z		;O bit Z do registrador STATUS n�o � zero? Ou seja, o resultado anterior n�o deu zero.
	call	Organiza		;N�o, o resultado deu zero sim. Chama a fun��o que reiniciar� a contagem da vari�vel quando a mesma for para o quarto incremento.
    movf	DISP3,W			;Move o conte�do de DISP3 para W
    sublw	D'10'			;Subtrai 10 da vari�vel W, ou seja se o resultado for zero, a vari�vel DISP3 deve ser reiniciada
    btfsc	STATUS,Z		;O bit Z do registrador STATUS � zero? Ou seja, o resultado da opera��o anterior n�o foi zero?
    call    Muda3			;N�o, o resultado foi zero. Ent�o chama a fun��o Muda3 que incrementa 1 na vari�vel "dezenas de minutos(DISP4)"
    						;e reinicia a contagem da vari�vel DISP3.	 
	
	movf	DISP3,W			;Sim.Move o conte�do de DISP3 para W
	call	Tabela			;O conte�do de DISP3 ser� o valor a ser mostrado no display3, ent�o chama a rotina de Tabela.
	
	bsf     PORTE,0         ;Define n�vel baixo em RE0 para desativar o display 1
    bsf     PORTE,1			;Define n�vel alto em RE1 para desativar o display 2
    bcf		PORTE,2 	 	;Define n�vel alto em RE2 para ativar o display 3
    bsf		PORTA,5			;Define n�vel alto em RA5 para desativar o display 4
	movwf	PORTD			;Liga os LEDs conforme valor retornado pela rotina de Tabela
	bcf		PORTD,0			;Liga o LED do ponto, para que o valor seja mostrado conforme solicitado. Ex: 23.59.
    call	Temporizacao	;Chama a rotina para aguardar 4,096 ms antes de escrever no pr�ximo display
    bsf		PORTD,0			;Desliga o LED do ponto.
	
	movf	DISP4,W			;Move o conte�do de DISP4 para W	
	sublw	D'3'			;Subtrai 3 da vari�vel W, pois, se o resultado dessa opera��o for zero, a vari�vel DISP4 deve ser reiniciada
	btfsc	STATUS,Z		;O bit z do registrador STATUS � zero? Ou seja, o resultado da opera��o anterior n�o foi zero?
    call 	Muda4			;N�o, o resultado deu zero. Ent�o chama a rotina Mudar4, que limpa a vari�vel DISP4 para reiniciar a contagem da mesma
    
    movf	DISP4,W			;Sim, n�o foi zero. Ent�o move o conte�do de DISP4 para W, para chamar a tabela, e mostrar no display o valor correspondente.
    call    Tabela			;Chama a rotina de tabela para retornar o valor a ser mostrado.
    
   	bsf     PORTE,0         ;Define n�vel baixo em RE0 para desativar o display 1
    bsf     PORTE,1			;Define n�vel alto em RE1 para desativar o display 2
    bsf		PORTE,2 	 	;Define n�vel alto em RE2 para desativar o display 3
    bcf		PORTA,5			;Define n�vel alto em RA5 para ativar o display 4
    movwf	PORTD			;Liga os LEDs conforme valor retornado pela rotina de Tabela
    call	Temporizacao	;Chama a rotina para aguardar 4,096 ms antes de escrever no pr�ximo display
    
goto VarrerDisplays
 	
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  	ROTINA MUDA1                                *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Muda1:

	incf    DISP2			;Incrementa 1 � vari�vel de dezenas de segundos	
 	clrf	Incremento		;Limpa a vari�vel Incremento, para reiniciar a contagem 
 							;das unidades de segundos.
 
return 	

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  	ROTINA MUDA2                                *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Muda2:

	incf    DISP3			;Incrementa 1 � vari�vel de dezenas de segundos	
 	clrf	DISP2			;Limpa a vari�vel DISP2, pois a mesma atingiu o valor m�ximo
 							;e deve ser reiniciada a contagem
 	incf	Auxiliar2		;Incrementa 1 � vari�vel Auxiliar2, para que, quando a mesma chegar ao valor
 							;23:59 deve reiniciar o cron�metro.						

return

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  	ROTINA MUDA3                                *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Muda3:
	
													
	incf    DISP4			;Incrementa 1 � vari�vel de dezenas de segundos	
 	clrf	DISP3			;Limpa a vari�vel DISP3, reiniciando a contagem pois a
 							;mesma atingiu o valor m�ximo de contagem						

return

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  	ROTINA MUDA4                                *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Muda4:	
 		
 	clrf	DISP4			;Limpa a vari�vel DISP4, reiniciando a mesma, pois chegou ao valor m�ximo
 	
return

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  ROTINA ORGANIZA                               *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Organiza:
    
    clrf	Auxiliar2		;Limpa a vari�vel Auxiliar2 ap�s a mesma contar at� 23.
	goto 	Muda3			;Chama a fun��o para reiniciar o DISP3
							;e incrementar 1 � vari�vel DISP4.													
return	


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  ROTINA TEMPORIZA��O                           *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

Temporizacao:
	
	nop						;Instru��o para perder um ciclo de m�quina. 
	btfss	INTCON,2		;Houve o estouro do Timer0?
	goto 	Temporizacao	;N�o, ent�o retorna para a rotina de Temporizacao
	bcf		INTCON,2		;Sim, ent�o limpa o flag do timer0 e retorna da rotina de temporiza��o.
				
return				

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                          	FIM DO PROGRAMA                             *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

END			            	; FIM DO PROGRAMA 				    	   