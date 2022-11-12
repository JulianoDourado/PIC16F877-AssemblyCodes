;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                   CÓDIGO FONTE P/ DATAPOLL PIC-2377                     *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;
; Autor: Juliano Rodrigues Dourado
;

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                             DESCRIÇÃO GERAL                             *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;A cada 250 ms devem ser incrementados os 
;displays de 7 segmentos, simulando um 
;cronômetro. Começando em 00.00 (MM.SS), 
;chegando a 23.59;
;A temporização deve ser realizada pelo Timer 1, 
;através do uso de interrupção;

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      CONFIGURAÇÃO DOS JUMPERS DE PLACA                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

;Habilitar todos os dips de CH4 (posição ON para 
;cima);
;Habilitar o dip CH6,1-4 (posição ON para cima);
;Desabilitar as demais chaves DIP;
;Manter o jumper J3 na posição B e J4 na posição A;

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                         CONFIGURAÇÕES PARA GRAVAÇÃO                     *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

__config  _WDT_OFF & _HS_OSC & _LVP_OFF & _DEBUG_ON & _BODEN_OFF 

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                          ARQUIVOS DE DEFINIÇÕES                         *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#INCLUDE <P16F877.INC>		;ARQUIVO PADRÃO MICROCHIP PARA 16F877 

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DEFINIÇÃO DAS VARIÁVEIS                             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

CBLOCK	0X20		    ;POSIÇÃO INICIAL DA RAM
    
    Incremento			;Variável para ser incrementada a cada 250 ms
    Auxiliar1			;Variável Auxiliar para contagem do tempo. Será utilizada para
    					;contar 250 ms, a cada 2 estouros do timer1
    Auxiliar2			;Variável para auxiliar na contagem do display3, pois quando a mesma tiver
     					;no valor, 23, será reiniciada.					
    PCLATH_TEMP			;Variável utilizada no salvamento e recuperação de contexto
    					;PCLATH temporário.
    STATUS_TEMP			;Variável utilizada no salvamento e recuperação de contexto
    					;STATUS temporário
    W_TEMP				;Variável utilizada no salvamento e recuperação de contexto
    					;W temporário.
	DISP2				;Variável para armazenar o conteúdo a ser mostrado no display2
	DISP3				;Variável para armazenar o conteúdo a ser mostrado no display3
	DISP4				;Variável para armazenar o conteúdo a ser mostrado no display4

ENDC					;Término da declaração das variáveis.

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      DEFINIÇÃO DOS BANCOS DA RAM 		      		    *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

bank0  MACRO 							;Cria uma macro para o banco 0 de memória.
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
	
	ORG	0x00				;ENDEREÇO INICIAL DE PROCESSAMENTO.
	goto	Inicio			;Vai para o início.
	
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *               VETOR DE INTERRUPÇÃO DO MICROCONTROLADOR                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x04			    ;ENDEREÇO INICIAL DA INTERRUPÇÃO.
Interrupcao:				;FUNÇÃO PARA TRATAMENTO DA INTERRUPÇÃO
  
;Comandos para salvar contexto (W e os flags do registrador STATUS), conforme
   ;DATASHEET.
   
    movwf  W_TEMP 		    ;Copia o valor de W para o registrador TEMP
    swapf  STATUS,W 	    ;Troca o valor de STATUS para salvar em W
    clrf   STATUS 	    	;Limpa os bits IRP,RP1,RP0 do registrador STATUS
    movwf  STATUS_TEMP 		;Salva o STATUS para o registrador STATUS_TEMP 
    movf   PCLATH, W 		;Move o PCLath para W
    movwf  PCLATH_TEMP 		;Salva o PCLATH em W
    clrf   PCLATH 			;Página zero, independentemente da página atual
