#include 'fileio.ch'
#INCLUDE "PROTHEUS.CH"

User Function MyWaitXX()
  Local cPathClient:= GetRemoteIniName() 
  Local nPos := 0
  Local nHandle := Nil
  Local cCompName := GetComputerName()
  local envcompname := ""
  local ccommand := "" 
  
  If empty(cCompName)
    //logError( "Error GetComputerName returns empty." )
	ADD_FAIL(aResult, -1 , 'empty(cCompName)')
    //return -1 
  Endif 
  
  nRT := GetRemoteType()
  if nRT < 0
    //logError( "Return -1" )
    //logError( "Error testing ComputerName." )
	ADD_FAIL(aResult, -2, 'nRT < 0')
    //return -2
  endif
  
  // SmartClient Windows
  if nRT >=0 .AND. nRT < 2 
    //retirando o nome do arquivo do ini
    nPos := Rat("\",cPathClient)
    if !( nPos == 0 )
      cPathClient := SubStr( cPathClient, 1, nPos )
      //loginfo("Path Client: "+ cPathClient)
    else
		ADD_FAIL(aResult, -3, '!( nPos == 0 )')
//      return -3
    endif
    
    ccommand := "hostname > result.txt"+ CRLF
    //cria o arquivo para o windows
    nHandle := fcreate(cPathClient+"test.bat") 
    FWrite(nHandle, ccommand)
    FClose(nHandle)
    
    WaitRun(cPathClient+"test.bat" )
    
    // Remove o Bat de teste criado path o Client
    nHandle := ferase(cPathClient+"test.bat")
    If nHandle == -1
      //loginfo( 'ERROR DELETE FILE test: FERROR ' + str(ferror(),4) + " Path: " + cPathClient+"test.bat")
		ADD_FAIL(aResult, -5, 'nHandle == -1')
//      return -5
    Endif

  // SmartClient Linux 
  elseif nRT == 2
    //retirando o nome do arquivo do ini
    nPos := Rat("/",cPathClient)
    if !( nPos == 0 )
      cPathClient := SubStr( cPathClient, 1, nPos )
      //loginfo("Path Client: "+ cPathClient)
    else
		ADD_FAIL(aResult, -4, '!( nPos == 0 )')
//      return -4
    endif
    ccommand := "hostname > result.txt" 
    
    //no linux, tenta executar direto
    ccommand2exec := ccommand
    
    WaitRun(ccommand )
    
  // SmartClient HTML
  elseif nRT == 5
    //loginfo( "SmartClient HTML not yet implemented." ) 
	ADD_FAIL(aResult, -1, 'nRT == 5')
    //return -1
  endif
  
  
  Sleep(1000)
  nHandle := fopen(cPathClient+'result.txt' , FO_READ + FO_SHARED )
  FRead( nHandle, envcompname, 200 ) // Lê os primeiros 10 bytes do arquivo
  fclose(nHandle)
  
  // Remove o arquivo de teste criado path o Client
  nHandle := ferase(cPathClient+"result.txt")
  If nHandle == -1
    //loginfo( 'ERROR DELETE FILE results: FERROR ' + str(ferror(),4))
	ADD_FAIL(aResult, -6, 'nHandle == -1')
    //return -6
  Endif
  
  If !isSrvUnix() // ===> WINDOWS <===
  
    if lower(envcompname) = lower(cCompName)
      //loginfo("result ok:"+cCompName)
    else
      //loginfo("error, from S.O.: "+envcompname+" function advpl GetComputername():"+cCompName)
		ADD_FAIL(aResult, -7, 'lower(envcompname) = lower(cCompName)')
//      return -7
    endif
  
  Else // ===> LINUX <===

    // ============== START ==============

    if lower(envcompname) = lower(cCompName)
      //loginfo("result ok:"+cCompName)
      //logError("result ok:"+cCompName)      
    else
      //loginfo("error, from S.O.: "+envcompname+" function advpl GetComputername():"+cCompName)
      //logError("error, from S.O.: "+envcompname+" function advpl GetComputername():"+cCompName)
		ADD_FAIL(aResult, -7, 'lower(envcompname) = lower(cCompName)')
//      return -7
    endif
    
    // ============== FINISH =============
  
  Endif
   
Return Nil
