#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'PARMTYPE.CH'
#INCLUDE 'TBICONN.CH'
 
#DEFINE VERSAO V1.0
#DEFINE DEFAULT_KV_IP   "127.0.0.1"
#DEFINE DEFAULT_KV_PORT 6379

#DEFINE STR0001 "KV ERROR CONNECT! N�o foi poss�vel se conectar so KV. Verifique os dados ou avise ao Administrador do ambiente."
#DEFINE STR0002 "KV ERROR CONNECT ON COMMAND RUN! N�o existe conex�o com o KV."
#DEFINE STR0003 "KV ERROR ON COMMAND RUN! Execu��o de Query com erro."
#DEFINE STR0004 "KV ERROR ON APPEND! Erro ao inserir comandos ao PIPELINE."
#DEFINE STR0005 "KV ERROR ON GETREPLY! Erro ao receber resposta do PIPELINE."

//-------------------------------------------------------------------
/*/{Protheus.doc} tTecKVClient
Defini��o da Classe: Classe de camada para acesso a KV desenvolvido pela Equipe de Tecnologia TOTVS

Objeto para auxiliar na abstra��o e consumo do banco de dados KV
com o intuito de otimizar KVs e processos que exigem grande velocidade
no armazenamento/atualiza��o e/ou recupera��o de dados. 
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Class tTecKVClient From tRedisClient
Data   cKVSrv
Data   nKVPort
Data   KVOnConnected
Data   cCmdKVRun
Data   xCmdSQLResult
Data   cCmdSQLError
Data   lHasConnError
Data   cHasConnError
Data   lShowConnError
Data   lHasCMDError
Data   lShowCMDError

// M�todos de Controle
Method New() Constructor 
Method KVOpenConn(cKVSrv,nKVPort)
Method KVCloseConn()
Method KVIsConnected()
Method KVObjDestroy()

// M�todos de Execu��o
Method KVDel()
Method KVSet()
Method KVAppend()
Method KVRunCmdExec()
Method KVRunGetReply()
Method KVSetNX()
Method KVGet()
Method KVGetSet()
Method KVHMSet()
Method KVHMGet()
Method KVHMGetAll()
Method KVSelectDB()
Method KVHINCR()
Method KVIncrFloat()

EndClass
 
//-------------------------------------------------------------------
/*/{Protheus.doc} New
Construtor da Classe
 
@param   cKVSrv  String para conex�o com o KV
@param   nKVPort Porta para conex�o com o KV
 
@return oSelf      Objeto de conex�o criado
 
@obs Aqui ainda n�o foi aberta a conex�o propriamente, apenas criada a classe.
 
@sample
//
// Inst�ncia da Classe de Conexao com o KV para uso como KV de dados
//
//     oKVClient := tTecKVClient():New()
//
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method New() Class tTecKVClient
:new()

// Default�s da conex�o
::lHasConnError  := .F.
::lShowConnError := .F.

Return self

//-------------------------------------------------------------------
/*/{Protheus.doc} KVOpenConn()
M�todo de Controle: Estabelece uma conex�o TCP com KV Local / Remoto.
			Caso omitidos os parametros de IP e Porta, ser�o assumidos valores DEAFULT

//     cKVSrv  - IP ou Name do Host onde est� instalado o KV. DEFAULT "127.0.0.1"
//     nKVPort - Porta para conex�o. DEFAULT 6379
//
//	Ex. oKVClient := tTecKVClient():KVOpenConn()                        // Acessando por LOCALHOST na Porta PADR�O (DECLARA��O DEFAULT)
//		oKVClient := tTecKVClient():KVOpenConn('12.172.72.72')          // Acessando por IP DECLARADO e Porta PADR�O
//		oKVClient := tTecKVClient():KVOpenConn('12.172.72.72',6379)     // Acessando por IP e Porta DECLARADOS
//		oKVClient := tTecKVClient():KVOpenConn(,7258)                   // Acessando por LOCALHOST e Porta ESPEC�FICA 
//
//  Obs: Para configura��es Espec�ficas verificar documenta��o dispon�vel em "https://KV.io/topics/config"
 
@sample
oKVClient:KVOpenConn()
oKVClient:Finish()  // <- Nao esquecer
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVOpenConn(cKVSrv,nKVPort) Class tTecKVClient

PARAMTYPE 0 VAR cKVSrv   As Character Optional Default DEFAULT_KV_IP
PARAMTYPE 1 VAR nKVPort  As Numeric Optional Default DEFAULT_KV_PORT

If ::connect(cKVSrv,nKVPort):ok()
    ::KVOnConnected := .T.
Else
    ::KVOnConnected := .F.
    ::lHasConnError := .T.
    ::cHasConnError := "ERROR CODE: " + AllTrim(Str(::nError)) + " | Error in Connection on Server:<<" + cKVSrv + ">> Port:<<" + AllTrim(Str(nKVPort)) + ">>"    // msg original completa
EndIf
 
Return NIL
 

//-------------------------------------------------------------------
/*/{Protheus.doc} KVCloseConn()
M�todo de Controle: Finaliza uma conex�o com KV Local / Remoto.
 
