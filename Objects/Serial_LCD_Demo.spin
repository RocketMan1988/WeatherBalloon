CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  TX_PIN        = 2
  BAUD          = 9_600

                     
OBJ

  LCD           : "FullDuplexSerial.spin"


PUB Main

  LCD.start(TX_PIN, TX_PIN, %1000, 9_600)
  waitcnt(clkfreq / 100 + cnt)                ' Pause for FullDuplexSerial.spin to initialize
  LCD.str(string("Hello, this text will wrap."))