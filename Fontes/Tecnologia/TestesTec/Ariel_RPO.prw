#INCLUDE "PROTHEUS.CH"
#INCLUDE 'TBICONN.CH' 
// #INCLUDE "COMPILE.CH"
// #INCLUDE "APDTREEN.CH"

User Function MyRPOCom()
local cSrc,nCnt
local oRpoForm	
local aListPEG	:= {}
local aMsgErr	:= {}

Static COMPILE_ELEMENTS  := 10
Static COMPILE_FUNCTION  := 1
Static COMPILE_PRG       := 2
Static COMPILE_SOURCE    := 3
Static COMPILE_OK        := 4
Static COMPILE_ALIAS     := 5
Static COMPILE_RECNO     := 6
Static COMPILE_ERROR_STR := 7
Static COMPILE_ERROR_COL := 8
Static COMPILE_ERROR_LINE:= 9
Static COMPILE_INDICE    := 10

Static __aRotErr		:= {}					//Array com os Erros de Roteiro de Calculo

RPCSetType(3)
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT"

// MyGetRPO(@oRpoForm)

cSrc := 'ConOut("Teste do Programa 1")'
AADD(aListPEG, {"MyFunc1" , "MyFunc1" , cSrc} )

cSrc := 'ConOut("Teste do Programa 2")'
AADD(aListPEG, {"MyFunc2" , "MyFunc2" , cSrc} )

If len(@aMsgErr) > 0
    ConOut("Problema na Compilação. VERIFICAR !!!!!!")
Else
    For nCnt:=1 to Len(aListPEG)
        cFunct	:= Lower(aListPEG[nCnt][2]+".PRG")
        If !(FindFunction(cFunct))
            cSrcRet := MyFunRot(aListPEG[nCnt][2],.T.,aListPEG[nCnt][3],@oRpoForm )
            lCompileOk := !MYErrorIn()
            If !( lCompileOk )
                ConOut("Falha na Compila?o dos seguintes Roteiros:")
            EndIf
        EndIf
    Next
EndIf

RESET ENVIRONMENT

Return Nil

Static Function MyFunRot(	cFunction	,;	//01 -> Filial do SRY ( Cabecalho de Roteiro de Calculo )
					lCompile	,;	//03 -> .T. para Compilar, .F. para Remover o Codigo
					cSrcOri		,;	//03 -> codigo fonte para ser compilado
					oRpoForm	;	//04 -> Objeto Repositorio
				)
Local aFunRot,aMsgErr,cPrgFile,nLoop,cSrc,nHandle
Local aPrgsCompile	:= {}
Local cSourcePath	:= "D:\Protheus\P12\BIN\P12.1.17\APO\RH\"

//local msteste := mil_ver()

Begin Sequence  //AQUI VERIFICAR SENÃO É O BEGIN SEQUENCE QUE ESTÁ QUEBRANDO O USO DO RPO
	DEFAULT lCompile := .T.
	IF ( lCompile )
		cPrgFile	:= Lower( ( cSourcePath + cFunction + ".PRG" ) )
		IF !( FileCreate( cPrgFile , @nHandle,,1 ) )
			MyRotAddErr( "Nao Foi Possivel Criar o arquivo." + " | " + cPrgFile )	
			Break
		EndIF

		aFunRot := {}
		aAdd( aFunRot , "User Function " + cFunction + "()" )
		aAdd( aFunRot , "" )
		aAdd( aFunRot , "Begin Sequence" )
		aAdd( aFunRot ,  cSrcOri)
		aAdd( aFunRot , "End Sequence" )
		aAdd( aFunRot , "" )
		aAdd( aFunRot , "Return( NIL )" )

		cSrc 	:= ""
		For nLoop := 1 To Len( aFunRot )
			cSrc += ( aFunRot[ nLoop ] + CRLF )
		Next nLoop

		fWrite( nHandle , cSrc )
		fClose( nHandle )

	EndIF

	AddPrgCompile( @aPrgsCompile , cFunction , cPrgFile , cSrc )
	IF !MyCompile( @oRpoForm , @aPrgsCompile , lCompile , @aMsgErr )
		MyRotAddErr( "Erro de Compilação <<" + cPrgFile + ">>")
		aEval( aMsgErr , { |cError| MyRotAddErr( cError ) } )
		MyRotAddErr( "Error Col:"		+ Str( oRpoForm:ErrCol  ) )
		MyRotAddErr( "Error Line:"	+ Str( oRpoForm:ErrLine ) )
	EndIF