;--------------------------------------------------------------------------------------------	
    bcf	   PIR1,0				;Limpa o flag de estouro do TIMER1
    
    movlw	B'00001011'			;|Esse conjunto de instruções, move o valor 3096 para TMR1,				
	movwf   TMR1H           	;|isso para, parametrizar, Interrupções a cada 125 ms. Pois, com					
    movlw	B'11011100'     	;|prescale de 1:8, cada incremento no registrador equivale a 0,002 ms.
    movwf	TMR1L				;|Logo, 62500*0,002 = 125 ms. Então, 65536 - 62500 = 3096.
    
    movlw   B'00110101'			;Redefine o prescale após carregar valores no TMR1H e TMR1L	
    movwf   T1CON				;Habilita o Timer1, clock interno como fonte e Prescale 1:8
    
    decfsz Auxiliar1			;Decrementa 1 da Auxiliar1, e pula se for zero, ou seja, se passaram 250 ms.
    goto   RecuperaContexto		;Pula para a label RecuperaContexto, ou seja, ainda não se passaram
    							;250ms para que seja realizada a operação de incremento.			
	movlw  D'2'					
	movwf  Auxiliar1			;Recarrega a variável Auxiliar1 com '2', pois haverá um estouro no timer1,
								;a cada 125ms, então 125ms * 2 = 250 ms.
	incf   Incremento			;Incrementa 1 à variável Incremento		
    
;Comandos para recuperar contexto, conforme DATASHEET 
RecuperaContexto:
	
    movf   PCLATH_TEMP, W 		;Recupera o PCLATH
    movwf  PCLATH 				;Move w para o PCLATH 
    swapf  STATUS_TEMP,W 		;Troca o registrador STATUS_TEMP e salva em W 
                    			;(define o banco para o estado original)
    movwf  STATUS 				;Move W para o registrador STATUS
    swapf  W_TEMP,F 	    	;Troca W_TEMP
    swapf  W_TEMP,W 			;Troca W_TEMP com W
	
	
	retfie	            				;Retorna da interrupção.
	
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  ROTINA TABELA                                 *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
ORG	 0x1E					;Endereço inicial da tabela.
Tabela:
	
	addwf	PCL			    ;Recebe pelo w a posição da tabela que se deseja ler,
							;e soma ao PC.
 	retlw   B'00000011'     ;Retorna 1a posição (W = 0)
 	retlw	B'10011111'		;Retorna 2a posição (W = 1)	
 	retlw	B'00100101'     ;Retorna 3a posição	(W = 2)
 	retlw	B'00001101'	    ;Retorna 4a posição (W = 3)
 	retlw	B'10011001'		;Retorna 5a	posição (W = 4)
 	retlw	B'01001001'	    ;Retorna 6a posição	(W = 5)	
 	retlw	B'01000001'		;Retorna 7a posição (W = 6)
 	retlw	B'00011111'		;Retorna 8a posição	(W = 7)
 	retlw	B'00000001'		;Retorna 9a posição (W = 8)
 	retlw	B'00001001'		;Retorna 10a posição (W = 9)	

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *              CONFIGURAÇÕES INICIAIS DE HARDWARE E SOFTWARE              *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; Nesta rotina são inicializadas as portas de I/O do microcontrolador, os
; periféricos que serão usados e as configurações dos registradores 
; especiais (SFR). 

