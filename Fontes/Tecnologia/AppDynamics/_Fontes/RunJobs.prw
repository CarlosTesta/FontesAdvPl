#include "protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"

User Function MyRunJob()
Local _cUIDCtl	:= "AppDTst"
Local lRetRun	:= VarSetUID(_cUIDCtl)
Local _cKeyCTL	:= "THR0001"
Local _cService := Iif(IsSrvUnix(),"appsrvlinux","appserver.exe")

lRetRun := VarClean(_cUIDCtl)
lRetRun := VarSetUID(_cUIDCtl)

lRetRun := VarSetA(_cUIDCtl,_cKeyCTL,{''})     // flag para diferenciar a thread em processo e aquela que já terminou
U_RunIns(_cUIDCtl,_cKeyCTL,20,_cService,"MATA010",.T.)
lRetRun := VarClean(_cUIDCtl)

Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³MyMata103 ?Autor ?Carlos Testa          ?Data 19/12/2017     ³±?
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±?         ³Rotina de teste da rotina automatica do programa MATA010     ³±?
±±?         ?com o intuito de testar o consumo de memoria durante a      ³±?
±±?         ?execucao da rotina por EXECAUTO                             ³±?
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ?Validacao do TOTVSTec11                                     ³±?
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function RunIns(_cUIDCtl,_cKeyCTL,_nInserts,_cService,_cRotina,_lDebug)
Local _cRandom,_nCnt,_cDescProd,_cCodUnico,lRetRun
Local _nMiddleTime,_cIniTime,_cTimeRun
Local _aSrvData	:= {}
Local _aVetor	:= {}											// vetor de dados para a ExecAuto
Local _aTimeRun	:= {}											// Array contendo os dados de hardware
local _nCntMemo	:= 1											// Contador de laços para medir a memoria durante o tempo de inserçao
lOCAL _nOper	:= 1											// Contador de laços para saber quantas vezes foi tomada o consumo de memória
local _nMemoCnt	:= Round((_nInserts * 0.2),0)					// Limite para emitir contagem, será efetuado à cada 10% de processamento da base
Local _cSrvIP	:= GetServerIP()								// IP do servidor atual
Local _cEnvWork	:= GetEnvServer()								// Environment atual de trabalho
Local _cThread	:= AllTrim(Str(ThreadID()))						// será usado para criar uma chave única de produto, evitando duplicidades
Local _cSrvPort	:= GetPvProfString("TCP","Port","undefined","appserver.ini")	// Porta do AppServer
Local _cVersion	:= GetSrvVersion()								// versão do binário em uso

DEFAULT _lDebug	:= .F.	// SOMENTE PARA FACILITAR O DEBUG E EVITAR O COMENTA/DESCOMENTA LINHAS

Private lMsErroAuto := .F.
Private lMsHelpAuto	:= .T.

RpcSetType( 3 )
If IsSrvUnix()
	// Para Testes no Linux
	PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"
Else
	// Para Testes na minha máquina

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT"
EndIf

// iremos trabalhar com o tempo MÉDIO DA EXECUÇÃO DE BLOCOS.
_cIniTime	:= Time()	// Tempo Inicial do processo
_cTimeRun	:= Time()	// tempo da ultima tomada de valores de hardware, usado para mostrar a variação de tempo entre cada bloco de inserts
_aSrvData	:= U_PegaVal(_cService)

