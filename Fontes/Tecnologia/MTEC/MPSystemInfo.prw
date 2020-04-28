#Include 'protheus.ch'
#Include 'fwmvcdef.ch'
#Include 'mpsysteminfo.ch'

Static __lGCADPatch := GetSrvProfString ( "GCADPATCH", "0" )

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSyInfoOpenTables
Abre a tabela MP_INFO/SYSTEM_INFO

@author Daniel Mendes

@since 04/06/2017
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function MPSyInfoOpenTables(lOpenTable)
Local oTableStruct
Local aTopInfo
Local oTblDDL
Local oStruct

Default lOpenTable:=.T.

	If !(Select("MP_INFO") > 0)
		// Nao utilizar a MPsysOpenTable, pois ocorre recursividade quando chamado por outro tabela ao validar a versao da mesma. 
		MPSysInitDDL() // Inicializa uma instância do tableDDL e efetua a conexão com o top.
		If lOpenTable .or. !TcCanOpen('SYSTEM_INFO')//se pediu para abrir a tabela ou se ela não existir no banco
			oStruct := MPSIfoDbStr()//oModel:getmodel(oModel:GetModelIds()[1]):getStruct()	
			oStruct:Activate()
			oTableStruct := oStruct:GetTableStruct(,"TOPCONN")
			oTableStruct:Activate()
			oTblDDL := FWTableDDL():New()

			#ifdef TOP 
				aTopInfo := FWGetTopInfo()
				oTblDDL:AddDbAcess( aTopInfo[1], aTopInfo[2], aTopInfo[3], aTopInfo[4], aTopInfo[5], aTopInfo[6], AdvConnect() )
				aTopInfo:=aSize(aTopInfo, 0)
				aTopInfo:=nil
			#endif
			
			oTblDDL:SetTableStruct( oTableStruct )
			oTblDDL:Activate()

			If !oTblDDL:TblExists()
				oTblDDL:CreateTable(.T.)
			EndIf

			oTblDDL:OpenTable()
			oTblDDL:DeActivate()
			oTblDDL := Nil
			oStruct:Deactivate()
			oStruct:Destroy()
			oStruct := Nil
			oTableStruct:Deactivate()
			oTableStruct := Nil
		EndIf
	EndIf

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de Dados

@author Rodrigo

@since 09/11/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
Local oModel
Local oStr1:= MPSIfoDbStr()

oModel := FWFormModel():New('MPSYSModel',,, {|oMdl|MPUserCommit(oMdl)},{||.T.})
oModel:SetDescription( STR0001 ) //'Informações sobre os dicionários e usuários no banco'
oModel:addFields('MPSYSINFO',,oStr1,,,{|x,y| FormLoadField(x,y)})

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSIfoDbStr()
Retorna estrutura do tipo FWformModelStruct. Da tabela de informação
do System

@author Rodrigo
@since 09/11/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function MPSIfoDbStr()
Local oStruct := FWFormModelStruct():New()

oStruct:AddTable('MP_INFO',{'MPI_SYNAME','MPI_KEY'},STR0003,{||"SYSTEM_INFO"}) //'Informaçãos dos Dicionarios no banco'
oStruct:AddIndex(1,"01",'MPI_SYNAME+MPI_KEY',STR0004,"","",.t.) //"Nome Ambiente+Chave"
oStruct:AddField(STR0005,STR0005 , 'MPI_SYNAME', 'C', MPSNameSize(), 0, , , {}, .F., , .T., .F., .F., , ) //'System Name'
oStruct:AddField(STR0006,STR0006 , 'MPI_KEY', 'C', 20, 0, , , {}, .T., , .T., .F., .F., , ) //'Chave'
oStruct:AddField(STR0007,STR0007 , 'MPI_VALUE', 'C', 30, 0, , , {}, .T., , .F., .F., .F., , ) //'Valor'
oStruct:AddField(STR0008,STR0008 , 'MPI_DATE', 'C', 14, 0, , , {}, .T., , .F., .F., .F., , ) //'Data e hora'
Return oStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSNameSize
Retorna o tamanho do campo MPI_SYNAME
	
@author Rodrigo
@since Nov 9, 2014
@version version
/*/
//-------------------------------------------------------------------
Function MPSNameSize()
Return 20

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSInfoAdd()
Adiciona ou atualiza informação na tabela de informacao do MP_SYS
	
@author Rodrigo
@since Nov 9, 2014
@version version
/*/
//-------------------------------------------------------------------
Function MPSInfoAdd(cKey,cValue,cSysName)
Local oModel     AS OBJECT 
Local oSubModel  AS OBJECT
Local nOpc       AS NUMERIC

oModel := ModelDef() 

Default cSysName := MPSysTblPrefix(.t.)

