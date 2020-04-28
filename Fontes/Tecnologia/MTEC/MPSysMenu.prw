#Include 'Protheus.ch'
#INCLUDE "TBICONN.CH"
#INCLUDE 'FWMvcDef.ch'

Static __MenuInDB
Static __cQryCustom

Function MPMenuInDB(lForce, lSetVersion, oLogFile)

Default lForce      := .F.
Default lSetVersion := .F.

#IFDEF TOP
	If __MenuInDB == Nil
		__MenuInDB := !Empty(MPSGetInfo("MENU"))
	EndIf

	If !__MenuInDB .And. lSetVersion
		MPSInfoAdd("MENU", GetRPORelease())
		__MenuInDB := .T.
	EndIf

	If lForce .Or. (__MenuInDB .And. Select("MPMENU_MENU") == 0)
		MPSysOpenTables({"MPMENU_MENU", ;
		                 "MPMENU_I18N", ;
		                 "MPMENU_ITEM", ;
		                 "MPMENU_KEY_WORDS", ;
		                 "MPMENU_FUNCTION", ;
		                 "MPMENU_RESERVED_WORD"},,,,,,,oLogFile,.T.)
	EndIf
#ELSE
	__MenuInDB := .F.
#ENDIF

Return __MenuInDB

Function MPMnuLooksUp()
Local oStruct := __MPMnuStruMenu()
Local oLkStr

	oLkStr := oStruct:GetLookUPStruct("M_ID|M_ARQMENU|M_VERSION|M_MD5_FILE|M_DEFAULT|M_DESC")
	oLkStr:SetReturnsFields({"M_NAME"})

	FWMakeLookup("_DBMENU", "Consulta de Menus", oLkStr, "DB")

Return oLkStr

