#INCLUDE "PROTHEUS.CH"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'TOPCONN.CH'

User Function MyTela()
  RPCSetType(3)
  PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"
  MyRun()

Return

Static Function MyRun()
Local oBrowse := Nil

// Incluido por causa da rotina MSDOCUMENT, o MVC não precisa de nenhuma variável private
Private cCadastro	:= "Grupo de Bens"

CHKFile("SNG")
CHKFile("FNG")

Viewdef()

Return Nil

Static Function Viewdef()
// Cria a estrutura a ser usada na View
Local oStruModel := FWFormStruct( 1, "SNG" )
Local oStruView := FWFormStruct( 2, 'SNG' )
Local _oModel := MPFormModel():New( 'ATFA271', /*bPreValidacao*/, {|oModel| AF271TOk(oModel) },  /*bGravacao*/ , /*bCancel*/ )

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel	:= FWLoadModel( 'ATFA271' )
Local oView		:= FWFormView():New()

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_SNG', oStruModel, 'SNGMASTER' )

TS271TOk(oModel)

Return oView


Static Function TS271TOk(oModel)
Local aArea			:= GetArea()
Local lDefTop		:= IfDefTop()
Local cAliasBem		:= GetNextAlias()
Local lRet			:= .T.
Local nOperation	:= oModel:GetOperation()
Local cGrupo		:= ''
lRet := lRet .and. CtbAmarra(M->NG_CCONTAB,M->NG_CUSTBEM,M->NG_SUBCCON,M->NG_CLVLCON,.T.,.T.)
lRet := lRet .and. CtbAmarra(M->NG_CDEPREC,M->NG_CCDESP,M->NG_SUBCDEP,M->NG_CLVLDEP,.T.,.T.)
lRet := lRet .and. CtbAmarra(M->NG_CCDEPR,M->NG_CCCDEP,M->NG_SUBCCDE,M->NG_CLVLCDE,.T.,.T.)
lRet := lRet .and. CtbAmarra(M->NG_CDESP,M->NG_CCCDES,M->NG_SUBCDES,M->NG_CLVLDES,.T.,.T.)
lRet := lRet .and. CtbAmarra(M->NG_CCORREC,M->NG_CCCORR,M->NG_SUBCCOR,M->NG_CLVLCOR,.T.,.T.)

RestArea(aArea)

Return lRet