Inicio: 

   bank1					;Seleciona o banco 1 de memória.
  
   movlw   B'00000000'		;Move para w o valor 00000000.
   movwf   TRISD            ;Move o valor de w para TRISD, para definir todos os bits de PORTD como saídas.
   movlw   B'00011111'		
   movwf   TRISA            ;Move pra TRISA o valor 00011111, para definir o bit RA5 como saída e acionar o display
   movlw   B'00000000'     
   movwf   TRISE 			;Move para TRISE o valor 00000000, para definir os bits RE2, RE1 e RE0 como saídas e acionarem o display.
   movlw   B'00001111'	    
   movwf   ADCON1           ;Move para o registrador ADCON1 o valor armazenado em w, definindo RE0,RE1,RE2 e RA5 como saídas DIGITAIS.
   movlw   B'00000101'			
   movwf   T1CON			;Habilita o Timer1, clock interno como fonte e Prescale 1:1	
   movlw   B'11000000'		
   movwf   INTCON			;Habilita as interrupções gerais, e as interrupções por periféricos. A interrupção pelo Timer0 
   							;fica desativada.	
   movlw   B'00000001'	
   movwf   PIE1				;Habilita interrupção para o Timer1.	
   
   movlw   B'11010101'		
   movwf   OPTION_REG		;Configura para o Timer0: Clock interno, incremento na borda de descida, prescaler dessaciado ao WDT
   							;e com taxa de 1:64. Ou seja, cada estouro equivale a 4,096 ms. Será usado para alternar entre displays.							
  
   bank0                    ;Seleciona o banco 0 de memória 
   clrf	PORTD		        ;Limpa todos os bits de saída, do PORTD, que são saídas para o LED.  
   
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     	   REINICIALIZAÇÃO DA RAM 	                       *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  LIMPA TODA A RAM DO BANC0 0, INDO DE 0X20 A 0X7F.
	
	movlw	0x20
	movwf	FSR				;APONTA O ENDEREÇAMENTO INDIRETO PARA
							;A PRIMEIRA POSIÇÃO DA RAM.
LIMPA_RAM
	clrf	INDF			;LIMPA A POSIÇÃO ATUAL.
	incf	FSR,F			;INCREMENTA PONTEIRO P/ A PRÓX. POS.
	movf	FSR,W
	xorlw	0x80			;COMPARA PONTEIRO COM A ÚLT. POS. +1.
	btfss	STATUS,Z		;JÁ LIMPOU TODAS AS POSIÇÕES?
	goto	LIMPA_RAM		;NÃO, LIMPA A PRÓXIMA POSIÇÃO.
							;SIM, CONTINUA O PROGRAMA.   

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	              				ROTINA PRINCIPAL                            *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


