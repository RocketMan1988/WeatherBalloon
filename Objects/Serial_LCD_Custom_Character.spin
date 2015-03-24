CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  TX_PIN        = 0
  BAUD          = 19_200

                     
OBJ

  LCD           : "FullDuplexSerial.spin"


PUB Main

  LCD.start(TX_PIN, TX_PIN, %1000, 19_200)
  waitcnt(clkfreq / 100 + cnt)                ' Pause for FullDuplexSerial.spin to initialize


  LCD.tx(250)                                 ' Define custom character 2
                                              ' Now send the eight data bytes
  LCD.tx(%00000)                              ' %00000 =
  LCD.tx(%00100)                              ' %00100 =     *
  LCD.tx(%01110)                              ' %01110 =   * * *
  LCD.tx(%11111)                              ' %11111 = * * * * *
  LCD.tx(%01110)                              ' %01110 =   * * *
  LCD.tx(%00100)                              ' %00100 =     *
  LCD.tx(%00000)                              ' %00000 =
  LCD.tx(%00000)                              ' %00000 =
  LCD.tx(2)                                   ' Display the new custom character 2