End Sequence

Return( cFunction )

Static Function AddPrgCompile( aPrgsCompile , cFunction , cPrgFile , cSrc )
Local nPrgsCompile
DEFAULT aPrgsCompile := {}

aAdd( aPrgsCompile , Array( COMPILE_ELEMENTS ) )
nPrgsCompile := Len( aPrgsCompile )

aPrgsCompile[ nPrgsCompile , COMPILE_FUNCTION	]	:= cFunction
aPrgsCompile[ nPrgsCompile , COMPILE_PRG		]	:= cPrgFile
aPrgsCompile[ nPrgsCompile , COMPILE_SOURCE		]	:= cSrc
aPrgsCompile[ nPrgsCompile , COMPILE_OK			]	:= .F.
aPrgsCompile[ nPrgsCompile , COMPILE_ALIAS		]	:= "SRY"
aPrgsCompile[ nPrgsCompile , COMPILE_RECNO		]	:= nPrgsCompile
aPrgsCompile[ nPrgsCompile , COMPILE_ERROR_STR	]	:= ""
aPrgsCompile[ nPrgsCompile , COMPILE_ERROR_COL	]	:= 0
aPrgsCompile[ nPrgsCompile , COMPILE_ERROR_LINE	]	:= 0
aPrgsCompile[ nPrgsCompile , COMPILE_INDICE		]	:= 1

Return( NIL )


// função de criação de Repositório temporário
Static Function MyGetRPO(oRpoForm)
Local oRpoForm := Rpo():New()
local bRet := oRpoForm:Open("D:\Protheus\P12\BIN\P12.1.17\APO\RH\rpofrmt1.rpo")
// oRpoForm:StartBuild( .T. )
Return Nil

Static Function MyRotAddErr( cErr )
Local aErr
Local nErr := Len( cErr )
DEFAULT __aRotErr := {}
IF ( nErr > 220 )
	aErr := {}
	While ( nErr > 220 )
		aAdd( aErr , SubStr( cErr , 1 , 220 ) )
		cErr := SubStr( cErr , 221 )
		IF ( ( nErr := Len( cErr ) ) < 220 )
			aAdd( aErr , cErr )
			Exit
		EndIF
	End While
	aEval( aErr , { |cErr| MyRotAddErr( cErr ) } )
ElseIF ( aScan( __aRotErr , { |x| x == cErr } ) == 0 )
	aAdd( __aRotErr , cErr )
EndIF	

Return( NIL )

Static Function MYErrorIn()
Return( !Empty( __aRotErr ) )

Static Function MyCompile( oRpoForm , aPrgsCompile , lCompile , aMsgErr )
Local cSrc
Local cPrgFile
Local cFunction
Local cSourcePath

Local lCompileOk

Local nPrg
Local nPrgs
Local nSrcChkSum

