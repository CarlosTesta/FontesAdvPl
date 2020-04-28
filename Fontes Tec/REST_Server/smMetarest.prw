#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "ISAMQry.CH"


//Nome do job de execução assíncrona da FIRST API
#DEFINE JOBNAME "ASYNCFIRSTAPI"
//Número máximo de registro a ser processados em sequência por ambiente
Static _MAXREGPROC
//Delay de execução entre chamadas separadas por ambiente
Static _EXECDELAY

/*/{Protheus.doc} SmMetaREST
Classe para execução de requisições do Facilitador em segundo plano.

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
Retorna o conteúdo da requisição assíncrona da FIRST API

@author thiago.santos
@since 21/06/2016
/*/
METHOD GetContent() CLASS SmMetaREST

Return ::Content

/*/{Protheus.doc} SetResponse
Prepara a resposta para ser comitada na tabela assíncrona da FIRST API

@author thiago.santos
@since 21/06/2016
/*/
METHOD SetResponse(cResponse) CLASS SmMetaREST

::Response += cResponse

Return

/*/{Protheus.doc} DoPost
Chamada de rest baseado no facilitador em segundo plano

@param cEntity, character, nome da entidade
@param cOperation, character, operação: post, put ou delete
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

//A filial é alterada para o tenantId informado
SmChangeFil(cTenantId)

//A chave deve ser guardada para ser usada como referência no método SetResponse
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
Persiste o resultado da operação assíncrona de REST

@param self, object, objeto SmMetaREST
@param lresult, boolean, se a operação foi ou não bem sucedida

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
Chamada principal para controle assíncrono de execuções da FIRST API

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
			//A execução com startjob síncrono é para que a chamada possa ser feita no ambiente correto
			StartJob("SmDoAREST", Alltrim(Z16_ENV), .T., MAXDT)
			Sleep( nDelay )
		ENDSCAN
	Else
		ConOut("[ASYNCFIRST] NÃO HÁ NADA A PROCESSAR")
	EndIf
	dbCloseArea()
EndDo

Return .T.

/*/{Protheus.doc} SmDoAREST
Método para execução de chamadas assíncronas da FIRST API, por ambiente.
O número máximo de requisições executadas por chamada é definido MAXREGPROC.

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

//Primeiramente, é preciso inicializar o ambiente
//Nesta etapa a filial é irrelevante pois a mesma será setada conforme mais pra frente
RPCSETENV("01", "01")
dbSelectArea("Z16")
dbSetorder(2)
lContinue := (dbSeek("0" + FWEnvServer()) .And. Z16_DTHR <= cMaxDT)

ConOut("[ASYNCFIRST][" + GetEnvServer() + "]Iniciando processamento de lista ")

While !KillApp() .And. lContinue .And. nProc > 0
	If SimpleLock() //Se não conseguir lockar o registro, outra thread já o está processando
		ConOut("[ASYNCFIRST][" + GetEnvServer() + "]Processando " + cValToChar(Recno()))
		//Para refletir o app e usuário do momento que o registro de fila foi incluso
		FWAppControl(Z16_MSAPPI, Z16_MSUSRI)
		oAREST:DoPost(Recno(), Z16_FILIAL, Alltrim(Z16_ENTITY), Lower(Alltrim(Z16_OPER)) ;
					, Alltrim(Z16_GUID), Alltrim(Z16_ITEM), Alltrim(Z16_ENT_ID), Z16_DATA)
		Sleep(1)
		lContinue := (dbSeek("0" + FWEnvServer()) .And. Z16_DTHR <= cMaxDT)
		nProc--
	Else
		//Para não quebrar ordem de execução, como há outra thread processando o ambiente, aborta
		Exit
	EndIf
End

Disconnect()
If nProc < MAXREGPROC()
	//Limpar memória se pelo menos um registro foi processado
	ReleaseProgs()
EndIf

Return

/*/{Protheus.doc} SmChangeFil
Método para execução de chamadas assíncronas da FIRST API, por ambiente.
O número de requisições executadas por 

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
Função para uso no IPC, nas etapas de incialização e finalização do job de execuções assíncronas da FIRST API

@author thiago.santos
@since 21/06/2016
/*/
Function AsyncIniEnd()
Return .T.

/*/{Protheus.doc} FIRSTHTTP
Função para inicialização do serviço de REST do FIRST API

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
// Inicializa o serviço  
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
Função para inicialização do serviço de REST do FIRST API

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