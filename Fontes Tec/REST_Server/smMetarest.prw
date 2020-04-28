#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "ISAMQry.CH"


//Nome do job de execu��o ass�ncrona da FIRST API
#DEFINE JOBNAME "ASYNCFIRSTAPI"
//N�mero m�ximo de registro a ser processados em sequ�ncia por ambiente
Static _MAXREGPROC
//Delay de execu��o entre chamadas separadas por ambiente
Static _EXECDELAY

/*/{Protheus.doc} SmMetaREST
Classe para execu��o de requisi��es do Facilitador em segundo plano.

@author thiago.santos
@since 21/06/2016
/*/
CLASS SmMetaREST
	DATA nRecno
	DATA model
	DATA idUrlparam
	DATA Content
	DATA Response

	METHOD New()
	METHOD GetContent()
	METHOD SetResponse()
	METHOD DoPost()

END WSRESTFUL

METHOD New() CLASS SmMetaREST

Return

/*/{Protheus.doc} GetContent
Retorna o conte�do da requisi��o ass�ncrona da FIRST API

@author thiago.santos
@since 21/06/2016
/*/
METHOD GetContent() CLASS SmMetaREST

Return ::Content

/*/{Protheus.doc} SetResponse
Prepara a resposta para ser comitada na tabela ass�ncrona da FIRST API

@author thiago.santos
@since 21/06/2016
/*/
METHOD SetResponse(cResponse) CLASS SmMetaREST

::Response += cResponse

Return

/*/{Protheus.doc} DoPost
Chamada de rest baseado no facilitador em segundo plano

@param cEntity, character, nome da entidade
@param cOperation, character, opera��o: post, put ou delete
@param cGUID, character, id do lote a ser processado
@param cItemId, character, id do lote a ser processado

@author thiago.santos
@since 21/06/2016
/*/
METHOD DoPost(nRecno, cTenantid, cEntity, cOperation, cGUID, cItemId, cId, cData) CLASS SmMetaREST
Local nSelect := Select()
Local bTeste := SysErrorBlock({|e| ConOut("***ERRO DE SISTEMA****" + CRLF + e:ErrorStack)})
Local lRet    := .T.
Local cAPI

//A filial � alterada para o tenantId informado
SmChangeFil(cTenantId)

//A chave deve ser guardada para ser usada como refer�ncia no m�todo SetResponse
::nRecno := nRecno
::model := cEntity
::idUrlParam := cId
::Content := cData
::Response := ""

ConOut("*************************************************")
ConOut("Processando " + cOperation + " " + cEntity)
ConOut("dados: " + cData)
ConOut("*************************************************")
cAPI := GetRealAPI(cEntity)

HTTPSetHeader({}) //Para simular http
If !Empty(cAPI)
	lRet := RestExecute(self, cAPI , cOperation, cId, cData)
Else
	lRet := SmFApiMVC(self, cOperation, cEntity,, 2)
EndIf

CommitREST(self, lRet)
ConOut("*************************************************")
ConOut("Procesos terminado " + IIF(lRet, " com sucesso", " com erro"))
ConOut("*************************************************")

HTTPClearBody()

dbSelectArea(nSelect)
SysErrorBlock(bTeste)

Return lRet

/*/{Protheus.doc} CommitREST
Persiste o resultado da opera��o ass�ncrona de REST

@param self, object, objeto SmMetaREST
@param lresult, boolean, se a opera��o foi ou n�o bem sucedida

@author thiago.santos
@since 21/06/2016
/*/
Static Function CommitREST(self, lResult)
If Recno() != ::nRecno
	dbGoTo(::nRecno)
EndIf

RecLock("Z16", .F.)
Z16_STATUS := IIF(lResult, 1, 2)
Z16_RET    := ::Response
Z16_PROCDT := SmDateTime()
Z16_QRYDT  := ""
MSUnlock()

::Response := ""

Return

/*/{Protheus.doc} RESTAsync
Chamada principal para controle ass�ncrono de execu��es da FIRST API

@author thiago.santos
@since 21/06/2016
/*/
Function RESTAsync()
Local lContinue := .T.
Local nDelay := EXECDELAY()