@obs Indispens�vel chamar o M�todo KVObjDestroy() dessa classe para evitar Leak de Mem�ria.
 
@sample
oKVClient:KVObjDestroy()  // <- Indispens�vel
oKVClient:KVCloseConn()
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVCloseConn() Class tTecKVClient
::disconnect()
Return NIL
 

//-------------------------------------------------------------------
/*/{Protheus.doc} KVObjDestroy()
M�todo de Controle: Detroi o objeto root atribuindo NIL � ele novamente
 
@sample
oKVClient:KVObjDestroy()  // <- Nao esquecer
oKVClient:KVCloseConn()
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVObjDestroy() Class tTecKVClient
Self := NIL
Return NIL

//-------------------------------------------------------------------
/*/{Protheus.doc} KVIsConnected()
M�todo de valida��o: Verifica se est� / ainda est� conectado ao KV, retorno .T. / .F.
 
@sample
oKVClient:KVOnConnected()
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVIsConnected() Class tTecKVClient
Return ::KVOnConnected

//-------------------------------------------------------------------
/*/{Protheus.doc} KVRunCmdExec()
M�todo de Execu��o: Executa os comandos no KV. Vari�vel para receber o retorno dever� ser passada como REFER�NCIA
 
@sample
oKVClient:exec(::cCmdKVRun,@::xCmdSQLResult):ok()
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVRunCmdExec(cCmdKVRun) Class tTecKVClient
Local cCmdSQLError
Local xRetCmd

If ::KVOnConnected
    If .Not. ::exec(cCmdKVRun,@xRetCmd):ok()
        cCmdSQLError := Alltrim(Str(::nError)) + " | " + AllTrim(::cError)
    EndIf
EndIf

Return ({cCmdSQLError,xRetCmd})

//-------------------------------------------------------------------
/*/{Protheus.doc} KVDel(cKey)
M�todo de Execu��o: Executa DELE��O de uma chave no banco
					Retorna msg de Erro caso exista, sen�o conte�do NIL
 
