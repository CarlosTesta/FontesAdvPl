#Include 'Protheus.ch'
#INCLUDE 'FWMvcDef.ch'

#DEFINE DESC    1
#DEFINE STATUS  2
#DEFINE CONTENT 3
#DEFINE UID     4
#DEFINE ITEMID  5

#DEFINE MN_DESC    1
#DEFINE MN_STATUS  2
#DEFINE MN_FUNC    3
#DEFINE MN_TABLES  4
#DEFINE MN_ACCESS  5
#DEFINE MN_MODULE  6
#DEFINE MN_TYPE    7
#DEFINE MN_RESNAME 8
#DEFINE MN_OWNER   9
#DEFINE MN_K_PT   10
#DEFINE MN_K_ES   11
#DEFINE MN_K_EN   12
#DEFINE MN_RESERV 13
#DEFINE MN_UID    14
#DEFINE MN_ITEMID 15

#XCOMMAND RUN_IF_TRUE <lVar> := <uVal> => <lVar> := IIF( <lVar>, <uVal>, <lVar> )

Static __aResrv
Static __cClearQry
Static __lImported := .F.
Static __oModel
Static __lMultiThread := .F.
Static __cUID

Function __MPDBXnuCheck(oWizard)
Local nStatus := 0 // Sucess
Local cStatus := ""
Local aStatus
Local nI


	If oWizard == Nil
		oWizard := MPDicWizard():New()
		If Select("SM0") == 0
			oWizard:OpenEnvironment()
		EndIf
	EndIf

	aStatus := __XnuChkFiles()
	
	For nI := 1 to Len(aStatus)
		If aStatus[nI][2] == 1
			cStatus += aStatus[nI][3] + CRLF
		ElseIf aStatus[nI][2] == 2
			nStatus := 2  // Error
    		cStatus += aStatus[nI][3] + CRLF
		EndIf
	Next

	If nStatus == 0 .And. !Empty(cStatus)
		nStatus := 1 // Warning
	EndIf

	If __oModel != Nil
		__oModel:Destroy()
		FreeObj(__oModel)
	EndIf

Return {nStatus, cStatus}

Function __XnuChkFiles()
Local aMods   := RetModName(.T.)
Local aXNU    := {}
Local nI
Local aStatus := {} //{nome modulo / Status / Msg / RetModName / aXNU}
// Status => 0 - Arquivo encontrado com chave itemID / 1 - arquivo não encontrado / 2 - Arquivo sem chave itemID 

	For nI := 1 to Len(aMods)
		If File(aMods[nI][2]+".XNU")
			aXNU := Eval(&('{|cFile,cUId,cMenu,cModVersion| StaticCall(ApLib180, __XNULoad__, cFile)}'), aMods[nI][2]+".XNU")
	 		If !Empty(aXNU) 
    			If Empty(aXNU[1][ITEMID])
    				Aadd(aStatus , {aMods[nI][2] , 2,  aMods[nI][2]+".XNU" + ' - Chave "ItemId" não encontrado '}, aClone(aMods[nI]), nil)
    			Else
    				Aadd(aStatus , {aMods[nI][2] , 0,  aMods[nI][2]+".XNU" + ' - OK ' , aClone(aMods[nI]), aClone(aXNU)}) 
    			EndIf
    		EndIf
		Else
			Aadd(aStatus , {aMods[nI][2] , 1,  aMods[nI][2]+".XNU" + " - Arquivo não encontrado "}, aClone(aMods[nI]), nil) 
		EndIf
		aSize(aXNU, 0)
	Next

	aSize(aMods, 0)

	
Return aStatus