// Estrutura do Array ==> Operação / Time / Processador / Memoria
AADD(_aTimeRun,{_cRotina,_cVersion,_cKeyCTL,AllTrim(Str(_nInserts)),"0000",Time(),ElapTime(_cIniTime,_cTimeRun),_aSrvData[1],_aSrvData[2],_aSrvData[3]})	// opção "0000" - registro INICIAL de processo
For _nCnt := 1 to _nInserts
	If (_nCntMemo > _nMemoCnt) .OR. (_nCnt == _nInserts)
		_aSrvData	:= U_PegaVal(_cService)		// Return({CProcSrv,CMemoSrv,CMemoApp})
		// AADD(_aRetMemo,StrTokArr2(StrTokArr2(_cValMemo,"  ",.f.)[4]," ",.f.)[1])
		// '"ROTINA";"VERSION";"THREAD";"INSERTS";"OPER";"TIME";"ELAPTIME";"CPU";"MEMOHDW";"MEMOAPP"'
		AADD(_aTimeRun,{_cRotina,_cVersion,_cKeyCTL,AllTrim(Str(_nMemoCnt)),StrZero(_nOper,4),Time(),ElapTime(_cTimeRun,Time()),_aSrvData[1],_aSrvData[2],_aSrvData[3]})
		_cTimeRun	:= Time()
		_nCntMemo	:= 1
		_nOper++

		If _lDebug
			// somente pra debug
			--ConOut(Repl("-",30))
			--ConOut("THREAD: " + _cKeyCTL + " | OPER: " + StrZero(_nOper,4))
			--ConOut(Repl("-",30))
			--ConOut()
		EndIf
	EndIf

	_cRandom	:= AllTrim(Str(Randomize(1,1000)))

	If AllTrim(_cRotina) == 'MATA010'
		_cCodUnico	:= _cThread + "." + AllTrim(StrZero(_nCnt,4)) + "." + _cRandom
		_cDescProd	:= "PROD_" + _cCodUnico
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//| Inclusão de Produto          |            
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		_aVetor:= {{"B1_COD"		,_cCodUnico					,Nil},;
					{"B1_CODITE"	,_cCodUnico					,Nil},;
					{"B1_DESC"		,_cDescProd				   	,Nil},;
					{"B1_TIPO"		,"PA"           			,Nil},; 
					{"B1_UM"		,"PC"           			,Nil},; 
					{"B1_LOCPAD"	,"01"           			,Nil},; 
					{"B1_PRV1"		,10*Val(substr(time(),7,2))	,Nil},;
					{"B1_GARANT"	,'2'            			,Nil},;
					{"B1_TE"		,'001'            			,Nil},;
					{"B1_TS"		,'501'            			,Nil},;
					{"B1_CODBAR"	,"789"+_cRandom				,Nil} }
		
		//--ConOut("Início Inclusão | Time: " + Time())
		MSExecAuto({|x,y| Mata010(x,y)},_aVetor,3) //Inclusao
	ElseIf AllTrim(_cRotina) == 'FINA040'
		_cHistorico	:= "EXECAUTO em " + DTOC(dDataBase)  + " as " + Time()
		_cCodUnico	:= _cThread + AllTrim(StrZero(_nCnt,4)) + _cRandom
		_aVetor  := {	{"E1_PREFIXO"	,"NF "           	,Nil},;
						{"E1_NUM"		,_cCodUnico         ,Nil},;
						{"E1_PARCELA"	,"1"             	,Nil},;
						{"E1_TIPO"		,"DP "          	,Nil},;
						{"E1_NATUREZ"	,"NFE"      		,Nil},;
						{"E1_CLIENTE"	,"000001"        	,Nil},;
						{"E1_LOJA"		,"01"            	,Nil},;
						{"E1_HIST"		,_cHistorico       	,Nil},;
						{"E1_EMISSAO"	,dDataBase       	,Nil},;
						{"E1_VENCTO"	,dDataBase       	,Nil},;
						{"E1_VENCREA"	,dDataBase      	,Nil},;
						{"E1_VALOR"		,Randomize(1,99999)	,Nil }}
		MSExecAuto({|x,y| Fina040(x,y)},_aVetor,3) //Inclusao
	ElseIf AllTrim(_cRotina) == 'FINA050'
		_cHistorico := "EXECAUTO em " + DTOC(dDataBase)  + " as " + Time()
		_cCodUnico	:= _cThread + AllTrim(StrZero(_nCnt,4)) + _cRandom
		_aVetor :={	{"E2_PREFIXO"		,'NF '				,Nil},;
						{"E2_NUM"		,_cCodUnico			,Nil},;
						{"E2_PARCELA"	,'1'				,Nil},;
						{"E2_TIPO"		,'DP '				,Nil},;			
						{"E2_NATUREZ"	,'NFE'				,Nil},;
						{"E2_FORNECE"	,'000001'			,Nil},; 
						{"E2_LOJA"		,'01'				,Nil},;      
						{"E2_HIST"		,_cHistorico       	,Nil},;
						{"E2_EMISSAO"	,dDataBase			,NIL},;
						{"E2_VENCTO"	,dDataBase			,NIL},;					 
						{"E2_VENCREA"	,dDataBase			,NIL},;					 					
						{"E2_VALOR"		,Randomize(1,99999)	,Nil}}
		MSExecAuto({|x,y,z| Fina050(x,y,z)},_aVetor,,3) //Inclusao
	Else
		ConOut("<<" + _cRotina + ">> ainda não implementados. Analisar !!!")
	EndIf

	// If lMsErroAuto
	// 	MostraErro()
	// Else
	// 	--ConOut("Final Inclusão | Time: " + Time())
	// 	--ConOut("")
	// Endif 

	_nCntMemo++		// contador de inserções para tomada de valores de hardware

