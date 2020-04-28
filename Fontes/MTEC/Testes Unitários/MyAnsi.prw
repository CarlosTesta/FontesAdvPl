User Function MyAnsi()
ConOut(ansitooem("á"))              // retorno " "
ConOut(ansitooem("á") == chr(160))  // retorno .F.
ConOut(ansitooem("á") == chr(32))   // retorno .T.
Return