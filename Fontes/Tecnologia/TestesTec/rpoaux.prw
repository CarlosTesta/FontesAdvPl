#include "Protheus.ch"

#define CLRF Chr(13)+Chr(10)

User Function xRpoAux()
Local cSrcName := "C:\totvs_13\apo_1217\rpofrmt1\source\srcaux.prg"
Local cRpoName := "C:\totvs_13\apo_1217\rpofrmt1\rpoaux.rpo"
Local oRpo := Nil
Local bRet := .F.
Local cSrc := ""
Local nSrcChkSum
Local uExec := ""
Local cFuncName := "S_SrcAux"
Local cExecName := "S_SrcAux()"

//RpcSetEnv("T1", "D MG 01")

oRpo := Rpo():New()

bRet := oRpo:Open(cRpoName)

oRpo:StartBuild( .T. )

If bRet == .T.

	nSrcChkSum	:= oRpo:ChkSum( cSrc )
	
	cSrc := U_RpoSrc(cSrcName, cFuncName)
	bRet := oRpo:Compile(cSrcName, cSrc, 0, nSrcChkSum)
	ConOut("Compilação: " + Iif(bRet == .T., "OK", "FAIL") )
	oRpo:EndBuild()
	
	//oRpo:StartBuild( .T. )
	//oRpo:GenPatch("", "rpofrmt1\", 3, "ANB", {"srcaux.prg"})
	//oRpo:EndBuild()
EndIf
If bRet
	ConOut("FindFunction: ", FindFunction(cFuncName))
	
	S_SrcAux() 
	uExec := &cExecName
	uExec := Eval({||S_SrcAux()})
	ConOut(uExec)
	
	/*
	oRpo:Close()

	oRpo := Rpo():New()
	bRet := oRpo:Open(cRpoName)
	S_SrcAux()
	*/


Else
	ConOut("Compile Fail")
EndIf
oRpo:Close()
Return


User Function RpoSrc(cSrcName, cFuncName)
Local cSrc := ""
Local nHandle

cSrc := "Function " + cFuncName + "() " + CRLF
cSrc += "ConOut(1234567890)" + CRLF
cSrc += "Return"

IF !( FileCreate( cSrcName , @nHandle,,1 ) )
	ConOut("Erro criacao do fonte ")
	Return
EndIF


fWrite( nHandle , cSrc )
fClose( nHandle )


Return cSrc


User Function RunRpo()
Local cRpoName := "C:\totvs\apo127\rpofrmt1\rpoaux.rpo"
Local oRpo := Nil
oRpo := Rpo():New()

bRet := oRpo:Open(cRpoName)
S_SrcAux() 
oRpo:Close()
Return
