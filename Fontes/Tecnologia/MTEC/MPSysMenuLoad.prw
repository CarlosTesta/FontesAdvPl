#INCLUDE 'Protheus.ch'
#INCLUDE "TBICONN.CH"
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

#DEFINE _ID        1
#DEFINE _TP_MENU   2
#DEFINE _ITEMID    3
#DEFINE _STATUS    4
#DEFINE _FATHER    5
#DEFINE _ORDER     6
#DEFINE _ID_FUNC   7
#DEFINE _FUNCTION  7
#DEFINE _RESNAME   8
#DEFINE _TYPE      9
#DEFINE _TABLES   10
#DEFINE _ACCESS   11
#DEFINE _OWNER    12
#DEFINE _DEFAULT  13
#DEFINE _K_PT     14
#DEFINE _K_ES     15
#DEFINE _K_EN     16
#DEFINE _N_PT     17
#DEFINE _N_ES     18
#DEFINE _N_EN     19
#DEFINE _MODULE   20

Static __cQuery

Function MPDBMenuFind(cSearch, nOrder)
	
	Local cRet := ''
	
	Default nOrder := 2
	
	If !Empty(cSearch)
		MPMENU_MENU->(dbSetOrder(nOrder))
		
		If MPMENU_MENU->(dbSeek(Alltrim(cSearch)))
			If nOrder == 1 //busca pelo M_ID e retorna pelo M_NAME
				cRet := MPMENU_MENU->M_NAME
			ElseIf nOrder == 2 //busca pelo M_NAME e retorna o M_ID
				cRet := MPMENU_MENU->M_ID
			EndIf
		EndIf
	
	EndIf
	
		
Return cRet
Static __lHasDefault 
Function MPDBMenuLoad(cId, lEdit, lReservedWords, cUId, cModName, cModVersion)
Local aMenu := {}
Local oPersit
	If __lHasDefault == Nil	
		oPersit := MPUserPersist()
		__lHasDefault  := oPersit:hasDefaultGroup(__cUserID)  
	Endif
	MPMENU_MENU->(dbSetOrder(1))

	If !Empty(cId) .And. MPMENU_MENU->(dbSeek(cId))

		cUId        := MPMENU_MENU->M_ID
		cModName    := MPMENU_MENU->M_NAME
		cModVersion := MPMENU_MENU->M_VERSION

		aMenu := MPMnuGetItems(@aMenu, cId, cId, MPMENU_MENU->M_MODULE, lEdit, lReservedWords)

	EndIf

	If Empty(aMenu)
		FwFrameTrace({{i18n("Menu Id #1", {cId}), "Not found"}} ,3)
	EndIf

Return aMenu

Function MPMnuGetItems(aMenu, cId_Menu, cFather, nModule, lEdit, lReservedWords, lUserReport)
Local aChildren
Local lFolder
Local nI, nQtd
Local aKeyWords
Local aTmp

Default lEdit          := .T.
Default lReservedWords := .F.
Default lUserReport    := .F.

	
	If lUserReport
		__cQuery := Nil//Se for impressão de relatório limpo a variavel de cQuery
	EndIf
	
	aChildren := GetChildren(cId_Menu, cFather)
	nQtd      := Len(aChildren)
	For nI := 1 To nQtd

		lFolder := aChildren[nI][2] == "1"

		aTmp         := Array(5)
		aTmp[STATUS] := aChildren[nI][_STATUS]
		Do Case
		Case aTmp[STATUS] == "1"
			aTmp[STATUS] := "E"
		Case aTmp[STATUS] == "2"
			aTmp[STATUS] := "D"
		Case aTmp[STATUS] == "3"
			aTmp[STATUS] := "H"
		End Case

		// I18n
		aTmp[DESC] := {AllTrim(aChildren[nI][_N_PT]), ;
		               AllTrim(aChildren[nI][_N_ES]), ;
		               AllTrim(aChildren[nI][_N_EN])}

		If lFolder

			aTmp[CONTENT] := {}
			aTmp[UID]     := aChildren[nI][_ID]
			aTmp[ITEMID]  := AllTrim(aChildren[nI][_ITEMID])
			MPMnuGetItems(@aTmp[CONTENT], cId_Menu, aChildren[nI][_ID], nModule, lEdit, lReservedWords)

			If !Empty(aTmp[CONTENT]) // Se a pasta não tiver itens, então não será mostrada

				If !(AllTrim(aTmp[ITEMID]) == 'B'+strZero(nModule, 2)+'0000001') .Or. lReservedWords // Reserved Words
					aAdd(aMenu, aClone(aTmp))
				EndIf

			EndIf

		Else

			aTmp             := aSize(aTmp, 15)
			aTmp[MN_FUNC]    := AllTrim(aChildren[nI][_FUNCTION])
			aTmp[MN_TABLES]  := StrtoKArr(AllTrim(aChildren[nI][_TABLES]),";")
			aTmp[MN_ACCESS]  := AllTrim(aChildren[nI][_ACCESS])
			aTmp[MN_MODULE]  := StrZero(aChildren[nI][_MODULE], 3)
			aTmp[MN_TYPE]    := aChildren[nI][_TYPE]
			aTmp[MN_RESNAME] := AllTrim(aChildren[nI][_RESNAME])
			aTmp[MN_OWNER]   := AllTrim(aChildren[nI][_OWNER])
			aTmp[MN_UID]     := aChildren[nI][_ID]
			aTmp[MN_ITEMID]  := AllTrim(aChildren[nI][_ITEMID])

			aTmp[MN_K_PT] := aChildren[nI][_K_PT]
			aTmp[MN_K_ES] := aChildren[nI][_K_ES]
			aTmp[MN_K_EN] := aChildren[nI][_K_EN]

			If "Reserved Words" $ aChildren[nI][_N_EN]
				aTmp[MN_RESERV] := GetRW()
			EndIf

			aAdd(aMenu, aTmp)

		Endif

	Next

	aSize(aChildren, 0)

