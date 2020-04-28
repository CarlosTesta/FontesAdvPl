#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'PARMTYPE.CH'

//sugestao de como escrever uma aplicacao usando esta interface nativa
User Function CacheTst()
Local aKeyDel   := {}
Local xKVresult := {}
Local aValIns   := {}
Local aKVresult
Local nCntDel
Local oKVClientCacheTst

oKVClient := tTecKVClient():New()
varinfo("Objeto KV",oKVClient)

oKVClient:KVOpenConn("10.172.78.78",6379)

ConOut("KVISCONNECTED >>")
ConOut(oKVClient:KVIsConnected())

// Teste de KVDel() com conteúdo único // OK !!!
// grupo de objetos para deleção
AADD(aKeyDel,"LastConection:")
AADD(aKeyDel,"MyKey")
AADD(aKeyDel,"mykey")
AADD(aKeyDel,"aMyKey")
For nCntDel := 1 To Len(aKeyDel)
  xKVresult := oKVClient:KVDel(aKeyDel[nCntDel])
  If xKVresult[1] != Nil
      ConOut("KV KVDel " + AllTrim(aKeyDel[nCntDel]) + " ErroR >>")
      ConOut(xKVresult)
    Else
      ConOut("KVDel "+ AllTrim(aKeyDel[nCntDel]) +" OK !!!")
  Endif
Next

// Teste de KVSet() com conteúdo único // OK !!!
cKey := "LastConection:"
xValue := "{User:__THIS,DateTime:" + AllTrim(DTOS(date())) + AllTrim(StrTran(Time(),":","")) + "}"
xKVresult := oKVClient:KVSet(cKey,xValue)
If xKVresult[1] != Nil
    ConOut("KV KVSet ErroR >>")
    ConOut(xKVresult)
  Else
    ConOut("KVSet OK !!!")
Endif

// uso do APPEND - Caso exista a chave, acrescenta novo ítem, 
//caso não exista, cria a chave e acresceta valor
cKey := "LastConection:"
xValue := "{User:__FULANO,DateTime:" + AllTrim(DTOS(date())) + AllTrim(StrTran(Time(),":","")) + "}"
xKVresult := oKVClient:KVAppend(cKey,xValue)
If xKVresult[1] != Nil
    ConOut("KV KVAppend ErroR >>")
    ConOut(xKVresult)
  Else
    ConOut("KVAppend OK !!!")
Endif

// uso do SetNX - Set if Not eXist - Somente insere dado caso a chave NÃO EXISTA
cKey := "MyKey"
xValue := "Hello"
xKVresult := oKVClient:KVSetNX(cKey,xValue)
If xKVresult[1] != Nil
    ConOut("KV KVSetNX1 ErroR >>")
    ConOut(xKVresult)
  Else
    ConOut("KVSetNX1 OK !!!")
Endif
xValue := "World"
xKVresult := oKVClient:KVSetNX(cKey,xValue)
If xKVresult[1] != Nil
    ConOut("KV KVSetNX2 ErroR >>")
    ConOut(xKVresult)
  Else
    ConOut("KVSetNX2 OK !!!")
Endif

// uso do Get - Recupera o conteúdo ATUAL de uma chave
// não é necessário xValue, mas mantido para compatibilização da classe, pode ser NIL
// Retorna um Array: [1] => Msg de Erro caso exista, 
//                   [2] => Conteúdo retornado
cKey := "MyKey"
xValue := ""
aKVresult := oKVClient:KVGet(cKey,xValue)
If aKVresult[1] != Nil
    ConOut("KV KVGet ErroR >>")
    ConOut(xKVresult[1])
  Else
    ConOut("KVGet OK !!!")
    ConOut("Valor Retornado da Chave " + cKey + " = " + aKVresult[2])
Endif

// uso do GetSet - Recupera o conteúdo ATUAL de uma chave e atribui novo valor à ela
// pode ser usado como incrementador e atribuidor de valor ATÔMICO
// não é necessário xValue, mas mantido para compatibilização da classe, pode ser NIL
// Retorna um Array: [1]=>Msg de Erro caso exista, [2] => Conteúdo retornado
cKey      := "MyKey"
xValue    := ""
aKVresult := oKVClient:KVGetSet(cKey,xValue)
If aKVresult[1] != Nil
    ConOut("KV KVGetSet ErroR >>")
    ConOut(xKVresult[1])
  Else
    ConOut("KVGetSet OK !!!")
    ConOut("Valor Retornado da Chave " + cKey + " = " + aKVresult[2])
Endif

