#---------------------------------#
#     TRABALHO REALIZADO POR:     #
#---------------------------------# 
#  Bruno Silva       - 30003769   #
#  Daniel Silvestre  - 30003099   #
#  Diogo Sousa       - 30003344   #
#  João Ramos        - 30002954   #
#---------------------------------#

.data
# GENERATOR.asm
# Alterar o seguinte mapa consoante a vossa forma (4x4), em que cada entrada (x,y) deve ser a localizacao de "1". 
# Considera-se um mapa e forma (4x4). Caso a sua forma 2D seja maior que 4x4, o codigo tera de ser modificado de forma concordante.
# Neste exemplo especifico, considerou-se a forma 2D identificada no trabalho como a forma "3".

# Definicao das entradas (x,y) que compoem a forma 2D

figure_x: .byte 0,0,1,2,3
figure_y: .byte 0,1,1,1,1

coluna: .asciiz "\nColuna Nº: "
linha: .asciiz "\nLinha Nº: "

nao_rodada: .asciiz "\n\nLOCALIZAÇÃO DA FIGURA SEM ROTAÇÃO:"
rodada: .asciiz "\n\nLOCALIZAÇÃO DA FIGURA COM ROTAÇÃO:"
nao_encontrada: .asciiz "\nA FIGURA NÃO FOI ENCONTRADA!"
 
bitmap: .word 0x10040000 # Endereco da heap

# Numero de celulas a 1 da forma escolhida. Neste caso, para a forma 3, temos 5 valores (0,0), (0,1), (1,1), (2,1), (3,1)
fig_cells: .byte 5

# Dimensao do bitmap e dada por l^2, onde l representa a dimensao do lado, que deve ser sempre impar.
# Para este caso, l=16, pois o BitMap Display está em 16x16 = 256 (Quadrado Perfeito). 
d: .word 16

# Espaco pre-alocado para o guardar bitmap na memoria [!]
map: .space 100000

.text
# Gerar um mapa aleatorio com 0's e 1's
jal GetRandomMap

# Coloca a forma 2D no mapa gerado, numa posicao aleatoria
jal GetMapwPiece 

li $a3, 0 # Contador para o numero de peças rodadas
li $a2, 0 # Contador para o numero de pecas não rodadas

jal NewMap # Reformula o mapa com a peca encontrada

li $a3, 0 # Contador para o nuemro de peças não rodadas
li $a2, 0 # Contador para o numero de pecas rodadas

jal PrintMap # Faz print do resultado no mapa com a forma


# ----------------------------------------------------------

# APOIO: 
	# -10 = sem rotaçao
	# -20 = com rotaçao
	# -11 = termino da sem rotaçao
	
li $t5,-11
li $t9, 0 
li $s0, -10 # Flag value para nao encontrada 
li $a0, -1 # Flag 

li $s4, 0
la $s2, d # $s2 contem o lado do mapa
lw $s3, ($s2)
add $t4, $a3, $a2 # Soma
beq $t4, $zero, not_found # Se a soma de $a3 com $a2 for igual a zero significa que 
			  # a peça nao esta no mapa, entao salta para a impressao da string nao_encontrada

j imprime_Semrotacao

# ---------------------------------------------------------------------------------------------------------

imprime_Semrotacao:  # Imprime as Coordenadas da peça sem Rotacao 
beq $s4,$a3,imprime_Comrotacao

addiu $s4, $s4, 2
lw $s7,($sp)  # Posição da peca mais à esquerda
li $a0, -20  # Valor flag para rotacao
beq $a0, $s7, imprime_Comrotacao  # Caso não seja -10, repete
addiu $sp,$sp,8 # Incrementaçao da stack
lw $s7, ($sp)

divu $s7, $s3 # Divisao entre posicao e o lado do mapa
mflo $s6 # Guarda em $s6 a coordenada y da posicao superior esquerda
mfhi $v1

subiu $s6, $s6, 1

li $v0, 4
la $a0, nao_rodada # Imprime mensagem da peca nao rodada 
syscall

li $v0, 4
la $a0, coluna # Imprime texto coluna
syscall

li $v0,1 # Imprime o inteiro, correspondente ao numero da coluna
move $a0, $v1
syscall

li $v0, 4
la $a0, linha # Imprime texto linha
syscall