Static Function __CheckXnus()
Local cStartPath := GetSrvProfString("StartPath","")
Local aFiles := Directory(cStartPath + "*.XNU", "D")
Local nI
Local aMods := RetModName(.T.)
Local aXNU
Local aStatus := {} //{nome modulo / Descricao / aXNU / codigo do modulo / default (1=padrao;2=customizado / cFile)}
Local cXNU
Local nPos
Local cQuery := ""
Local aMenuCustom := {}
Local oStatement
Local cAlias
	
	//------------------------------------------------------------------------------
	// Obtem os menus customizados por grupo ou usuario (M_DEFAULT = 2)
	//------------------------------------------------------------------------------
	cQuery += " SELECT  M_NAME NAME, M_MODULE MODULE"
	cQuery += " FROM " + MPSysSqlName("MPMENU_MENU")
	cQuery += " WHERE M_DEFAULT ='2'  AND" 
	cQuery += " D_E_L_E_T_ =' '"
	cQuery += " ORDER BY MODULE"
		
	cQuery := ChangeQuery(cQuery)
	
	oStatement := FWPreparedStatement():New(cQuery)
	cQuery := oStatement:getFixQuery()
	MPSysOpenQuery(cQuery,@cAlias)
	While (cAlias)->(!Eof())
		aAdd(aMenuCustom,{ ALLTRIM((cAlias)->(NAME)), (cAlias)->(MODULE)})
		(cAlias)->(DbSkip())
	Enddo
	oStatement:Destroy()
	
	(cAlias)->(DbCloseArea())
	
	//-----------------------------------------------------------------------------------------------
	// Analisa cada arquivo encontrado no startpath, verificando se é um menu padrão ou customizado
	//-----------------------------------------------------------------------------------------------
	For nI:=1 to Len(aFiles)
		If File(aFiles[nI][1])
			cXNU := StrTran(aFiles[nI][1],".XNU","")
			aXNU := Eval(&('{|cFile,cUId,cMenu,cModVersion| StaticCall(ApLib180, __XNULoad__, cFile)}'), cXNU+".XNU")
	 		If !Empty(aXNU)
	 			
	 			//Verifica se o menu é padrão
	 			nPos := aScan(aMods, {|x| UPPER(ALLTRIM(x[2])) == UPPER(ALLTRIM(cXNU)) })
	 		 	
	 		 	//Menu padrão precisa possuir ITEMID, menos SIGAESP
	 		 	If nPos > 0 .And. (!Empty(aXNU[1][ITEMID]) .OR. cXNU == "SIGAESP") 
	 		 		Aadd(aStatus , {cXNU , aMods[nPos][3], aClone(aXNU), aMods[1][1], 1, cStartPath + aFiles[nI][1]})
	 		 	ElseIf nPos == 0
	 		 		
	 		 		//Verifica se o menu customizado já existe no banco de dados
	 		 		nPos := aScan(aMenuCustom, {|x| Upper(AllTrim(x[1])) == cXNU })
	 		 		
	 		 		If nPos > 0
	 		 			// Se o menu customizado já existe no banco, usa o modulo que está lá
	 		 			Aadd(aStatus , {cXNU , cXNU, aClone(aXNU), aMenuCustom[nPos][2], 2, cStartPath + aFiles[nI][1]})
	 		 		Else
	 		 			// Se o menu não existe no banco, coloca sempre o modulo 97 (SIGAESP)
	 		 			Aadd(aStatus , {cXNU , cXNU, aClone(aXNU), 97, 2, cStartPath + aFiles[nI][1] })
	 		 		EndIf
	 		 			 		 		 		 	
	 		 	EndIf
    			
    		EndIf
		EndIf
	Next nX

Return aStatus

Function MPMenuImport(cIDSemaphore,cFile, nMod, cDesc, lDefault,cEmp,cFil, cMultiThreadID)
Local lOpenSemaphore
Local cID := UPPER(cFile)
Local cDir

