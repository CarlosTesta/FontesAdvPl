#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSysDBHelper
Funções genericas de tratamento de arquivos do framework no banco de 
dados.
	
@author Rodrigo Antonio
@since Oct 13, 2014
@version {$Version}
/*/
//-------------------------------------------------------------------
Function __MPSysDBHelper()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MPSyTblPrefix
Retorna o prefixo do ambiente para ser utilizados nas tabelas do 
framework.
	
@author Rodrigo
@since Oct 13, 2014
@version version
/*/
//-------------------------------------------------------------------
Function MPSysTblPrefix(lToSeek)
Local cPrefix := ""

Default lToSeek := .F.

if lToSeek
      cPrefix := cPrefix + Space(MPSNameSize()-Len(cPrefix))
Endif

//TODO:Verificar o que fazer com o prefixo 

Return cPrefix

//-------------------------------------------------------------------
/*/{Protheus.doc} MPTblInDB
Função que retorna se a tabela existe no Banco
	
@author arthur.fucher
@since Nov 18, 2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function MPTblInDB(cTable)
Local inDB := .F.
	#IFDEF TOP
		If TCIsConnected()
			inDB := TCCanOpen(cTable)
		EndIf	
	#ENDIF
Return inDB

//-------------------------------------------------------------------
/*/{Protheus.doc} MPTblNames
Retorna o nome das tabelas de um determinado item.
Disponíveis: "PROFILE", "WORKROLE", "USER", "MENU", "DIC", "HELP"
	
@param cNameSpace String contendo o nome dos itens que deseja retornar as tabelas, podendo ser vazio caso queira todas. 
									Pode ser passado também com mais de um, exemplo: "PROFILE|WORKROLE".

@return aTables Array contendo o nome das tabelas.
@author arthur.fucher
@since Nov 21, 2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function MPTblNames(cNameSpace)
Local aTables := {}
Local cPrefix := MPSysTblPrefix()
Local aDic
Local nDic
	
	//------------------
	//Tabelas do Profile
	//------------------
	If Empty(cNameSpace) .Or. "PROFILE" $ cNameSpace
		AAdd( aTables , cPrefix +  'MP_SYSTEM_PROFILE')
	EndIf
	//-----------------------------
	//Tabelas do Papel de Trabalho
	//-----------------------------
	If Empty(cNameSpace) .Or. "WORKROLE" $ cNameSpace
		AAdd( aTables , cPrefix +  'MP_SYSTEM_WORKROLE')
	EndIf

	//-----------------------------
	//Tabelas de usuário
	//-----------------------------
	If Empty(cNameSpace) .Or. "USER" $ cNameSpace
		AAdd( aTables , cPrefix +  'SYS_GRP_ACCESS')
		AAdd( aTables , cPrefix +  'SYS_GRP_ACCRESTRIC')
		AAdd( aTables , cPrefix +  'SYS_GRP_ACESSIB')
		AAdd( aTables , cPrefix +  'SYS_GRP_FILIAL')
		AAdd( aTables , cPrefix +  'SYS_GRP_GROUP')
		AAdd( aTables , cPrefix +  'SYS_GRP_MODULE')
		AAdd( aTables , cPrefix +  'SYS_GRP_PANEIS')
		AAdd( aTables , cPrefix +  'SYS_GRP_PRINTER')
		AAdd( aTables , cPrefix +  'SYS_GRP_WORK_PAPER')
		AAdd( aTables , cPrefix +  'SYS_POL_COMMUNIC')
		AAdd( aTables , cPrefix +  'SYS_POL_FLG_IDENTY')
		AAdd( aTables , cPrefix +  'SYS_POL_OAUTH')
		AAdd( aTables , cPrefix +  'SYS_POL_PAINEIS')
		AAdd( aTables , cPrefix +  'SYS_POL_POLICE')
		AAdd( aTables , cPrefix +  'SYS_POL_PROTHEUS')
		AAdd( aTables , cPrefix +  'SYS_POL_RULES_VIOL')
		AAdd( aTables , cPrefix +  'SYS_POL_SAML')
		AAdd( aTables , cPrefix +  'SYS_RULES')
		AAdd( aTables , cPrefix +  'SYS_RULES_BUTTONS')
		AAdd( aTables , cPrefix +  'SYS_RULES_FEATURES')
		AAdd( aTables , cPrefix +  'SYS_RULES_GRP_GLO')
		AAdd( aTables , cPrefix +  'SYS_RULES_GRP_RULES')
		AAdd( aTables , cPrefix +  'SYS_RULES_TRANSACT')
		AAdd( aTables , cPrefix +  'SYS_RULES_USR_GLO')
		AAdd( aTables , cPrefix +  'SYS_RULES_USR_RULES')
		AAdd( aTables , cPrefix +  'SYS_USR')
		AAdd( aTables , cPrefix +  'SYS_USR_ACCESS')
		AAdd( aTables , cPrefix +  'SYS_USR_ACCRESTRIC')
		AAdd( aTables , cPrefix +  'SYS_USR_ACESSIB')
		AAdd( aTables , cPrefix +  'SYS_USR_FILIAL')
		AAdd( aTables , cPrefix +  'SYS_USR_GROUPS')
		AAdd( aTables , cPrefix +  'SYS_USR_LOGCFG')
		AAdd( aTables , cPrefix +  'SYS_USR_MODULE')
		AAdd( aTables , cPrefix +  'SYS_USR_PANEIS')
		AAdd( aTables , cPrefix +  'SYS_USR_PAPER')
		AAdd( aTables , cPrefix +  'SYS_USR_PRINTER')
		AAdd( aTables , cPrefix +  'SYS_USR_SSIGNON')
		AAdd( aTables , cPrefix +  'SYS_USR_SUPER')
		AAdd( aTables , cPrefix +  'SYS_USR_VINCFUNC')
	EndIf
	
	If Empty(cNameSpace) .Or. "MENU" $ cNameSpace
		AAdd( aTables , cPrefix +  'MPMENU_FUNCTION')
		AAdd( aTables , cPrefix +  'MPMENU_I18N')
		AAdd( aTables , cPrefix +  'MPMENU_ITEM')
		AAdd( aTables , cPrefix +  'MPMENU_KEY_WORDS')
		AAdd( aTables , cPrefix +  'MPMENU_MENU')
		AAdd( aTables , cPrefix +  'MPMENU_RW')
	EndIf
	
	If Empty(cNameSpace) .Or. "REPORTLAYOUT" $ cNameSpace
		AAdd( aTables, MPDicSysName('XB5') )
	EndIf
	
	If Empty(cNameSpace) .Or. "DIC" $ cNameSpace
		aDic := MPDicGetTables()
		For nDic := 1 To Len(aDic)
			AAdd( aTables, MPDicSysName(aDic[nDic]) )
		Next
	EndIf
	
	If Empty(cNameSpace) .Or. "COMPANY" $ cNameSpace
		AAdd( aTables , cPrefix +  'SYS_COMPANY')
		AAdd( aTables , cPrefix +  'SYS_COMPANY_CFGIT')
		AAdd( aTables , cPrefix +  'SYS_COMPANY_CFG')
	EndIf

	If Empty(cNameSpace) .Or. "HELP" $ cNameSpace
		AAdd( aTables , cPrefix + 'XB4')
	EndIf

Return aTables