// uso do HMSet - insere um array em chave unica (HASH) com valores MÚLTIPLOS / ÚNICO
// caso a chave não exista será criada e acrescentado dados em blocos em chamada ÚNICA
// Retorna um Array: [1]=> Array com os ERROS isolados dos inserts
//                   [2]=> NIL
cKey := "aMyKey"
AADD(aValIns,{"ValC1","Value1"})
AADD(aValIns,{"ValC2","Value2"})
AADD(aValIns,{"ValC3","Value3"})
AADD(aValIns,"Xrec")
AADD(aValIns,{"ValC4","Value4"})
AADD(aValIns,{"ValC5","Value"})
AADD(aValIns,{"ValN1","1"})
AADD(aValIns,"1632")
AADD(aValIns,"MOVI")
AADD(aValIns,{"ValN2","2"})
AADD(aValIns,{"ValN3","3"})
AADD(aValIns,{"ValN4","4"})
AADD(aValIns,{"ValN5","4"})
AADD(aValIns,{"ValN6","6"})
aKVresult := oKVClient:KVHMSet(cKey,aValIns)
If aKVresult != NIL
    VarInfo("KV KVHMSet ErroR >>",aKVresult)
  Else
    ConOut("KVHMSet OK !!!")
Endif

// ao passar o Array com nomes das chaves que se quer pesquisar, devolve um Array {key,value}
cKey := "aMyKey"
aValIns := {}
AADD(aValIns,{"ValC1",})
AADD(aValIns,{"ValC4",})
AADD(aValIns,{"ValC5",})
AADD(aValIns,{"ValN4",})
AADD(aValIns,{"ValN6",})
AADD(aValIns,{"Tst1",})
aKVresult := oKVClient:KVHMGet(cKey,@aValIns)
If aKVresult != NIL
    VarInfo("KV KVHMSet ErroR >>",aKVresult)
  Else
    VarInfo("KVHMSet OK !!!",aValIns)
Endif

oKVClient:KVObjDestroy()

Return

// Passando somente a chave a ser pesquisada, traz todo o conteúdo blocado em DUAS COLUNAS
cKey := "TAB26"
aValIns := {}
aKVresult := oKVClient:KVHMGetAll(cKey,@aValIns)
If aKVresult != NIL
    VarInfo("KV KVHMSet ErroR >>",aKVresult)
  Else
    VarInfo("KVHMSet OK !!!",aValIns)
Endif

// Alterna para um DataBase Específico
aKVresult := oKVClient:KVSelectDB("2")
If aKVresult != NIL
    VarInfo("KV KVSelectDB ErroR >>",aKVresult)
Endif

// efetua o incremento em uma chave decidindo se o numero é inteiro ou decimal
aValIns := {}
AADD(aValIns,{"A","1"})
AADD(aValIns,{"C","3"})
AADD(aValIns,{"C","0.2342"})
AADD(aValIns,{"C","222"})
AADD(aValIns,{"B","3"})
AADD(aValIns,{"B","57.659"})
AADD(aValIns,{"B","-45"})
AADD(aValIns,{"B","-0.659"})
AADD(aValIns,{"TST","1"})
aKVresult := oKVClient:KVHINCR(cKey,aValIns)
If aKVresult != NIL
    VarInfo("KV KVHINCR ErroR >>",aKVresult)
  Else
    VarInfo("KVHINCR OK !!!",aValIns)
Endif

oKVClient:KVObjDestroy()

Return


User Function TstAll()
// Passando somente a chave a ser pesquisada, traz todo o conteúdo blocado em DUAS COLUNAS
Local aValIns := {}
Local cKey := "NFSRel"
Local nCntDel
oKVClient := tTecKVClient():New()
oKVClient:KVOpenConn("127.0.0.1",6379)


// Alterna para um DataBase Específico
aKVresult := oKVClient:KVSelectDB("2")
If aKVresult != NIL
    VarInfo("KV KVSelectDB ErroR >>",aKVresult)
Endif

// efetua o incremento em uma chave decidindo se o numero é inteiro ou decimal
//aValIns := {}
//AADD(aValIns,{"A",AllTrim(Str(Randomize(-100,100)))})
//AADD(aValIns,{"C",AllTrim(Str(Randomize(-100,100)))})
//AADD(aValIns,{"B",AllTrim(Str(Randomize(-100,100)))})
//AADD(aValIns,{"TST",AllTrim(Str(Randomize(-100,100)))})
//VarInfo("Antes !!!",aValIns)

for nCntDel := 1 to 100
    aValIns := {}
    AADD(aValIns,{"TST","1"})
    aKVresult := oKVClient:KVHINCR("MyKey",aValIns)
    If aKVresult != NIL
        VarInfo("KV KVHINCR ErroR >>",aKVresult)
    Else
        VarInfo("KVHINCR OK !!!",aValIns)
    Endif
Next
// Encerra a conexão com o Redis
oKVClient:KVObjDestroy()

Return


User Function TesteIncr()
Local _nCnt
Local nThreads  := 100
Local nIncr     := 1156

//JOB´s de Stress de disco para sobrecarregar o Protheus
For _nCnt := 1 To nThreads
    SmartJob('U_GetIncr',getenvserver(),.F.,AllTrim(Str(_nCnt)),nIncr)
Next

Return Nil


User Function GetIncr(CThread,nIncr)
//User Function GetIncr()
// Passando somente a chave a ser pesquisada, traz todo o conteúdo blocado em DUAS COLUNAS
Local aValIns   := {}
Local cIPSrv    := '10.171.67.173'
Local nPortSrv  := 6379
Local cKey := "PLSCod"
Local nCntDel

DEFAULT cThread := '1' 
DEFAULT nIncr   := 10

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