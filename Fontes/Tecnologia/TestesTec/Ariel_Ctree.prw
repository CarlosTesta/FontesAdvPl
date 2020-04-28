#INCLUDE "PROTHEUS.CH"
#INCLUDE 'TBICONN.CH' 
#include "topconn.ch"

User Function MyCtree()
Local _nConta		:= 1
Local _nDias		:= 1
Local _dDataIni 	:= CTOD("10/01/2018")
Local _cTable1		:= "MYTABLE1"
Local _cRDD			:= "CTREECDX"	// pode ser usado tanto para Ctree Local quanto Ctree Server
Local _aEstruTab 	:= { ;
                        	{ 'COD'  , 'C',  3, 0 }, ;
	                        { 'NOME' , 'C', 10, 0 }, ;
                        	{ 'IDADE', 'N',  3, 0 }, ;
                        	{ 'NASC' , 'D',  8, 0 } ;
						}

RPCSetType(3)
// PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT"

// caso exista o arquivo, apaga para rodar novamente
If File(_cTable1+GetDBExtension())
	fErase(_cTable1+GetDBExtension())
EndIf

// Cria a tabela no formato da RDD atual, no caso Ctree
DBCreate( _cTable1,_aEstruTab, _cRDD )
DBUseArea( .T., _cRDD, _cTable1, (_cTable1), .F., .F. )	// ultimo parametro determina=> .T.=somente leitura / .F.=Todas operações

For _nCnt := 1 to 100
	if _nConta == 10
		_nConta := 1
		_nDias++	// soma mais um dia à data à cada 10 inserções
	Else
		_nConta++
	EndIf

	(_cTable1)->( DBAppend( .T. ) )
	(_cTable1)->COD		:= AllTrim(StrZero(_nCnt,3))
	(_cTable1)->NOME	:= "FULANO_" + AllTrim(StrZero(_nCnt,3))
	(_cTable1)->IDADE	:= 20 + _nDias
	(_cTable1)->NASC	:= _dDataIni + _nDias
	(_cTable1)->( DBCommit() )
Next

// criando filtro com data inicial + 5, deve trazer 10 registros
(_cTable1)->( DbSetFilter({|| NASC == (_dDataIni + 5) }, "NASC==(_dDataIni + 5)") )
ConOut("== Teste Filtro Ctree ==============================")
ConOut( "Filtro criado >> " + (_cTable1)->(DBFilter()) )
ConOut( "_dDataIni >> " + DTOC(_dDataIni) )

(_cTable1)->( dbGoTop() )
While (_cTable1)->(!EOF())
	ConOut("COD:" + (_cTable1)->COD)
	ConOut("NOME:" + (_cTable1)->NOME)
	ConOut("IDADE:" + Alltrim(Str((_cTable1)->IDADE)))
	ConOut("NASC:" + DTOC((_cTable1)->NASC))
	ConOut("-------------------------------")
	(_cTable1)->( dbSkip() )
EndDo
ConOut("== Teste Filtro Ctree ==============================")

(_cTable1)->(DBCloseArea())

Return Nil


