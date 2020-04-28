#include 'protheus.ch'
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"

User Function TstResult()

RPCSetType(3)

// Ambiente para o Lobo Guara
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT"	

// Ambiente para Build do Portal
//PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"	

U_RunQry1()	// Roda a Query no Formato de TCSqlExec, criando uma área para trabalho

U_RunQry2()	// Roda a Query no Formato de EMBEDDED, criando uma área para trabalho


return

User Function RunQry1()
Local cQuery
Local aTotClasse := {}
Local cTimeIni := Time()

// montei a query desta forma pois se vc precisar colocar mais dados no retorno, só replicar uma 
// o SELECT + UNION trocando o conteúdo do SUBSTRING. hoje o máximo de classes que tenho vai até 100
cQuery := "SELECT B1_COD AS CODIGO,B1_DESC AS DESCRICAO, (SELECT X5_DESCRI FROM SX5990 WHERE X5_TABELA = '02' AND X5_CHAVE = 'PA') AS TIPO, (SELECT AH_DESCPO FROM SAH990 WHERE AH_UNIMED = 'PC') AS UNIDADE_MEDIDA, B1_LOCPAD AS LOCAL_PADRAO, 'CLASSE_0024' AS CLASSE "
cQuery += "FROM SB1990 WHERE SUBSTRING(B1_COD,1,4) = '0024' "
cQuery += "UNION "
cQuery += "SELECT B1_COD AS CODIGO,B1_DESC AS DESCRICAO, (SELECT X5_DESCRI FROM SX5990 WHERE X5_TABELA = '02' AND X5_CHAVE = 'PA') AS TIPO, (SELECT AH_DESCPO FROM SAH990 WHERE AH_UNIMED = 'PC') AS UNIDADE_MEDIDA, B1_LOCPAD AS LOCAL_PADRAO, 'CLASSE_0002' AS CLASSE "
cQuery += "FROM SB1990 WHERE SUBSTRING(B1_COD,1,4) = '0002' "
cQuery += "UNION "
cQuery += "SELECT B1_COD AS CODIGO,B1_DESC AS DESCRICAO, (SELECT X5_DESCRI FROM SX5990 WHERE X5_TABELA = '02' AND X5_CHAVE = 'PA') AS TIPO, (SELECT AH_DESCPO FROM SAH990 WHERE AH_UNIMED = 'PC') AS UNIDADE_MEDIDA, B1_LOCPAD AS LOCAL_PADRAO, 'CLASSE_0015' AS CLASSE "
cQuery += "FROM SB1990 WHERE SUBSTRING(B1_COD,1,4) = '0015' "
cQuery += "UNION "
cQuery += "SELECT B1_COD AS CODIGO,B1_DESC AS DESCRICAO, (SELECT X5_DESCRI FROM SX5990 WHERE X5_TABELA = '02' AND X5_CHAVE = 'PA') AS TIPO, (SELECT AH_DESCPO FROM SAH990 WHERE AH_UNIMED = 'PC') AS UNIDADE_MEDIDA, B1_LOCPAD AS LOCAL_PADRAO, 'CLASSE_0010' AS CLASSE "
cQuery += "FROM SB1990 WHERE SUBSTRING(B1_COD,1,4) = '0010' "
cQuery += "ORDER BY CLASSE"

dbUseArea(.T., "TOPCONN", TCGENQRY(,,cQuery), "MYRESULT", .F.)
dbGoTop()

// Apartir deste ponto já existe uma área de trabalho chamada MYRESULT que vc pode fazer o que quiser com ela, 
// abaixo somente um exemplo de totalizador por classe
While MYRESULT->(!Eof())
	nPosClasse := ASCAN(aTotClasse, {|x| x[1] == MYRESULT->CLASSE})
	If nPosClasse > 0
		aTotClasse[nPosClasse][2]++
	Else
		AADD(aTotClasse,{MYRESULT->CLASSE,1})
	EndIf
	MYRESULT->( dbSkip() )
EndDo
MYRESULT->(dbCloseArea())

