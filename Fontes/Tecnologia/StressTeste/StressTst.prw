#INCLUDE 'PROTHEUS.CH'
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

/*/
Rotina com o intuito de stressar hardware com rotina pesadas do protheus, 
coletando informações de consumo do sistema operacional e tomada de tempo das rotinas.
Rotina desenvolvida para ser um "Orchestra Monitor" que dispara e sincroniza a execução
das rotinas entre um ou vários Slave´s Protheus e, estes por sua vez, devolvem um JSON
de resultados para ser compilado no Monitor da Rotina
Autor: Carlos Testa
Uso: Amplo com algumas funções de uso específico a partir do "Build 7.00.131227A - Nov  7 2017 - 22:39:07 NG "

Testes Contemplados
    * Consumo de IO utilizando SPF
    * Acesso ao banco de dados e velocidade de processamento
    * Rotinas Automáticas Protheus (MATA010 e MATA103) para teste de processo
    * Consumo de Web Service nos Slaves
    * 

Parâmetros de Uso: Os parametros setados no monitor serão replicados para os Slaves para 
que todos trabalhem dentro do mesmo cenário.
/*/
User Function StressTst()
Local _nCnt
Local _cSPF_MAN := GetPvProfString("STRESS","SPF_MAN","undefined","appserver.ini")
Local _nSPF_MAN := Val(SubStr(_cSPF_MAN,1,At("/",_cSPF_MAN)-1))
Local _cEXEC010 := GetPvProfString("STRESS","EXEC010","undefined","appserver.ini")
Local _nEXEC010 := Val(SubStr(_cEXEC010,1,At("/",_cEXEC010)-1))
Local _cEXEC103 := GetPvProfString("STRESS","EXEC103","undefined","appserver.ini")
Local _nEXEC103 := Val(SubStr(_cEXEC103,1,At("/",_cEXEC103)-1))


//JOB´s de Stress de disco para sobrecarregar o Protheus
For _nCnt := 1 To _nSPF_MAN
    SmartJob('U_SPFMan',getenvserver(),.F.)
Next

//JOB´s de inserção de Produtos para simular usabilidade de usuários Protheus
For _nCnt := 1 To _nEXEC010
    Startjob('U_Exec010',getenvserver(),.F.)
Next


For _nCnt := 1 To _nEXEC103
    Startjob('U_Exec103',getenvserver(),.F.)
Next

Return
