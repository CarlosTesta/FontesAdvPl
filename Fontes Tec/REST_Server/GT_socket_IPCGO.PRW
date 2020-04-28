#Include 'Protheus.ch'

// Essa função recupera um socket da fila pelo Id de prefixo "MASTER_" e o coloca novamente na fila, com Id de prefixo "TCP_".
User Function GTMaster()
Local nSeq := 0
lOCAL cId, oObj, cKey, nRet,cOutBuffer
 
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
	
End
Return

// Recupera um socket da fila para fazer o tratamento da conexão.
// Essa função deve ser chamada por cada thread de trabalho.

User Function GTConn(cTCPId)
Local nMAX_BUFFER:= 10240
Local cOutBuffer := ''
Local nRet := 0
Local cInBuffer := ''
Local nRetAll := 0
Local cInBufferAll := ''
Local oHttpParser
Local bRet := .F.
Local aHeaders := {}
Local aHeader := {}
Local nRetHttpParser := 0
Local nReadBytes := 0

local nI := 0
local nJ := 0
local str := ''

Local lError := .T.

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
	str := ''
	
	// Recupera objeto da conexão
	oObjConn := Nil
	
	while ( oObjConn == Nil)
		oObjConn := GetTcpObj(cTCPId)
	End
	
	oHttpParser := tHttpParser():New()
	lError := .T.
	While .T.
		cInBuffer := space(nMAX_BUFFER)
		nRet := oObjConn:Receive(cInBuffer, nMAX_BUFFER, 10)
		if nRet < 0
			exit
		Endif
		
		IF nRet == 0
			exit
		Endif
		
		cInBufferAll := cInBufferAll + cInBuffer
		nRetAll := nRetAll + nRet
		
		aHeaders := {}
		bRet = oHttpParser:Http_Parser(cInBufferAll, nRetAll, @aHeaders, @nRetHttpParser, @nReadBytes)
		
		If ! bRet
			If nRetHttpParser == 0 // Parser ok mas incompleto, tenta continuar lendo
				loop
			Endif
		Else
			For nI := 1 to 1
				aHeader = aHeaders[nI]
				str := "Header: " + AllTrim(Str(nI)) + " itens: " + AllTrim(Str(Len(aHeader))) + " Campo: "
				For nJ := 1 to Len(aHeader)
					str := str + (aHeader[nJ]) + " | "
				Next
			Next
		Endif
		
		cOutBuffer := "HTTP/1.1 200 OK"+CRLF
		cOutBuffer += "Content-Type: text/html"+CRLF
		cOutBuffer += "Content-Length: 6"+CRLF+CRLF
		cOutBuffer += "TESTAO"
		nRetAll := len(cOutBuffer)
		if nRet <= 0
			exit
		Endif
		
		lError := .F.
		cInBufferAll := ''
		nRetAll := 0
		exit
	Enddo
	
	If (oObjConn != NIL)
		// Fecha o socket desta conexao ..
		oObjConn:Close()
		oObjConn := NIL
	Endif
	
	oHttpParser := NIL
	
	exit
end

return .T.


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