While !KillApp() .And. lContinue
	SmSQLExec("SELECT Z16_ENV, MAX(Z16_DTHR) MAXDT FROM Z16 WHERE Z16_STATUS = 0 GROUP BY Z16_ENV", "Z16")
	
	If lContinue := (SmHasResult() .And. !Empty(Z16_ENV))
		SCAN
			ConOut("[ASYNCFIRST] PROCESSANDO " + Alltrim(Z16_ENV))
			//A execu��o com startjob s�ncrono � para que a chamada possa ser feita no ambiente correto
			StartJob("SmDoAREST", Alltrim(Z16_ENV), .T., MAXDT)
			Sleep( nDelay )
		ENDSCAN
	Else
		ConOut("[ASYNCFIRST] N�O H� NADA A PROCESSAR")
	EndIf
	dbCloseArea()
EndDo

Return .T.

/*/{Protheus.doc} SmDoAREST
M�todo para execu��o de chamadas ass�ncronas da FIRST API, por ambiente.
O n�mero m�ximo de requisi��es executadas por chamada � definido MAXREGPROC.

@param cMaxDT, character, 

@author thiago.santos
@since 21/06/2016
/*/
Main Function SmDoAREST(cMaxDT)
Local oAREST
Local nProc
Local lContinue

SetVarNameLen(50)
oAREST := SmMetaREST():New()
nProc := MAXREGPROC()

ConOut("[ASYNCFIRST][" + GetEnvServer() + "]Setando ambiente ")

//Primeiramente, � preciso inicializar o ambiente
//Nesta etapa a filial � irrelevante pois a mesma ser� setada conforme mais pra frente
RPCSETENV("01", "01")
dbSelectArea("Z16")
dbSetorder(2)
lContinue := (dbSeek("0" + FWEnvServer()) .And. Z16_DTHR <= cMaxDT)

ConOut("[ASYNCFIRST][" + GetEnvServer() + "]Iniciando processamento de lista ")

While !KillApp() .And. lContinue .And. nProc > 0
	If SimpleLock() //Se n�o conseguir lockar o registro, outra thread j� o est� processando
		ConOut("[ASYNCFIRST][" + GetEnvServer() + "]Processando " + cValToChar(Recno()))
		//Para refletir o app e usu�rio do momento que o registro de fila foi incluso
		FWAppControl(Z16_MSAPPI, Z16_MSUSRI)
		oAREST:DoPost(Recno(), Z16_FILIAL, Alltrim(Z16_ENTITY), Lower(Alltrim(Z16_OPER)) ;
					, Alltrim(Z16_GUID), Alltrim(Z16_ITEM), Alltrim(Z16_ENT_ID), Z16_DATA)
		Sleep(1)
		lContinue := (dbSeek("0" + FWEnvServer()) .And. Z16_DTHR <= cMaxDT)
		nProc--
	Else
		//Para n�o quebrar ordem de execu��o, como h� outra thread processando o ambiente, aborta
		Exit
	EndIf
End

Disconnect()
If nProc < MAXREGPROC()
	//Limpar mem�ria se pelo menos um registro foi processado
	ReleaseProgs()
EndIf

Return

/*/{Protheus.doc} SmChangeFil
M�todo para execu��o de chamadas ass�ncronas da FIRST API, por ambiente.
O n�mero de requisi��es executadas por 

@author thiago.santos
@since 21/06/2016
/*/
Function SmChangeFil(cTenantid)

//Para mudar de filial
cEmpAnt := Left(cTenantid, 2)
cFilAnt := cTenantid
cAliasEsp := GetAliasEsp()

Return

/*/{Protheus.doc} AsyncIniEnd
Fun��o para uso no IPC, nas etapas de incializa��o e finaliza��o do job de execu��es ass�ncronas da FIRST API

@author thiago.santos
@since 21/06/2016
/*/
Function AsyncIniEnd()
Return .T.

/*/{Protheus.doc} FIRSTHTTP
Fun��o para inicializa��o do servi�o de REST do FIRST API

@author thiago.santos
@since 21/06/2016
/*/
Main Function FIRSTHTTP()
Local aInstances := GetPvProfString("DOMAINDB", "ASYNCInstances", "", GetAdv97())
Local cManualJob

