User Function MyAnsi()
ConOut(ansitooem("�"))              // retorno " "
ConOut(ansitooem("�") == chr(160))  // retorno .F.
ConOut(ansitooem("�") == chr(32))   // retorno .T.
Return