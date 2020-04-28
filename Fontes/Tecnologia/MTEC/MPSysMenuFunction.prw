#Include 'Protheus.ch'
#INCLUDE 'FWMvcDef.ch'

Static Function GetStruFunction()
Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("MPMENU_FUNCTION", {"F_FUNCTION"}, "Rotinas dos menus do Microsiga Protheus", {|oStru| MPSysTblPrefix()+"MPMENU_FUNCTION"}) //"Rotinas dos menus do Microsiga Protheus"
	oStruct:AddIndex(1, "01", "F_ID"               , "Código", "", "", .T. ) //"Código"
	oStruct:AddIndex(1, "02", "F_DEFAULT+F_FUNCTION", "Rotina", "", "", .T. ) //"Rotina"

	oStruct:AddField("ID"     , "", "F_ID"      , "C",  32, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Rotina" , "", "F_FUNCTION", "C",  50, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Padrão" , "", "F_DEFAULT" , "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Sim","2=Não"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)

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
Local oStrMenuFunction

	oStrMenuFunction := GetStruFunction()
	oStrMenuFunction:Activate()

	oModel:= FWFormModel():New("MPSysMenuFunction",/*Pre-Validacao*/,/*Pos-Validacao*/,{|oMdl| MPUserCommit(oMdl)}, {|oMdl| FWFormCancel(oMdl)})
	oModel:AddFields("Function", NIL, oStrMenuFunction, /*Pre-Validacao*/, /*Pos-Validacao*/)
	oModel:SetPrimaryKey({})

	oModel:GetModel('Function'):SetDescription('Funções')

Return oModel