Next
_aSrvData	:= U_PegaVal(_cService)
AADD(_aTimeRun,{_cRotina,_cVersion,_cKeyCTL,AllTrim(Str(_nInserts)),"9999",Time(),ElapTime(_cIniTime,Time()),_aSrvData[1],_aSrvData[2],_aSrvData[3]})	// opção "9999" - registro FINAL de processo

If _lDebug
	// --ConOut para Printar o tempo de cada execução em cada passada, 
	ConOut(Repl("=",80))
	ConOut("LOG de Processo. Server:" + _cSrvIP + " | Porta:" + _cSrvPort + " | Environment: " + _cEnvWork)
	ConOut("_cUIDCtl:" + _cUIDCtl  + " | _cKeyCTL:" + _cKeyCTL + " | ElalTime: " + ElapTime(_cIniTime,Time()) )
	ConOut(Repl("-",80))
	VarInfo("",_aTimeRun)
	ConOut(Repl("=",80))
Endif

// grava o Array de dados coletados na variável global 
// para ser composto um arquivo único no final de todo processamento
lRetRun := VarSetA(_cUIDCtl,_cKeyCTL,_aTimeRun)

RESET ENVIRONMENT

Return(.T.)

User Function PegaVal(_cService)
Local nResp,nRet,nSize,oJson
Local cInBuffer	:= space(20480)
Local oSktData	:= tSocketClient():New()
Local nTimeOut	:= 3
Local cParam	:= "" + Chr(232)
Local CMemoApp	:= "0"
Local CProcSrv	:= "0"
Local CMemoSrv	:= "0"
Local _aRetMemo	:= {}
Local _cIpSrv	:= Iif(IsSrvUnix(),"10.171.67.42","10.171.67.43")

DEFAULT _cService := Iif(IsSrvUnix(),"appsrvlinux_no_bt","appserver.exe")	// somente para debug

nResp	:= oSktData:Connect( 27000, _cIpSrv , nTimeOut )
nSize	:= oSktData:Send( cParam )
nRet	:= oSktData:Receive(cInBuffer, Len(cInBuffer), nTimeOut)

If (nRet > 0 )
	// limpeza do header http da msg
	cInBuffer := substr(cInBuffer,at("{",cInBuffer),len(cInBuffer))
	oJson := JsonObject():new()
    oJson:fromJson(cInBuffer)
	For nCnt := 1 to Len(oJson["services"])
		If oJson["services"][nCnt]["bin_name"] == _cService
			CMemoApp := AllTrim(Str(NoRound(oJson["services"][nCnt]["mem_work"] / 1024)))
		EndIf
	Next
	CMemoSrv := GetSrvMemInfo()
	AADD(_aRetMemo,StrTokArr2(StrTokArr2(CMemoSrv,"  ",.f.)[4]," ",.f.)[1])
	CMemoSrv := _aRetMemo[Len(_aRetMemo)]
	CProcSrv := AllTrim(Str(oJson["machine"][1]["cpu"]))
EndIf

If oSktData:IsConnected()
	// ConOut("Desconectando Cliente. Saindo.")
	oSktData:CloseConnection()
EndIf

FreeObj(oJson)
FreeObj(oSktData)

Return({CProcSrv,CMemoSrv,CMemoApp})