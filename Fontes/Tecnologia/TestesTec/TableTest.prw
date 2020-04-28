#include "protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"
User Function TableTst()
Local _nCnt
Local _aEstrTab := {}

// conecta no ambiente Protheus
RPCSetType(3)
//PREPARE ENVIRONMENT EMPRESA 'T1' FILIAL 'D MG 01 ' MODULO 'FAT'
PREPARE ENVIRONMENT EMPRESA '99' FILIAL '01' MODULO 'FAT'

ConOut("Início" + " " + Time())
// estrutura do arquivo de trabalho - Cria a Tabela
Aadd(_aEstrTab,{"A1_COD"	,"C",06,0})	
Aadd(_aEstrTab,{"A1_LOJA"	,"C",04,0})	
Aadd(_aEstrTab,{"A1_NOME"	,"C",35,0})

// garantir a não existencia
If TCCanOpen("SA1TEST")
	TCDelFile("SA1TEST")
	TCRefresh("SA1TEST")
EndIf
dbcreate("SA1TEST",_aEstrTab,"TOPCONN")
dbUseArea (.T.,"TOPCONN","SA1TEST","SA1TST",.T., .F.)
ConOut("Criou Tabela" + " " + Time())

// Abre a area de trabalho e insere Registros
dbSelectArea("SA1TST")
SA1TST->( dbGoTop() )
For _nCnt := 1 to 10
	RecLock("SA1TST",.T.)
	SA1TST->A1_COD	:= StrZero(_nCnt,6)
	SA1TST->A1_LOJA	:= StrZero(_nCnt,4)
	SA1TST->A1_NOME	:= "Compra de Tudo - Loja " + AllTrim(Str(_nCnt))
	MsUnLock()
Next
ConOut("Fez Inserção" + " " + Time())

// Alteracao dos registros inseridos
SA1TST->( dbGoTop() )
For _nCnt := 1 to 10
	dbGoTo(_nCnt)
	RecLock("SA1TST",.F.)
	SA1TST->A1_COD	:= StrZero(1000+_nCnt,6)
	SA1TST->A1_LOJA	:= StrZero(1000+_nCnt,4)
	SA1TST->A1_NOME	:= "Agora o NOVO Compra de Tudo - Loja " + AllTrim(Str(_nCnt))
	MsUnLock()
Next
ConOut("Fez Alteração" + " " + Time())

// Eliminação de 1 registro apenas
dbGoTo(Randomize(1,10))
RecLock("SA1TST",.F.)
SA1TST->(DbDelete())
MsUnLock()
ConOut("Fez Exclusão de registro")

// Apagando a tabela no banco
TCDelfile("SA1TEST")
TCRefresh("SA1TEST")
ConOut("Fez Drop de Tabela" + " " + Time())

RESET ENVIRONMENT

Return
