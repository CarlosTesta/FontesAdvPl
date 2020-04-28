#include "protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"
#include 'parmtype.ch'


/*/
������������������������������������������������������������������������������
��������������������������������������������������������������������������Ŀ��
���Fun��o    �MyMata103 ?Autor ?Carlos Testa          ?Data 19/12/2017     ��?
��������������������������������������������������������������������������Ĵ��
��?         �Rotina de teste da rotina automatica do programa MATA010     ��?
��?         ?com o intuito de testar o consumo de memoria durante a      ��?
��?         ?execucao da rotina por EXECAUTO                             ��?
��������������������������������������������������������������������������Ĵ��
���Uso       ?Validacao do TOTVSTec11                                     ��?
���������������������������������������������������������������������������ٱ�
������������������������������������������������������������������������������
������������������������������������������������������������������������������
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

// iremos trabalhar com o tempo M�DIO DA EXECU��O DE BLOCOS.
_nIniTime	:= Microseconds()
For _nCnt := 1 to _nExec010
	_cRandom	:= AllTrim(Str(Randomize(1,100000)))
	_cCodUnico	:= AllTrim(StrZero(_nCnt,4)) + "." + _cRandom
	_cDescProd	:= "PRODUTO " + _cCodUnico
		
	//������������������������������Ŀ
	//| Inclus�o de Produto          |
	//��������������������������������
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
	
	//ConOut("In�cio Inclus�o | Time: " + Time())
	MSExecAuto({|x,y| Mata010(x,y)},_aVetor,3) //Inclusao

	/*
	If lMsErroAuto
		MostraErro()
	Else
		ConOut("Final Inclus�o | Time: " + Time())
		ConOut("")
	Endif 
	*/

Next

// ConOut para Printar o tempo de cada execu��o em cada passada
ConOut(Repl("-",80))
_nMiddleTime := (Microseconds()-_nIniTime)/_nExec010
ConOut('LOG de Processo "EXEC010" | THREAD: "'+_cThread+'" | Lacos: "'+AllTrim(Str(_nExec010))+'" | Server:"'+_cSrvIP+':'+_cSrvPort+'" | Environment:"'+_cEnvWork+'" | Tempo Medio:"'+ AllTrim(Str(_nMiddleTime))+'" segundos.')
ConOut(Repl("-",80))

RESET ENVIRONMENT

Return(.T.)