#Include 'Protheus.ch'
#INCLUDE 'FWMvcDef.ch'

#XCOMMAND RUN_IF_TRUE <lVar> := <uVal> => <lVar> := If( <lVar> == .T., Eval( {|| <uVal> } ), <lVar> )

Static __oModel

Static Function GetStruReservWord()
Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("MPMENU_RESERVED_WORD", {"R_LANG"}, "Palavres reservadas para a busca dos menus do Microsiga Protheus", {|oStru| MPSysTblPrefix()+"MPMENU_RW"}) //"Palavres reservadas para a busca dos menus do Microsiga Protheus"
	oStruct:AddIndex(1, "01", "R_LANG+R_DESC", "Língua+Descrição", "", "", .T. ) //"Língua"+"Descrição"

	oStruct:AddField("Língua"   , "", "R_LANG"   , "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=pt-br","2=pt-pt","3=es","4=en"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Descrição", "", "R_DESC"   , "C", 250, 0, {|| .T. } ,/*bWhen*/,/*aValues*/,/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)
	oStruct:AddField("Padrão"   , "", "R_DEFAULT", "C",   1, 0, {|| .T. } ,/*bWhen*/,{"1=Sim","2=Não"},/*lObrigat*/,/*bInit*/,/*lKey*/,/*lNoUpd*/,/*lVirtual*/)

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
Local oStrMenuReservWord

	oStrMenuReservWord := GetStruReservWord()
	oStrMenuReservWord:Activate()

	oModel:= FWFormModel():New("MPSysMenuReservedWord",/*Pre-Validacao*/,/*Pos-Validacao*/,{|oMdl| FWFormCommit(oMdl)}, {|oMdl| FWFormCancel(oMdl)})
	oModel:AddFields("RESERVEDWORD", NIL, oStrMenuReservWord, /*Pre-Validacao*/, /*Pos-Validacao*/)
	oModel:SetPrimaryKey({})

	oModel:GetModel('RESERVEDWORD'):SetDescription('Reserved Word')

Return oModel

Function MPDBSetReseved(aResrv)
Local lOk := .T.
Local cTable
Local cLang
Local nI

	If !Empty(aResrv)

		Default __oModel := FWLoadModel("MPSysMenuReservedWord")

		cTable := __oModel:GetModel("RESERVEDWORD"):getStruct():GetTableStruct(,"TOPCONN"):cTableName
	
		TCSQLEXEC('DELETE FROM ' + cTable)

		__oModel:SetOperation(MODEL_OPERATION_INSERT)
		For nI := 1 to Len(aResrv)

			If __oModel:Activate()

				//{"1=pt-br","2=pt-pt","3=es","4=en"}
				Do Case
				Case aResrv[nI][1] == "POR T"
					cLang := "1"
				Case aResrv[nI][1] == "POR P"
					cLang := "2"
				Case aResrv[nI][1] == "SPA E"
					cLang := "3"
				Case aResrv[nI][1] == "ENG I"
					cLang := "4"
				End Case
	
				RUN_IF_TRUE lOk := __oModel:SetValue("RESERVEDWORD", "R_LANG", cLang)
				RUN_IF_TRUE lOk := __oModel:SetValue("RESERVEDWORD", "R_DESC", aResrv[nI][2])
				RUN_IF_TRUE lOk := __oModel:SetValue("RESERVEDWORD", "R_DEFAULT", '1')

				If lOk := (__oModel:VldData() .And. __oModel:CommitData())
					FwFrameTrace({{"Reserved Words", "Sucesso"}, aResrv[nI]})
				Else
					FwFrameTrace({{"Reserved Words", "Erro"}, aResrv[nI]}, 3)
					VarInfo("GetErrorMessage", __oModel:GetErrorMessage())
				EndIf

				__oModel:DeActivate()

			EndIf
	
		Next
	
	EndIf

Return lOk