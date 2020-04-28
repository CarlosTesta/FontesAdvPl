	#Include 'protheus.ch'
#Include 'parmtype.ch'
#Include 'fwmvcdef.ch'
#Include 'mpsysopentables.ch'

Static __aSqlNames  := {}
Static __cAliasNoTransaction := ""
Static oTblDDL
Static __lOpened := .F.
Static __lMig := .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysOpenTables
Abre tabelas no banco MP_.....

@param aTables Array Simples com o nome da Tabela a serem abertas
@param aAlias Array simples com o nome do alias que deve ser usado para cada tabela.
			  Esse parametro é opcional, se ele não for passado, o alias a ser utilizado
			  na abertura será o nome da tabela.
@param oMeter Componente do tipo TMeter a ser usado na abertura 
@param aTablesCreated Array simples que deve ser passado por referencia para a função.
					  Esse array será preenchido com o nome das tabelas que foram criadas
	                  na abertura.
@param lShared Indica se as tabelas devem ser abertas em modo compartilhado.
@param lException Indica se deve gerar erro caso uma tabela não possa ser aberta.

@return lRet Indica se a tabela foi aberta com sucesso

@author Rodrigo Antonio
@since Oct 7, 2014
@version $Version
/*/
//------------------------------------------ -------------------------
Function MPSysOpenTables(aTables, aAlias, oMeter, aTablesCreated, lShared, lException, cEmpresa, oLogFile, lAlter, nCount)
Local nX			AS NUMERIC
Local cTable		AS CHAR
Local cAlias		AS CHAR
Local oStruct		AS OBJECT
Local lRet 			AS LOGICAL
Local oCacheModel   AS OBJECT
Local aArea	  		AS ARRAY
Local lMeter01 		AS LOGICAL
Local lMeter02 		AS LOGICAL

lRet      := .F.
aArea	  := FWGetArea()
lMeter01  := .F.
lMeter02  := .F.

DEFAULT aAlias := {}
DEFAULT oMeter := NIL
DEFAULT aTablesCreated := {}
DEFAULT lShared := .T.
DEFAULT lException := .T.
DEFAULT lAlter := .F.
DEFAULT nCount := 0

lRet := .F.
oCacheModel := Nil
lContinue := .T.
aArea	  := FWGetArea()
lMeter01 := .F.
lMeter02 := .F.


If __lMig .And. !Empty(aTables)
	//Atualiza a métrica da barra de progresso
	lMeter01 := oMeter != NIL .And. oMeter:ClassName() == "TMETER" .And. !Empty(nCount)
	lMeter02 := oMeter != NIL .And. !( oMeter:ClassName() == "TMETER" )

	//Crio ele antes do loop
	If oTblDDL == Nil
		MPSysInitDDL()
	EndIf

	For nx := 1 to Len(aTables)
		cTable := cAlias := 	aTables[nX]
		
		If Len(aAlias) >= nX .AND. aAlias[nx] <> nil
			cAlias := aAlias [nx]
		EndIf
			
		If !(Select(cTable) > 0 )
		
			oStruct := GetStruct(cTable, @oCacheModel, cAlias)
			If oStruct == NIL
				 UserException(STR0001 + cTable + STR0002) //"Erro ao criar a tabela "
			EndIf
			
			oTblDDL:Deactivate() 
			
			//------------------------------
			//Só continua se tiver migrado
			//------------------------------
			If __lMig
				If !lException
					oTblDDL:disableException()
				EndIf

				oTblDDL:SetTableStruct(oStruct)
				oTblDDL:Activate()
				
				If !oTblDDL:TblExists()
					oTblDDL:CreateTable(.T.,.T.,.T.)//todas as tabelas criadas com recno autoincremental e clob.
					aAdd(aTablesCreated, cTable)
					
					If oLogFile != Nil
						oLogFile:write(oStruct:GetTableName()+chr(13)+chr(10))
					EndIf
					
					If lMeter02
						oMeter:SetMeterTitle( STR0003 + cTable + ' ... ' ) //"Criando a tabela "
					EndIf

				ElseIf lAlter 
					oTblDDL:AlterTable()
				EndIf				

				//------------------------------------------------------------------------------------------
				// Utilizado para atualizar a barra de de progresso de abertura do sistema
				//------------------------------------------------------------------------------------------
				If lMeter01
					oMeter:Set( nX + nCount )
				EndIf
				lRet := oTblDDL:OpenTable(lShared,,.F.)
			EndIf

			oStruct:Deactivate()
			oStruct := Nil
		Endif
	Next nX
EndIf

If oCacheModel != Nil
	oCacheModel:Destroy()
	oCacheModel := Nil
EndIf

FWRestArea( aArea )
aArea := aSize( aArea , 0 )
aArea := Nil

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysAlterTable
Altera a estrutura de uma tabela no banco e abre a tabela, baseado na
estrutura que é passada por parametro. 

@param oStruct Objeto do tipo FWTableStruct
@param cTable identificação da tabela

@author Juliane Venteu
@since Oct 7, 2014
@version $Version
/*/
//------------------------------------------ -------------------------
Function MPSysAlterTable(oStruct, cTable)
Local lRet := .F.

	If !(Select(cTable) > 0 )
		If oTblDDL == Nil
			MPSysInitDDL()
		Else
			oTblDDL:Deactivate() 
		Endif
		oStruct:Activate()
		oTblDDL:SetTableStruct(oStruct)				
		oTblDDL:Activate()		
		lRet := oTblDDL:AlterTable()
	Endif


Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} getStruct
Retorna a estrutura da tabela baseado no alias
@param cAlias Alias da tabela
@return oStruct Estutura do tipo TableStruct
@author Rodrigo Antonio
@since Nov 3, 2014
@version version
/*/
//-------------------------------------------------------------------
Static function GetStruct(cTable,oCacheModel, cAlias, cEmpresa)

Local oStruct

	If "MP_INFO" $ cTable
		oStruct := getGenericModelStruct(cAlias,@oCacheModel,"MPSystemInfo","MPSYSModel")
	ElseIf "MPUSR_"$ cTable 
		oStruct := getUsrStruct(cAlias,@oCacheModel)
	ElseIf "MPGRP_"$ cTable
		oStruct := getGrpStruct(cAlias,@oCacheModel)
	ElseIf "MPMENU_RESERVED_WORD" == cTable
		oStruct := getGenericModelStruct(cAlias)
	ElseIf "MPMENU_FUNCTION" == cTable
		oStruct := getGenericModelStruct(cAlias,@oCacheModel,"MPSysMenuFunction","MPSysMenuFunction")
	ElseIf "MPMENU_" $ cTable
		oStruct := getGenericModelStruct(cAlias)
	ElseIf "PROFALIAS" $ cTable  
		oStruct := getProfileStruct(cTable)	
	ElseIf "PROFUSR" $ cTable  
		oStruct := getWorkRoleStruct(cTable)
	ElseIf "MP_POL" $ cTable
		oStruct := getGenericModelStruct(cAlias,@oCacheModel,"MPUserAccount","POLICE")		
	ElseIf "MPRL_" $ cTable //Rules
	 	oStruct := getGenericModelStruct(cAlias,@oCacheModel,"FWRulesAccountData","MPRULEACCOUNTDATA")
	ElseIf "MPURL_" $ cTable //User Rules
	 	oStruct := getGenericModelStruct(cAlias,@oCacheModel,"MPUserACCOUNTRules","MPUSERACCOUNTRULES")	 	
	ElseIf "MPGRL_" $ cTable //User Rules
	 	oStruct := getGenericModelStruct(cAlias,@oCacheModel,"MPGroupACCOUNTRules","MPGROUPACCOUNTRULES")
	ElseIf cTable == "XX8"
		oStruct := getXX8Struct()
	ElseIf cTable == "XX9"
		oStruct := getXX9Struct()
	ElseIf cTable == "SM0"
		oStruct := getSM0Struct()
	Else
		oStruct := MPDicStruct(cTable, cAlias, cEmpresa)
	Endif
	
	If ValType(oStruct) == "O"
		oStruct:Activate()
		MPSysSqlUpdName(cAlias,oStruct:GetTableName())
		If !oStruct:UseTransaction()
			MPPutNoTranAlias(cAlias)
		EndIf
	EndIf

Return oStruct
//-------------------------------------------------------------------
/*/{Protheus.doc} getProfileStruct
Retorna estrutura do profile.
	