Begin Sequence

	aMsgErr := {}

	IF !( lCompileOk := !Empty( aPrgsCompile ) )
    	Break
	EndIF

	IF !( lCompileOk := MyRpoForm(@oRpoForm) )
		aAdd( aMsgErr , "ERRO:" )
		Break
	EndIF

	IF !( oRpoForm:StartBuild( .T. ) )
		aAdd( aMsgErr , "Nao Foi Possivel Compilar a Formula:" )	//"Nao Foi Possivel Compilar a Formula:"
		aAdd( aMsgErr , "Rpo em uso por Outro Processo." )			//"Rpo em uso por Outro Processo."
		aAdd( aMsgErr , oRpoForm:ErrStr )
		Break
	EndIF

	DEFAULT lCompile	:= .T.
	nPrgs := Len( aPrgsCompile )
	For nPrg := 1 To nPrgs
		cFunction	:= aPrgsCompile[ nPrg , 1 ]
		cPrgFile	:= aPrgsCompile[ nPrg , 2 ]
		IF ( lCompile )
			cSrc		:= aPrgsCompile[ nPrg , 3 ]
			nSrcChkSum	:= oRpoForm:ChkSum( cSrc )
			IF !( lCompileOk := oRpoForm:Compile( cPrgFile , cSrc , 0, nSrcChkSum ) )
				ConOut( "Error Prg:" 	+ cPrgFile		 		  )
				ConOut( "Error Str:" 	+ oRpoForm:ErrStr 		  )
				ConOut( "Error Col:" 	+ Str( oRpoForm:ErrCol  ) )
				ConOut( "Error Line:" 	+ Str( oRpoForm:ErrLine ) )
				aPrgsCompile[ nPrg , COMPILE_ERROR_STR 	] := oRpoForm:ErrStr
				aPrgsCompile[ nPrg , COMPILE_ERROR_COL 	] := oRpoForm:ErrCol
				aPrgsCompile[ nPrg , COMPILE_ERROR_LINE	] := oRpoForm:ErrLine
			EndIF
		ElseIF IsFunction( cFunction )
			cPrgFile := ( cFunction + ".PRG" )
			IF ( lCompileOk := (oRpoForm:RemProg( cPrgFile ).and.!IsFunction( cFunction )))				 
				IF !Empty( cSourcePath := GetRpoForm( .F. , .T. ) )
					cPrgFile := ( cSourcePath + ( cFunction + ".PRG" ) )
					FileErase( cPrgFile )
				EndIF	
				//"O Progama"###"Foi Removido Com Sucesso..."
				ConOut( "O Progama" + " " + cPrgFile + " " + "Foi Removido Com Sucesso..." )
			EndIF
		EndIF
		aPrgsCompile[ nPrg , COMPILE_OK ] := lCompileOk
	Next nPrg
	oRpoForm:EndBuild()
	oRpoForm:Close()
	MyRpoForm(@oRpoForm ,.T.)

End Sequence

Return( lCompileOk )

Static Function MyRpoForm( oRpoForm , lClose )
Local lMyRpoForm	:= .T.
Local lIsObject
Local lGetNew

// DEFAULT oRpoForm := "RpoForm_No_Init"
// DEFAULT lClose := .F.

If lClose
	oRpoForm:Close()
Else
	Begin Sequence

		cGetRpoForm := "D:\Protheus\P12\BIN\P12.1.17\APO\RH\rpofrmt1.rpo"
		IF !( lMyRpoForm := !Empty( cGetRpoForm ) )
			Break
		EndIF
		
		// IF (;
		// 		( lIsObject := ( ValType( __oRpoForm ) == "O" ) );
		// 		.and.;
		// 		!( lGetNew := (;
		// 						( oRpoForm <> cGetRpoForm );
		// 						.or.;
		// 						!__oRpoForm:Open( cGetRpoForm );
		// 					);
		// 		);
		// 	)
		// 	If !( lClose )
		// 		Break
		// 	EndIf
		// EndIF
		
		// IF (;
		// 		( lIsObject );
		// 		.and.;
		// 		(;
		// 			( lGetNew );
		// 			.or.;
		// 			( lClose );
		// 		);	
		// 	)
		// 	__oRpoForm:Close()
		// 	__oRpoForm := NIL
		// 	IF ( lClose )
		// 		Break
		// 	EndIF
		// EndIF

		oRpoForm	:= cGetRpoForm
		oRpoForm	:= Rpo():New()
		lMyRpoForm	:= oRpoForm:Open( cGetRpoForm )
		IF !( lMyRpoForm )
			lIsObject := ( ValType( __oRpoForm ) == "O" )
			IF ( lIsObject )
				__oRpoForm:Close()
			EndIF
			__oRpoForm := NIL
			oRpoForm := "RpoForm_No_Init"
		EndIF

	End Sequence
End

Return( lMyRpoForm )