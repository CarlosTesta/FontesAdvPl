#Include 'Protheus.ch'

// Recupera um socket da fila para fazer o tratamento da conexão.
// Essa função deve ser chamada por cada thread de trabalho.
User Function GTConn(cTCPId)
Local nMAX_BUFFER:= 10240
Local cOutBuffer := ''
Local nRet := 0
Local cInBuffer := ''
Local nRetAll := 0
Local cInBufferAll := ''
Local oHttpParser := nil
Local bRet := .F.
Local aHeaders := {}
Local aHeader := {}
Local nRetHttpParser := 0
Local nReadBytes := 0
local nI := 0
local nJ := 0
local MyStr := ''
Local lError := .T.
Local cJsonRcv	:= ""
Local cMsgSend
Local oObjConn

While .T.
	
	cOutBuffer := ''
	nRet := 0
	nRetAll := 0
	cInBufferAll := ''
	
	bRet := .F.
	aHeaders := {}
	aHeader := {}
	nRetHttpParser := 0
	nReadBytes := 0
	
	nI := 0
	nJ := 0
	MyStr := ''
	
	// Recupera objeto da conexão
	oObjConn := Nil
	
	while ( oObjConn == Nil)
		oObjConn := GetTcpObj(cTCPId)
	End
	
	oHttpParser := tHttpParser():New()
	lError := .T.
	While .T.
		//oHttpParser := tHttpParser():New()
		cInBuffer := space(nMAX_BUFFER)
		nRet := oObjConn:Receive(cInBuffer, nMAX_BUFFER, 10)

		if nRet < 0
			exit
		Endif
		
		cInBufferAll := cInBufferAll + cInBuffer
		nRetAll := nRetAll + nRet
		
		aHeaders := {}
		bRet = oHttpParser:Http_Parser(cInBufferAll, nRetAll, @aHeaders, @nRetHttpParser, @nReadBytes)
		
		If ! bRet
			If nRetHttpParser == 0 // Parser ok mas incompleto, tenta continuar lendo
				conout("Parser ok mas incompleto !!!")
				loop
			Endif
		Else
			For nI := 1 to 1
				aHeader = aHeaders[nI]
				MyStr := "Header: " + AllTrim(Str(nI)) + " itens: " + AllTrim(Str(Len(aHeader))) + " Campo: "
				For nJ := 1 to Len(aHeader)
					MyStr := MyStr + (aHeader[nJ]) + " | "
				Next
			Next
			//conout("== VARINFO DO RECEIVE ==========")
			//varinfo("Header",aHeaders[8][2])
			//conout("== VARINFO DO RECEIVE ==========")
			//conout()
			//conout()
		Endif

		cJsonRcv	:= aHeaders[8][2]
		
		// cJsonRcv	:= '{"ROWS": [{"FABRICA": "VW","NOME": "FUSCA","MOTOR": "BOXER 1.2/BOXER 1.3/zzzz 1.5/BOXER 1.6"}]}'
		//conout("")
		//conout("cJsonRcv >>" + cJsonRcv)

		cMsgSend	:= U_MyTstJS(cJsonRcv)
		//cMsgSend	:= cJsonRcv 
		
		//conout("cMsgSend >>" + cMsgSend)
		//conout("")
				
		cOutBuffer := "HTTP/1.1 200 OK"+CRLF
		cOutBuffer += "Content-Type: text/html"+CRLF
		cOutBuffer += "Content-Length: " + AllTrim(Str(Len(cMsgSend))) +CRLF+CRLF
		//cOutBuffer += "TESTAO"	// original
		cOutBuffer += cMsgSend
		nRetAll := len(cOutBuffer)
		
		nRet := oObjConn:Send(cOutBuffer, nRetAll)
		if nRet <= 0
			exit
		Endif
		
		lError := .F.
		cInBufferAll := ''
		nRetAll := 0
		exit

		//cMsgSend := NIL		// começou em 79.000
		
	Enddo
	
	aHeaders := nil
	aHeader := nil

	If (oObjConn != NIL)
		// Fecha o socket desta conexao ..
		FreeObj(oObjConn)
	Endif
	
	FreeObj(oHttpParser)
	
	exit
end

return .T.

// Essa função recupera um socket da fila pelo Id de prefixo "MASTER_" e o coloca novamente na fila, com Id de prefixo "TCP_".
User Function GTMaster()
Local nSeq := 0, cId, oObj, cKey
While ! KillApp()
	// Pega da fila
	cId  := "MASTER_" + strzero(++nSeq, 6)
	oObj := Nil
	while ( oObj == nil)
		oObj := GetTcpObj(cId)
	end
	
	// Coloca novamente na fila
	cKey := "TCP_" + strzero(nSeq, 6)
	SetTcpObj(cKey, oObj)
	SmartJob("U_GTConn", GetEnvServer(), .F., cKey)
	//StartJob("U_GTConn", GetEnvServer(), .F., cKey)
End
Return

// Thread principal, de accept.
User Function GTIpc()
Local nSeq := 0
Local cTCPIdx := time()
Local cTCPMaster := ''

Local oSockSrv
Local nPort := 9001
Local oObjConn
Local nErrCode,cErrMsg := ''

StartJob("U_GTMaster", GetEnvServer(), .F.)

oSockSrv := tSocketSrv():New()
If !oSockSrv:StartTcp(nPort)
	nErrCode := oSockSrv:GetError(@cErrMsg)
	return
Endif

oObjConn := NIL
While !killapp()
	
	If oObjConn = NIL
		oObjConn := oSockSrv:Accept( 0 )
	Endif
	
	If oObjConn = NIL
		nErrCode := oSockSrv:GetError(@cErrMsg)
		loop
	Endif
	
	// Cria identificador unico para esta conexão
	// e salva objeto da conexao na memoria
	cTCPMaster := "MASTER_"+ strzero(++nSeq, 6)
	SetTcpObj(cTCPMaster, oObjConn)
	
	oObjConn := NIL
	cTCPIdx := NIL
	
Enddo

// Fecha o Socket Server
oSockSrv:Close()

return .T.


User Function MyTstJS2()
Local _cMsg := '{"ROWS":[{"NOME":"FUSCA","MOTOR":"BOXER 1.2/kikiki 1.3/BOXER 1.5/BOXER 1.6","FABRICA":"VW"},{"NOME":"Fissori","MOTOR":"3 tempos 38BHP","FABRICA":"Wemagete"}]}'
Local _cRetMy

for _cCnt:=1 to 1000
	_cRetMy := U_MyTstJS(_cMsg)
	//inkey(10)
Next 
//conout("SAI !!!!" + _cRetMy)

Return


User Function MyTstJS(cJsonSend)
Local cRetorno	//,nCnt
local wrk := {}
Local JsonObj := JsonObject():new()
	
	if (JsonObj:FromJson(cJsonSend) == .F.)
		conout("JSON com erro !!")
		return("Error JSON")
	endif
	
	wrk := JsonObj:ToJson()

    wrk := JsonObject():new()
    wrk['FABRICA']	:= 'Wemagete'
    wrk['NOME']		:= 'Fissori'
    wrk['MOTOR']		:= '3 tempos 38BHP'

	cWrkRet := wrk:ToJson()

	AADD(JsonObj['ROWS'], wrk)
	cRetorno := JsonObj:ToJson()

	FreeObj(JsonObj)

return(cRetorno)
