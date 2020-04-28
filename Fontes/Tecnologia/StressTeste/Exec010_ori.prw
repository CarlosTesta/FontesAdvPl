#include "protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"
#include 'parmtype.ch'


/*/
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
北谀哪哪哪哪穆哪哪哪哪哪履哪哪哪履哪哪哪哪哪哪哪哪哪哪哪履哪哪穆哪哪哪哪哪目北
北矲un噭o    矼yMata103 ?Autor ?Carlos Testa          ?Data 19/12/2017     潮?
北媚哪哪哪哪呐哪哪哪哪哪聊哪哪哪聊哪哪哪哪哪哪哪哪哪哪哪聊哪哪牧哪哪哪哪哪拇北
北?         砇otina de teste da rotina automatica do programa MATA010     潮?
北?         ?com o intuito de testar o consumo de memoria durante a      潮?
北?         ?execucao da rotina por EXECAUTO                             潮?
北媚哪哪哪哪呐哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪拇北
北砋so       ?Validacao do TOTVSTec11                                     潮?
北滥哪哪哪哪牧哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪馁北
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌
/*/
User Function Exec010()
Local _cRandom,_nCnt,_cDescProd,_cCodUnico,_nIniTime,_nMiddleTime
Local _aVetor	:= {}	// vetor de trabalho
Local _cExec010	:= GetPvProfString("STRESS","Exec010","undefined","appserver.ini")
Local _nExec010	:= Iif(!Empty(_cExec010),Val(SubStr(_cExec010,At("/",_cExec010)+1)),10)	// caso sem valor, assume 10
Local _cThread	:= AllTrim(Str(ThreadID()))						// numero da thread para garantir unicidade no nome do arquivo
Local _cSrvIP	:= GetServerIP()								// IP do servidor atual
Local _cSrvPort	:= GetPvProfString("TCP","Port","undefined","appserver.ini")	// Porta do AppServer
Local _cEnvWork	:= GetEnvServer()								// Environment atual de trabalho

Private lMsErroAuto := .F.
Private lMsHelpAuto	:= .T.

RpcSetType( 3 )
PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"

// iremos trabalhar com o tempo M蒁IO DA EXECU敲O DE BLOCOS.
_nIniTime	:= Microseconds()
For _nCnt := 1 to _nExec010
	_cRandom	:= AllTrim(Str(Randomize(1,100000)))
	_cCodUnico	:= AllTrim(StrZero(_nCnt,4)) + "." + _cRandom
	_cDescProd	:= "PRODUTO " + _cCodUnico
		
	//谀哪哪哪哪哪哪哪哪哪哪哪哪哪哪目
	//| Inclus鉶 de Produto          |
	//滥哪哪哪哪哪哪哪哪哪哪哪哪哪哪馁
	_aVetor:= {{"B1_COD"	,_cCodUnico					,Nil},;
	 		  {"B1_CODITE"	,_cCodUnico					,Nil},;
	 		  {"B1_DESC"	,_cDescProd				   	,Nil},;
			  {"B1_TIPO"	,"PA"           			,Nil},; 
			  {"B1_UM"		,"PC"           			,Nil},; 
			  {"B1_LOCPAD"	,"01"           			,Nil},; 
			  {"B1_PRV1"	,10*Val(substr(time(),7,2))	,Nil},;
			  {"B1_GARANT"	,'2'            			,Nil},;
			  {"B1_TE"		,'001'            			,Nil},;
			  {"B1_TS"		,'501'            			,Nil},;
			  {"B1_CODBAR"	,"789"+_cRandom				,Nil} }
	
	//ConOut("In韈io Inclus鉶 | Time: " + Time())
	MSExecAuto({|x,y| Mata010(x,y)},_aVetor,3) //Inclusao

	/*
	If lMsErroAuto
		MostraErro()
	Else
		ConOut("Final Inclus鉶 | Time: " + Time())
		ConOut("")
	Endif 
	*/

Next

// ConOut para Printar o tempo de cada execu玢o em cada passada
ConOut(Repl("-",80))
_nMiddleTime := (Microseconds()-_nIniTime)/_nExec010
ConOut('LOG de Processo "EXEC010" | THREAD: "'+_cThread+'" | Lacos: "'+AllTrim(Str(_nExec010))+'" | Server:"'+_cSrvIP+':'+_cSrvPort+'" | Environment:"'+_cEnvWork+'" | Tempo Medio:"'+ AllTrim(Str(_nMiddleTime))+'" segundos.')
ConOut(Repl("-",80))

RESET ENVIRONMENT

Return(.T.)