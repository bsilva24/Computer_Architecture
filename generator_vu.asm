.data
#GENERATOR.asm
#Alterar o seguinte mapa consoante a vossa forma (4x4), em que cada entrada (x,y) deve ser a localizacao de "1". 
#Considera-se um mapa e forma (4x4). Caso a sua forma 2D seja maior que 4x4, o codigo tera de ser modificado de forma concordante.
#Neste exemplo especifico, considerou-se a forma 2D identificada no trabalho como a forma "1".

#Definicao das entradas (x,y) que compoe a forma 2D
figure_x: .byte 0,0,1,2,3
figure_y: .byte 0,1,1,1,1

#Numero de celulas a 1 da forma escolhida. Neste caso, para a forma 1, temos 4 valores (0,0), (1,0), (2,0) e (1,1)
fig_cells: .byte 5

#Dimensao do bitmap e' dada por l^2, onde l representa a dimensao do lado, que deve ser sempre impar.
#Para este caso, l=11. 
d: .word 16

#espaco pre-alocado para o guardar bitmap na memoria [!]
map: .space 100000

.text

#Gerar um mapa aleatorio com 0's e 1's
jal GetRandomMap

#Coloca a forma 2D no mapa gerado, numa posicao aleatoria
jal GetMapwPiece

#Faz print do resultado no mapa com a forma
jal PrintMap

j exit


GetRandomMap:
#Gera um mapa aleatorio com 0's e 1's
	
	#protege as variaveis usadas
	addi $sp,$sp,-8	
	sw $s1,0($sp)
	sw $s2,4($sp)
	sw $s0,8($sp)
	

	#$t1 - area do mapa
	lw $t1, d
	
	multu $t1,$t1
	
	#$t2 - Numero total de entradas no mapa 
	mflo $t2

	#Guarda em $s0 o endereço do mapa a preencher 
	la $s0, map

	#inicia o contador iterador no array com todas as entradas do mapa 
	li $t4,0
	
	#Prepara a execucao de randoms para 
	li $v0, 42 # Codigo associado a' geracão de nnmeros inteiros aleatorios
	li $a0, 1	
	addi $a1, $t2, 1 #fin [!]

	#Percorre todos as entradas, determinando se sao preenchidas a "0" ou a "1". 
	#(Este codigo pode ser modificado para se tornar o preenchimento mais ou menos denso de 1's, 
	# correndo-se o risco, no caso mais denso, de existirem varias formas 2D iguais as que procuramos)
	#Neste momento, guarda 4 zeros, e depois, de forma aleatoria, coloca um "1" ou um "0".
	LOOP0:	
		beq $t4,$t2,return01     		
		addi $s0, $s0, 1		
		sb $zero, ($s0) 	#Guarda 0 nesta posicao
		addi $t4,$t4,1
		
		beq $t4,$t2,return01
		addi $s0, $s0, 1		
		sb $zero, ($s0) 	#Guarda 0 nesta posicao
		addi $t4,$t4,1
		
		beq $t4,$t2,return01
		addi $s0, $s0, 1		
		sb $zero, ($s0) 	#Guarda 0 nesta posicao		
		addi $t4,$t4,1
		
		#beq $t4,$t2,return01
		#addi $s0, $s0, 1		
		#sb $zero, ($s0) 	#Guarda 0 nesta posicao	
		#addi $t4,$t4,1		
		
		beq $t4,$t2,return01    
		addi $s0, $s0, 1 
		li $a1, 2		
		syscall
		
		#guarda random "1" ou "0" - comentar esta linha para ter um mapa sem ruido
		sb $a0, ($s0) 		
						
		addi $t4,$t4,1
		j LOOP0

	return01:
	

	lw $s1,0($sp)
	lw $s2,4($sp)
	lw $s0,8($sp)	
	addi $sp,$sp,8
	 	
	jr $ra

