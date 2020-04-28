#INCLUDE "PROTHEUS.CH"

// ============================================================================
// Função de Recuperação de fontes !!!
// NEcessário regerar o binário, publicando a função 
// ============================================================================

STATIC aRecover := {}

USER Function SRCRecover()
Local cFnCall := '__GeraSRC'
Local nI  , nT
Local cLib , cXVer
Local aInfo := {}
Local aNoREc := {}

set date british
set century on 

// Lista de fontes a recuperar
cText := myread("\recover.txt")

//cText := strtran(cText," ","")
While CRLF+CRLF $ cText
	cText := strtran(cText,CRLF+CRLF,CRLF)
Enddo
cText := strtran(cText,CRLF,chr(10))

aRecover := strtokarr(cText,chr(10))

If !FindFunction(cFnCall)
	UserException('Recover Source Function not present')
ElseIf MsgYesNo('!!! Clean D:\SternaProject\Protheus\DEFRAG\c\ap7\rpo directory !!! Start recover RPO functions ? ')
	nT := len(aRecover)
	For nI := 1 to nT   
		conout (aRecover[nI]) // Abramo
		if !".BMP"$aRecover[nI] .and. !".GIF"$aRecover[nI] .and. !".JPG"$aRecover[nI] .and. ascan(aNoRec,{|x| x$upper(aRecover[nI]) }) == 0
			if !file("D:\SternaProject\Protheus\DEFRAG\c\ap7\rpo\"+aRecover[nI])
				aInfo := GETAPOINFO(aRecover[nI]) 
				// Pega informacao do fonte
				if empty(aInfo)
					conout("File ["+padr(aRecover[nI],20)+"] SOURCE INFO NOT AVAILABLE OR OUT FOUND.")
				Else
					conout("File ["+padr(aInfo[1],20)+"] Type ["+aInfo[2]+"] Build ["+padr(aInfo[3],10)+"] Date ["+dtoc(aInfo[4])+"]")
					&cFnCall.(aRecover[nI],,)
					if !file("D:\SternaProject\Protheus\DEFRAG\c\ap7\rpo\"+aRecover[nI])
						conout("*** SOURCE RECOVER FAILED ON FILE "+aRecover[nI]+" ***")
					Endif
				Endif
			else
				conout("Arquivo ["+aRecover[nI]+"] recuperado anteriormente ... ")
			Endif
		Endif
		if killapp()
			conout("*** Processo ABORTADO")
			__quit()
		endif			
	Next
Endif

Return


USER Function SRCRecP12()
Local cFnCall := 'GetSource'
Local nI  , nT
Local cLib , cXVer
Local aNoREc := {}

set date british
set century on 

// Lista de fontes a recuperar
cText := myread("\recover.txt")

//cText := strtran(cText," ","")
While CRLF+CRLF $ cText
	cText := strtran(cText,CRLF+CRLF,CRLF)
Enddo
cText := strtran(cText,CRLF,chr(10))

aRecover := strtokarr(cText,chr(10))

If !FindFunction(cFnCall)
	UserException('Recover Source Function not present')
ElseIf MsgYesNo('!!! Clean D:\SternaProject\Protheus\DEFRAG\c\ap7\rpo directory !!! Start recover RPO functions ? ')
	nT := len(aRecover)
	For nI := 1 to nT
		//aRecover[nI] := substr(aRecover[nI],29,100) //Abramo para MARFIG !!!
		if !".BMP"$aRecover[nI] .and. !".GIF"$aRecover[nI] .and. !".JPG"$aRecover[nI] .and. ascan(aNoRec,{|x| x$upper(aRecover[nI]) }) == 0
			if !file("D:\SternaProject\Protheus\DEFRAG\c\ap7\rpo\"+aRecover[nI])
				aInfo := GETAPOINFO(aRecover[nI])
				// Pega informacao do fonte
				if empty(aInfo)
					conout("File ["+padr(aRecover[nI],20)+"] SOURCE INFO NOT AVAILABLE OR OUT FOUND.")
				Else
					conout("File ["+padr(aInfo[1],20)+"] Type ["+aInfo[2]+"] Build ["+padr(aInfo[3],10)+"] Date ["+dtoc(aInfo[4])+"]")
					GetSource(aRecover[nI],"D:\SternaProject\Protheus\DEFRAG\c\ap7\rpo\")
					if !file("D:\SternaProject\Protheus\DEFRAG\c\ap7\rpo\"+aRecover[nI])
						conout("*** SOURCE RECOVER FAILED ON FILE "+aRecover[nI]+" ***")
					Endif
				Endif
			else
				conout("Arquivo ["+aRecover[nI]+"] recuperado anteriormente ... ")
			Endif
		Endif
		if killapp()
			conout("*** Processo ABORTADO")
			__quit()
		endif			
	Next
Endif

Return


USER Function AllFunc()
Local ni,nt,ax
ax := GetFuncArray("U_*")
nt := len(ax)
for ni := 1 to nt
conout(ax[ni])
Next
Return

STATIC Function MyRead(cFile)
Local nh := fopen(cFile)
Local cBuff
if nh == -1
	UserException("OPEN ERROR "+cFile)
Endif
nTam := fseek(nh,0,2)
IF nTam == 0
	UserException("SIZE 0 ERROR "+cFile)
Endif
fseek(nh,0)
cBuff := space(nTam)
fread(nh,@cBuff,nTam)
fclose(nh)
Return cBuff

// Cria um MAPA do RPO
USER Function RPOMap()
Local cRpoPath := GetSrvProfString('SourcePath','NOT FOUND')
Local aFonteRes := {} , nRes
Local aFonteFun := {} , nFun
Local aFonteCls := {} , nCls
Local aFonteALL := {}
Local aFunctions := {}
Local aFonteInfo := {} 
Local nI , nT

MsgRun("Identificando Resources do RPO","Aguarde...",{|| GetResInfo(@aFonteRes) } )
MsgRun("Identificando Funcoes do RPO","Aguarde...",{|| aFunctions := GetFuncArray("*") } )
MsgRun("Identificando Fontes de Funcoes do RPO","Aguarde...",{|| GetFunInfo(@aFonteFun,@aFonteALL) } )
MsgRun("Identificando Fontes de Classes do RPO","Aguarde...",{|| GetClaInfo(@aFonteCls,@aFonteAll) } )
MsgRun("Detalhamento de Fontes","Aguarde...",{|| GetSrcDetail(@aFonteAll,@aFonteInfo) } )

nAll := len(aFunctions)
nRes := len(aFonteRes)
nFun := len(aFonteFun)
nCls := len(aFonteCls)
nTot := len(aFonteALL)

conout(padc(" INFORMACOES DO RPO ",79,'='))
conout("Path .........: "+cRpoPath)
conout("")
conout("Funcoes Compiladas...: "+str(nAll,7))
conout("Resources ...........: "+str(nRes,7))
conout("Fontes com Funcoes...: "+str(nFun,7))
conout("Fontes com Classes...: "+str(nCls,7))
conout("Total de Fontes .....: "+str(nTot,7))
conout("")

nT := len(aFonteInfo[1])
conout(padc(" Tipos de Fontes ",30,'-'))
For nI := 1 to nT
	conout(padr(aFonteInfo[1][nI][1],21,".")+": "+str(aFonteInfo[1][nI][2],7))
Next

nT := len(aFonteInfo[2])
conout(padc(" Tipos de Build ",30,'-'))
For nI := 1 to nT
	conout(padr(aFonteInfo[2][nI][1],21,".")+": "+str(aFonteInfo[2][nI][2],7))
Next

conout(replicate("-",79))
Return



STATIC Function GetResInfo(aFonteRes)
Local nRes 
nRes  := aFonteRes := GetResArray("*")
Return



STATIC Function GetFunInfo(aFonteFun,aFonteALL)
Local nI , nFun
aFonteFun := GetSrcArray("*")
nFun := len(aFonteFun)
For nI := 1 to nFun
	If ascan(aFonteALL,{|x| x[1] == aFonteFun[nI]}) == 0
		aadd(aFonteALL , { aFonteFun[nI] } )
	Endif
Next
Return

STATIC Function GetClaInfo(aFonteCls,aFonteALL)
Local nI , nCla
aFonteCls := GetClsArray("*")
nCla := len(aFonteCls)
For nI := 1 to nCla
	If ascan(aFonteALL,{|x| x[1] == aFonteCls[nI]}) == 0
		aadd(aFonteALL , { aFonteCls[nI] } )
	Endif
Next
                                     
Return

// conout("File ["+padr(aInfo[1],20)+"] 
// Type ["+aInfo[2]+"] 
// Build ["+padr(aInfo[3],10)+"] 
// Date ["+dtoc(aInfo[4])+"]")

STATIC Function GetSrcDetail(aFonteAll,aFonteInfo)
Local nI , nT := len(aFonteAll)
Local aTipos := {}
Local aBuilds := {}
Local nPos
For nI := 1 to nT
	// Recupera as informacoes deste fonte / recurso
	aInfo := GETAPOINFO(aFonteAll[nI][1])
	aadd(aFonteAll[nI],aclone(aInfo ))
	// Acrescenta o tipo de recurso encontrado em um array de Tipos 
	nPos := ascan(aTipos,{ |x| x[1] == aInfo[2] } )
	IF nPos = 0
		aadd(aTipos,{aInfo[2],1})
	Else
		aTipos[nPos][2] := aTipos[nPos][2] + 1 
	Endif
	// Acrescenta o direito de Build usado em uma lista de direitos
	nPos := ascan(aBuilds,{ |x| x[1] == aInfo[3] })
	IF nPos = 0
		aadd(aBuilds,{aInfo[3],1})
	Else
		aBuilds[nPos][2] := aBuilds[nPos][2] + 1 
	Endif
Next
aadd(aFonteInfo,aclone(aTipos))
aadd(aFonteInfo,aclone(aBuilds))
Return


/*
getfuncprm      [CR]
Recupera os parametros declarados de uma funcao compilada no RPO
*/

USER Function MYFunc(ze)
Local ax//ni,nt,
ax := GetFuncPrm("U_MYFUNC")
varinfo("AX",ax)
Return

