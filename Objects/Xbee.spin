OBJ
  
  XB   :       "XBee_Object_2"

CON                             'Global Constants

  _CLKMODE = XTAL1 + PLL4X      'Set to ext low-speed crystal, 4x PLL                           
  _XINFREQ = 5_000_000          'Set frequency to external crystals 5MHz speed

      ' Set pins and Baud rate for XBee comms  
  XB_Rx     = 0              ' XBee Dout
  XB_Tx     = 1              ' XBee Din
  XB_Baud   = 9600

  ' Carriage return value
  CR = 13

  ' Used to recieve commands
  ComandIn  = 0

VAR                             'Variables


PUB Main

  XB.RxFlush
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud)   ' Initialize comms for XBee
  XB.Delay(1000)                       ' One second delay 
  XB.str(string("XB is running..."))   ' Notify base
  XB.CR

    repeat
      SendGPS
      RxCMD


PUB SendGPS

      XB.Tx("!")                       ' Send start delimiter
      XB.str(@GPS[105])                ' Send GPS stored coordinates
      XB.Tx("!")                       ' Send start delimiter
      XB.CR 

PUB RxCMD

    Repeat
      DataIn := XB.RxTime(2000)           ' Wait for byte with timeout <-Also the time to update GPS
      If DataIn == "!"                    ' Check if delimiter
        CommandIn := XB.RxDecTime(1000)   ' Wait for decimal value that significes a command
        If Command == 0                   ' If value not receieved value is 0
          XB.CR
          XB.Str(string(CR,"Command not recieved"))    ' Send message to base that the command was not recieved...                                 
          XB.CR
       Case Command
         "1":  ' Command 1: 
             PC.str(string(13,13,"Command One Executing..."))
         

         "2":  ' Command 2: 
             PC.str(string(13,13,"Command Two Executing..."))
     Else




