## Simple malloc implementation made in assembly

 - No programa, %rax é utilizado apenas para manipular
valores de retorno de função, pois preferi evitar 
erros caso sobreescrevesse o registrador sem querer

- Caso o tamanho do próximo bloco for menor do que 1
byte, o bloco é alocado com o tamanho inteiro. Por 
exemplo, caso exista um bloco livre de 50 bytes e eu
aloque um espaço de 40 bytes, o espaço livre de 10 bytes
que sobra não é suficiente nem para as informações 
gerenciais do proximo bloco (que ocupam 16 bytes). Neste 
caso, o bloco será alcacado com tamanho de 50 bytes. Uma 
outra alternativa a isso seria alocar um bloco novo no 
topo da heap.