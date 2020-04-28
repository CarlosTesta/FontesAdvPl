#include "protheus.ch"
#include "fileio.ch"

User Function RetFunc()
ConOut("Chegou !!!")
GetSource("LJ7023.PRW","D:\reversao") //vai colocar o fonte recuperado em c:\
GetSource("LJ7020.PRW","D:\reversao") //vai colocar o fonte recuperado em c:\
GetSource("MA020TOK.PRW","D:\reversao") //vai colocar o fonte recuperado em c:\
GetSource("MT103NPC.PRW","D:\reversao") //vai colocar o fonte recuperado em c:\

Return

User Function RetFunc1()
Local cResCont1 := GetApoRes("LJ7020.PRW")
Local cResCont2 := GetApoRes("LJ7023.PRW")

conout(Iif(cResCont1 == cResCont2,"Iguais","Diferentes"))

ConOut(Repl("=",80))
ConOut(cResCont1)
ConOut(Repl("-",80))
ConOut(Repl("-",80))
ConOut(cResCont2)
ConOut(Repl("=",80))
Return

User Function Reversao()
Local nCnt,clOk
Local aLstSrc := {}
// Local nHandle := FT_FUse("D:\SternaProject\Protheus\DEFRAG_rpo\Reversao\Lista_Reversao.txt") 

FT_FGoTop()                 // Posiciona na primeria linha
While !FT_FEOF()
  AADD(aLstSrc,AllTrim(FT_FReadLn()))
  FT_FSKIP()                // Pula para próxima linha
End
FT_FUSE()                   // Fecha o Arquivo

ConOut("-------------------------------------------------------------------")
ConOut("===================================")
For nCnt := 1 To Len(aLstSrc)
  GetSource(aLstSrc[nCnt],"D:\SternaProject\Protheus\DEFRAG_rpo\Reversao\revertidos")
	clOk := Iif(File("D:\SternaProject\Protheus\DEFRAG_rpo\Reversao\revertidos\"+aLstSrc[nCnt],0,.F.),"OK","ERROR")
	ConOut("Revertendo Fonte <<"+ aLstSrc[nCnt] + ">> " + clOk)
Next
ConOut("===================================")
ConOut(" ACABOU !!!!!!")
ConOut("-------------------------------------------------------------------")
Return


User Function Reverte()

GetSource("MyList.PRW","D:\SternaProject\Protheus\DEFRAG_rpo\Reversao\revertidos\MyList.PRW") //vai colocar o fonte recuperado em c:\

Return Nil
