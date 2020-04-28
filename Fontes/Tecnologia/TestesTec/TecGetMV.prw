#INCLUDE "PROTHEUS.CH"

User Function TecGetMV()
// Local xRet
// Local cRDD		:= __LocalDriver
// Local cPathSX6  := Upper(GetPvProfString( GetEnvServer() , "StartPath" , "" , GetAdv97() ) ) + "SX6"


// dbUseArea(.T., cRDD, cFile,"TRB", .F., .F.)
// DBSelectArea("SX6")
// SX6->(DBSetOrder(1)) //X6_FIL+X6_VAR
// If !SX6->(MSSeek(XFilial("SN1") + "MV_ULTDEPR"))
// endif
conout("U_TecGetMV")

TecGetMV()

Return()

Static Function TecGetMV()
    conout("Static TecGetMV")
Return
