#include "protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัอออออออออออออออออออออออออออออออออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ SPFMan  บAutor  ณCarlos TESTA                                       บ Data ณ  18/12/2017  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Programa para Stress de ambiente Protheus                                                 บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบObjetivo  ณ Gerar Excesso de IO e consumo de mem๓ria em simultaneo                                    บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Testes do AdvTec11.                                                                       บฑฑ
ฑฑบ          ณ   * Cria um arquivo de Help Padrao do Protheus a partir do SYSTEMLOAD                     บฑฑ
ฑฑบ          ณ     replica os dados deste arquivo de help para uma matriz em memoria                     บฑฑ
ฑฑบ          ณ     depois efetua algumas manutencoes nos dados para forcar trabalho em memoria	         บฑฑ
ฑฑบ          ณ     apos todo o processamento, grava os dados em um arquivo de memoria que foi ZERADO     บฑฑ
ฑฑบ          ณ     atraves de rotinas padrao do Protheus para manipular arquivos SUPERFILE               บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function SPFMan()
Local _cKey1,_cKey2,_cKey3,_cMemo,_nReg,_nTotAlt,_nCnt,_nIniTime,_cTarget,_nMiddleTime
Local _aDadosSPF	:= {}
Local _cSrvIP		:= GetServerIP()								// IP do servidor atual
Local _cSrvPort		:= GetPvProfString("TCP","Port","undefined","appserver.ini")	// Porta do AppServer
Local _cEnvWork		:= GetEnvServer()								// Environment atual de trabalho
Local _cThread		:= AllTrim(Str(ThreadID()))						// numero da thread para garantir unicidade no nome do arquivo
Local _cSource		:= GetSystemLoadDir()+"HLP_"+_cThread+".TXT"	// nome da copia do HLP especifico para cada thread para rodar em paralelo
Local _cSPFMan		:= GetPvProfString("STRESS","SPF_MAN","undefined","appserver.ini")
Local _nSPFMan		:= Iif(!Empty(_cSPFMan),Val(SubStr(_cSPFMan,At("/",_cSPFMan)+1)),10)	// caso sem valor, assume 10

RpcSetType( 3 )
PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"

// criacao do arquivo de origem de dados
__CopyFile(GetSystemLoadDir()+'HLPDFPOR.TXT',_cSource)

// iremos trabalhar com o tempo MษDIO DA EXECUวรO DE BLOCOS.
_nIniTime	:= Microseconds()
For _nCnt := 1 to _nSPFMan
	_cTarget	:= "SPF_MAN_"+_cThread+"_"+StrZero(_nCnt,3)+".STRESS"	// nome do arquivo de teste

	// cria um arquivo SUPER FILE baseado no arquivo de HELP do sistema para testar as funcoes de controle
	aDir := Directory(_cSource)
	CreateHlp(_cTarget,_cSource,aDir[1,2],.T.)

	_nTotAlt := SPF_RECCOUNT(_cTarget,1)
	If _nTotAlt < 0 
		Conout("Falha no SPF_RECCOUNT() no arquivo " + _cTarget)
		Return -1
	EndIf
	// pontera primeiro registro do SUPER FILE
	_nReg := SPF_GOTOP(_cTarget,1)
	If _nReg < 0 
		Conout("Falha no primeiro SPF_GOTOP() no arquivo " + _cTarget)
		Return -1
	Else
		While _nReg > 0
			SPF_GETFIELDS(_cTarget,_nReg,@_cKey1,@_cKey2,@_cKey3,@_cMemo)
			AADD(_aDadosSPF,{_cTarget,_cKey1,_cKey2,_cKey3,AllTrim(_cMemo)})
			_nReg := SPF_SKIP(_cTarget,_nReg,1)
		EndDo
	EndIf

	SPF_Close(_cTarget)
	fErase(_cTarget)
Next
// Apaga o arquivo de origem de dados copiado a partir do arquivo real do protheus
fErase(_cSource)

// ConOut para Printar o tempo de cada execu็ใo em cada passada
ConOut(Repl("-",80))
_nMiddleTime := (Microseconds()-_nIniTime)/_nSPFMan
ConOut('LOG de Processo "SPF_MAN" | THREAD: "'+_cThread+'" | Lacos: "'+AllTrim(Str(_nSPFMan))+'" | Server:"'+_cSrvIP+':'+_cSrvPort+'" | Environment:"'+_cEnvWork+'" | Tempo Medio:"'+ AllTrim(Str(_nMiddleTime))+'" segundos.')
ConOut(Repl("-",80))

RESET ENVIRONMENT

Return Nil