li $v0, 1 # Imprime o inteiro, correspondente ao numero da linha
move $a0,$s6
syscall

j imprime_Semrotacao

# ------------------------------------------------------------------

imprime_Comrotacao: # Imprime as Coordenadas da peça com Rotacao
beq  $t9,$a2,exit
addiu $t9, $t9, 2  # Incrementa o contador 
li $a0, -10 # Corresponde a peca nao rodada
lw $s7,($sp)
beq $s7, $a0, imprime_Semrotacao

addiu $sp,$sp,8 # Incrementaçao da stack
lw $s7, ($sp)
divu $s7, $s3 # Divisao entre posicao e o lado do mapa
mflo $s6 # Guarda em $s6 a coordenada y da posicao superior esquerda
mfhi $v1

li $v0, 4
la $a0, rodada # Imprime mensagem da peca rodada 
syscall

li $v0, 4
la $a0, coluna # Imprime texto coluna
syscall

li $v0,1 # Imprime o inteiro, correspondente ao numero da coluna
move $a0, $v1 
syscall

li $v0, 4
la $a0, linha # Imprime texto linha
syscall

li $v0, 1 # Imprime o inteiro, correspondente ao numero da linha
move $a0,$s6
syscall
j imprime_Comrotacao

# ----------------------------------------------------------------	

j exit

not_found:
li $v0, 4
la $a0, nao_encontrada
syscall

j exit

# ---------------------------------------------------------------- 

GetRandomMap:
# Gera um mapa aleatorio com 0's e 1's
	
	# Protege as variaveis usadas
	addi $sp,$sp,-8	
	sw $s1,0($sp)
	sw $s2,4($sp)
	sw $s0,8($sp)

	# $t1 - Area do mapa
	lw $t1, d
	
	multu $t1,$t1
	
	# $t2 - Numero total de entradas no mapa 
	mflo $t2

	# Guarda em $s0 o endereco do mapa a preencher 
	la $s0, map

	# Inicia o contador iterador no array com todas as entradas do mapa 
	li $t4,0
	
	# Prepara a execucao de randoms para 
	li $v0, 42 # Codigo associado a geracao de numeros inteiros aleatorios
	li $a0, 1	
	addi $a1, $t2, 1 # Fim [!]

	# Percorre todos as entradas, determinando se sao preenchidas a "0" ou a "1". 
	# (Este codigo pode ser modificado para se tornar o preenchimento mais ou menos denso de 1's, 
	# correndo-se o risco, no caso mais denso, de existirem varias formas 2D iguais as que procuramos)
	# Neste momento, guarda 4 zeros, e depois, de forma aleatoria, coloca um "1" ou um "0".
	LOOP0:	
		beq $t4,$t2,return01     		
		addi $s0, $s0, 1		
		sb $zero, ($s0) 	# Guarda 0 nesta posicao
		addi $t4,$t4,1
		
		beq $t4,$t2,return01
		addi $s0, $s0, 1		
		sb $zero, ($s0) 	# Guarda 0 nesta posicao
		addi $t4,$t4,1
		
		beq $t4,$t2,return01
		addi $s0, $s0, 1		
		sb $zero, ($s0) 	# Guarda 0 nesta posicao		
		addi $t4,$t4,1
		
		#beq $t4,$t2,return01
		#addi $s0, $s0, 1		
		#sb $zero, ($s0) 	# Guarda 0 nesta posicao	
		#addi $t4,$t4,1		
		
		beq $t4,$t2,return01    
		addi $s0, $s0, 1 
		li $a1, 2		
		syscall
		
		# Guarda random "1" ou "0" - comentar esta linha para ter um mapa sem ruido
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
	# Protege variaveis usadas
	addi $sp,$sp,-16
	sw $s7,0($sp)
	sw $s4,4($sp)
	sw $s0,8($sp)
	sw $s5,12($sp)
	sw $s6,16($sp)
	
	# Lado do mapa - $s0
	lw $s0, d
	multu $s0,$s0
	
	# Area do mapa
	mflo $t2
	
	# Encontra aleatoriamente uma posicao para a forma 2D ($s4)
	li $v0, 42
	li $a0, 1
	addi $a1, $t2, 1
	syscall
	move $s4, $a0 # Em $s4 fica a posicao da forma	
	
	# Descomentar a proxima linha para colocar a forma numa posicao conhecida (15) - para debuging 
	# Atencao que a posicao da forma conta a partir de 0. 
	# li $s4, 15
	
	li $a0, 1
	li $a1, 2
	syscall

	move $v0, $a0 # Guarda em $vo a rotacao da forma (parametro para jal rodada)
	
	# Verifica se a forma deve ser rodada de 180 graus consoante o random anterior
	bne $v0, $zero, nao_rodar
		
		# Prepara a chamada da funcao rodada, guardando $ra
		addi $sp, $sp, -4
		sw $ra, ($sp) 
		# Roda a forma de 180 graus
		jal rodar
	
	# Recupera o $ra do $sp
	lw $ra, ($sp) 
	addi $sp, $sp, 4
	
	nao_rodar:
	
	# Vai buscar o inicio do mapa (endereco) e guarda em $t7
	la $t7, map
	
	# Carrega os endereco das posicoes (x,y) da forma 	
	la $s5, figure_x
	la $s6, figure_y	
	
	# Carrega o numero de entradas da forma
	lb $s7, fig_cells
	
	# Faz um loop que precorre todas as entradas da forma ($s7) e devolve um mapa com a forma inserida.
	LOOP2:	beq $s1, $s7, return02
				
		# Vai buscar os valores da primeira entrada para x e para y		
		lb $t5, ($s5) # X
		lb $t6, ($s6) # Y relativos da cada ponto da forma
		
		divu $s4, $s0 		
		# Posicao x da forma no mapa dada a posicao absoluta da forma encontrada anteriormente
		mfhi $t3
		
		# Posicao y da formano mapa dada a posicao absoluta da forma encontrada anteriormente
		mflo $t8
				
		# Posicao x,y final do elemento (posicao do elemento na forma + posicao da forma no mapa): 
		add $t5, $t5, $t3 # X
		add $t6, $t8, $t6 # Y
	
		li $t9, 1
		
		multu $t6, $s0
		mflo $t3
		# $s2 - Posicao final no array da entrada da forma de cada iteracao do loop
		add $t0, $t3, $t5
		# $t6 - Endereco dessa entrada						
		add $t6, $t7, $t0
		
		# Escrita do valor 1 nesse endereco
		sb $t9, ($t6)
		
		addi $s1, $s1, 1 # Iteracao no loop		
		addi $s5, $s5, 1 # Iteracao do endereco x
		addi $s6, $s6, 1 # Iteracao do endereco y	
			
		j LOOP2	
	
	return02:
	sw $s7,0($sp)
	sw $s4,4($sp)
	sw $s0,8($sp)
	sw $s5,12($sp)
	sw $s6,16($sp)
	
	addi $sp,$sp,16	
	
	li $s1, 0
		
	jr $ra		