Function __MPMnuStruMenu()
Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("MPMENU_MENU", {"M_ID"}, "Menus do Microsiga Protheus", {|oStru| MPSysTblPrefix()+"MPMENU_MENU"}) //"Menus do Microsiga Protheus"
	oStruct:AddIndex(1, "01", "M_ID"    , "Código", "", "", .T. ) //"Código"
	oStruct:AddIndex(1, "02", "M_NAME"  , "Nome"  , "", "", .T. ) //"Nome"
	oStruct:AddIndex(1, "03", "M_MODULE", "Módulo", "", "", .T. ) //"Módulo"

	oStruct:AddField("ID"       , "", "M_ID"      , "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Nome"     , "", "M_NAME"    , "C",  50, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Descrição", "", "M_DESC"    , "C", 150, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,{|| GetMenuDesc() }/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/)
	oStruct:AddField("Versão"   , "", "M_VERSION" , "C",  10, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Módulo"   , "", "M_MODULE"  , "N",   3, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("MD5"      , "", "M_MD5_FILE", "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Padrão"   , "", "M_DEFAULT" , "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Sim","2=Não"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Arq Menu" , "", "M_ARQMENU" , "C",  80, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)

Return oStruct

Static Function GetStruItem()
Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("MPMENU_ITEM", {"I_ID_MENU", "I_ID"}, "Itens dos menus do Microsiga Protheus", {|oStru| MPSysTblPrefix()+"MPMENU_ITEM"}) //"Itens dos menus do Microsiga Protheus"
	oStruct:AddIndex(1, "01", "I_ID_MENU+I_ID+I_ID_FUNC"    , "Id Menu+Código+Rotina", "", "", .T. ) //"Id Menu"+"Código"+"ID Rotina"
	oStruct:AddIndex(1, "02", "I_ID_MENU+I_DEFAULT+I_ITEMID", "Id Menu+ItemID"       , "", "", .T. ) //"Id Menu"+"ItemID"
	oStruct:AddIndex(1, "03", "I_ID_MENU+I_FATHER+I_TP_MENU", "Id Menu+Pai+Tipo Menu", "", "", .T. ) //"Id Menu"+"Pai"+"Tipo Menu"

	oStruct:AddField("ID Menu"     , "", "I_ID_MENU", "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("ID"          , "", "I_ID"     , "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Pai"         , "", "I_FATHER" , "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Ordem"       , "", "I_ORDER"  , "N",   4, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("ItemID"      , "", "I_ITEMID" , "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Tipo Item"   , "", "I_TP_MENU", "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Pasta","2=Item"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Status"      , "", "I_STATUS" , "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Enable","2=Disable","3=Hidden"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Rotina"      , "", "I_ID_FUNC", "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("ResName"     , "", "I_RESNAME", "C",  10, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Tipo"        , "", "I_TYPE"   , "N",   1, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Tabelas"     , "", "I_TABLES" , "C", 254, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Acesso"      , "", "I_ACCESS" , "C",  10, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Proprietário", "", "I_OWNER"  , "C",  10, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Módulo"	   , "", "I_MODULE" , "N",   3, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Padrão"      , "", "I_DEFAULT", "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Sim","2=Não"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)

Return oStruct

Static Function GetStruKeyWord()
Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("MPMENU_KEY_WORDS", {"K_ID_ITEM", "K_LANG"}, "Palavres chaves das funções dos menus do Microsiga Protheus", {|oStru| MPSysTblPrefix()+"MPMENU_KEY_WORDS"}) //"Palavres chaves das funções dos menus do Microsiga Protheus"
	oStruct:AddIndex(1, "01", "K_ID_ITEM+K_LANG", "Função+Língua", "", "", .T. ) //"Função"+"Língua"
	oStruct:AddIndex(1, "02", "K_DESC"          , "Descrição"    , "", "", .T. ) //"Descrição"

	oStruct:AddField("Função"   , "", "K_ID_ITEM", "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Língua"   , "", "K_LANG"   , "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=pt","2=es","3=en"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Descrição", "", "K_DESC"   , "C", 250, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Padrão"   , "", "K_DEFAULT", "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Sim","2=Não"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)

Return oStruct

Function MPMnuStruI18n()
Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("MPMENU_I18N", {"N_PAREN_TP", "N_PAREN_ID", "N_LANG"}, "I18n dos menus e funções do Microsiga Protheus", {|oStru| MPSysTblPrefix()+"MPMENU_I18N"}) //"I18n dos menus e funções do Microsiga Protheus"
	oStruct:AddIndex(1, "01", "N_PAREN_TP+N_PAREN_ID+N_LANG", "Parent+Parent ID+Língua", "", "", .T. ) //"Parent"+"Parent ID"+"Língua"
	oStruct:AddIndex(1, "02", "N_DESC"                      , "Descrição"              , "", "", .T. ) //"Descrição"

	oStruct:AddField("Parent"   , "Parent"   , "N_PAREN_TP", "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Menu","2=Item"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Parent ID", 'Parent ID', "N_PAREN_ID", "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Língua"   , 'Língua'   , "N_LANG"    , "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=pt","2=es","3=en"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Descrição", 'Descrição', "N_DESC"    , "C", 250, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Padrão"   , 'Padrão'   , "N_DEFAULT" , "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Sim","2=Não"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)

Return oStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} Modeldef
Modelo de dados do menu       

@author Felipe Bonvicini Conti
@since 07/10/2014
@version $Version
/*/
//-------------------------------------------------------------------
Static Function Modeldef()
Local oModel  := NIL
Local oStrMenu
Local oStrItem
Local oStrKW
Local oStrI18n

	oStrMenu     := __MPMnuStruMenu()
	oStrItem     := GetStruItem()
	oStrKW       := GetStruKeyWord()
	oStrI18n     := MPMnuStruI18n()

	oStrMenu:Activate()
	oStrItem:Activate()
	oStrKw:Activate()
	oStrI18n:Activate()

	oModel:= FWFormModel():New("MPSysMenu",/*Pre-Validacao*/,/*Pos-Validacao*/,{|oMdl| MPUserCommit(oMdl)}, {|oMdl| FWFormCancel(oMdl)})
	oModel:AddFields("MENU", NIL, oStrMenu, /*Pre-Validacao*/, /*Pos-Validacao*/, {|oField| FormLoadField(oField) }/*Carga*/)
	oModel:AddGrid("ITEM", "MENU", oStrItem, /*Pre-Validacao*/, /*Pos-Validacao*/,,, {|oField| FormLoadGrid(oField,,.F.) } /*Carga*/)
	oModel:AddGrid("KEYWORDS", "ITEM", oStrKW, /*Pre-Validacao*/, /*Pos-Validacao*/,,, {|oField| FormLoadGrid(oField,,.F.) } /*Carga*/)
	oModel:AddGrid("I18N_MENU", "MENU", oStrI18n, /*Pre-Validacao*/, /*Pos-Validacao*/,,, {|oField| FormLoadGrid(oField,,.F.) } /*Carga*/)
	oModel:AddGrid("I18N_ITEM", "ITEM", oStrI18n, /*Pre-Validacao*/, /*Pos-Validacao*/,,, {|oField| FormLoadGrid(oField,,.F.) } /*Carga*/)

	oModel:SetPrimaryKey({})

	oModel:SetRelation( 'ITEM', { { 'I_ID_MENU', 'M_ID'} }, 'I_ID_MENU' )
	oModel:SetRelation( 'I18N_MENU', { { 'N_PAREN_TP', "'1'"}, { 'N_PAREN_ID', 'M_ID' } }, 'N_PAREN_TP+N_PAREN_ID+N_LANG' )
	oModel:SetRelation( 'I18N_ITEM', { { 'N_PAREN_TP', "'2'"}, { 'N_PAREN_ID', 'I_ID' } }, 'N_PAREN_TP+N_PAREN_ID+N_LANG' )
	oModel:SetRelation( 'KEYWORDS' , { { 'K_ID_ITEM', 'I_ID'} }, 'K_ID_ITEM' )

	oModel:GetModel( 'ITEM' ):SetOptional(.T.)
	oModel:GetModel( 'KEYWORDS' ):SetOptional(.T.)
	oModel:GetModel( 'I18N_MENU' ):SetOptional(.T.)
	oModel:GetModel( 'I18N_ITEM' ):SetOptional(.T.)
	
	oModel:GetModel('MENU'):SetDescription('Menu')
	oModel:GetModel('ITEM'):SetDescription('Item')
	oModel:GetModel('KEYWORDS'):SetDescription('Key Word')
	oModel:GetModel('I18N_ITEM'):SetDescription('I18n Item')
	oModel:GetModel('I18N_MENU'):SetDescription('I18n Menu')

Return oModel

Static Function GetMenuDesc()
Local cLang

	Do Case
	Case __Language == 'SPANISH'
		cLang := "2"
	Case __Language == 'ENGLISH'
		cLang := "3"
	OtherWise
		cLang := "1"
	End Case

Return Posicione("MPMENU_I18N", 1, "1" + MPMENU_MENU->M_ID + cLang, "N_DESC")