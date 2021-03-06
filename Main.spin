{{
Weather Balloon Project Master Version 1.2

History:
1) Version 1.0 - Baseline Version Written
2) Version 1.1 - Added WatchDog Timer if the Serial Mode is turned off  ...Currently Testing...  Added Command 2: REBOOT (Have to enter 42 after 2 to ensure reboot)
3) Version 1.2 - Worked on the SD Card Code to make it close the file after writing to it. Should make the logging more stable...
4) Version 1.3 - Updated the GPS Baud rate to 9600 and Added a command to print the command list

Baseline Version includes:
1) GPS Monitoring
2) GPS Coordinates Transmitting
3) GPS Coordinates Logged to micro SD card
4) Display GPS on LCD screen and allow sleep function 
5) Commanding to Xbee
  
Pins:

0)GPS Tx
1)LCD Screen
2)Vertical Axis
3)Horizontail Axis
4)Xbee Rx Dout 
5)Xbee Tx Din
6)
7)
8)SD CS
9)SD DI
10)SD CLK
11)SD DO
10)
11)
12)
...
32)



Cogs:
1) Flight Computer (Sensors and logic)
2) GPS and SD Reader/Writer
3) GPS Parsing
4) GPS Serial
5) SD Serial
6) Xbee Serial
7) Xbee TX and RX
8) Serial Terminal for debuging or a watchdog timer (Can be deleted)



The Joystick works with the RC circuit below:
  
          220Ω  C=.1uF
I/O Pin ──┳── GND
             │
           ┌R
           │ │
           └─┻─── GND

  



}}

CON

  Serial = 0                    'If 1 then use the serial connection. If 0 then don't use the serial connection and watchdog timer active.
  'Balloon Mode is now a variable

OBJ
  
  LCD   :      "Serial_Lcd"
  XB    :      "XBee_Object_2"
  sdfat :      "fsrw"
  RC    :      "RCTIME"
  gps  :       "gps_basic"                                            ' gps input
  term :       "fullduplexserial"                                     ' for terminal comms
  
CON                             'Global Constants


  _CLKMODE = XTAL1 + PLL16X      'Set to ext low-speed crystal, 4x PLL                           
  _XINFREQ = 5_000_000          'Set frequency to external crystals 5MHz speed

      ' Set pins and Baud rate for XBee comms  
  XB_Rx     = 4              ' XBee Dout
  XB_Tx     = 5              ' XBee Din
  XB_Baud   = 9600

      ' Set pins and Baud rate for LCD comms  
  LCD_Tx     = 1              'The Pin the LCD is hooked up to
  LCD_Lines  = 2              'The lines on the LCD
  LCD_Baud   = 9600
 

      ' Set pins for SD Card  
  SD_DO     = 11              
  SD_CLK    = 10              
  SD_DI     = 9
  SD_CS     = 8

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

  RX1    = 31                                                   ' programming port
  TX1    = 30

  GPS_RX = 0 

  PST = -8                                                      ' US time zone offsets
  MST = -7
  CST = -6
  EST = -5

  #1, HOME, GOTOXY, #8, BKSP, TAB, LF, CLREOL, CLRDN, CR       ' PST formmatting control
  #14, GOTOX, GOTOY, CLS

dat

screen                  byte    "============================", CR
                        byte    "          GPS Demo          ", CR
                        byte    "============================", CR
                        byte                                    CR
                        byte    "GPS Fix........ ",             CR
                        byte    "Satellites..... ",             CR
                        byte                                    CR
                        byte    "UTC time....... ",             CR
                        byte    "Local time..... ",             CR
                        byte    "Latitude....... ",             CR
                        byte    "Longitude...... ",             CR
                        byte    "Altitude (M)... ",             CR
                        byte    "GPGGA: ........ ",             CR
                        byte    "GPRMC: ........ ",             CR  
                        byte    0



  
