#Include 'Protheus.ch'
#INCLUDE 'FWMvcDef.ch'

Static Function GetStruItem()
Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("MPMENU_ITEM", {"I_ID"}, "Itens dos menus do Microsiga Protheus", {|oStru| MPSysTblPrefix()+"MPMENU_ITEM"}) //"Itens dos menus do Microsiga Protheus"
	oStruct:AddIndex(1, "01", "I_ID+I_ID_FUNC"    , "Código+Rotina", "", "", .T. ) //"Código"+"ID Rotina"
	oStruct:AddIndex(1, "02", "I_DEFAULT+I_ITEMID", "ItemID"       , "", "", .T. ) //"ItemID"

	oStruct:AddField("ID"          , "", "I_ID"     , "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Tipo Item"   , "", "I_TP_MENU", "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Pasta","2=Item"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("ItemID"      , "", "I_ITEMID" , "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Status"      , "", "I_STATUS" , "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Enable","2=Disable","3=Hidden"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Rotina"      , "", "I_ID_FUNC", "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("ResName"     , "", "I_RESNAME", "C",  10, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Tipo"        , "", "I_TYPE"   , "N",   1, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Tabelas"     , "", "I_TABLES" , "C", 254, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Acesso"      , "", "I_ACCESS" , "C",  10, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Proprietário", "", "I_OWNER"  , "C",  10, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Módulo"	   , "", "I_MODULE" , "N",  3, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
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

//-------------------------------------------------------------------
/*/{Protheus.doc} Modeldef
Modelo de dados do menu       

@author Felipe Bonvicini Conti
@since 07/10/2014
@version $Version
/*/
//-------------------------------------------------------------------
Static Function Modeldef()
Local oModel := NIL
Local oStrMenuItem
Local oStrI18n
Local oStrKeyWord

	oStrMenuItem := GetStruItem()
	oStrI18n     := MPMnuStruI18n()
	oStrKeyWord  := GetStruKeyWord()

	oStrMenuItem:Activate()
	oStrI18n:Activate()
	oStrKeyWord:Activate()

	oModel:= FWFormModel():New("MPSysMenuItem",/*Pre-Validacao*/,/*Pos-Validacao*/,{|oMdl| MPUserCommit(oMdl)}, {|oMdl| FWFormCancel(oMdl)})
	oModel:AddFields("ITEM", NIL, oStrMenuItem, /*Pre-Validacao*/, /*Pos-Validacao*/, {|oField| FormLoadField(oField) }/*Carga*/)
	oModel:AddGrid("I18N_ITEM", "ITEM", oStrI18n, /*Pre-Validacao*/, /*Pos-Validacao*/,,, {|oField| FormLoadGrid(oField,,.F.) } /*Carga*/)
	oModel:AddGrid("KEYWORDS", "ITEM", oStrKeyWord, /*Pre-Validacao*/, /*Pos-Validacao*/,,, {|oField| FormLoadGrid(oField,,.F.) } /*Carga*/)
	oModel:SetPrimaryKey({})

	oModel:SetRelation( 'I18N_ITEM', { { 'N_PAREN_TP', "'2'"}, { 'N_PAREN_ID', 'I_ID' } }, 'N_PAREN_TP+N_PAREN_ID+N_LANG' )
	oModel:SetRelation( 'KEYWORDS' , { { 'K_ID_ITEM', 'I_ID'} }, 'K_ID_ITEM' )

	oModel:GetModel( 'I18N_ITEM' ):SetOptional(.T.)
	oModel:GetModel( 'KEYWORDS' ):SetOptional(.T.)

	oModel:GetModel('ITEM'):SetDescription('Item')
	oModel:GetModel('I18N_ITEM'):SetDescription('I18n Item')
	oModel:GetModel('KEYWORDS'):SetDescription('Key Words')

Return oModel