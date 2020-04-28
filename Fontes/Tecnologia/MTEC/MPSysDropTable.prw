#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysDropTable
Apaga uma tabela do banco de dados.

@param cTableName Nome da tabela

@result Lógico, indica se as tabelas foram eliminadas com sucesso.

@author Juliane Venteu

@since 05/12/2014
@version P12
/*/
//-------------------------------------------------------------------
Function MPSysDropTable(aTables, lForceAll)
Local cTableName
Local cAlias
Local nX	
Local lLock
Local lRetorno := .F.
Local cDrive := "TOPCONN"

Default lForceAll := .F.

	For nX:=1 to Len(aTables)
		cTableName := aTables[nX]
		cAlias := MPSysAliasName(cTableName)
				
		If !Empty(cAlias) .And. Select(cAlias) > 0
			(cAlias)->(DbCloseArea()) 
		EndIf
				
		If !NetErr()
			lLock := LockTable(cTableName,cDrive,.T.)
			
			If ( lLock )
				//-------------------------------------------------------
				// Apaga a tabela
				//-------------------------------------------------------
				If MSFile(cTableName, ,cDrive)
					lRetorno := MsErase(cTableName,,cDrive)					
				EndIf  
				
				LockTable(cTableName,cDrive,.F.)
				TcRefresh( cTableName )
				//-------------------------------------------------------
				// Se der erro em alguma tabela, aborta a operação
				//-------------------------------------------------------
				If !lRetorno .And. !lForceAll
					Exit
				EndIf
			EndIf
		EndIf
	Next nX
	
Return lRetorno .or. lForceAll

Static Function LockTable(cTableName,cDrive,lLock)

Local lOk		:= .F.
Local nWait	:= 0
Static	 __nLock := 0

If lLock
	While !lOk .And. nWait < 10 .And. !KillApp()
		lOk := LockByName(cTableName+cDrive,.F.,.F.,.T.)
		If !lOk
			Sleep(nWait*500)
			nWait++
		EndIf
	EndDo
	If lOk
		__nLock++
	EndIf
Else
	__nLock--
	If __nLock <= 0
		UnLockByName(cTableName+cDrive,.F.,.F.,.T.)
		lOk := .T.
	EndIf
EndIf
Return(lOk)


User Function testeDropTable()
Local aSXs
Local nX
Local aTables := {}
		
	RPCClearEnv()
	RPCSetType(3)
	RPCSetEnv("T2","D MG 01", , , , , , , , .F.)
	
	aSXs :=  MPDicGetTables()
	For nX:=1 to Len(aSXs)
		aadd(aTables, MPDicSysName(aSXs[nX]))		
	Next nX
	MPSysDropTable(aTables)

Return

User Function DropAll()
Local aSpaces := {"PROFILE", "WORKROLE", "USER", "MENU", "HELP", "COMPANY"}
Local aTables := {}
Local aAux    := {}
Local cEmp    := ""
Local aSM0
Local nI

	OpenSM0()
	aSM0 := FWLoadSM0()

	For nI := 1 to Len(aSM0)

		If cEmp == aSM0[nI][1]
			Loop
		EndIf		

		RPCClearEnv()
		RPCSetType(3)
		RPCSetEnv(cEmp := aSM0[nI][1], aSM0[nI][2], , , , , , , , .F.)

		aAux := MPTblNames("DIC")
		aEval(aAux, {|x| aAdd(aTables, x) })
		aSize(aAux, 0)

	Next

	For nI := 1 to Len(aSpaces)
		 aAux := MPTblNames(aSpaces[nI])
		 aEval(aAux, {|x| aAdd(aTables, x) })
		 aSize(aAux, 0)
	Next nI

	aAdd(aTables, "SYSTEM_INFO")

	i18nConOut("Drop all #1 tables: #2", {Len(aTables), MPSysDropTable(aTables, .T.)})

	aSize(aSM0, 0)
	aSize(aSpaces, 0)
	aSize(aTables, 0)

Return 