VAR                             'Variables


     byte Balloon_Mode               'If 1 then go into balloon mode. If 0 then go into test mode.
     byte watchDogDisable           'If 1 then the watchdog timer will not take action

     byte     GPS_SD_CogID       'Used to itentify the cog the GPS and the SD write functions are currently on
     byte     Xbee_CogID         'Used to identify the cog the Xbee transmit is currently on
     byte     LCD_CogID          'Used to identify the cog the Xbee transmit is currently on             
     byte     menuSleepCount     'Used to sleep the menu if on for a certain amount of time 
     long     Stack_GPS_SD[228]  'Stack Space for GPS and SD  (To be made smaller at a latter time)
     long     Stack_Xbee[228]    'Stack Space for Xbee  (To be made smaller at a latter time) 
     long     Stack_LCD[228]     'Stack Space for LCD  (To be made smaller at a latter time)
     long     Stack_Watch_Dog[228]     'Stack Space for LCD  (To be made smaller at a latter time)
     long     Stack_Terminal[228]     'Stack Space for LCD  (To be made smaller at a latter time)
     long     GPSs[100]          'GPS Coordinates - 100 bytes... To be adjusted
     byte     mount              'Stores if the GPS was mounted or not = 0 for not mounted
     long     Vertical           'GPS Coordinates - 100 bytes... To be adjusted
     long     Horizontal         'Joystick's horizontal position
     long     RCValue            'Joystick's vertical position
     byte     CommandIn
     byte     cognumber
     byte     okay
     long     GPSstring[100]

     byte     watchDogGPS
     byte     watchDogXbee
     byte     watchDogSD

     byte filenameSD[256]
     byte inter_time[256]
     byte time[256]


PUB Main                        ''Main Weather Balloon Program - Incharge of starting all those cogs to run various task.
 
   
  cognumber := 0                'Used to preset cognumber to 0. Cognumber is used to check for the serial connection was made.
  okay := 0
{Start Cogs that need to run right below here}

     Balloon_Mode := 1               'If 1 then go into balloon mode. If 0 then go into test mode.
     watchDogDisable := 0

  Xbee_CogID := cognew(Start_Xbee                         , @Stack_Xbee)  {{Starts 2 cogs}} 
  WaitCnt(ClkFreq * 2 + Cnt)    
   
  GPS_SD_CogID := cognew(Start_GPS_SD                       , @Stack_GPS_SD)  {{Starts 5 cogs+serial_terminal_cog...}} 'Watch Dog Timer started  from GPS_SD or Serial output
  WaitCnt(ClkFreq * 5 + Cnt)
                                                             
  Start_LCD

PUB Start_LCD

  LCD.init(LCD_Tx, LCD_Baud, LCD_Lines)  'Set up the LCD's Pin, Baud Rate, and the line size

  LCD.cls                                'Clear Screen and move cursor to 0,0   
  LCD.putc(18)                           'Turn off backlight    
  LCD.cursor(0)
  LCD.putc(17)                           'Turn on backlight  {{Look to delete in the future if LCD.displayOn works above}}
  LCD.str(string("Weather Balloon"))     'Display 'Weather Balloon' on the first line
  LCD.putc(13)                           'Move to line 2
  LCD.str(string("Version 1.3"))         'Display 'Version 1.2' on line 2

{Give time for Cogs to start running}  
  WaitCnt(ClkFreq * 5 + Cnt)             'Wait for 5 seconds <- In place to allow time for the Cogs to become active and to read the LCD screen                             
  LCD.putc(212)                          'Set Note to a quarter note
  LCD.putc(220)                          'Play note
  LCD.cls                                'Clear Screen and move cursor to 0,0
  Flight                                 'Goto the main flight computer

PUB Flight