ConOut("== Totalização do SB1 | TCGenQry ==================")
VarInfo("Total de Registros",aTotClasse)
ConOut("Tempo de Execução da Query " + ElapTime(cTimeIni,Time()))
ConOut("== Totalização do SB1 | TCGenQry ==================")

Return Nil

User Function RunQry2()
Local cQuery
Local aTotClasse := {}
Local cTimeIni := Time()

// montei a query desta forma pois se vc precisar colocar mais dados no retorno, só replicar uma 
// o SELECT + UNION trocando o conteúdo do SUBSTRING. hoje o máximo de classes que tenho vai até 100
BeginSql Alias "MYRESULT"
SELECT SB1.B1_COD AS CODIGO,SB1.B1_DESC AS DESCRICAO, (SELECT SX5.X5_DESCRI FROM SX5990 SX5 WHERE SX5.X5_TABELA = '02' AND SX5.X5_CHAVE = 'PA') AS TIPO, (SELECT SAH.AH_DESCPO FROM SAH990 SAH WHERE SAH.AH_UNIMED = 'PC') AS UNIDADE_MEDIDA, SB1.B1_LOCPAD AS LOCAL_PADRAO, 'CLASSE_0024' AS CLASSE
FROM %table:SB1% SB1 WHERE SUBSTRING(SB1.B1_COD,1,4) = '0024'
UNION
SELECT B1_COD AS CODIGO,B1_DESC AS DESCRICAO, (SELECT X5_DESCRI FROM SX5990 WHERE X5_TABELA = '02' AND X5_CHAVE = 'PA') AS TIPO, (SELECT AH_DESCPO FROM SAH990 WHERE AH_UNIMED = 'PC') AS UNIDADE_MEDIDA, B1_LOCPAD AS LOCAL_PADRAO, 'CLASSE_0002' AS CLASSE
FROM %table:SB1% WHERE SUBSTRING(B1_COD,1,4) = '0002'
UNION
SELECT B1_COD AS CODIGO,B1_DESC AS DESCRICAO, (SELECT X5_DESCRI FROM SX5990 WHERE X5_TABELA = '02' AND X5_CHAVE = 'PA') AS TIPO, (SELECT AH_DESCPO FROM SAH990 WHERE AH_UNIMED = 'PC') AS UNIDADE_MEDIDA, B1_LOCPAD AS LOCAL_PADRAO, 'CLASSE_0015' AS CLASSE
FROM %table:SB1% WHERE SUBSTRING(B1_COD,1,4) = '0015'
UNION
SELECT B1_COD AS CODIGO,B1_DESC AS DESCRICAO, (SELECT X5_DESCRI FROM SX5990 WHERE X5_TABELA = '02' AND X5_CHAVE = 'PA') AS TIPO, (SELECT AH_DESCPO FROM SAH990 WHERE AH_UNIMED = 'PC') AS UNIDADE_MEDIDA, B1_LOCPAD AS LOCAL_PADRAO, 'CLASSE_0010' AS CLASSE
FROM %table:SB1% WHERE SUBSTRING(B1_COD,1,4) = '0010'
ORDER BY CLASSE
EndSql

// Apartir deste ponto já existe uma área de trabalho chamada MYRESULT que vc pode fazer o que quiser com ela, 
// abaixo somente um exemplo de totalizador por classe
While MYRESULT->(!Eof())
	nPosClasse := ASCAN(aTotClasse, {|x| x[1] == MYRESULT->CLASSE})
	If nPosClasse > 0
		aTotClasse[nPosClasse][2]++
	Else
		AADD(aTotClasse,{MYRESULT->CLASSE,1})
	EndIf
	MYRESULT->( dbSkip() )
EndDo
MYRESULT->(dbCloseArea())

ConOut()
ConOut("== Totalização do SB1 | SQL Embedded ==================")
VarInfo("Total de Registros",aTotClasse)
ConOut("Tempo de Execução da Query " + ElapTime(cTimeIni,Time()))
ConOut("== Totalização do SB1 | SQL Embedded ==================")

Return Nil