Return aMenu

Static Function GetChildren(cId_Menu, cFather)
Local aRet   := {}
Local cQuery := ""
Local cAlias := "TMP_CHILDREN"
//Local nTime  := Seconds()

	cQuery := GetQuery(cId_Menu, cFather)

	//Memowrite("\QRY.txt", cQuery)

	DbUseArea( .T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .F. )

	While !(cAlias)->(Eof())
		aAdd(aRet, {(cAlias)->I_ID,(cAlias)->I_TP_MENU,(cAlias)->I_ITEMID, ;
		            (cAlias)->I_STATUS,(cAlias)->I_FATHER,(cAlias)->I_ORDER, ;
		            (cAlias)->F_FUNCTION,(cAlias)->I_RESNAME,(cAlias)->I_TYPE, ;
		            (cAlias)->I_TABLES,(cAlias)->I_ACCESS,(cAlias)->I_OWNER, ;
		            (cAlias)->I_DEFAULT, ;
		            AllTrim((cAlias)->K_PT), AllTrim((cAlias)->K_ES), AllTrim((cAlias)->K_EN), ;
		            (cAlias)->N_PT, (cAlias)->N_ES, (cAlias)->N_EN, ;
		            (cAlias)->I_MODULE } )
		(cAlias)->(dbSkip())
	End

	(cAlias)->(DbCloseArea())

//	i18nConOut("Time to Children: #1", {Seconds()-nTime})

Return aRet

Static Function GetQuery(cId_Menu, cFather)

	If __cQuery == Nil
		__cQuery := " SELECT I.I_ID_MENU,I.I_ID,I.I_TP_MENU,I.I_ITEMID,"
	  __cQuery +=        " I.I_STATUS,I.I_FATHER,I.I_ORDER,F.F_FUNCTION,"
	  __cQuery +=        " I.I_RESNAME,I.I_TYPE,I.I_TABLES,I.I_ACCESS,"
	  __cQuery +=        " I.I_OWNER,I.I_MODULE,I.I_DEFAULT,"
	  __cQuery +=        " K1.K_DESC K_PT, K2.K_DESC K_ES, K3.K_DESC K_EN,"
	  __cQuery +=        " N1.N_DESC N_PT, N2.N_DESC N_ES, N3.N_DESC N_EN "
		__cQuery +=   " FROM " + MPSysSqlName("MPMENU_ITEM") + " I "
		__cQuery +=   " LEFT JOIN " + MPSysSqlName("MPMENU_FUNCTION") + " F ON F.F_ID = I.I_ID_FUNC AND F.D_E_L_E_T_ = ' '"
		__cQuery +=   " LEFT JOIN " + MPSysSqlName("MPMENU_KEY_WORDS") + " K1 ON K1.K_ID_ITEM = I.I_ID AND K1.K_LANG = '1' AND K1.D_E_L_E_T_ = ' '"
		__cQuery +=   " LEFT JOIN " + MPSysSqlName("MPMENU_KEY_WORDS") + " K2 ON K2.K_ID_ITEM = I.I_ID AND K2.K_LANG = '2' AND K2.D_E_L_E_T_ = ' '"
		__cQuery +=   " LEFT JOIN " + MPSysSqlName("MPMENU_KEY_WORDS") + " K3 ON K3.K_ID_ITEM = I.I_ID AND K3.K_LANG = '3' AND K3.D_E_L_E_T_ = ' '"
		__cQuery +=   " LEFT JOIN " + MPSysSqlName("MPMENU_I18N") + " N1 ON N1.N_PAREN_TP = '2' AND N1.N_PAREN_ID = I.I_ID AND N1.N_LANG = '1' AND N1.D_E_L_E_T_ = ' '"
		__cQuery +=   " LEFT JOIN " + MPSysSqlName("MPMENU_I18N") + " N2 ON N2.N_PAREN_TP = '2' AND N2.N_PAREN_ID = I.I_ID AND N2.N_LANG = '2' AND N2.D_E_L_E_T_ = ' '"
		__cQuery +=   " LEFT JOIN " + MPSysSqlName("MPMENU_I18N") + " N3 ON N3.N_PAREN_TP = '2' AND N3.N_PAREN_ID = I.I_ID AND N3.N_LANG = '3' AND N3.D_E_L_E_T_ = ' '"
		__cQuery +=  " WHERE I.I_ID_MENU = '#1'"
		__cQuery +=    " AND I.I_FATHER  = '#2'"
		__cQuery +=    " AND I.D_E_L_E_T_ = ' ' "
		If Type("__cUserID") != "U" .And. __cUserID <> "000000"
			__cQuery +=    GetFuncRules("#3")
		EndIf
		__cQuery +=  " ORDER BY I.I_ORDER"

		__cQuery := ChangeQuery(__cQuery)
	EndIf