{Start of the main flight computer used to check sensors, store sensor data in varriables, make decisions, take pictures, etc...}   
   repeat
     Joystick                           'Check and update the horizontal and vertical varriables
      if Vertical > 8                   'If user is holding the menu button up then display GPS coords on the screen
       LCD_write_GPS
      if Vertical < 8 and Vertical > 2  'else clear and turn off the GPS screen
         LCD_clear_off
      if Vertical < 2
       LCD_write_status   
     WaitCnt(ClkFreq / 2 + Cnt) 
     SensorCheck                         'Conduct a sensor cheeck and update the sensor's varriables
 
{{Below here do a command based case logic, parameter based logic, and andthing else...}}

PUB LCD_write_status 

      LCD.cls
      LCD.putc(17)                           'Turn on backlight  {{Look to delete in the future if LCD.displayOn works above}}
      LCD.str(string("Time:"))
      LCD.str(gps.fs_local_time)

      LCD.putc(13)

      LCD.str(string("Satellites:"))
      LCD.str(gps.s_satellites)
      {{Add the LONG var from the GPS}}
      WaitCnt(ClkFreq * 5 + Cnt)             'Wait for 5 seconds <- In place to allow time for the Cogs to become active and to read the LCD screen                             


PUB LCD_write_GPS                                       {{Write the GPS to the LCD screen}}
   
      LCD.cls
      LCD.putc(17)                           'Turn on backlight  {{Look to delete in the future if LCD.displayOn works above}}
      LCD.str(string("LA:"))
      LCD.str(gps.s_latitude)
      {{Add the LAT var from the GPS}}
      LCD.putc(13)
      LCD.str(string("LG:"))
      LCD.str(gps.s_longitude)
      {{Add the LONG var from the GPS}}
      WaitCnt(ClkFreq * 5 + Cnt)             'Wait for 5 seconds <- In place to allow time for the Cogs to become active and to read the LCD screen                             



PUB LCD_clear_off

  LCD.cls                                'Clear Screen and move cursor to 0,0   
  LCD.putc(18)                           'Turn off backlight    
  LCD.cursor(0)
    
PUB Joystick

    RC.RCTIME(2,1,@Vertical)
    RC.RCTIME(3,1,@Horizontal) 
    Vertical := (Vertical  + 33) / 33
    Horizontal := (Horizontal + 33) / 30


PUB SensorCheck
 



PUB filename
  SetString( @time, gps.s_local_time )

  AddString( @inter_time, string("T_"), @time    )
 
  AddString( @filenameSD, @inter_time, string(".txt") )
  

PRI SetString( dstStrPtr, srcStrPtr )
  ByteMove(dstStrPtr, srcStrPtr, StrSize(srcStrPtr)+1)  '+1 for zero termination
   
PRI AddString( dstStrPtr, srcStrPtr1, srcStrPtr2 ) | len
  len := StrSize(srcStrPtr1)
  ByteMove(dstStrPtr, srcStrPtr1, len)
  ByteMove(dstStrPtr += len, srcStrPtr2, StrSize(srcStrPtr2)+1)   '+1 for zero termination


PUB Start_GPS_SD                       ''Obtains the GPS coordinates and writes them to an SD Card. In the future this could be combined with the xbee.

 mount := \sdfat.mount_explicit(SD_DO, SD_CLK, SD_DI, SD_CS)


  waitcnt(clkfreq*5 + cnt)
  gps.startx(GPS_RX, CST, 9_600, 2_500)
  waitcnt(clkfreq*3 + cnt)

  filename 

  
  sdfat.popen(@filenameSD, "a")
  sdfat.pflush 
  sdfat.pclose
  
  waitcnt(clkfreq / 10 + cnt)
  if Serial == 1
    term.start(RX1, TX1, %0000, 115_200)                          ' start terminal comms
  else
    GPS_SD_CogID := cognew(watchDogTimer                       , @Stack_Watch_Dog) 
    WaitCnt(ClkFreq * 1 + Cnt)


  waitcnt(clkfreq / 10 + cnt)                                  ' let objects start


  waitcnt(clkfreq * 2 + cnt)                                  ' let objects start

  
  repeat 
    if serial == 1
      printSerialGPS
    watchDogSD := 1
    if gps.hasgps == true
      watchDogGPS := 1
    writeGPSToSD
    WaitCnt(ClkFreq * 1 + Cnt) 
      
  
                                           
  
  
  