Main:

	movlw	B'11111111'		;Move para w o valor '11111111'
	movwf	PORTD			;Desliga as saídas do PORTD para que os LEDs iniciem desligados
	movlw	D'2'			
	movwf   Auxiliar1		;A variável Auxiliar1 inicia com o valor 2, pois dela será decrementado a cada
							;interrupção, que acontecerá à cada 125ms. Então, a mesma terá valor 0 quando se 
							;passarem 250 ms, e será recarregada com o valor 2 dentro da rotina de Interrupção.
	movlw	D'0'			
	movwf	Auxiliar2		;Inicia a variável Auxiliar2 em 0, que servirá para contar até 23, quando deve-se
							;reiniciar o ciclo de contagem, 23:59 -> 00:00.						
							
	clrf	TMR1L			;Limpa o registrador TMR1L para em seguida, escrever no mesmo.
	
	movlw	B'00001011'		;|Esse conjunto de instruções, move o valor 3096 para TMR1,				
	movwf   TMR1H           ;|isso para, parametrizar, Interrupções a cada 125 ms. Pois, com					
    movlw	B'11011100'     ;|prescale de 1:8, cada incremento no registrador equivale a 0,002 ms.
    movwf	TMR1L			;|Logo, 62500*0,002 = 125 ms. Então, 65536 - 6250 = 3096.
    
    movlw   B'00110101'		;Redefine o prescale após carregar valores no TMR1H e TMR1L	
    movwf   T1CON			;Habilita o Timer1, clock interno como fonte e Prescale 1:8	
    

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      ROTINA VARRER DISPLAYS                            *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   
VarrerDisplays:
    
    movf	Incremento,W	;Move o conteúdo de Incremento para W
    sublw	D'10'			;Subtrai 10 da variável W, ou seja se o resultado for zero, a variável Incremento deve ser reiniciada e 
    						;deve incrementar 1 na variável DISP2.
    btfsc	STATUS,Z		;O bit Z do resgistrador STATUS é zero? Ou seja, o resultado da operação anterior não foi zero?
    call	Muda1			;Chama a rotina Muda1, que incrementa 1 na variável de "Dezenas de segundos (DISP2)" e reinicia a contagem
    						;de unidades de segundos na variável Incremento.
    movf	Incremento,W    ;Passa o conteúdo de incremento para W
    call    Tabela			;O conteúdo de incremento será o valor a ser mostrado no display1, então chama a rotina de tabela. 	
    	
	bcf     PORTE,0         ;Define nível baixo em RE0 para ativar o display 1
    bsf     PORTE,1			;Define nível alto em RE1 para desativar o display 2
    bsf		PORTE,2 	 	;Define nível alto em RE2 para desativar o display 3
    bsf		PORTA,5			;Define nível alto em RA5 para desativar o display 4
    movwf	PORTD			;Liga os LEDs de acordo com o valor retornado em W pela rotina de Tabela.
    call	Temporizacao	;Chama a rotina para aguardar 4,096 ms antes de escrever no próximo display
    
    movf	DISP2,W			;Move o conteúdo de DISP2 para W
    sublw	D'6'			;Subtrai 6 da variável W, ou seja se o resultado for zero, a variável DISP2 deve ser reiniciada, e deve ser incrementado
    						; 1 na variável DISP3.
    btfsc	STATUS,Z		;O bit Z do registrador STATUS é zero? Ou seja, o resultado da operação anterior não foi zero?	
    call    Muda2			;Não.Chama a rotina Muda2, que incrementa 1 na variável "unidades de minutos(DISP3)" e reinicia a contagem
    						;de dezenas de segundos.
    movf	DISP2,W			;Sim.Move o conteúdo de DISP2 para W
    call    Tabela			;O conteúdo de DISP 2 será o valor a ser mostrado no display2, então chama a rotina de tabela.							
    
    bsf     PORTE,0         ;Define nível baixo em RE0 para desativar o display 1
    bcf     PORTE,1			;Define nível alto em RE1 para ativar o display 2
    bsf		PORTE,2 	 	;Define nível alto em RE2 para desativar o display 3
    bsf		PORTA,5			;Define nível alto em RA5 para desativar o display 4y
    movwf	PORTD			;Liga os LEDs conforme valor retornado pela Tabela.
    call	Temporizacao	;Chama a rotina para aguardar 4,096 ms antes de escrever no próximo display
    
    movf	Auxiliar2,W		;Move o conteúdo de Auxiliar2 para W
	sublw	D'24'			;Subtrai 24 de W, pois, se o resultado for zero, significa que devemos reiniciar o cronômetro, pois 
							;chegamos ao valor máximo, 23:59. Essa variável é incrementada a cada mudança da variável DISP3.
	btfsc	STATUS,Z		;O bit Z do registrador STATUS não é zero? Ou seja, o resultado anterior não deu zero.
	call	Organiza		;Não, o resultado deu zero sim. Chama a função que reiniciará a contagem da variável quando a mesma for para o quarto incremento.
    movf	DISP3,W			;Move o conteúdo de DISP3 para W
    sublw	D'10'			;Subtrai 10 da variável W, ou seja se o resultado for zero, a variável DISP3 deve ser reiniciada
    btfsc	STATUS,Z		;O bit Z do registrador STATUS é zero? Ou seja, o resultado da operação anterior não foi zero?
    call    Muda3			;Não, o resultado foi zero. Então chama a função Muda3 que incrementa 1 na variável "dezenas de minutos(DISP4)"
    						;e reinicia a contagem da variável DISP3.	 
	
	movf	DISP3,W			;Sim.Move o conteúdo de DISP3 para W
	call	Tabela			;O conteúdo de DISP3 será o valor a ser mostrado no display3, então chama a rotina de Tabela.
	
	bsf     PORTE,0         ;Define nível baixo em RE0 para desativar o display 1
    bsf     PORTE,1			;Define nível alto em RE1 para desativar o display 2
    bcf		PORTE,2 	 	;Define nível alto em RE2 para ativar o display 3
    bsf		PORTA,5			;Define nível alto em RA5 para desativar o display 4
	movwf	PORTD			;Liga os LEDs conforme valor retornado pela rotina de Tabela
	bcf		PORTD,0			;Liga o LED do ponto, para que o valor seja mostrado conforme solicitado. Ex: 23.59.
    call	Temporizacao	;Chama a rotina para aguardar 4,096 ms antes de escrever no próximo display
    bsf		PORTD,0			;Desliga o LED do ponto.
	
	movf	DISP4,W			;Move o conteúdo de DISP4 para W	
	sublw	D'3'			;Subtrai 3 da variável W, pois, se o resultado dessa operação for zero, a variável DISP4 deve ser reiniciada
	btfsc	STATUS,Z		;O bit z do registrador STATUS é zero? Ou seja, o resultado da operação anterior não foi zero?
    call 	Muda4			;Não, o resultado deu zero. Então chama a rotina Mudar4, que limpa a variável DISP4 para reiniciar a contagem da mesma
    
    movf	DISP4,W			;Sim, não foi zero. Então move o conteúdo de DISP4 para W, para chamar a tabela, e mostrar no display o valor correspondente.
    call    Tabela			;Chama a rotina de tabela para retornar o valor a ser mostrado.
    
   	bsf     PORTE,0         ;Define nível baixo em RE0 para desativar o display 1
    bsf     PORTE,1			;Define nível alto em RE1 para desativar o display 2
    bsf		PORTE,2 	 	;Define nível alto em RE2 para desativar o display 3
    bcf		PORTA,5			;Define nível alto em RA5 para ativar o display 4
    movwf	PORTD			;Liga os LEDs conforme valor retornado pela rotina de Tabela
    call	Temporizacao	;Chama a rotina para aguardar 4,096 ms antes de escrever no próximo display
    