If !Empty(aInstances) .And. !FWJobActive(JOBNAME)
	aInstances := StrToKArr(aInstances, ",")
	While  Len(aInstances)<4
		aadd(aInstances,"1")
	EndDo

	cManualJob := "ManualJob"
	&cManualJob.(JOBNAME /*JobName*/,;
				GetEnvServer() /*Environment*/,;
				"IPC" /*Type*/,;
				"AsyncIniEnd" /*OnStart*/,;
				"RESTAsync" /*OnConnect*/,;
				"AsyncIniEnd" /*OnExit*/,;
				"" /*SessionKey*/,;
				60 /*RefreshRate*/,;
				Val(aInstances[1]) /*Instances min*/,;
				Val(aInstances[2]) /*Instances max*/,;
				Val(aInstances[3]) /*Instances minfree*/,;
				Val(aInstances[4]) /*Instances inc*/)
	Sleep(100)
	While !IpcGo(JOBNAME)
		ConOut("Tentando inicializar " + JOBNAME)
		Sleep(100)
	EndDo
EndIf

Return	HTTP_START()

Static Function MAXREGPROC()
Default _MAXREGPROC := Val(GetPvProfString("DOMAINDB", "ASYNCStep", "30", GetAdv97()))
Return _MAXREGPROC

Static Function EXECDELAY()
Default _EXECDELAY := Val(GetPvProfString("DOMAINDB", "ASYNCDelay", "100", GetAdv97()))

Return _EXECDELAY

Static Function RestExecute(self, cAPI , cAction , cId, cData)
Local lReturn  := .F.
Local aURLParms := {}
Local aFault

If !Empty(cId)
	aAdd(aURLParms, cId)
EndIf

HTTPSetHeader({{"_BODY_", cData}})
//----------------------------------------
// Inicializa o servi�o  
//----------------------------------------
__REST := WSClassNew(cAPI)
__REST:aClassMethod := RestLoadMethod(cAPI)
__REST:aClassData := RestLoadData(cAPI)

__REST:aURLParms := aURLParms

If __REST:HasMethod(cAction, aURLParms)
	//----------------------------------------
	// Executa a API Rest  
	//----------------------------------------
	If !(lReturn := __REST:CallMethod())
		aFault := GetRestFault()
		//{__WS_FAULT_CODE, __WS_FAULT_MSG, __WS_FAULT_JSON}
		HTTPSetStatus(aFault[1], aFault[2])
	EndIf
Else
	SetRestFault(404)
EndIf

::SetResponse(HTTPGetBody())

Return lReturn

Static Function GetRealAPI(cEntity)
Local cRestName

RestLoadClass()

cRestName := FWRESTCLSNAME("first/api/v1/" + cEntity)
If cRestName == "REST_FIRST" //APIs do facilitador tratamos a parte
	cRestname := nil
Endif

Return cRestName

/*/{Protheus.doc} SYNCFIRST
Fun��o para inicializa��o do servi�o de REST do FIRST API

@author thiago.santos
@since 21/06/2016
/*/
Main Function SYNCFIRST()
Local aInstances := GetPvProfString("DOMAINDB", "ASYNCInstances", "", GetAdv97())
Local cManualJob

ConOut("JOB SYNCFIRST")
If !Empty(aInstances) .And. !FWJobActive(JOBNAME)
	ConOut("INICIANDO JOB SYNCFIRST")
	aInstances := StrToKArr(aInstances, ",")
	While  Len(aInstances)<4
		aadd(aInstances,"1")
	EndDo

	cManualJob := "ManualJob"
	&cManualJob.(JOBNAME /*JobName*/,;
				GetEnvServer() /*Environment*/,;
				"IPC" /*Type*/,;
				"AsyncIniEnd" /*OnStart*/,;
				"RESTAsync" /*OnConnect*/,;
				"AsyncIniEnd" /*OnExit*/,;
				"" /*SessionKey*/,;
				60 /*RefreshRate*/,;
				Val(aInstances[1]) /*Instances min*/,;
				Val(aInstances[2]) /*Instances max*/,;
				Val(aInstances[3]) /*Instances minfree*/,;
				Val(aInstances[4]) /*Instances inc*/)
	Sleep(100)
	While !IpcGo(JOBNAME)
		ConOut("Tentando inicializar " + JOBNAME)
		Sleep(100)
	EndDo

	ConOut("IPCGO JOB SYNCFIRST")
Else
	IpcGo(JOBNAME)
EndIf


Return	.T.