pub moveto(x, y)

'' Position PST cursor at x/y

  term.tx(GOTOXY)
  term.tx(x)
  term.tx(y)


PUB printSerialGPS | sync, ok 

    sync := cnt

    if (gps.hasgps == false)                                    ' connected?
      term.tx(CLS)                                              ' no, reset screen
      term.str(@screen)
      moveto(16, 4)
      term.str(string("No GPS"))                                ' display no-connect msg
    else
      term.tx(CLS)                                                  ' clean-up terminal
      term.str(@screen)
      moveto(16, 4)
      term.str(gps.s_gpsfix)                                    ' gps quality (fix)
      term.tx(CLREOL)
      ok := gps.n_gpsfix                                        ' flag for other fields
      
      moveto(16, 5)
      term.str(gps.s_satellites)
      term.tx(CLREOL)

      moveto(16, 7)
      term.str(gps.fs_utc_time)
      term.tx(CLREOL)

      moveto(16, 8)
      term.str(gps.fs_local_time)
      term.tx(CLREOL)
              
      moveto(16, 9)
      term.tx(" ")
      term.str(gps.s_latitude)
      term.tx(CLREOL)

      moveto(16, 10)
      term.str(gps.s_longitude)
      term.tx(CLREOL)

      moveto(16, 12)
      term.str(gps.GPSgga)
      term.tx(CLREOL)

      moveto(16, 13)
      term.str(gps.GPSrmc)
      term.tx(CLREOL)
      
      moveto(16, 14)
      term.str(@filenameSD)
      term.tx(CLREOL)

      moveto(16, 15)
      term.dec(watchDogGPS)
      term.tx(CLREOL)
      moveto(16, 16)
      term.dec(watchDogXbee)
      term.tx(CLREOL)
      moveto(16, 17)
      term.dec(watchDogSD)
      term.tx(CLREOL)
    waitcnt((clkfreq * 1) + cnt)                               ' refresh once per second
    

    
Pub int_GPS

    GPS_SD_CogID := cognew(Start_GPS_SD                       , @Stack_GPS_SD)  {{Enter in GPS/SD SubRoutine at a latter time}}


PUB Stop_GPS

    cogstop(GPS_SD_CogID)                                                                 {{Kill the GPS/SD}}
    GPS_SD_CogID := -1

PUB writeGPSToSD  

    sdfat.popen(@filenameSD, "a")
    sdfat.pflush 
    sdfat.pputs(string(13,10,"$"))
    sdfat.pputs(gps.GPSgga)
    sdfat.pputs(string(13,10,"$"))
    sdfat.pputs(gps.GPSrmc)
    sdfat.pclose        
        

PUB Start_Xbee                          ''Below: Start_Xbee, SendGPS and RxCMD are all used for xbee transmission

  XB.RxFlush
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud)   ' Initialize comms for XBee
  XB.Delay(1000)                       ' One second delay 
  XB.str(string("XB is running.....",13))   ' Notify base
  XB.CR


    repeat
      SendGPS
      RxCMD
      watchDogXbee := 1
          
      
