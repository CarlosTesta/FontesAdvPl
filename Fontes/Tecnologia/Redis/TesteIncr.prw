User Function TesteIncr()
Local _nCnt
Local nThreads  := 100
Local nIncr     := 650

//JOB´s de Stress de disco para sobrecarregar o Protheus
For _nCnt := 1 To nThreads
    SmartJob('U_GetIncr',getenvserver(),.F.,AllTrim(Str(_nCnt)),nIncr)
Next

Return Nil


//User Function GetIncr(CThread,nIncr)
User Function MyGetIncr()
// Passando somente a chave a ser pesquisada, traz todo o conteúdo blocado em DUAS COLUNAS
Local aValIns   := {}
Local cIPSrv    := '10.171.67.173'
Local nPortSrv  := 6379
Local cKey := "PLSCod"
Local cThread := '1' 
Local nIncr   := 10

//Local cIPSrv    := '10.172.78.78'
//DEFAULT cThread := '1' 
//DEFAULT nIncr   := 10

oKVClient := tTecKVClient():New()
oKVClient:KVOpenConn(cIPSrv,nPortSrv)


If !oKVClient:KVIsConnected(cIPSrv,nPortSrv)
    ConOut(oKVClient:cHasConnError)
    Return Nil
EndIf

// Alterna para um DataBase Específico
aKVresult := oKVClient:KVSelectDB("2")
If aKVresult[1] != NIL
    VarInfo("KV KVSelectDB ErroR >>",aKVresult[2])
Else
    for nCntDel := 1 to nIncr
        aValIns := {}
        AADD(aValIns,{"CODIGO","1"})
        aKVresult := oKVClient:KVHINCR(cKey,aValIns)
        If aKVresult != NIL
            VarInfo("KV KVHINCR ErroR >>",aKVresult)
        Else
            //ConOUt("==============================")
            //ConOUt(cThread)
            //ConOUt(Alltrim(StrZero(nCntDel,5)))
            //ConOUt(aValIns[1][1])
            //ConOUt(aValIns[1][2])
            ConOut("{Thread:'" + cThread + "',Laco :'" + Alltrim(StrZero(nCntDel,5)) + "'} | {KEY:'" + aValIns[1][1] + "',VALUE:'" + aValIns[1][2] + "'}")
            //ConOUt("==============================")
        Endif
    Next
Endif
// Encerra a conexão com o Redis
oKVClient:KVObjDestroy()

Return