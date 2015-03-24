OBJ
  
  LCD   :       "Serial_Lcd"

CON                             'Global Constants

  _CLKMODE = xtal1 + pll16x      'Set to ext low-speed crystal, 16x PLL                           
  _XINFREQ = 5_000_000          'Set frequency to external crystals 5MHz speed


      ' Set pins and Baud rate for XBee comms  
  LCD_Tx     = 0              'The Pin the LCD is hooked up to
  LCD_Lines  = 2              'The lines on the LCD
  LCD_Baud   = 9600
 
  ' Carriage return value
  CR = 13

PUB Start_LCD

  LCD.init(LCD_Tx, LCD_Baud, LCD_Lines)  'Set up the LCD's Pin, Baud Rate, and the line size
  LCD.displayOn  
  LCD.putc(17)                           'Turn on backlight
  LCD.cls
  LCD.str(string("You're Very Nice"))     'Display Weather Balloon on the first line
  LCD.putc(13)
  LCD.putc(13)                           'Move to line 2
  LCD.str(string("NUM ... NUM"))         'Display Version 1.0 on line 2
  WaitCnt(ClkFreq * 2 + Cnt)             'Wait for 5 seconds <- In place to allow time for the Cogs to become active and to read the LCD screen                             

  LCD.cls                                 'Clear Screen and move cursor to 0,0  
  LCD.str(string("I Like Your Face"))     'Display Weather Balloon on the first line
  LCD.putc(13)                           'Move to line 2
  LCD.putc(13)
  LCD.str(string("NUM ... NUM"))         'Display Version 1.0 on line 2 
  WaitCnt(ClkFreq * 2 + Cnt)             'Wait for 5 seconds <- In place to allow time for the Cogs to become active and to read the LCD screen
  LCD.putc(212)                          'Set Note to a quarter note
  LCD.putc(220)                          'Play note

 repeat
   LCD.cls                                'Clear Screen and move cursor to 0,0
   WaitCnt(ClkFreq / 4 + Cnt) 
   LCD.str(string("SARAH!!!"))            'Display Weather Balloon on the first line
   LCD.putc(13)                           'Move to line 2
   LCD.str(string("<3 ^_^ <3"))           'Display Version 1.0 on line 2
   WaitCnt(ClkFreq / 2 + Cnt)
 