PUB SendGPS

    if balloon_mode == 0 
      XB.Tx("!")                       ' Send start delimiter
      XB.CR 
      XB.str(string("============================"))
      XB.CR 
      XB.str(string("             GPS            "))
      XB.CR 
      XB.str(string("============================"))
      XB.CR
      XB.CR
      XB.str(string("GPS Fix........ "))
      XB.str(gps.s_gpsfix)
      XB.CR
      XB.str(string("Satellites..... "))
      XB.str(gps.s_satellites)
      XB.CR
      XB.CR
      XB.str(string("Date........... "))
      XB.str(gps.fs_date)
      XB.CR      
      XB.str(string("Satellites..... "))
      XB.str(gps.s_satellites)
      XB.CR
      XB.str(string("UTC time....... "))
      XB.str(gps.fs_utc_time)
      XB.CR
      XB.str(string("Local time..... "))
      XB.str(gps.fs_local_time)
      XB.CR
      XB.str(string("Latitude....... "))
      XB.str(gps.s_latitude)
      XB.CR
      XB.str(string("Longitude...... "))
      XB.str(gps.s_longitude)
      XB.CR                                                              
      XB.str(string("Altitude (M)... "))
      XB.str(gps.s_altm)
      XB.CR
      XB.str(string("Speed (Mph).... "))
      XB.str(gps.n_speedm)
      XB.CR
      XB.str(string("Bearing (D).... "))
      XB.str(gps.s_bearing)
      XB.CR
      XB.str(string("GPGGA: ........ "))
      XB.str(gps.GPSgga)
      XB.CR
      XB.str(string("GPRMC: ........ "))
      XB.str(gps.GPSrmc)
      XB.CR
      XB.str(string("Results: ...... "))
      XB.str(gps.rslt_pntr)
      XB.CR
      XB.CR

    else
       XB.CR
       XB.str(string("$"))
       XB.str(gps.GPSgga)
       WaitCnt(ClkFreq * 1/6 + Cnt)
       'XB.CR
       'XB.str(string("$"))
       'XB.str(gps.GPSrmc)
       'Code above works well for hyperteerminal logging --> Goops --> Google Earth
    
      
PUB RxCMD | DataIn

      DataIn := XB.RxTime(2000)           ' Wait for byte with timeout <-Also the time to update GPSs
      XB.CR 
      If DataIn == "!"                    ' Check if delimiter
        CommandIn := XB.RxDecTime(10000)   ' Wait for decimal value that significes a command
        XB.Str(string(CR,"Delimiter ",CR,"Command: "))    ' Send message to base that the command was not recieved...
        XB.dec(CommandIn)
                         
        Case CommandIn                    'Check
          1:  ' Command 1: 
            XB.CR
            XB.str(string(CR,"Command 1: Command List: Command 1(Command List), Command 2(Reboot), Command 3(Activate Balloon Mode), Command 4(Deactivate Balloon Mode), Command 5(WatchDog Disable), Command 6(WatchDog Enable), Command 7(SD Unmount), Command 8(No Op Test Command)"))
            CommandIn := 0
          2:  ' Command 2: 
            XB.CR
            XB.str(string(CR,"Command 2: REBOOT: Password?"))
            CommandIn := 0
            XB.CR
            CommandIn := XB.RxDecTime(10000)   ' Wait for decimal value that significes a command
            XB.Str(string(CR,"Delimiter ",CR,"Command: "))    ' Send message to base that the command was not recieved...
            XB.dec(CommandIn)
             if CommandIn == 42
               XB.str(string(CR,"Rebooting..."))
               REBOOT
          3:  ' Command 3: 
            XB.CR
            XB.str(string(CR,"Command 3: Balloon Mode Activated"))
            CommandIn := 0
            Balloon_Mode := 1 
            XB.CR
          4:  ' Command 4: 
            XB.CR
            XB.str(string(CR,"Command 4: Balloon Mode Deactivated"))
            Balloon_Mode := 0                                   
            CommandIn := 0
            XB.CR
          5:  ' Command 5: 
            XB.CR
            XB.str(string(CR,"Command 5: WatchDog Timer Disabled"))
            watchDogDisable := 1
            CommandIn := 0
            XB.CR
          6:  ' Command 6: 
            XB.CR
            XB.str(string(CR,"Command 6: WatchDog Timer Enabled"))
            CommandIn := 0
            watchDogDisable := 0 
            XB.CR
          7:  ' Command 7: 
            XB.CR
            XB.str(string(CR,"Command 7: SD unmount Executing..."))
            sdfat.unmount
            CommandIn := 0
            XB.CR
          8:  ' Command 8: 
            XB.CR
            XB.str(string(CR,"Command 8: No Op Test Command"))
            CommandIn := 0
            XB.CR        
          255:   ' If value not receieved value is 255
            XB.CR
            XB.Str(string(CR,"Command not recieved"))    ' Send message to base that the command was not recieved...                                 
            XB.CR


