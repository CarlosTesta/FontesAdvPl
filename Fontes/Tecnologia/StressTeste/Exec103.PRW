#include "protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"
#include 'parmtype.ch'

/*/
Funcao: Exec103 | Autor Carlos Testa | Data 19/12/2017
    Rotina de teste da rotina automatica do programa MATA103
    com o intuito de testar o consumo de memoria durante a
    execucao da rotina por EXECAUTO
Validacao TOTVSTEC
/*/
User Function Exec103()
Local _nY,_nCnt,_nQuant,_nVUnit,_nVTot,_nIniTime,_nMiddleTime,_nTotProd
Local _aCabec	:= {}
Local _aItens	:= {}
Local _aLinha	:= {}
Local _cDoc		:= ""
Local _cExec103	:= GetPvProfString("STRESS","Exec103","undefined","appserver.ini")
Local _nExec103	:= Iif(!Empty(_cExec103),Val(SubStr(_cExec103,At("/",_cExec103)+1)),10)	// caso sem valor, assume 10
Local _cThread	:= AllTrim(Str(ThreadID()))						// numero da thread para garantir unicidade no nome do arquivo
Local _cSrvIP	:= GetServerIP()								// IP do servidor atual
Local _cSrvPort	:= GetPvProfString("TCP","Port","undefined","appserver.ini")	// Porta do AppServer
Local _cEnvWork	:= GetEnvServer()								// Environment atual de trabalho

PRIVATE lMsErroAuto := .F.
Private lMsHelpAuto	:= .T.

// Abertura do ambiente
RpcSetType( 3 )
PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "COM"

// iremos trabalhar com o tempo MÉDIO DA EXECUÇÃO DE BLOCOS.
_nIniTime	:= Microseconds()
For _nY := 1 To _nExec103
    // NUMERO DA NOTA ARMAZENADO EM UM MV SO PARA FACILITAR OS TESTES - Testa
	//_cDoc := GetMV("ES_NUMDOC")
	_cDoc := StrZero(Val(AllTrim(StrTran(Str(Val(_cThread)+round(Microseconds()-int(Microseconds()),6)),".",""))),13)

	_aCabec := {}
	_aItens := {}
	
	aadd(_aCabec,{"F1_TIPO"   ,"N"})
	aadd(_aCabec,{"F1_FORMUL" ,"N"})
	aadd(_aCabec,{"F1_DOC"    ,(_cDoc)})
	aadd(_aCabec,{"F1_SERIE"  ,"UNI"})
	aadd(_aCabec,{"F1_EMISSAO",dDataBase})
	aadd(_aCabec,{"F1_DESPESA",12})         //despesa - teste
	aadd(_aCabec,{"F1_FORNECE","000001"})
	aadd(_aCabec,{"F1_LOJA"   ,"01"})
	aadd(_aCabec,{"F1_ESPECIE","NFE"})
	aadd(_aCabec,{"F1_COND","001"})
	aadd(_aCabec,{"F1_DESCONT",0,NIL})
	aadd(_aCabec,{"F1_SEGURO",0,NIL})
	aadd(_aCabec,{"F1_FRETE",0,NIL})
	aadd(_aCabec,{"F1_VALMERC",312,NIL})
	aadd(_aCabec,{"F1_VALBRUT",312,NIL})
	
	dbSelectArea("SB1")
	dbGoTop()
    _nTotProd := SB1->(RecCount())
	For _nCnt := 1 to 15
		SB1->( dbGoTo(Randomize(1,_nTotProd)) )		// pega aleatorio qq produto entre 1 e TotaldeProdutos
		_nQuant	:= Randomize(1,25)
		_nVUnit	:= 10*Randomize(1,127)
		_nVTot	:= a410Arred((_nQuant*_nVUnit),"D1_TOTAL")
		_aLinha := {}
		aadd(_aLinha,{"D1_ITEM"  ,STRZERO(_nCnt,2)				,Nil})
		aadd(_aLinha,{"D1_COD"  ,SB1->B1_COD					,Nil})
		aadd(_aLinha,{"D1_QUANT",_nQuant						,Nil})
		aadd(_aLinha,{"D1_VUNIT",_nVUnit						,Nil})
		aadd(_aLinha,{"D1_TOTAL",_nVTot							,Nil})
		aadd(_aLinha,{"D1_TES",SB1->B1_TE						,Nil})
		aadd(_aLinha,{"D1_SEGURO",3*Randomize(1,175)			,NIL})
		aadd(_aLinha,{"D1_VALFRE",((_nCnt*Randomize(1,15))*0.05),NIL})
		aadd(_aLinha,{"D1_DESPESA",Randomize(35,198)			,NIL})
		aadd(_aLinha,{"AUTDELETA" ,"N"							,Nil}) // Incluir sempre no ?timo elemento do array de cada item
		aadd(_aItens,_aLinha)
	Next

	MATA103(_aCabec,_aItens)

	/*
	If !lMsErroAuto
		//ConOut("Incluido com sucesso! "+_cDoc)
		If SX6->( dbSeek(xFilial("SX6")+"ES_NUMDOC") )
			Reclock("SX6",.F.)
			SX6->X6_CONTEUD := Soma1(_cDoc,9)
			Sx6->( MsUnLock() )
		EndIf
	Else
		//ConOut("Erro na inclusao!")
		//MostraErro()
	EndIf
	*/
Next

// ConOut para Printar o tempo de cada execução em cada passada
ConOut(Repl("-",80))
_nMiddleTime := (Microseconds()-_nIniTime)/_nExec103
ConOut('LOG de Processo "EXEC103" | THREAD: "'+_cThread+'" | Lacos: "'+AllTrim(Str(_nExec103))+'" | Server:"'+_cSrvIP+':'+_cSrvPort+'" | Environment:"'+_cEnvWork+'" | Tempo Medio:"'+ AllTrim(Str(_nMiddleTime))+'" segundos.')
ConOut(Repl("-",80))

RESET ENVIRONMENT

Return