@sample
Local xRetKV := {}
xRetKV := oKVClient:KVdEL(cKey)
Return(xRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVDel(cKey) Class tTecKVClient
Local xRetKV := {}
Local cCmdKVRun := "del " + cKey
xRetKV := ::KVRunCmdExec(cCmdKVRun)

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVSet(cKey,xValue)
M�todo de Execu��o: Executa inser��o/altera��o de uma chave no banco
					  Retorna msg de Erro caso exista, sen�o conte�do NIL 
 
@sample
Local xRetKV := {}
xRetKV := oKVClient:KVSet(cKey,xValue)
Return(xRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVSet(cKey,xValue) Class tTecKVClient
Local xRetKV := {}
Local cCmdKVRun := "set " + cKey + " " + xValue
xRetKV := ::KVRunCmdExec(cCmdKVRun)

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVAppend(cKey,xValue)
M�todo de Execu��o: Executa inser��o de uma chave no banco
					Retorna msg de Erro caso exista, sen�o conte�do NIL
 
@sample
Local xRetKV := {}
xRetKV := oKVClient:KVAppend(cKey,xValue)
Return(xRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVAppend(cKey,xValue) Class tTecKVClient
Local xRetKV := {}
Local cCmdKVRun := "append " + cKey + " " + xValue
xRetKV := ::KVRunCmdExec(cCmdKVRun)

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVSetNX(cKey,xValue)
M�todo de Execu��o: Executa inser��o de uma chave no banco caso ela n�o exista.
                    Se for chamado novamente, manter� somente o dado imputado originalmente.
					Retorna msg de Erro caso exista, sen�o conte�do NIL
 
@sample
Local xRetKV := {}
xRetKV := oKVClient:KVSetNX(cKey,xValue)
Return(xRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVSetNX(cKey,xValue) Class tTecKVClient
Local xRetKV := {}
Local cCmdKVRun := "setnx " + cKey + " " + xValue
xRetKV := ::KVRunCmdExec(cCmdKVRun)

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVGet(cKey,xValue)
M�todo de Execu��o: Recupera o conte�do de uma chave "cKey"
                    n�o � necess�rio xValue, mas mantido para compatibiliza��o da classe, pode ser NIL
                    Retorna um Array: [1]=>Msg de Erro caso exista, [2]=>Conte�do retornado
 
@sample
Local aRetKV := {}
aRetKV := oKVClient:KVGet(cKey,xValue)
Return(aRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVGet(cKey,xValue) Class tTecKVClient
Local xRetKV := {}
Local cCmdKVRun := "get " + cKey
xRetKV := ::KVRunCmdExec(cCmdKVRun)

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVGetSet(cKey,xValue)
M�todo de Execu��o: Recupera o conte�do de uma chave "cKey"
                    n�o � necess�rio xValue, mas mantido para compatibiliza��o da classe, pode ser NIL
                    Retorna um Array: [1]=>Msg de Erro caso exista, [2]=>Conte�do retornado
 
@sample
Local aRetKV := {}
aRetKV := oKVClient:KVGetSet(cKey,xValue)
Return(aRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVGetSet(cKey,xValue) Class tTecKVClient
Local xRetKV := {}
Local cCmdKVRun := "getset " + cKey + " " + xValue
xRetKV := ::KVRunCmdExec(cCmdKVRun)

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVHMSet(cKey,xValue)
M�todo de Execu��o: inser��o de Array com valores M�LTIPLOS / �NICOS 
                    Retorna um Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
@sample
Local aRetKV := {}
aRetKV := oKVClient:KVHMSet(cKey,xValue)
Return(aRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVHMSet(cKey,aValue) Class tTecKVClient
Local xRetKV := Nil
Local aRetKV := {}
Local nCnt
Local cCmdKVRun := "hmset " + cKey

For nCnt := 1 To Len(aValue)
    If ValType(aValue[nCnt]) == "A"
        cCmdKVRun += " " + aValue[nCnt][1] + " '" + aValue[nCnt][2] + "'"
    Else
        cCmdKVRun += " field"+ AllTrim(str(nCnt)) + " '" + aValue[nCnt] + "'"
    EndIf
Next
aRetKV := ::KVRunCmdExec(cCmdKVRun)
If aRetKV[1] != Nil // primeira posi��o do Array � um retorno de erro
    xRetKV := {}
    AADD(xRetKV,{cCmdKVRun,aRetKV[1]})
EndIf

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVHMGet(cKey,xValue)
M�todo de Execu��o: recupera��o de Array com valores M�LTIPLOS / �NICOS. 
                    O Array passado por referencia � utilizado para a montagem do retorno e tamb�m gera uma Array de erros caso ocorram.
                    Execu��o de SUCESSO:
                        Retorna uma Array com os dados solicitados (@aValIns) e Array com os erros isolados.
                        Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
                        Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
                    Em caso de ERRO:
                        Retorna um Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL

@sample
Local aRetKV := {}
Local aValIns := {}
AADD(aValIns,{"Field1",})
AADD(aValIns,{"Field2",})
AADD(aValIns,{"Field3",})
aRetKV := oKVClient:KVHMSet(cKey,aValIns)
Return(aRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVHMGet(cKey,aValIns) Class tTecKVClient
Local nCnt
Local cCmdKVRun 
Local xRetKV := NIL
Local aRetKV := {}

If Len(aValIns) == 0
    cCmdKVRun := "hkeys " + cKey
    aRetKV := ::KVRunCmdExec(cCmdKVRun)
    For nCnt := 1 to Len(aRetKV[2])
        AADD(aValIns,{aRetKV[2][nCnt],})
    Next
EndIf

For nCnt := 1 To Len(aValIns)
    cCmdKVRun := "hmget " + cKey + " " + aValIns[nCnt][1]
    aRetKV := ::KVRunCmdExec(cCmdKVRun)
    If aRetKV[1] != Nil // primeira posi��o do Array � um retorno de erro
        If ValType(xRetKV) == NIL
            xRetKV := {}
        EndIf
        AADD(xRetKV,{cCmdKVRun,aRetKV[1]})
    Else
        aValIns[nCnt][2] := aRetKV[2][1]
    EndIf
Next

Return (xRetKV)


//-------------------------------------------------------------------
/*/{Protheus.doc} KVHMGetAll(cKey,xValue)
M�todo de Execu��o: recupera��o de Array com valores M�LTIPLOS / �NICOS. 
                    O Array passado por referencia � utilizado para a montagem do retorno e tamb�m gera uma Array de erros caso ocorram.
                    Execu��o de SUCESSO:
                        Retorna uma Array com os dados solicitados (@aValIns) e Array com os erros isolados.
                        Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
                        Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
                    Em caso de ERRO:
                        Retorna um Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL

@sample
Local aRetKV := {}
Local aValIns := {}
AADD(aValIns,{"Field1",})
AADD(aValIns,{"Field2",})
AADD(aValIns,{"Field3",})
aRetKV := oKVClient:KVHMSet(cKey,aValIns)
Return(aRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVHMGetAll(cKey,aValIns) Class tTecKVClient
Local nCnt
Local cCmdKVRun 
Local xRetKV := NIL
Local aRetKV := {}

cCmdKVRun := "hgetall " + cKey
aRetKV := ::KVRunCmdExec(cCmdKVRun)
If aRetKV[1] != Nil // primeira posi��o do Array � um retorno de erro
    xRetKV := {}
    AADD(xRetKV,{cCmdKVRun,aRetKV[1]})
Else
    For nCnt := 1 to Len(aRetKV[2]) Step 2
        AADD(aValIns,{aRetKV[2][nCnt],aRetKV[2][nCnt+1]})
    Next
EndIf

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVSelectDB(cKey)
M�todo de Execu��o: Alterna entre os DataBases existentes na estrutura
					Retorna msg de Erro caso exista, sen�o conte�do NIL
 
@sample
Local xRetKV := {}
xRetKV := oKVClient:KVdEL(cKey)
Return(xRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVSelectDB(cKey) Class tTecKVClient
Local xRetKV := {}
Local cCmdKVRun := "select " + cKey
xRetKV := ::KVRunCmdExec(cCmdKVRun)

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVHINCR(cKey,xValue)
M�todo de Execu��o: recupera��o de Array com valores M�LTIPLOS / �NICOS. 
                    O Array passado por referencia � utilizado para a montagem do retorno e tamb�m gera uma Array de erros caso ocorram.
                    Execu��o de SUCESSO:
                        Retorna uma Array com os dados solicitados (@aValIns) e Array com os erros isolados.
                        Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
                        Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
                    Em caso de ERRO:
                        Retorna um Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL

@sample
Local aRetKV := {}
Local aValIns := {}
AADD(aValIns,{"Field1",})
AADD(aValIns,{"Field2",})
AADD(aValIns,{"Field3",})
aRetKV := oKVClient:KVHMSet(cKey,aValIns)
Return(aRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVHINCR(cKey,aValIns) Class tTecKVClient
Local nCnt
Local cCmdKVRun 
Local xRetKV    := NIL
Local aRetKV    := {}

For nCnt := 1 To Len(aValIns)
    cCmdKVRun := "hincrbyfloat " + cKey + " " + aValIns[nCnt][1] + " " + aValIns[nCnt][2]
    aRetKV := ::KVRunCmdExec(cCmdKVRun)
    If aRetKV[1] != Nil // primeira posi��o do Array � um retorno de erro
        If ValType(xRetKV) == "U"
            xRetKV := {}
            AADD(xRetKV,{cCmdKVRun,aRetKV[1]})
        EndIf
        AADD(xRetKV,{cCmdKVRun,aRetKV[1]})
    Else
        // atribui o valor de retorno no mesmo array de entrada
        aValIns[nCnt][2] := aRetKV[2]
    EndIf
Next

Return (xRetKV)

//-------------------------------------------------------------------
/*/{Protheus.doc} KVHINCR(cKey,xValue)
M�todo de Execu��o: recupera��o de Array com valores M�LTIPLOS / �NICOS. 
                    O Array passado por referencia � utilizado para a montagem do retorno e tamb�m gera uma Array de erros caso ocorram.
                    Execu��o de SUCESSO:
                        Retorna uma Array com os dados solicitados (@aValIns) e Array com os erros isolados.
                        Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
                        Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL
                    Em caso de ERRO:
                        Retorna um Array: [1]=>Msg de Erro ISOLADA caso exista, [2]=>NIL

@sample
Local aRetKV := {}
Local aValIns := {}
AADD(aValIns,{"Field1",})
AADD(aValIns,{"Field2",})
AADD(aValIns,{"Field3",})
aRetKV := oKVClient:KVHMSet(cKey,aValIns)
Return(aRetKV)
 
@author Carlos Testa
@since 15/09/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Method KVIncrFloat(cKey,aValIns) Class tTecKVClient
Local nCnt
Local cCmdKVRun 
Local xRetKV    := NIL
Local aRetKV    := {}

For nCnt := 1 To Len(aValIns)
    cCmdKVRun := "INCRBYFLOAT " + cKey + " " + aValIns[nCnt][1] + " " + aValIns[nCnt][2]
    aRetKV := ::KVRunCmdExec(cCmdKVRun)
    If aRetKV[1] != Nil // primeira posi��o do Array � um retorno de erro
        If ValType(xRetKV) == "U"
            xRetKV := {}
            AADD(xRetKV,{cCmdKVRun,aRetKV[1]})
        EndIf
        AADD(xRetKV,{cCmdKVRun,aRetKV[1]})
    Else
        // atribui o valor de retorno no mesmo array de entrada
        aValIns[nCnt][2] := aRetKV[2]
    EndIf
Next

Return (xRetKV)