PUB watchDogTimer


    REPEAT
      WaitCnt(ClkFreq * 5 + Cnt)
      if (watchDogGPS == 0 OR watchDogXbee == 0 OR watchDogSD == 0)
        XB.str(string("WatchDog Timer Failed Test 1:"))
        XB.CR
        XB.CR
        XB.str(string("WatchDog Parameters (GPS, Xbee, SD Card):"))
        XB.dec(watchDogGPS)
        XB.dec(watchDogXbee)
        XB.dec(watchDogSD) 
        WaitCnt(ClkFreq * 16 + Cnt)
        if (watchDogGPS == 0 OR watchDogXbee == 0 OR watchDogSD == 0)
          XB.str(string("WatchDog Timer Failed Test 2:"))
          XB.CR
          XB.CR
          XB.str(string("WatchDog Parameters (GPS, Xbee, SD Card):"))
          XB.dec(watchDogGPS)
          XB.dec(watchDogXbee)
          XB.dec(watchDogSD)
          WaitCnt(ClkFreq * 9 + Cnt)
           if (watchDogGPS == 0 OR watchDogXbee == 0 OR watchDogSD == 0)
             XB.str(string("WatchDog Timer Failed Test 3:"))
             XB.CR
             XB.CR
             XB.str(string("WatchDog Parameters (GPS, Xbee, SD Card):"))
             XB.dec(watchDogGPS)
             XB.dec(watchDogXbee)
             XB.dec(watchDogSD)
             WaitCnt(ClkFreq * 5 + Cnt)
              if (watchDogGPS == 0 OR watchDogXbee == 0 OR watchDogSD == 0)
               if (watchDogDisable == 0)
                XB.str(string("Rebooting Xbee due to: "))
                  if (watchDogGPS == 0)
                    XB.str(string("GPS Problem"))
                  if (watchDogXbee == 0)
                    XB.str(string(" Xbee Problem"))
                  if (watchDogSD == 0)
                    XB.str(string(" SD Problem"))
                REBOOT
      watchDogGPS := 0
      watchDogXbee := 0
      watchDogSD := 0

      if balloon_mode == 0
        XB.CR
        XB.CR
        XB.CR
        XB.str(string("Reset Watchdog TimerXXXXXXXXXXXXXXXXXx"))
        XB.CR
        XB.CR
        XB.CR


            
{{ Underneath is an example using the Full serial Duplex. I didn't use this example because it requires an extra cog to control the LCD...
However, it makes a great example of what all the bytes do when sent/the control of the LCD!

  LCD.start(TxPin, TxPin, %1000, 9_600)
  WaitCnt(ClkFreq / 100 + Cnt)          ' Pause to initialize
  LCD.tx(12)                            ' Clear
  LCD.tx(17)                            ' Turn on backlight
  LCD.str(String("Hello, world..."))    ' First line
  LCD.tx(13)                            ' Line feed
  LCD.str(String("from Parallax!"))     ' Second line
  LCD.tx(212)                           ' Set quarter note
  LCD.tx(220)                           ' A tone
  WaitCnt(ClkFreq * 3 + Cnt)            ' Wait 3 seconds
  LCD.tx(18)                            ' Turn off backlight


}}


dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}  