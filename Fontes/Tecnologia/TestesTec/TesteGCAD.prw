#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"

User Function TstGCAD()
Local cQuery	:= "SELECT MPI_VALUE FROM SYSTEM_INFO WHERE MPI_SYNAME ='                    ' AND MPI_KEY='WORKROLEINDB' AND D_E_L_E_T_ = ' '"
Local cColumn	:= 'MPI_VALUE'

RPCSetType(3)

// Ambiente para o Lobo Guara
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT"	

// Ambiente para Build do Portal
//PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"	

MPSysExecScalar(cQuery,cColumn)

return

User Function MyScalar()
Local nX
Local xValue
Local cAlias	:= GetNextAlias()

dbSelectArea("SNG")

U_MyOpnQry(cQuery,@cAlias)

If Select(cAlias) > 0
	 xValue := (cAlias)->(&cColumn)
	(cAlias)->(DbCloseArea())
Endif
Return xValue

User Function MyOpnQry(cQuery,cAlias)
Local nX
Local cSaveAlias	:= Alias()
//Local aSetField		:= {}

If Select(cAlias) > 0  
	DbSelectArea(cAlias)
	DbCloseArea()
Endif
DbUseArea(.t.,"TOPCONN",TcGenQry(,,cQuery),cAlias)

If Select(cAlias) > 0
	For nX := 1 To Len ( aSetField )
		TcSetField( cAlias, aSetField[nX][1] , aSetField[nX][2], aSetField[nX][3], aSetField[nX][4] )
	Next nX	
Else	
	//FWLogMsg("ERROR",,"ENVIROMENT","START","OPEN",,TcSqlError(),)
	ConOut("Error in DB:" + TcSqlError())
EndIf
if !Empty(cSaveAlias) 
	DbSelectArea(cSaveAlias)
Endif

Return cAlias