Return i18n(__cQuery, {cId_Menu, cFather, IIf(Type("__cUserID") != "U", __cUserID, "''")})

Static Function GetFuncRules(cTag)
Local cQuery := ""

	MPRulesOpenTable() // Forçar a abertura das tabelas de privilégios
	
	cQuery +=	" AND (I_TP_MENU = 1 OR F.F_FUNCTION IS NULL OR "
	cQuery +=	     " (I_TP_MENU = 2 "
	cQuery +=	  " AND EXISTS ( "
	If !__lHasDefault
		cQuery +=				"SELECT M.F_FUNCTION "
		cQuery +=	                 " FROM " + MPSysSqlName("MPMENU_FUNCTION") + " M "
		cQuery +=	                " WHERE M.F_FUNCTION = F.F_FUNCTION "
		cQuery +=	               " EXCEPT "
	Endif
	//cQuery +=	               " ( "
	cQuery +=	               " SELECT RT.RL__ROTINA "
	cQuery +=	                 " FROM " + MPSysSqlName("MPUSR_GROUPS") + " UG "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPURL_RULES") + " RUR ON (RUR.USER_ID = UG.USR_ID AND "
	cQuery +=	                                                                       " RUR.D_E_L_E_T_ = ' ') "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPRL_TRANS") + " RT ON (RT.RL__ID = RUR.USR_RL_ID AND "
	cQuery +=                                                                      " RT.RL__ACESSO = '2' AND " // Nao Permitido
	cQuery +=                                                                      " RT.RL__ROTINA = F.F_FUNCTION AND "
	cQuery +=	                                                                     " RT.D_E_L_E_T_ = ' ') "
	cQuery +=	                " WHERE UG.D_E_L_E_T_ = ' ' "
	cQuery +=	                  " AND UG.USR_ID     = '" + cTag + "'"
	cQuery +=	                " UNION "
	cQuery +=	               " SELECT RT.RL__ROTINA "
	cQuery +=	                 " FROM " + MPSysSqlName("MPUSR_GROUPS") + " UG "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPGRL_RULES") + " RGR ON (RGR.GROUP_ID = UG.USR_GRUPO AND "
	cQuery +=	                                                                       " RGR.D_E_L_E_T_ = ' ') "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPRL_TRANS") + " RT ON ( RT.RL__ID = RGR.GR__RL_ID AND "
	cQuery +=                                                                       " RT.RL__ACESSO = '2' AND " // Nao Permitido
	cQuery +=                                                                       " RT.RL__ROTINA = F.F_FUNCTION AND "
	cQuery +=	                                                                      " RT.D_E_L_E_T_ = ' ') "
	cQuery +=	                " WHERE UG.D_E_L_E_T_ = ' ' "
	cQuery +=	                  " AND UG.USR_ID     = '" + cTag + "'"
//	cQuery +=	               " ) "

	cQuery +=	                " UNION "

//	cQuery +=	               " ( "
	cQuery +=	               " SELECT RT.RL__ROTINA "
	cQuery +=	                 " FROM " + MPSysSqlName("MPUSR_GROUPS") + " UG "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPURL_RULES") + " RUR ON (RUR.USER_ID = UG.USR_ID AND "
	cQuery +=	                                                                       " RUR.D_E_L_E_T_ = ' ') "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPRL_TRANS") + " RT ON (RT.RL__ID = RUR.USR_RL_ID AND "
	cQuery +=                                                                      " RT.RL__ACESSO = '1' AND " // Permitido
	cQuery +=                                                                      " RT.RL__ROTINA = F.F_FUNCTION AND "
	cQuery +=	                                                                     " RT.D_E_L_E_T_ = ' ') "
	cQuery +=	                " WHERE UG.D_E_L_E_T_ = ' ' "
	cQuery +=	                  " AND UG.USR_ID     = '" + cTag + "'"
	cQuery +=	                " UNION "
	cQuery +=	               " SELECT RT.RL__ROTINA "
	cQuery +=	                 " FROM " + MPSysSqlName("MPUSR_GROUPS") + " UG "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPGRL_RULES") + " RGR ON (RGR.GROUP_ID = UG.USR_GRUPO AND "
	cQuery +=	                                                                       " RGR.D_E_L_E_T_ = ' ') "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPRL_TRANS") + " RT ON ( RT.RL__ID = RGR.GR__RL_ID AND "
	cQuery +=                                                                       " RT.RL__ACESSO = '1' AND " // Permitido
	cQuery +=                                                                       " RT.RL__ROTINA = F.F_FUNCTION AND "
	cQuery +=	                                                                      " RT.D_E_L_E_T_ = ' ') "
	cQuery +=	                " WHERE UG.D_E_L_E_T_ = ' ' "
	cQuery +=	                  " AND UG.USR_ID     = '" + cTag + "'"
	//cQuery +=	               " ) "

	cQuery +=	               " EXCEPT "

	//cQuery +=	               " ( "
	cQuery +=	               " SELECT RT.RL__ROTINA "
	cQuery +=	                 " FROM " + MPSysSqlName("MPUSR_GROUPS") + " UG "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPURL_RULES") + " RUR ON (RUR.USER_ID = UG.USR_ID AND "
	cQuery +=	                                                                       " RUR.D_E_L_E_T_ = ' ') "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPRL_TRANS") + " RT ON (RT.RL__ID = RUR.USR_RL_ID AND "
	cQuery +=                                                                      " RT.RL__ACESSO = '2' AND " // Negado
	cQuery +=                                                                      " RT.RL__ROTINA = F.F_FUNCTION AND "
	cQuery +=	                                                                     " RT.D_E_L_E_T_ = ' ') "
	cQuery +=	                " WHERE UG.D_E_L_E_T_ = ' ' "
	cQuery +=	                  " AND UG.USR_ID     = '" + cTag + "'"
	cQuery +=	                " UNION "
	cQuery +=	               " SELECT RT.RL__ROTINA "
	cQuery +=	                 " FROM " + MPSysSqlName("MPUSR_GROUPS") + " UG "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPGRL_RULES") + " RGR ON (RGR.GROUP_ID = UG.USR_GRUPO AND "
	cQuery +=	                                                                       " RGR.D_E_L_E_T_ = ' ') "
	cQuery +=	                " INNER JOIN " + MPSysSqlName("MPRL_TRANS") + " RT ON ( RT.RL__ID = RGR.GR__RL_ID AND "
	cQuery +=                                                                       " RT.RL__ACESSO = '3' AND " // Negado
	cQuery +=                                                                       " RT.RL__ROTINA = F.F_FUNCTION AND "
	cQuery +=	                                                                      " RT.D_E_L_E_T_ = ' ') "
	cQuery +=	                " WHERE UG.D_E_L_E_T_ = ' ' "
	cQuery +=	                  " AND UG.USR_ID     = '" + cTag + "'"
//	cQuery +=	               " ) "

	cQuery +=	            ")"
	cQuery +=	       ")"
	cQuery +=	    ")"

Return cQuery

Static Function GetRW()
Local aRet   := {{"POR T",""},{"POR P",""},{"SPA E",""},{"ENG I",""}}
Local cQuery := ""
Local cAlias := "TMP_RW"

	cQuery += "SELECT RW.R_LANG, RW.R_DESC"
	cQuery +=  " FROM " + MPSysSqlName("MPMENU_RESERVED_WORD") + " RW "
	cQuery += " WHERE RW.R_DEFAULT = '1'"
	cQuery +=   " AND RW.D_E_L_E_T_ = ' '"

	DbUseArea( .T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .F. )

	While !(cAlias)->(Eof())

		Do Case
		Case (cAlias)->R_LANG == "1" //"POR T"
			aRet[1][2] := (cAlias)->R_DESC
		Case (cAlias)->R_LANG == "2" //"POR P"
			aRet[2][2] := (cAlias)->R_DESC
		Case (cAlias)->R_LANG == "3" //"SPA E"
			aRet[3][2] := (cAlias)->R_DESC
		Case (cAlias)->R_LANG == "4" //"ENG I"
			aRet[4][2] := (cAlias)->R_DESC
		End Case

		(cAlias)->(dbSkip())

	End

	(cAlias)->(DbCloseArea())

Return aRet



Function MPDBMenuName(cID)
return MPDBMenuFind(cID, 1) 


Function MPDBMenuID(cName)
return MPDBMenuFind(cName, 2) 

