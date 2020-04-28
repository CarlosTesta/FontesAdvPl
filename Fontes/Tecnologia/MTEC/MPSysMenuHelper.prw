#INCLUDE 'Protheus.ch'

Static __TABLE_MENU := MPSysSqlName("MPMENU_MENU")

Function MPMnuExist(cMenu, nOrder)
Local xPk := cMenu

Default nOrder := 2

	If nOrder == 1
		cMenu := MPDBMenuFind(cMenu)
	EndIf

Return MPSeekMenu("MPMENU_MENU", xPk, nOrder)

Function MPSeekMenu(cTable, xPk, nOrder)
Local lRet := .F.

Default xPk    := ""
Default nOrder := 1

	If "MPMENU_" $ cTable
		(cTable)->(dbSetOrder(nOrder))
		lRet := (cTable)->(DbSeek( xPK ))
	EndIf

Return lRet

Function MPGetMenus()
Local aRet   := {}
Local cQuery := ""
Local cAlias := GetNextAlias()

	cQuery += " SELECT M_ID, M_NAME, M_DEFAULT "
	cQuery +=   " FROM "+__TABLE_MENU
	cQuery +=  " WHERE D_E_L_E_T_ = '' "
	cQuery := ChangeQuery(cQuery)

	DbUseArea( .T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .F. )

	While !(cAlias)->(Eof())
		aAdd(aRet, {(cAlias)->M_ID, AllTrim((cAlias)->M_NAME), (cAlias)->M_DEFAULT} )
		(cAlias)->(dbSkip())
	End

	(cAlias)->(dbCloseArea())

Return aRet