Local __oSemaphore
	
	__cUID := cMultiThreadID
	
	//Indica que a importação está correndo via MultiThread
	__lMultiThread := .T.	
	
	//Indica que a migração está em andamento
	StartMigration()
	MPIsUsrInDB()
	_SetUserInDb(.F.)
	
	//Abertura de Ambiente
	RpcClearEnv()
	RpcSetType(3)
	RPCSetEnv(cEmp, cFil)
		
	//Abre as tabelas de Menu
	MPMenuInDB()
	
	cDir := AllTrim(GetSrvProfString("MenuPath",""))
	
	//Abre o semaforo
	__oSemaphore := FWThreadSemaphoreEx():new(cIDSemaphore)
	__oSemaphore:Activate()
	lOpenSemaphore := __oSemaphore:Open()	
	
	If MPDBXnuFImport(cFile, nMod, cDesc, lDefault)
		//-------------------------------------------------------------------------------------------
		// Lista para o semaforo os arquivos que devem ser movidos
		//-------------------------------------------------------------------------------------------		
		If lOpenSemaphore
			__oSemaphore:write(cID + "_ARQ", Alltrim(Strtran(UPPER(cFile), "\SYSTEM\", "")))
		EndIf			
	Else
		i18nConOut("#1 | #2 Fail (File Exists: #3)", {nMod, cFile, File(cDir+cFile)})
	EndIf
	
	//-------------------------------------------------------------------------------------------
	// Avisa o semaforo que finalizou a migração desse menu
	//-------------------------------------------------------------------------------------------
	If lOpenSemaphore
		__oSemaphore:write(cID, "END")	
	EndIf
	
	__oSemaphore:DeActivate()
	__oSemaphore := NIL
			
Return

Main Function __MPDBXnuImport(oWizard, lRestore)
Local aSucess := {}
Local nSeconds
Local oMenu
Local aMods		//{nModulo, cFile , cDescMod, lDefault}
Local cDir
Local nI
Local aFiles
Local aXnuDefaults := RetModName(.T.)
Local lDefault := .T.

Default lRestore := .F.
	
	//Indica que a importação está correndo com uma única thread
	__lMultiThread := .F.
	
	If oWizard == Nil
		oWizard := MPDicWizard():New()
		If Select("SM0") == 0
			oWizard:OpenEnvironment()
		EndIf
	EndIf

	i18nConOut("Menu in DB: #1", {MPMenuInDB(.T.,,oWizard:oLogFile)})

	nSeconds := Seconds()

	aMods := GetXnu()

	If lRestore
		aFiles := {}
		aEval(aMods, {|x| aAdd(aFiles, x[2])})
		oWizard:ImpMoveToOrigin("MENU", aFiles)
		aSize(aFiles, 0)
	EndIf

	cDir := AllTrim(GetSrvProfString("MenuPath",""))
	oWizard:SetTotalRegs(Len(aMods))
	For nI := 1 to Len(aMods)
	
		If MPDBXnuFImport(aMods[nI][2], aMods[nI][1], aMods[nI][3], aMods[nI][4], oWizard)
			aAdd(aSucess, Alltrim(Strtran(UPPER(aMods[nI][2]), "\SYSTEM\", "")))
		Else
			i18nConOut("#1 | #2 Fail (File Exists: #3)", {aMods[nI][1], aMods[nI][2], File(cDir+aMods[nI][2])})
		EndIf
		oWizard:Step()
	Next
	aSize(aMods, 0)
	
	__ClearUnusedFunc()

	oWizard:SetMoveFiles("MENU", aSucess)

	If lRestore
		oWizard:ImpMoveToBKP("MENU", aSucess)
	EndIf

	i18nConOut("Menu in DB: #1", {MPMenuInDB(.T.)})

	i18nConOut("Tempo: #1", {Seconds() - nSeconds})
	
	
	__UpdMenuUsrGr()

Return {0, Nil}

// ************************************
//               IMPORT
// ************************************
Function MPDBXnuFImport(cFile, nMod, cDesc, lDefault,oWizard)
Local cMd5File := ""
Local aXNU
Local cUId
Local cMenu
Local cModVersion

	If Empty(cFile)
		Return .F.
	EndIf

	If File(cFile)
		cMd5File := MD5File(cFile)
	EndIf

	aXNU := Eval(&('{|cFile,cUId,cMenu,cModVersion| StaticCall(ApLib180, __XNULoad__, cFile, .F., .T., @cUId, @cMenu, @cModVersion)}'), ;
	             cFile, @cUId, @cMenu, @cModVersion)

Return MPDBXnuImport(aXNU, cMenu, cDesc, nMod, cModVersion, cUId, lDefault, cMd5File, oWizard, cFile)

Function MPDBXnuImport(aXNU, cMenu, cDesc, nMod, cModVersion, cUId, lDefault, cMD5File, oWizard, cFile, lSync)
Local lOk := .T.
Local nI, nX, nQtd, nQtdI18n
Local oModel, oI18n
Local lUpdate
Local cDefault
Local nPosName
Local aMenuStruct
Local oLogFile := IIF(oWizard <> nil, oWizard:oLogFile , nil)
Local lRW
Local cGet

Default cMenu       := ""
Default cDesc       := cMenu
Default cModVersion := "10.1"
Default lDefault    := .F.
Default cMD5File    := ""
Default cFile 		:= cMenu
Default lSync		:= .F.
	
	Default __oModel := FWLoadModel("MPSysMenu")
	
	If !__lImported .And. !__lMultiThread
		__lImported := .T.
		MPMenuInDB(.T., .T.,oLogFile) // Força criar a chave de versão
	EndIf

	If lDefault
		cDefault := "1"
	Else
		cDefault := "2"
		cMenu := FormatMnuName(cFile)
		aMenuStruct := __oModel:GetModel("MENU"):GetStruct():aFields
		nPosName := aScan(aMenuStruct, {|x| x[3] == "M_NAME"}) 
		cMenu := PADR(cMenu,aMenuStruct[nPosName,5])
	EndIf

	nQtd := Len(aXNU)
	If nQtd > 0
		

		If lUpdate := MPMnuExist(cMenu, 2)
			__oModel:SetOperation(MODEL_OPERATION_UPDATE)
		Else
			__oModel:SetOperation(MODEL_OPERATION_INSERT)
		EndIf

		If __oModel:Activate()

			If lUpdate
				cUId := __oModel:GetValue("MENU", "M_ID")
			Else
				If Empty(cUId)
					cUId := FWUUIDV1(.F.)
				EndIf
				RUN_IF_TRUE lOk := __oModel:SetValue("MENU", "M_ID", cUId, .T.)
			EndIf

			RUN_IF_TRUE lOk := __oModel:SetValue("MENU", "M_NAME", cMenu, .T.)
			RUN_IF_TRUE lOk := __oModel:SetValue("MENU", "M_VERSION", cModVersion, .T.)
			RUN_IF_TRUE lOk := __oModel:SetValue("MENU", "M_MODULE", nMod, .T.)
			RUN_IF_TRUE lOk := __oModel:SetValue("MENU", "M_DEFAULT", cDefault, .T.)
			RUN_IF_TRUE lOk := __oModel:SetValue("MENU", "M_ARQMENU", AllTrim(cFile), .T.)

			//TODO: Estudar a necessidade de usar o MD5 File.
			RUN_IF_TRUE lOk := __oModel:SetValue("MENU", "M_MD5_FILE", cMD5File, .T.)

			If __aResrv == Nil .AND. aXNU[Len(aXNU)][ITEMID] <> nil
				If At("B"+StrZero(nMod,2), aXNU[Len(aXNU)][ITEMID]) > 0 // Verifico se o ultimo registro é o palavrsa reservadas (Padrão ser o último)

					If __lMultiThread
						//-----------------------------------------------------------------------
						// Quando é multi thread executa a função uma unica vez
						// controlando a inclusao pela variavel global
						//-----------------------------------------------------------------------
						lRW := VarGetX(__cUID,"RW",@cGet)
						If !lRW
							VarSetX(__cUID,"RW","OK")							
						EndIf
					Else
						lRW := .F.
					EndIf
					
					If !lRW
						Default __aResrv := aXNU[Len(aXNU)][CONTENT][1][MN_RESERV]
						RUN_IF_TRUE lOk  := MPDBSetReseved(__aResrv)
					EndIf
				EndIf
			EndIf
			
			// I18n Menu
			oI18n := __oModel:GetModel("I18N_MENU")
			If !oI18n:SeekLine({{"N_LANG", "1"}/*, {"N_DEFAULT", cDefault}*/}) // Localiza e ja posiciona na linha
				If oI18n:IsUpdated() .Or. oI18n:IsDeleted() .Or. lSync
					oI18n:AddLine()
				EndIf
			EndIf
	

			RUN_IF_TRUE lOk := oI18n:SetValue("N_LANG", "1", .T.)
			RUN_IF_TRUE lOk := oI18n:SetValue("N_DESC", cDesc, .T.)
			RUN_IF_TRUE lOk := oI18n:SetValue("N_DEFAULT", cDefault, .T.)
			
			
			// Salva os Menus e MenuItems
			RUN_IF_TRUE lOk := SetContents(lUpdate, ;
			                               aXNU, ;
			                               cUId, ;
			                               cUId, ;
			                               __oModel:GetModel("ITEM"), ;
			                               __oModel:GetModel("I18N_ITEM"), ;
			                               __oModel:GetModel("KEYWORDS"), ;
			                               cDefault, ;
			                               lSync)

			If lUpdate .And. !lSync
				// Quando for update e a linha não tiver sido sobreescrita, então indica que é uma linha q foi removida do XNU
				RUN_IF_TRUE lOk := RemoveDelItems(__oModel:GetModel("ITEM"), "I_DEFAULT")
				RUN_IF_TRUE lOk := RemoveDelItems(oI18n, "N_DEFAULT")
			EndIf 

			If lOk := (__oModel:VldData() .And. __oModel:CommitData())				
				FwFrameTrace({{i18n("Modulo #1 | #2", {nMod, cMenu}), "Sucesso"}})
			Else
				FwFrameTrace({{i18n("Modulo #1 | #2", {nMod, cMenu}), "Erro"}} ,3)
				VarInfo("GetErrorMessage", __oModel:GetErrorMessage())
			EndIf

			__oModel:DeActivate()

		EndIf

	Else
		lOk := .F.
		FwFrameTrace({{i18n("Modulo #1 | #2", {nMod, cMenu}), "file is empty"}} ,3)
	EndIf

	aSize(aXNU, 0)

Return lOk

Static Function SetContents(lUpdate, aXNU, cID_Menu, cID_Father, oItem, oI18NItem, oKeyWords, cDefault, lSync)
Local lOk := .T.
Local nI, nX
Local cDesc
Local cI_ID
Local lFolder
Local cItemId
Local nQtd
Local lFoundItem
Local lItemExists //verifica se o item existe incluindo nos registros deletados

Default cID_Father := ""
Default lSync := .F.

	For nI := 1 To Len(aXNU)
		cI_ID := ''
		cItemId := ''
		lFolder := ValType(aXNU[nI][CONTENT]) == "A"

		If !IsInCallStack('PublishDb') //na manutenção de menus não deve copiar os id's dos itens
			If lFolder
				cI_ID   := aXNU[nI][UID]
				cItemId := aXNU[nI][ITEMID]
			Else
				cI_ID   := aXNU[nI][MN_UID]
				cItemId := aXNU[nI][MN_ITEMID]
			EndIf
		EndIf

		If "__MDILERDA" $ cItemId
			Loop
		EndIf

		If cDefault == "1"
			lFoundItem := oItem:SeekLine({{"I_ITEMID", cItemId}/*, {"N_DEFAULT", "1"}*/}) // Localiza e ja posiciona na linha
		Else
			lFoundItem := oItem:SeekLine({ {"I_ID", cI_Id} }) // Localiza e ja posiciona na linha
		EndIf

		//---------------------------------------------------------------------------
		// se for processamento de sincronização deve ignorar e não importar
		// os itens que já existem na base de dados (mesmo estando como deletados).
		//---------------------------------------------------------------------------
		If lSync 
			lItemExists := _XNUItemExists(cID_Menu, cItemId)
			If (lItemExists .AND. !lFoundItem) // Se o item estiver como deletado, pula a importação
				Loop
			ElseIf lItemExists .AND. !lFolder //Se o item existe no banco e nao for uma pasta, pula importacao. Em itens existentes continua apenas quando for pasta para entrar nos filhos
				Loop
			EndIf
		EndIf
		
		If lFoundItem 
			cI_ID := oItem:GetValue("I_ID")
		ElseIF !lItemExists
			If oItem:IsUpdated() .Or. oItem:IsDeleted() .Or. lSync
				oItem:AddLine()
			EndIf

			If Empty(cI_ID)
				cI_ID := FWUUIDV4(.F.)
			EndIf 

			RUN_IF_TRUE lOk := oItem:SetValue("I_ID", cI_ID, .T.)
		EndIf

		IF (!lSync) .OR. (lSync .AND. !lItemExists) 
			// I18n Item
			For nX := 1 to Len(aXNU[nI][DESC])
				If !oI18NItem:SeekLine({{"N_LANG", cValToChar(nX)}/*, {"N_DEFAULT", cDefault}*/}) // Localiza e ja posiciona na linha
					If oI18NItem:IsUpdated() .Or. oI18NItem:IsDeleted() .Or. lSync
						oI18NItem:AddLine()
					EndIf
				EndIf
				RUN_IF_TRUE lOk := oI18NItem:SetValue("N_LANG", cValToChar(nX), .T.)
				RUN_IF_TRUE lOk := oI18NItem:SetValue("N_DESC", aXNU[nI][MN_DESC][nX], .T.)
				RUN_IF_TRUE lOk := oI18NItem:SetValue("N_DEFAULT", cDefault, .T.)
			Next nX
	
			If lUpdate .And. !lSync
				// Quando for update e a linha não tiver sido sobreescrita, então indica que é uma linha q foi removida do XNU
				RUN_IF_TRUE lOk := RemoveDelItems(oI18NItem, "N_DEFAULT")
			EndIf
			
			
			RUN_IF_TRUE lOk := oItem:SetValue("I_FATHER", cID_Father, .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_ORDER", nI, .T.)
	
			RUN_IF_TRUE lOk := oItem:SetValue("I_TP_MENU", IIF(lFolder, '1', '2'), .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_STATUS", IF(aXNU[nI][STATUS]=="E", "1", IF(aXNU[nI][STATUS]=="D", "2", "3") ), .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_ITEMID", cItemId, .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_DEFAULT", cDefault, .T.)
		EndIf
		
		If lFolder

			RUN_IF_TRUE lOk := SetContents(lUpdate, ;
			                               aXNU[nI][CONTENT], ;
			                               cID_Menu, ;
			                               cI_ID, ;
			                               oItem, ;
			                               oI18NItem, ;
			                               oKeyWords, ;
			                               cDefault, ;
			                               lSync)
		Else

			RUN_IF_TRUE lOk := oItem:SetValue("I_ID_FUNC", GetIdFunction(aXNU[nI][MN_FUNC]), .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_RESNAME", aXNU[nI][MN_RESNAME], .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_TYPE", aXNU[nI][MN_TYPE], .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_TABLES", ArrTokStr(aXNU[nI][MN_TABLES],";"), .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_ACCESS", aXNU[nI][MN_ACCESS], .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_OWNER", aXNU[nI][MN_OWNER], .T.)
			RUN_IF_TRUE lOk := oItem:SetValue("I_MODULE", Val(aXNU[nI][MN_MODULE]), .T.)


		
			// KeyWord
			For nX := 1 to 3
				Do Case
				Case nX == 1
					cDesc := aXNU[nI][MN_K_PT]
				Case nX == 2
					cDesc := aXNU[nI][MN_K_ES]
				Case nX == 3
					cDesc := aXNU[nI][MN_K_EN]
				End Case

				If !Empty(cDesc)
					If !oKeyWords:SeekLine({{"K_LANG", cValToChar(nX)}/*, {"K_DEFAULT", cDefault}*/}) // Localiza e ja posiciona na linha
						If oKeyWords:IsUpdated() .Or. oKeyWords:IsDeleted() .Or. lSync
							oKeyWords:AddLine()
						EndIf
					EndIf
					RUN_IF_TRUE lOk := oKeyWords:SetValue("K_LANG", cValToChar(nX), .T.)
					RUN_IF_TRUE lOk := oKeyWords:SetValue("K_DESC", cDesc, .T.)
					RUN_IF_TRUE lOk := oKeyWords:SetValue("K_DEFAULT", cDefault, .T.)
				EndIf
			Next nX

			If lUpdate .And. !lSync
				// Quando for update e a linha não tiver sido sobreescrita, então indica que é uma linha q foi removida do XNU
				RUN_IF_TRUE lOk := RemoveDelItems(oKeyWords, "K_DEFAULT")
			EndIf 
		EndIf

		

	Next nI

Return lOk

Static Function RemoveDelItems(oMdl, cCpo_Default)
Local lOk   := .T.
Local nQtd
Local nLine
Local nX

	If !oMdl:IsEmpty()

		nLine := oMdl:GetLine()

		nQtd  := oMdl:Length()
		For nX := 1 to nQtd
			If !oMdl:IsUpdated(nX)
				RUN_IF_TRUE lOk := (oMdl:goLine(nX) == nX)
				//If oMdl:GetValue(cCpo_Default) == "1" // DEFAULT
					RUN_IF_TRUE lOk := oMdl:DeleteLine( , .T.)
				//EndIf
				//TODO: Verifiar se será necesário informar ao IDENTITY que o menu foi removido.
			EndIf
		Next

		oMdl:goLine(nLine)

	EndIf

Return lOk

Static Function GetIdFunction(cFunction, cDefault)
Local cId := ""
Local lMigrated := .F.
Local cGet := ""

Default cDefault := "1"

	If !Empty(cFunction)
		cFunction := AllTrim(cFunction)
				
		If __lMultiThread
			cId := FWUUIDV4(.F.)
			
			//-----------------------------------------------------------------------------------
			// Quando a importação é executada multithread, o semaforo é usado para guardar todas
			// as funções que já foram incluidas no banco, para driblar a concorrencia no banco
			//-----------------------------------------------------------------------------------						 
			lMigrated := VarGetX(__cUID,cFunction,@cGet)
			
			If !lMigrated				
				VarSetX(__cUID,cFunction,cId)
				MPMENU_FUNCTION->(DbAppend(.T.))				
				MPMENU_FUNCTION->F_ID       := cId
				MPMENU_FUNCTION->F_FUNCTION := cFunction
				MPMENU_FUNCTION->F_DEFAULT  := cDefault						
			Else
				cId := cGet		
			EndIf
			
		Else		
			MPMENU_FUNCTION->(dbSetOrder(2))
			//-------------------------------------------------------------------------------
			// Colocado o valor 50 para o PADR pois estava fazendo um dbseek soft. Caso o tamanho
			// do campo F_FUNCTION mude, mudar também o valor do PADR
			//-------------------------------------------------------------------------------
			If !MPMENU_FUNCTION->(dbSeek(cDefault+PADR(cFunction,50)))
				MPMENU_FUNCTION->(DbAppend(.T.))				
				MPMENU_FUNCTION->F_ID       := FWUUIDV4(.F.)
				MPMENU_FUNCTION->F_FUNCTION := cFunction
				MPMENU_FUNCTION->F_DEFAULT  := cDefault
			EndIf
			cId := MPMENU_FUNCTION->F_ID				
		EndIf
		
	EndIf

Return cId

//TODO: FAZER ISTO TAMBEM PARA OS ITEMS QUE NÃO ESIVEREM VINCULADOS A NENHUM MENU PADRÃO

//Se existir alguma função que não esta relacionada a nenhum menu padrão, então ela será removida
Function __ClearUnusedFunc()
Local cAlias  := "TMP_CLEAR"
Local lCommit := .F.

	If __cClearQry == Nil
		__cClearQry := " SELECT F.R_E_C_N_O_ F_REC "
		__cClearQry +=   " FROM " + MPSysSqlName("MPMENU_FUNCTION") + " F "
		__cClearQry +=   " LEFT JOIN " + MPSysSqlName("MPMENU_ITEM") + " I ON I.I_ID_FUNC = F.F_ID AND I.D_E_L_E_T_ = ''"
		__cClearQry +=  " WHERE I.I_ID_FUNC IS NULL"
		__cClearQry +=    " AND F.F_DEFAULT = '1'" // talves para todos?
		__cClearQry +=    " AND F.D_E_L_E_T_ = ''"

		__cClearQry := ChangeQuery(__cClearQry)
	EndIf

	DbUseArea( .T., "TOPCONN", TCGenQry(,,__cClearQry), cAlias, .F., .F. )

	While !(cAlias)->(Eof())
		MPMENU_FUNCTION->(dbGoTo((cAlias)->F_REC))
		If RecLock("MPMENU_FUNCTION", .F.)
			lCommit := .T.
			MPMENU_FUNCTION->(DbDelete())
			MPMENU_FUNCTION->(MsUnLock())
		EndIf
		(cAlias)->(dbSkip())
	End

	If lCommit
		MPMENU_FUNCTION->(DbCommit())
	EndIf

	(cAlias)->(DbCloseArea())

Return 


Function GetXnu()
Local aXnu := {} //{nModulo, cFile , cDescMod,  lDefault}
Local oStatement := nil
Local cQuery := ''
Local cAlias
Local aXnuDefaults := RetModName(.T.)
Local cDescMod := ''
Local nPos := 0
Local nX 
Local cStartPath := GetSrvProfString("StartPath","")
Local lDB2 := Upper(TCGETDB()) == "DB2"

//se tiver fluig só devolve os menus padroes
If FluigSSO() < 3 
	aXnu := aXnuDefaults
Else
	
//---------------------------------------------------------------------------------------
// A query não tem distinct explicito porque o union (sem o all) já faz um distinct
//---------------------------------------------------------------------------------------
	If lDB2
		cQuery += " SELECT DISTINCT MODULO, ARQMENU FROM ("
	EndIf
	
	cQuery += " SELECT  USR_MODULO MODULO, UPPER(USR_ARQMENU) ARQMENU"
	cQuery += " FROM " + MPSysSqlName("MPUSR_MODULE") 
	cQuery += " WHERE D_E_L_E_T_ =' ' "
	cQuery += " UNION "
	cQuery += " SELECT  GR__MODULO MODULO, UPPER(GR__ARQMENU) ARQMENU" 
	cQuery += " FROM " + MPSysSqlName("MPGRP_MODULE")
	cQuery += " WHERE D_E_L_E_T_ =' ' "
	cQuery += " ORDER BY 2"
	
	If lDB2
		cQuery += " )"
	EndIf
	
	cQuery := ChangeQuery(cQuery)
	
	oStatement := FWPreparedStatement():New(cQuery)
	cQuery := oStatement:getFixQuery()
	MPSysOpenQuery(cQuery,@cAlias)
	While (cAlias)->(!Eof())
			
		nPos := aScan(aXnuDefaults, {|x| x[1] == (cAlias)->(MODULO)})
		If nPos > 0 
			cDescMod := aXnuDefaults[nPos][3]
		Else
			cDescMod := ''
		EndIf
		
		aAdd(aXnu,{(cAlias)->(MODULO), (cAlias)->(ARQMENU)  , cDescMod, .F. })
		(cAlias)->(!DbSkip())
	Enddo
	oStatement:Destroy()
	
	(cAlias)->(DbCloseArea())
EndIf


//------------------------------------------------------------------------------
// junta menu de usuarios e grupos com menus padroes e ajusta flag 'default'
//------------------------------------------------------------------------------
For nX := 1 to Len(aXnuDefaults)

	//Procura o menu padrao na lista de menus de usuarios/grupos. 
	//Se encontrar , marca como padrao. Se nao achar, inclui o menu padrao. 	
	nPos := AScan(aXNU, {|x|Upper(Alltrim(x[2])) == Upper(AllTrim(cStartPath + aXnuDefaults[nX][2] + RetExtMnu())) } )  	
	
	If nPos > 0
		aXNU[nPos][4] := .T.	
	Else
		Aadd(aXnu, {aXnuDefaults[nX][1], cStartPath + aXnuDefaults[nX][2] + RetExtMnu(), aXnuDefaults[nX][3],  .T.} )
	EndIf
	
Next nX

Return(aXnu)



Function __UpdMenuUsrGr()

TcSQLExec("UPDATE " + MPSysSqlName("MPGRP_MODULE") + " SET GR__ARQMENU = COALESCE((SELECT M_ID FROM " + MPSysSqlName("MPMENU_MENU")+ " WHERE D_E_L_E_T_ =' ' AND UPPER(M_ARQMENU) = UPPER(GR__ARQMENU) AND GR__MODULO = M_MODULE ),SPACE(80)) ")

TcSQLExec("UPDATE " + MPSysSqlName("MPUSR_MODULE") + " SET USR_ARQMENU = COALESCE((SELECT M_ID FROM " + MPSysSqlName("MPMENU_MENU")+ " WHERE D_E_L_E_T_ =' ' AND UPPER(M_ARQMENU) = UPPER(USR_ARQMENU) AND USR_MODULO = M_MODULE ),SPACE(80)) ")


Return


Static Function FormatMnuName(cName)

Local cStartPath := GetSrvProfString("StartPath","")

cName := StrTran(upper(cName), upper(cStartPath), '')
cName := StrTran(upper(cName), '.XNU', '')
cName := StrTran(cName, '\', '_')
cName := StrTran(cName, '/', '_')


While AT('_',cName) == 1
	cName := SubStr(cName, 2, Len(cName) - 1)
EndDo


Return Alltrim(cName)




Function XNUDBRestore(a,b)

Local cText := ''

cText += 'O processo de restauração consiste em remover os itens de um determinado menu e importar novamente.'
cText += 'Neste processo, todos os itens de menu serão removidos. '
cText += CRLF + CRLF + 'Atenção: Para restaurar um menu coloque o arquivo com extensão XNU relativo ao menu no startpath. '
cText += 'Serão restaurados todos os menus que possuírem o arquivo no startpath. '
cText += CRLF + CRLF + 'Os menus encontrados para restauração estão listados ao lado.'

_ScrenDefUPDXnu(2, cText)



Return


Static Function _ScrenDefUPDXnu(nType, cText)
Local oDlgModal
Local oDlg
Local oTitle
Local oListXNU
Local cListXNU := ''
Local nX
Local aStatus := {}
Local cBtnText := IIF(nType == 1, 'Atualizar', 'Restaurar')
Local oText
Local cFunction := IIF(nType == 1, '__XNUDBSync', '__XNUDBRestore')

FWMsgRun(, {|| aStatus := __CheckXnus() },"Aguarde", "Carregando...")

//--------------------------
//Cria a Dialog Modal
//--------------------------
oDlgModal:= FWDialogModal():New()
oDlgModal:setCloseButton(.F.)
oDlgModal:setFreeArea(400,200)	
oDlgModal:setTitle(cBtnText + " Menus")
oDlgModal:createDialog()
oDlgModal:createFormBar()

If Len(aStatus) > 0
	oDlgModal:addCloseButton(, "Cancelar")
	oDlgModal:AddButton( cBtnText, &("{||"+ cFunction + "(aStatus),oDlgModal:oOwner:End()}"), cBtnText, , .T. )
Else
	oDlgModal:addCloseButton(, "Fechar")
EndIf

oDlg := oDlgModal:getPanelMain()

oText := TMultiget():new( 10, 10, {|| cText }, oDlg, 220, 150,,,,,,.T.,,,,,,.T.,,,,.F.,.F. )
oText:SetCss("TMultiGet{border:none;color: #808080;font-size: 16px;}")

oListXNU := TMultiget():new( 25, 160, {|| "" }, oDlg, 160, 120,,,,,,.T.,,,,,,.T.,,,,.F.,.T. )
oListXNU:Align := CONTROL_ALIGN_RIGHT

If Len(aStatus) > 0
	For nX := 1 to Len(aStatus)	
		cListXnu += aStatus[nx][1] + ' - ' + aStatus[nx][2] + CRLF	
	NExt nX
Else
	cListXNU := "Não há menus para " + cBtnText + "."
	cListXNU += CRLF + CRLF + "Nenhum arquivo com extensão XNU foi encontrado no startpath."
EndIf

oListXNU:AppendText(cListXnu)
oListXNU:GoTop()

oDlgModal:activate()

aStatus := ASize(aStatus,0)

Return

Function XNUDBSync(a,b)

Local cText := ''

cText += 'O processo de atualização consiste em adicionar novos itens padrões de menu.'
cText += ' Nesse processo, os itens de menu já existentes não serão alterados, apenas novos itens serão incluídos. Itens que foram excluídos pelo usuário não serão restaurados.'
cText += CRLF + CRLF + 'Atenção: Para atualizar um menu coloque o arquivo com extensão XNU relativo ao menu no startpath. '
cText += CRLF +'Serão atualizados todos os menus que possuírem o arquivo no startpath. '
cText += CRLF + CRLF + 'Os menus encontrados para atualização estão listados ao lado.'

_ScrenDefUPDXnu(1, cText)

Return
		

function __XNUDBRestore(aStatus)
Local nX
Local aXnu 
Local cIDMenu := ''
Local cMD5
Local cFile

If MsgYesNo( "Deseja iniciar o processo de restauração de menus?" ,  "Atenção")
	For nX := 1 to Len(aStatus)
		
		cFile := aStatus[nX][6]
		cMD5 := MD5File(cFile)
			
		aXnu := aStatus[nX][3] //estrutura do menu
			
		//---------------------------------------------
		//Deleta os itens do menu que será reimportado
		//---------------------------------------------
		cIDMenu := MPSysExecScalar("SELECT M_ID FROM "+ MPSysSqlName("MPMENU_MENU") +" WHERE D_E_L_E_T_ =' '  AND M_NAME = '"+ Alltrim(upper(aStatus[nX][1]))+ "' AND M_DEFAULT = " + CValToChar(aStatus[nX][5]), "M_ID")
		If !Empty(cIDMenu)
			TcSQLExec("DELETE FROM "+ MPSysSqlName("MPMENU_ITEM") + " WHERE I_ID_MENU = '"+cIDMenu+"'")
		EndIf
				
		//----------------------------------------
		//Reimporta o menu (apenas os itens, o registro pai continua o mesmo, para não ter problemas com o ID)	
		//----------------------------------------
		FWMsgRun(, {|| MPDBXnuImport(aXNU, aStatus[nX][1], aStatus[nX][2], aStatus[nX][4], , , aStatus[nX][5] == 1, cMD5, , cFile) },"Restaurando Menus", "Restaurando menu " + aStatus[nX][1] + ".")
						
		//----------------------------------------
		//Limpa variáveis
		//----------------------------------------
		aXnu := ASize(aXnu,0)	
		
		//----------------------------------------
		// Menu customizado atualiza o DEFAULT para 2
		//----------------------------------------
		If aStatus[nX][5] = 2
			TCSQLExec("UPDATE " + MPSysSqlName("MPMENU_MENU") + " SET M_DEFAULT = 2 WHERE D_E_L_E_T_ =' ' AND M_MD5_FILE = '" + cMD5 + "'")
		EndIf			
			
	Next nX

	
	APMsgInfo("Menus restaurados com sucesso")
EndIf

Return 



Function _XNUItemExists(cIDMenu, cItemId, lDeleted)

Local cID
Local cQuery 
Local lRet := .F.

Default lDeleted := .T. //Considera itens deletados 

cQuery := "SELECT I_ID FROM "+ MPSysSqlName("MPMENU_ITEM") + ;
" WHERE I_ITEMID = '"+ cItemId + "' AND I_ID_MENU = '"+ cIDMenu+ "' AND I_DEFAULT = 1"

If !lDeleted	
	cQuery +=  " AND D_E_L_E_T_ =' '  "
EndIf

//Verifica se existe o item de menu padrao no banco
cID := MPSysExecScalar(cQuery, "I_ID")

lRet := !Empty(cID)

Return lRet




Function __XNUDBSync(aStatus)
Local nX
Local cIDMenu
Local aXNU
Local lNewMenu
Local cFile
Local cMD5

If MsgYesNo(  "Deseja iniciar o processo de atualização de menus?",  "Atenção")
    //--------------------------------------------------------
    //Inserir menus novos ou atualiza menus com itens novos
    //-------------------------------------------------------
	For nX := 1 to Len(aStatus)
		cFile := aStatus[nX][6]
		cMD5 := MD5File(cFile)
		
		aXnu := aStatus[nX][3] //estrutura do menu
		cIDMenu := MPSysExecScalar("SELECT M_ID FROM "+ MPSysSqlName("MPMENU_MENU") +" WHERE D_E_L_E_T_ =' '  AND M_NAME = '"+ Alltrim(upper(aStatus[nX][1]))+ "' AND M_DEFAULT = '" + CValToChar(aStatus[nX][5]) +"'", "M_ID")
		
		//--------------------------------------------------------------------------------------
		//Se o menu for customizado, apaga e reimporta todos os itens que não possuirem ITEMID
		//Isso é necessario pois sem o codigo ITEMID não tem como encontrar o registro
		//--------------------------------------------------------------------------------------
		If !Empty(cIDMenu) .And. aStatus[nX][5]
			TcSQLExec("DELETE FROM "+ MPSysSqlName("MPMENU_ITEM") + " WHERE I_ID_MENU = '"+cIDMenu+"' AND I_ITEMID = '' ")
		EndIf
		
		lNewMenu := Empty(cIDMenu)
		FWMsgRun(, {|| MPDBXnuImport(aXNU, aStatus[nX][1], aStatus[nX][2], aStatus[nX][4], , , aStatus[nX][5] == 1,cMD5 , ,cFile, !lNewMenu ) },"Atualização de Menus", "Atualizando menu " + aStatus[nX][1] + ".")
				
		//----------------------------------------
		//Limpa variáveis
		//----------------------------------------
		aXnu := ASize(aXnu,0)
				
		//----------------------------------------
		// Menu customizado atualiza o DEFAULT para 2
		//----------------------------------------
		If aStatus[nX][5] = 2
			TCSQLExec("UPDATE " + MPSysSqlName("MPMENU_MENU") + " SET M_DEFAULT = 2 WHERE D_E_L_E_T_ =' ' AND M_MD5_FILE = '" + cMD5 + "'")
		EndIf
	Next nX
	
	APMsgInfo("Menus atualizados com sucesso")
EndIf
Return

