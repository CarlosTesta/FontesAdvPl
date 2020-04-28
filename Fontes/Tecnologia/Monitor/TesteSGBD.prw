// opções a serem contempladas com tempos
//Cria / Deleta / Insere (1 e N) / Modifica (1 e N) / Exclui (1 e N) / Trunca / DELETA ARQUIVO
//User Function TCount()
//Local cOpc      := "TOP_COUNT"
User Function TCount(cOpc)
Local nCntOp,nRegOp
Local aEnlapsed := {}
Local aStruTbl  := {}
Local aDataIns  := {}

AADD(aStruTbl,{"FIELD_CS","C",015,0})   // campo caracter CURTO (SHORT)
AADD(aStruTbl,{"FIELD_CL","C",250,0})	// campo caracter LONGO (LONG)
AADD(aStruTbl,{"FIELD_NI","N",007,0})   // campo numérico INTEIRO
AADD(aStruTbl,{"FIELD_ND","N",010,4})   // campo numérico DECIMAL
AADD(aStruTbl,{"FIELD_D" ,"D",008,0})
AADD(aStruTbl,{"FIELD_L" ,"L",001,0})

AADD(aEnlapsed,{cOpc,"CREATE",MicroSeconds(),})
If cOpc == "TRB_COUNT"
    // criação da tabela
    dbCreate("TECMON"+GetDbExtension(),aStruTbl,__LocalDriver)
    dbUseArea(.T.,__LocalDriver,"TECMON"+GetDbExtension(),"TBL",.F.,.F.)
Else
    // criação da tabela
    dbCreate("TECMON",aStruTbl,"TOPCONN")
    dbUseArea(.T., "TOPCONN","TECMON","TBL", .T., .F.)
    // Ajustando campos para o recebimento padrão de dados no formato do ERP
    TcSetField("TBL","FIELD_NI","N", 07, 0 )
    TcSetField("TBL","FIELD_ND","N", 10, 4 )
    TcSetField("TBL","FIELD_D" ,"D", 08, 0 )
    TcSetField("TBL","FIELD_L" ,"L", 01, 0 )
EndIf
dbSelectArea("TBL")
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// Inserção 1 REGISTRO
aDataIns := U_MontaDt(1)
AADD(aEnlapsed,{cOpc,"INSERTx1",MicroSeconds(),})
For nCntOp := 1 To Len(aDataIns)
    RecLock("TBL",.T.)
    TBL->FIELD_CS   := aDataIns[nCntOp][1]
    TBL->FIELD_CL   := aDataIns[nCntOp][2]
    TBL->FIELD_NI   := aDataIns[nCntOp][3]
    TBL->FIELD_ND   := aDataIns[nCntOp][4]
    TBL->FIELD_D    := aDataIns[nCntOp][5]
    TBL->FIELD_L    := .T.
    TBL->( MsUnLock() )
Next
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para o Inserção em N
aDataIns := U_MontaDt(Randomize(1,500))
AADD(aEnlapsed,{cOpc,"INSERTxN",MicroSeconds(),})
For nCntOp := 1 To Len(aDataIns)
    RecLock("TBL",.T.)
    TBL->FIELD_CS   := aDataIns[nCntOp][1]
    TBL->FIELD_CL   := aDataIns[nCntOp][2]
    TBL->FIELD_NI   := aDataIns[nCntOp][3]
    TBL->FIELD_ND   := aDataIns[nCntOp][4]
    TBL->FIELD_D    := aDataIns[nCntOp][5]
    TBL->FIELD_L    := .T.
    TBL->( MsUnlock() )
Next
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para ALTERAÇÃO de 1 Registro ALEATORIO
AADD(aEnlapsed,{cOpc,"ALTERx1",MicroSeconds(),})
nRegOp := Randomize(1,TBL->(RecCount()) )
TBL->( dbGoTo(nRegOp) )    // seleciona um registro aleatório na base
RecLock("TBL")
TBL->FIELD_CL   := "REGISTRO ALTERADO PARA " + MD5(Str(MicroSeconds()),2)+MD5(Str(MicroSeconds()),2)
TBL->( MsUnlock() )
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para ALTERAÇÃO de 10 Registros ALEATORIOS
AADD(aEnlapsed,{cOpc,"ALTERx10",MicroSeconds(),})
nRegOp := Int(TBL->(RecCount())/10)
For nCntOp := 1 to nRegOp Step 10
    TBL->( dbGoTo(nCntOp) )    // seleciona um registro aleatório na base
    RecLock("TBL")
    TBL->FIELD_CL   := "REGISTRO ALTERACAO " + Str(nCntOp) + " PARA " + MD5(Str(MicroSeconds()),2)
    TBL->( MsUnlock() )
Next
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para o Exclusão de 1 Registro ALEATORIO
AADD(aEnlapsed,{cOpc,"DELETEx1",MicroSeconds(),})
nRegOp := Randomize(1,TBL->(RecCount()) )
TBL->( dbGoTo(nRegOp) )     // seleciona um registro aleatório na base
RecLock("TBL")
TBL->( dbDelete() )         // deleção formato ERP
TBL->( MsUnlock() )
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada para o Exclusão de N Registro ALEATORIO
AADD(aEnlapsed,{cOpc,"DELETEx10",MicroSeconds(),})
nRegOp := Int(TBL->(RecCount())/10)
For nCntOp := 1 to nRegOp Step 10
    TBL->( dbGoTo(nCntOp) )     // seleciona um registro aleatório na base
    RecLock("TBL")
    TBL->( dbDelete() )         // deleção formato ERP
    TBL->( MsUnlock() )
Next
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

// chamada TRUNCATE de tabela 
AADD(aEnlapsed,{cOpc,"TRUNCATE",MicroSeconds(),})
If cOpc == "TRB_COUNT"
    TBL->( __dbZap() )
Else
    TCSQLExec("TRUNCATE TABLE TECMON")
    TCSQLExec("COMMIT")
EndIf
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

TBL->( dbCloseArea() )
//VarInfo("Dados " + cOpc,aEnlapsed)

// eliminando o arquivo de trabalho
AADD(aEnlapsed,{cOpc,"DROP",MicroSeconds(),})
If cOpc == "TRB_COUNT"
    fErase("TECMON"+GetDbExtension())
Else
    TCDelfile("TECMON")
EndIf
aEnlapsed[Len(aEnlapsed)][4] := MicroSeconds()

Return(aEnlapsed)