PrintMap:

NewMap:
addi $s1, $s1, 1 # Incrementa
li $s2, 2


	# Lado do mapa - $s0
	lw $t1, d
	multu $t1,$t1
	# Area do mapa
	mflo $t2
	
	# Inicializa a iteracao
	li $t4,0
	
	la $t7, map
	
	# Faz print do bitmap, iterando por todas as celulas
	##########
	lw $a1, bitmap # Carrega em a1 o endereco da heap
	##########
	li $v1,1 # Carrega o contador com valor 1
	LOOP1:		
		beq $t4,$t2,return2 
		lb $a0, ($t7)
		li  $v0, 1          		
		# Imprime o valor que esta no bitmap ($t7)
		bne $s1, $s2, naocorretudo
		syscall
		naocorretudo:
		addi $t7, $t7, 1 
		#---------------------------------------------------------------------		
		li $t3, 4 # Guarda 4
		li $t6, 0 # Contador de "1's" seguidos
		beq $a0, $zero, salto # Caso seja 0 -> salto
		add $t0, $t4, $zero # Guarda a posicao
		subiu $t0, $t0, 1 # Decrementa 1 a posicao uma vez que comeca no zero
		miniloop: # Confirma se é superior esquerdo
		lb $t5, 1($t7) # Carrega em $t5 o valor da prox posicao
		beq $t5, $zero, salto # Sai se o prox valor for 0
		add $t6, $t6, 1 # Incrementa numero de 1s
		beq $t6, $t3, label11 # Foram encontrados 4 1's seguidos
		j miniloop
		
		
		#---------------------------------------------------------------------		
		
		label11: # Verifica o bit restante
		# INICIO PARTE SEM ROTACAO
		lb $t6, -18($t7)
		beq $t6, $zero, check_rotation # Nao apresenta ser a fig3, verificar se existe uma rotacao
		li $v0, 16 # Carrega-se o lado do bitmap
		addiu $a3, $a3, 2 # Sempre que a peça é encontrada é adicionado um a este contador
		li $v1, -10 # Valor flag for no rotation
		subiu $sp, $sp, 4 
		sw $v1, ($sp) # Guarda -10 flag na stack
		subiu $sp, $sp, 4
		sw $t0, ($sp) # Guarda na stack a posiçao da peça mais á esquerda	
		##
		li $s5, 2
		sb $s5, -18($t7)
		sb $s5, -2($t7)
		sb $s5, -1($t7)
		sb $s5, 0($t7)
		sb $s5, 1($t7)
		# FIM PARTE SEM ROTACAO
		j salto
		
		check_rotation:
		# INICIO PARTE COM ROTACAO
		lb $t6, 17($t7) # Implica a posicao estar invertida (offset de d -> lado do bitmap)
		beq $t6, $zero, salto # Nao existe
		
		li $v0, 16 # Carrega-se o lado do bitmap
		divu $t0, $v0 # Divisao entre posicao e o lado do mapa
		## 
		addiu $a2, $a2, 2 # Sempre que a peça é encontrada é adicionado um a este contador
		li $v1, -20
		subiu $sp, $sp, 4
		sw $v1, ($sp) # Guarda -20flag na stack
		subiu $sp, $sp, 4 # Decrementaçao da stack
		sw $t0,($sp) # Guarda na stack a posiçao da peça mais á esquerda

		li $s5, 2
		sb $s5, 17($t7)
		sb $s5, 1($t7)
		sb $s5, 0($t7)
		sb $s5, -1($t7)
		sb $s5, -2($t7)
	
		# FIM PARTE COM ROTACAO
		
		salto:	# Bitmap com cores amarela e vermelha
		bne $a0, $zero, amarelo
		li $a0, 0x000000 # Codigo da cor preta de fundo do bitmap
		sw $a0, ($a1)
		j bitdisplay
		
		amarelo:
		li $s2, 2
		beq $a0, $s2, vermelho
		li $a0, 0xfdfe02
		sw $a0, ($a1)
		j bitdisplay
		
		vermelho:
		li $a0, 0xff3f00
		sw $a0, ($a1)
		
		bitdisplay:
		addi $a1, $a1, 4
		
		li $v0, 0xB
		addi $a0, $zero, 0x20
		# Imprime um zero de separacao horizontal
		syscall		

		li $v0, 1
		addi $t4, $t4, 1
		divu $t4, $t1	# Procura o resto para saber se tem que introduzir uma quebra de linha            
		mfhi $t3
		
					
		# Se chegou ao fim da linha imprime um carrier - return - nova linha
		bne $zero, $t3, next
			li $v0, 0xB
			addi $a0, $zero, 0xA
			syscall
			li $v0, 1				
		
		next:
		
		j LOOP1

	return2:	

	jr $ra
	
rodar:  # Roda uma forma de 180 graus - igual a simetria em x e simetria em y
	
	# Carrega entradas em x e dimensao da forma
	la $t1, figure_x
	lb $t3, fig_cells 
	
	move $t4, $zero
	# Itera em cada entrada em x para fazer simetria em x
	LOOP3:
		beq, $t3, $t4, exit2		
		
		# Faz simetria em x, usando $t5 para guardar o valor		
		lb $t5, ($t1)
		# Partindo do principio que a forma tem 4 entradas de lado, a simetria deve ser 4-x, 
		# sendo x a posicao actual deste "1" 
		
		li $t6, 4  # Subtrai a 4 a posicao actual
		sub $t5, $t6, $t5
		
		# Guarda a entrada de novo no map.
		sb $t5, ($t1)
		
		# Itera
		addi $t4, $t4, 1
		addi $t1, $t1, 1
		j LOOP3
	exit2:
	
	# Carrega entradas em y e posicao da forma
	la $t1, figure_y
	
	move $t4, $zero
	# Itera em cada entrada em y para fazer simetria em y (igual ao codigo para x)
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
li $v0, 10
syscall