@author arthur fucher
@since Oct 7, 2014
@version version
/*/
//-------------------------------------------------------------------
Static Function getProfileStruct(cTable)
Local oModel
Local oSubModel
Local oStruct
Local oTblStruct
oModel := FWLoadModel("PROFILE")
oSubModel := oModel:GetModel("PROFILE")
oStruct := oSubModel:GetStruct("PROFILE")
@assume oStruct as FWFormModelStruct
oTblStruct := oStruct:GetTableStruct(,"TOPCONN")
oTblStruct:SetUseTransaction(.F.)
Return oTblStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} getWorkRoleStruct
Retorna estrutura do Papel de Trabalho (WorkRole)
	
@author Arthur
@since Oct 7, 2014
@version version
/*/
//-------------------------------------------------------------------
Static Function getWorkRoleStruct(cTable)
Local oModel
Local oSubModel
Local oStruct
Local oTblStruct
oModel := FWLoadModel("MPWORKROLE")
oSubModel := oModel:GetModel("WORKROLE")
oStruct := oSubModel:GetStruct("WORKROLE")
@assume oStruct as FWFormModelStruct
oTblStruct := oStruct:GetTableStruct(,"TOPCONN")
Return oTblStruct


//-------------------------------------------------------------------
/*/{Protheus.doc} getUsrStruct
long_description
	
@author Rodrigo
@since Oct 7, 2014
@version version
/*/
//-------------------------------------------------------------------
Static function getUsrStruct(cTable,oCacheModel)
Local aModels
Local oStruct
Local oSubModel
Local nX
Local oTableStruct
Local oUsrStruct 
Local aTable
Local nY
Local aFields
Local nQtd := 0