#IFDEF TOP
	MPSyInfoOpenTables()

	If MP_INFO->(DbSeek(cSysName+cKey))
		nOpc := MODEL_OPERATION_UPDATE 
	Else
		nOpc := MODEL_OPERATION_INSERT
	EndIf

	oModel:SetOperation(nOpc)
	oModel:Activate()
	oSubModel := oModel:GetModel('MPSYSINFO')

	If nOpc == MODEL_OPERATION_INSERT
		oSubModel:SetValue('MPI_SYNAME',cSysName)
		oSubModel:SetValue('MPI_KEY',cKey)
	EndIf

	oSubModel:SetValue('MPI_VALUE',cValue)
	oSubModel:SetValue('MPI_DATE',FWTimeStamp(1))

	If oModel:VldData()
		oModel:CommitData()
	Else
		VarInfo("GetErrorMessage", oModel:GetErrorMessage())
		UserException(STR0009) //"Erro ao grava tabela de informação do sistema"
	EndIf

	oModel:DeActivate()
	oModel:Destroy()
	oSubModel:=nil
	oModel:=nil

#ENDIF

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSInfoDel()
Remove registro da tabela de informacao do MP_SYS
	
@author Felipe Bonvicini Conti
@since Out 29, 2016
@version version
/*/
//-------------------------------------------------------------------
Function MPSInfoDel(cKey,cSysName)
Local oModel 

Default cSysName := MPSysTblPrefix(.t.)

#IFDEF TOP
	MPSyInfoOpenTables()

	If MP_INFO->(DbSeek(cSysName+cKey))
		oModel := ModelDef()
		oModel:SetOperation(MODEL_OPERATION_DELETE)
		oModel:Activate()
		If oModel:VldData()
			oModel:CommitData()
		Else
			VarInfo("GetErrorMessage", oModel:GetErrorMessage())
			UserException(i18n(STR0010, {cSysName + cKey})) //"Erro ao remover registro #1 da tabela de informação do sistema"
		Endif
		oModel:DeActivate()
		oModel:Destroy()
	EndIf
#ENDIF

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSGetInfo()
Retorna o valor de uma chave existente na tabela MP_SYS.
Se a chave não existir, retorna uma string vazia.
	
@author Juliane Venteu
@since Nov 9, 2014
@version version
/*/
//-------------------------------------------------------------------
Function MPSGetInfo( cKey )
Local cValue := ""

#IFDEF TOP
	//----------------------------------------------------------------------
	// Tratamento para os ambientes de GCAD não olharem a system_info
	// pois eles tem um ambiente TOP que não tem conexão com o banco
	//----------------------------------------------------------------------
	If __lGCADPatch == "0" .And. FWHasTopInfo()
		If !TcIsConnect() .or. !TcCanOpen('SYSTEM_INFO')
			MPSyInfoOpenTables(.F.)
		Endif

		cValue:=MpSysExecScalar(("SELECT MPI_VALUE FROM SYSTEM_INFO WHERE MPI_SYNAME ='"+MPSysTblPrefix(.T.)+"' AND MPI_KEY='"+cKey+"' AND D_E_L_E_T_ = ' '"),'MPI_VALUE')

		If Empty(cValue)
			cValue:=''//para garantir que nunca retorne nil
		Endif
	EndIf
#ENDIF

Return cValue

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSGetAll()
Retorna todos os valores da tabela MP_INFO.
	
@author Felipe Bonvicini Conti
@since Nov 22, 2016
@version P12
/*/
//-------------------------------------------------------------------
Function MPSGetAll()
Local aRet := {}
Local cQryAlias
Local cQuery
Local oSt

#IFDEF TOP
	If __lGCADPatch == "0" .And. FWHasTopInfo()
		If !TcIsConnect() .or. !TcCanOpen('SYSTEM_INFO')
			MPSyInfoOpenTables(.F.)
		EndIf

		cQuery := "SELECT DISTINCT MPI_SYNAME, MPI_KEY, MPI_VALUE, MPI_DATE"
		cQuery +=  " FROM SYSTEM_INFO"
		cQuery += " WHERE D_E_L_E_T_ = ?"
		cQuery +=   " AND MPI_SYNAME = ?" 

		oSt := FWPreparedStatement():New(cQuery)
		oSt:setString(1, ' ')
		oSt:setString(2, MPSysTblPrefix(.T.))
		cQuery := oSt:getFixQuery()
		cQuery := ChangeQuery(cQuery)

		MPSysOpenQuery(cQuery, @cQryAlias)

		While !(cQryAlias)->(Eof())
			aAdd(aRet, {(cQryAlias)->MPI_SYNAME, (cQryAlias)->MPI_KEY, (cQryAlias)->MPI_VALUE, (cQryAlias)->MPI_DATE})
			(cQryAlias)->(dbSkip())
		EndDo

		(cQryAlias)->(dbCloseArea())
		
		oSt:Destroy()
		FwFreeObj(oSt)
	EndIf
#ENDIF

Return aRet