#DEFINE SEMAFORO 'IDUNICOTESTE'
User Function ipcwaitex()
  StartJob("U_ipcjobs",GetEnvServer(),.F.)
  StartJob("U_ipcjobs",GetEnvServer(),.F.)
   
  Sleep( 1000 )
  IPCGo( SEMAFORO, "Data atual " + cvaltochar(threadid())+ time() )

  sleep(1000)
  IPCGo( SEMAFORO, "Data atual " + cvaltochar(threadid()) + time() )
   
Return
 
User Function ipcjobs()
  Local cPar
  while !killapp()
    lRet := IpcWaitEx( SEMAFORO, 5000, @cPar )
    if lRet
      conout(cPar)
      exit
    else
    	conout(cPar)
    endif
  enddo
Return