goto VarrerDisplays
 	
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  	ROTINA MUDA1                                *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Muda1:

	incf    DISP2			;Incrementa 1 à variável de dezenas de segundos	
 	clrf	Incremento		;Limpa a variável Incremento, para reiniciar a contagem 
 							;das unidades de segundos.
 
return 	

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  	ROTINA MUDA2                                *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Muda2:

	incf    DISP3			;Incrementa 1 à variável de dezenas de segundos	
 	clrf	DISP2			;Limpa a variável DISP2, pois a mesma atingiu o valor máximo
 							;e deve ser reiniciada a contagem
 	incf	Auxiliar2		;Incrementa 1 à variável Auxiliar2, para que, quando a mesma chegar ao valor
 							;23:59 deve reiniciar o cronômetro.						

return

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  	ROTINA MUDA3                                *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Muda3:
	
													
	incf    DISP4			;Incrementa 1 à variável de dezenas de segundos	
 	clrf	DISP3			;Limpa a variável DISP3, reiniciando a contagem pois a
 							;mesma atingiu o valor máximo de contagem						

return

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  	ROTINA MUDA4                                *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Muda4:	
 		
 	clrf	DISP4			;Limpa a variável DISP4, reiniciando a mesma, pois chegou ao valor máximo
 	
return

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  ROTINA ORGANIZA                               *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  
Organiza:
    
    clrf	Auxiliar2		;Limpa a variável Auxiliar2 após a mesma contar até 23.
	goto 	Muda3			;Chama a função para reiniciar o DISP3
							;e incrementar 1 à variável DISP4.													
return	


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *	                      	  ROTINA TEMPORIZAÇÃO                           *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

Temporizacao:
	
	nop						;Instrução para perder um ciclo de máquina. 
	btfss	INTCON,2		;Houve o estouro do Timer0?
	goto 	Temporizacao	;Não, então retorna para a rotina de Temporizacao
	bcf		INTCON,2		;Sim, então limpa o flag do timer0 e retorna da rotina de temporização.
				
return				

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                          	FIM DO PROGRAMA                             *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

END			            	; FIM DO PROGRAMA 				    	   