Do Case

	Case cTable == "MPUSR_USR"
		oUserStruct:=__FWUsrStrDataUser()
		oUserStruct:Deactivate()
		oStruct:=__FwStrDtUser02()//datastorage
		oUserStruct:LoadFields(oStruct:GetFields())
		oStruct:=Nil
		oStruct:=__FwStrRestriction()//restriction
		oUserStruct:LoadFields(oStruct:GetFields())
		oStruct:=Nil
		oStruct:=_FwDtUsrStruct()//protheusdata
		oUserStruct:LoadFields(oStruct:GetFields())
		oStruct:=Nil
		oStruct:=oUserStruct
		oUserStruct:=nil
	Case cTable == "MPUSR_GROUPS"
		oStruct:=_FWStrGrpUsr()
		Case cTable == "MPUSR_SSIGNON"
		oStruct:=_FWSSOnStr()
	Case cTable == "MPUSR_ACCSRESTRI"
		oStruct:=_FWAccRStruct()
	Case cTable == "MPUSR_SUPER"
		oStruct:=_fwStruSuper()
		Case cTable == "MPUSR_PAPER"
		oStruct:=_FwUrsPaperStruct()
		Case cTable == "MPUSR_FILIAL"
		oStruct:=_FwUsrFilStruct()
	Case cTable == "MPUSR_ACCESS"
		oStruct:=_FwUsrAccStruct()
	Case cTable == "MPUSR_MODULE"
		oStruct:=_FwUsrMdlStruct()
	Case cTable == "MPUSR_PRITER"
		oStruct:=_FwUsrPrinterStruct()
	Case cTable == "MPUSR_LOGCFG"
		oStruct:=_FwUsrLgCfgStruct()
	Case cTable == "MPUSR_VINCFUNC"
		oStruct:=_FWUsrVincStr()
	Case cTable == "MPUSR_PANEIS"
		oStruct:=_FwUsrPanelStruct()
	Case cTable == "MPUSR_ACESSIB"
		oStruct:=_FwAccebilStru()
	Case cTable == "MPUSR_OAUTH"
		oStruct:=_FWStrSysOAuth()
	OtherWise//tratamento anterior, caso alguma outra tabela entre no jogo
		If oCacheModel == Nil
			oCacheModel := FWLoadModel("MPUSERACCOUNTDATA")
		Else	
			If !( oCacheModel:GetId() == "FWUSERACCOUNTDATA" )
				oCacheModel:Destroy()
				oCacheModel := FWLoadModel("MPUSERACCOUNTDATA")
			Endif
		EndIf
		aModels := oCacheModel:GetModelIds()
		@assume oStruct as FWFormModelStruct
		@assume oSubModel as FWFormFieldsModel
		For nX := 1 to Len(aModels)		
			oSubModel 	:= oCacheModel:getmodel(aModels[nx])		
			oStruct		:= oSubModel:getStruct()	
			aTable := oStruct:GetTable()
			if aTable[1] == cTable    
				oStruct:Activate()
				Exit
			endif
		next nX
	EndCase
	oTableStruct:=oStruct:getTableStruct(,"TOPCONN")
	oStruct:=nil
	oTableStruct:Deactivate()

Return  oTableStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} getSM0Struct
long_description
	
@author Renan Fragoso
@since Oct 7, 2014
@version 11-12
/*/
//-------------------------------------------------------------------
Static function getSM0Struct()

Local oModel
Local oModelSM0
Local oMdlStructSM0
Local oStructSM0 

@assume oModel as MPFormModel
@assume oModelSM0 as FWFormFieldsModel
@assume oStructSM0 as FWFormModelStruct

oModel := FWLoadModel("MPCOMPANYDATA")
oModelSM0 := oModel:getModel( "SM0" )
oMdlStructSM0 := oModelSM0:getStruct()
oStructSM0 := oMdlStructSM0:GetTableStruct(,"TOPCONN")
oStructSM0:SetUseTransaction(.F.)
Return oStructSM0


//-------------------------------------------------------------------
/*/{Protheus.doc} getGrpStruct
long_description
	
@author Rodrigo
@since Oct 7, 2014
@version version
/*/
//-------------------------------------------------------------------
Static function getGrpStruct(cTable,oCacheModel)
Local aModels
Local oStruct
Local oSubModel
Local nX
Local oTableStruct
Local oUsrStruct 
Local aTable
Local nY
Local aFields
Local nQtd := 0

@assume oStruct As FWFormModelStruct
@assume oSubModel As FWFormFieldsModel

If oCacheModel == Nil
	oCacheModel := FWLoadModel("MPGROUPACCOUNTDATA")
Else	
	If !( oCacheModel:GetId() == "FWGROUPACCOUNTDATA" )
		oCacheModel:Destroy()
		oCacheModel := FWLoadModel("MPGROUPACCOUNTDATA")
	EndIf
EndIf

aModels := oCacheModel:GetModelIds()

If cTable == "MPGRP_GROUP" //A Cabecalho é especial pois agregar alguns models
	For nX := 1 to Len(aModels)
		oSubModel := oCacheModel:getmodel(aModels[nx])
		oStruct:= oSubModel:getStruct()
		If aModels[nX] == "DATAGROUP"
			oUsrStruct := oStruct
			oUsrStruct:DeActivate()			
		ElseIf aModels[nx]$ "DATASTORAGE|PROTHEUSDATA" 
			oUsrStruct:LoadFields(oStruct:GetFields())					
		Endif
	Next nX
	oUsrStruct:Activate()
	oTableStruct := oUsrStruct:GetTableStruct(,"TOPCONN")

Else
	For nX := 1 To Len(aModels)		
		oSubModel 	:= oCacheModel:getmodel(aModels[nx])		
		oStruct		:= oSubModel:getStruct()	
		aTable := oStruct:GetTable()
		If aTable[1] == cTable    
			oStruct:Activate()
			oTableStruct := oStruct:GetTableStruct(,"TOPCONN")
			Exit
		EndIf
	Next nX
EndIf

Return  oTableStruct
//-------------------------------------------------------------------
/*/{Protheus.doc} getGenericModelStruct
Retorna uma estrutura baseado num MVC Generico
@param cAlias Alias procurada
@param oCacheModel Objeto do Modelo para cache, passar Nil como referencia
@param cSource Nome do fonte que contem o Modelo
@param cID Id do Modelo para Cache

@return
@author Rodrigo
@since Nov 4, 2014
@version version
/*/
//-------------------------------------------------------------------
Static Function getGenericModelStruct(cAlias,oCacheModel,cSource,cId)
Local oStruct
Local aModels
Local nX
Local oSubModel
Local oTableStruct
Local aTable
@assume oCacheModel as FWFormModel


Do Case
	Case cAlias =="MP_INFO"
		oStruct:=MPSIfoDbStr()
	Case cAlias =='MPMENU_MENU'
		oStruct:=__MPMnuStruMenu()
	Case cAlias == 'MPMENU_I18N'
		oStruct:=MPMnuStruI18n()
	Case cAlias =='MPMENU_ITEM'
		oStruct:=_FwGetStruItem()
	Case cAlias == 'MPMENU_KEY_WORDS'
		oStruct:=FwGetStruKeyWord()
	Case cAlias == 'MPMENU_RESERVED_WORD'
		oStruct:=_FWStruReservWord()
	Case cAlias =='MPMENU_FUNCTION'
		oStruct:=_FwStruMFunc()
	Case cAlias == 'MP_POLICE'
		oStruct:=_FwStrPolice()
	Case cAlias == 'MP_POL_VIOL'
		oStruct:=_FWStrViolPol()
	Case cAlias =='MP_POL_COMM'
		oStruct:=_FWStrCommPol()
	Case cAlias =='MP_POL_SAML'
		oStruct:=_FwStrSamStruct()
	Case cAlias == 'MP_POL_FLUIG'
		oStruct:=_FWStrFluigPol()
	Case cAlias =='MP_POL_PROTHEUS'
		oStruct:=_FWStrProPol()
	Case cAlias =='MP_POL_PAINEIS'
		oStruct:=_FwStrPanelPol()
	Case cAlias =='MP_POL_OAUTH'
		oStruct :=_FWStrOauthPol()
	Case cAlias =='MPRL_RULES'
		oStruct :=_FWRulStr1()
	Case cAlias =='MPRL_TRANS'
		oStruct :=_FwRulStr2()
	Case cAlias =='MPRL_FEATU'
		oStruct:=_FWRulStr3()
	Case cAlias =='MPRL_BUTTONS'
		oStruct :=_FwRulStr4()
	Case cAlias == 'MPURL_CAB'
		oStruct :=_FWStrUCabRules()
	Case cAlias =='MPURL_RULES'
		oStruct :=_FWStrURules()
	Case cAlias =='MPGRL_CAB'
		oStruct :=_FWStrGpCab()
	Case cAlias =='MPGRL_RULES'
		oStruct:=_FWStrGpRules()
	OtherWise
		if oCacheModel == Nil
			oCacheModel := FWLoadModel(cSource)
		Else	
			if !(oCacheModel:GetId() == cId)
				oCacheModel:Destroy()
				oCacheModel:=nil
				oCacheModel := FWLoadModel(cSource)
			Endif
		Endif

		aModels := oCacheModel:GetModelIds()
		@assume oStruct   as FWFormModelStruct
		@assume oSubModel as FWFormFieldsModel

		For nX := 1 to Len(aModels)
			oSubModel := oCacheModel:getmodel(aModels[nx])		
			oStruct   := oSubModel:getStruct()	
			aTable    := oStruct:GetTable()
			if aTable[1] == cAlias
				Exit
			Else
				oStruct:=nil
				aTable:=nil
				oSubModel:=nil
			endif
		next nX
		aModels:=aSize(aModels,0)
		aModels:=nil
	EndCase
	If oStruct <> nil
		oStruct:Activate()
		oTableStruct := oStruct:GetTableStruct(,"TOPCONN")
	Endif
	oStruct:=nil
	aTable:=nil
	oSubModel:=nil

Return oTableStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} getMenuStruct
long_description
	
@author Felipe
@since Oct 7, 2014
@version version
/*/
//-------------------------------------------------------------------
Static Function getMenuStruct(cTable)
Local oModel
Local aModels
Local oStruct
Local oSubModel
Local nX
Local oTableStruct
Local oUsrStruct 
Local aTable
Local cModel

	If cTable = "MPMENU_RESERVED_WORD"
		cModel := "MPSysMenuReservedWord"
	Else
		cModel := "MPSysMenu"
	EndIf

	oModel  := FWLoadModel(cModel)
	aModels := oModel:GetModelIds()

	@assume oStruct   as FWFormModelStruct
	@assume oSubModel as FWFormFieldsModel

	For nX := 1 to Len(aModels)
		oSubModel := oModel:getmodel(aModels[nx])		
		oStruct   := oSubModel:getStruct()	
		aTable    := oStruct:GetTable()
		if aTable[1] == cTable
			oStruct:Activate()
			oTableStruct := oStruct:GetTableStruct(,"TOPCONN")
			Exit
		endif
	next nX

Return oTableStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysSqlUpdName
long_description
	
@author Rodrigo
@since Oct 24, 2014
@version version
/*/
//-------------------------------------------------------------------
Function MPSysSqlUpdName(cAlias,cRealName)
Local nPos
nPos := aScan(__aSqlNames,{|x|x[1]==cAlias})
if (nPos > 0 )
	__aSqlNames[nPos][2] := cRealName
else
	aAdd(__aSqlNames,{cAlias,cRealName})
endif

Return

Function MPPutNoTranAlias( cAlias )
	__cAliasNoTransaction += cAlias + "|"
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MPAliasIsNoTransaction
Verifica se um alias foi aberto utilizando conexão não transacionada.
	
@author Juliane
@since Oct 24, 2014
@version version
/*/
//-------------------------------------------------------------------
Function MPAliasIsNoTransaction(cAlias)
Return cAlias $ __cAliasNoTransaction

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysSqlName
Essa função retorna o nome fisico de uma tabela, baseada no alias com o qual a mesma foi aberta.

@sample
cRealName := MPSysSqlName("SX2TMP")
If cRealName == "SX2990"
	alert("empresa 99")
EndIf

@return cRealName Nome fisico da tabela
	
@author Rodrigo Antonio
@since Oct 24, 2014
@version P12
/*/
//-------------------------------------------------------------------
Function MPSysSqlName(cAlias)
Local nPos := aScan(__aSqlNames,{|x|x[1]==cAlias})
Local cRealName
Local oStruct
if (nPos > 0 )
	cRealName := __aSqlNames[nPos][2]
Else
	oStruct:=GetStruct(cAlias,,cAlias)
	If oStruct <> nil
		cRealName:=oStruct:GetTableName()
		oStruct:Deactivate()
		FWFreeObj(oStruct)
	Else
		UserException(STR0004 +cAlias)  //"Invalid alias "
	Endif
Endif
Return cRealName



Function MPSysAliasName(cRealName)
Local nPos := aScan(__aSqlNames,{|x|x[2]==cRealName})
Local cAlias := ""
if (nPos > 0 )
	cAlias := __aSqlNames[nPos][1] 
Endif
Return cAlias


//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysOpenQuery
Abre um alias qua a query informada
@param cQuery Query a ser executada
@param cAlias Se informado cria na alias informada, se ela estiver aberta
fecha antes de abrir. Caso não seja informada,  deve-se passar uma 
variavel por referêncial, que ira ser preenchida com o novo Alias.
@param 	aSetField   Vetor com os campos para execucao de TCSetField	com a estrutura:
						[1] Nome do Campo
						[2] Tipo
						[3] Tamanho
						[4] Decimal

@author Rodrigo Antonio
@since Oct 24, 2014
@version P12
@obs Atenção, a alias atual não é alterar, ou seja, é necessário acessar a tabelas via (cAlias)->CAMPO, ou
efetuar um DbSelectArea(cAlias), e fazer o tratamento de salvar e restaurar area.
/*/
//-------------------------------------------------------------------
Function MPSysOpenQuery(cQuery,cAlias,aSetField)
Local nX
Local cSaveAlias := Alias()
PARAMTYPE 0 VAR cQuery AS CHARACTER
PARAMTYPE 1 VAR cAlias AS CHARACTER OPTIONAL Default GetNextAlias()
PARAMTYPE 2 VAR aSetField AS ARRAY OPTIONAL Default {}

If Select(cAlias) > 0  
	DbSelectArea(cAlias)
	DbCloseArea()
Endif
DbUseArea(.t.,"TOPCONN",TcGenQry(,,cQuery),cAlias)

If Select( cAlias) > 0
	For nX := 1 To Len ( aSetField )
		TcSetField( cAlias, aSetField[nX][1] , aSetField[nX][2], aSetField[nX][3], aSetField[nX][4] )
	Next nX	
Else	
	FWLogMsg("ERROR",,"ENVIROMENT","START","OPEN",,TcSqlError(),)
	UserException(STR0005 + TcSqlError()) //"Error in DB:"
EndIf
if !Empty(cSaveAlias) 
	DbSelectArea(cSaveAlias)
Endif

Return cAlias

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysExecScalar
Executa a consulta e retorna a primeira coluna da primeira linha 
no conjunto de resultados retornado pela consulta. 
Colunas ou linhas adicionais são ignoradas.

@param cQuery Consulta a ser executada
@param cColumn	Nome da coluna a ser retornada
@return xValue Valor da consulta 
@author Rodrigo Antonio
@since Feb 4, 2015
@version P12
/*/
//-------------------------------------------------------------------
Function MPSysExecScalar(cQuery,cColumn)
Local nX
Local cSaveAlias := Alias()
Local xValue
Local cAlias
PARAMTYPE 0 VAR cQuery AS CHARACTER
PARAMTYPE 1 VAR cColumn AS CHARACTER 
MPSysOpenQuery(cQuery,@cAlias)

If Select(cAlias) > 0
	 xValue := (cAlias)->(&cColumn)
	(cAlias)->(DbCloseArea())
Endif
Return xValue

//-------------------------------------------------------------------
/*/{Protheus.doc} MPActiveConNoTransaction
Ativa a conexão não transacionada dos dicionários, usando ela para se comunicar com o TOP.
	
@author Juliane Venteu
@since Nov 26, 2014
@version 12
@protected
/*/
//-------------------------------------------------------------------
Function MPActiveConNoTransaction()
Local aTopInfo
Local nConnection
	If !__lOpened
		If oTblDDL == NIL
			MPSysInitDDL()
		EndIf
		//----------------------------------------
		//Verifica se possui conexão sem transação
		//----------------------------------------
		If !oTblDDL:HasConnection(.F.)
			aTopInfo := FwRetTopInfo()
			nConnection:=fwNoTranConn(,aTopInfo[1],aTopInfo[2],aTopInfo[3],aTopInfo[4],aTopInfo[5],aTopInfo[6])
		EndIF
		
		oTblDDL:SaveConnection()
		oTblDDL:ConnectDBAcess(.F.)

		__lOpened := .T.
	EndIf
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MPDeActiveConNoTransaction
Desativa a conexão não transacionada dos dicionários, usando a conexão
transacionada para se comunicar com o TOP.
	
@author Juliane Venteu
@since Nov 26, 2014
@version 12
@protected
/*/
//-------------------------------------------------------------------
Function MPDeActiveConNoTransaction()
	If __lOpened
		oTblDDL:RestoreConnection()
		__lOpened := .F.
	EndIf
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} getXX8Struct
long_description
	
@author Renan Fragoso
@since Oct 7, 2014
@version 11-12
/*/
//-------------------------------------------------------------------
Static function getXX8Struct()

Local oModel
Local oModelXX8
Local oMdlStruct
Local oStructXX8

@assume oModel as MPFormModel
@assume oModelSM0 as FWFormFieldsModel
@assume oStructSM0 as FWFormModelStruct

oModel := FWLoadModel("MPCOMPANYDATA")
oModelXX8 := oModel:getModel( "XX8" )
oMdlStruct := oModelXX8:getStruct()
oStructXX8 := oMdlStruct:GetTableStruct(,"TOPCONN")
oStructXX8:SetUseTransaction(.F.)

Return oStructXX8

//-------------------------------------------------------------------
/*/{Protheus.doc} getXX9Struct
long_description
	
@author Renan Fragoso
@since Oct 7, 2014
@version 11-12
/*/
//-------------------------------------------------------------------
Static function getXX9Struct()

Local oModel
Local oModelXX9
Local oStructXX9 
Local oMdlStruct

@assume oModel as MPFormModel
@assume oModelXX9 as FWFormFieldsModel
@assume oStructXX9 as FWFormModelStruct

oModel := FWLoadModel("MPCOMPANYDATA")
oModelXX9 := oModel:getModel( "XX9" )
oMdlStruct := oModelXX9:getStruct()
oStructXX9 := oMdlStruct:GetTableStruct(,"TOPCONN")
oStructXX9:SetUseTransaction(.F.)

Return oStructXX9

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysInitDDL
Função responsável por criar uma instância do tableDDL e efetuar a conexão com o top.

@author Felipe Bonvicini Conti
@since Oct 19, 2016
@version $Version
/*/
//-------------------------------------------------------------------
Function MPSysInitDDL()
Local lDisconnect  := .F.
Local lAddDbAccess := .F.
Local nConnection
Local aTopInfo

	If oTblDDL == NIL
		oTblDDL := FWTableDDL():New()
		nConnection := AdvConnection()

		//Sempre adiciono o dbaccess. Pode acontecer de já existir conexão. Ai dá ruim.
 		aTopInfo := FwRetTopInfo()

 		//------------------------------------------------
 		//Se não possui o AdvConnection cria uma conexão
 		//------------------------------------------------
 		If nConnection == Nil .OR. nConnection < 0
 			If oTblDDL:HasConnection(.T.)
 				//Caso já exiata conexão, atualizo o array de dados de conexão na FwTableDDL 
 				oTblDDL:AddDbAcess( aTopInfo[1] , aTopInfo[2] , aTopInfo[3] , ;
					aTopInfo[4] , aTopInfo[5] , aTopInfo[6] , nConnection , .T. )
 				oTblDDL:ConnectDBAcess(.T.)
 			Else
	 			Connect(,.T.)
	 			nConnection  := AdvConnection()
	 			lDisconnect  := .T.
	 			lAddDbAccess := .T.

				//Caso a conexão tenha sido efetuada pelo Connect, informo a FwTableDDl sobre essa conexão
				oTblDDL:AddDbAcess( aTopInfo[1] , aTopInfo[2] , aTopInfo[3] , ;
					aTopInfo[4] , aTopInfo[5] , aTopInfo[6] , nConnection , .T. )
	 		EndIf
		Else
			//Já existindo conexão, informo a mesma para a FwTableDDL
			oTblDDL:AddDbAcess( aTopInfo[1] , aTopInfo[2] , aTopInfo[3] , ;
				aTopInfo[4] , aTopInfo[5] , aTopInfo[6] , nConnection , .T. )
 		EndIf

		aTopInfo := aSize( aTopInfo , 0 )
		aTopInfo := Nil

		//----------------------------------------------------------------------------------
		// Quando o ambiente não está usando dicionarios no banco de dados, a conexão
		// não transacionada é fechada, pois não há necessidade de utilização da mesma uma vez
		// que já existe a conexão transacionada
		//----------------------------------------------------------------------------------
		If !MPTblInDB(__MPRealName(,"USR")) .And. !__MigIsRunning() .And. !FWStartDicInDB()
			//If lDisconnect
			//	FWClsNoTranConn(nConnection)
		//	Endif
			__lMig := .F.
			
		EndIf
				
	EndIf
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} FwValidAlter

	Valida se a tabela pode sofrer o alter table no futuro retirar essa validação pois irá levar em consideração
	a release da lib, junto com segmentos.

	@author Alvaro Camillo
	@since 07/02/2017
	@version P12
	@param cTable Tabela a avaliar
	@return lAlter Confirma se pode realizar o alter table
/*/
//-------------------------------------------------------------------

Function FwValidAlter(cTable)
Local lReturn := .F.

Default cTable := ""

If Type( "cpaisloc" ) == "C" .And. cPaisLoc == "RUS"
	lReturn := .T.


EndIf


Return lReturn

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSOpTbMig
Seta a variável estática __lMig conforme o valor informado

@author Daniel Mendes
@since Feb 02, 2017
@version $Version
/*/
//-------------------------------------------------------------------
Function MPSOpTbMig(lSet)
__lMig := lSet
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} FWClsConnctDB
Limpa o objeto estático do fonte

@author Daniel Mendes
@since Aug 14, 2017
@version P12
@protected
/*/
//-------------------------------------------------------------------
Function FWClsConnctDB()

If oTblDDL != Nil
	oTblDDL:Deactivate()
	oTblDDL := Nil
EndIf

Return Nil