GetMapwPiece:

	#protege variaveis usadas
	addi $sp,$sp,-16
	sw $s7,0($sp)
	sw $s4,4($sp)
	sw $s0,8($sp)
	sw $s5,12($sp)
	sw $s6,16($sp)
	

	#lado do mapa - $s0
	lw $s0, d
	multu $s0,$s0
	
	#area do mapa
	mflo $t2
	
	#encontra aletoriamente uma posicao para a forma 2D ($s4)
	li $v0, 42
	li $a0, 1
	addi $a1, $t2, 1
	syscall
	move $s4, $a0 # em $s4 fica a posicao da forma	
	
	#Descomentar a proxima linha para colocar a forma numa posicao conhecida (15) - para debuging 
	#Atencao que a posicao da forma conta a partir de 0. 
	#li $s4, 15
	
	li $a0, 1
	li $a1, 2
	syscall

	move $v0, $a0 #guarda em $vo a rotacao da forma (parametro para jal rotate)
	
	#verifica se a forma deve ser rodada de 180 graus consoante o random anterior
	bne $v0, $zero, nrotate
		
		#prepara a chamada da funcao rotate, guardando $ra
		addi $sp, $sp, -4
		sw $ra, 0($sp) 
		#Roda a forma de 180 graus
		jal rotate
	
	#recupera o $ra do $sp
	lw $ra, 0($sp) 
	addi $sp, $sp, 4
	
	
	nrotate:
	
	#vai buscar o inicio do mapa (endereco) e guarda em $t7
	la $t7, map
	
	#carrega os endereco das posicoes (x,y) da forma 	
	la $s5, figure_x
	la $s6, figure_y	
	
	#carrega o numero de entradas da forma
	lb $s7, fig_cells
	
	#faz um loop que precorre todas as entradas da forma ($s7) e devolve um mapa com a forma inserida.
	LOOP2:	
		beq $s1, $s7, return02
				
		#vai buscar os valores da primeira entrada para x e para y		
		lb $t5, ($s5) #x
		lb $t6, ($s6) #y relativos da cada ponto da forma
		
		
		divu $s4, $s0 		
		#posicao x da forma no mapa dada a posicao absoluta da forma encontrada anteriormente
		mfhi $t3
		
		#posicao y da formano mapa dada a posicao absoluta da forma encontrada anteriormente
		mflo $t8
		
				
		#posicao x,y final do elemento (posicao do elemento na forma + posicao da forma no mapa): 
		add $t5, $t5, $t3 #x
		add $t6, $t8, $t6 #y
	
		li $t9, 1
		
		multu $t6, $s0
		mflo $t3
		#$s2 - posicao final no array da entrada da forma de cada iteracao do loop
		add $t0, $t3, $t5
		#$t6 - endereco dessa entrada						
		add $t6, $t7, $t0
		
		#escrita do valor 1 nesse endereco
		sb $t9, ($t6)
		
		addi $s1, $s1, 1 #iteracao no loop		
		addi $s5, $s5, 1 #iteracao do endereco x
		addi $s6, $s6, 1 #iteracao do endereco y	
			
		j LOOP2	
	
	return02:
	

	sw $s7,0($sp)
	sw $s4,4($sp)
	sw $s0,8($sp)
	sw $s5,12($sp)
	sw $s6,16($sp)
	
	addi $sp,$sp,16	
	
	jr $ra		

PrintMap:
#imprime o bitmap com "0" e "1" no ecr‹
	

	#lado do mapa - $s0
	lw $t1, d
	multu $t1,$t1
	# area do mapa
	mflo $t2
	
	
	#inicializa a iteracao
	li $t4,0
	
	la $t7, map
	
	#Faz print do bitmap, iterando por todas as celulas
	LOOP1:	
		beq $t4,$t2,return2
		lb $a0, ($t7)
		addi $t7, $t7, 1 
		li  $v0, 1          		
		#imprime o valor que esta no bitmap ($t7)
		syscall
		
		li $v0, 0xB
		addi $a0, $zero, 0x20
		#imprime um zero de separacao horizontal
		syscall		

		li $v0, 1
		addi $t4, $t4,1
		divu $t4, $t1	#procura o resto para saber se tem que introduzir uma quebra de linha            
		mfhi $t3				
		#se chegou ao fim da linha imprime um carrier - return - nova linha
		bne $zero, $t3, next
			li $v0, 0xB
			addi $a0, $zero, 0xA
			syscall
			li $v0, 1				
		
		next:
		
		j LOOP1

	return2:	

	jr $ra


rotate:
#roda uma forma de 180 graus - igual a simetria em x e simetria em y
	
	#carrega entradas em x e dimensao da forma
	la $t1, figure_x
	lb $t3, fig_cells 
	
	move $t4, $zero
	#itera em cada entrada em x para fazer simetria em x
	LOOP3:
		beq, $t3, $t4, exit2		
		
		#faz simetria em x, usando $t5 para guardar o valor		
		lb $t5, ($t1)
		#partindo do principio que a forma tem 4 entradas de lado, a simetria deve ser 4-x, 
		#sendo x a posicao actual deste "1" 
		li $t6, 4
		#subtrai a 4 a posicao actual
		sub $t5, $t6, $t5
		
		#guarda a entrada de novo no map.
		sb $t5, ($t1)
		
		#itera
		addi $t4, $t4, 1
		addi $t1, $t1, 1
		j LOOP3
	exit2:
	
	#carrega entradas em y e posicao da forma
	la $t1, figure_y
	
	move $t4, $zero
	#itera em cada entrada em y para fazer simetria em y (igual ao codigo para x)
	LOOP4:
		beq, $t3, $t4, exit3				
		lb $t5, ($t1)
		li $t6, 4
		sub $t5, $t6, $t5
		sb $t5, ($t1)
		
		addi $t4, $t4, 1
		addi $t1, $t1, 1
		j LOOP4
	exit3:


	jr $ra



exit:

