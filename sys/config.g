; Jubilee CoreXY ToolChanging Printer - Config File
; This file intended for Duet 3 hardware, main board plus onr expansion boards

; Name and network
; This is configured from the connected Raspberry Pi or here if in stand alone
; mode
;-------------------------------------------------------------------------------
; Networking
;M550 P"Jubilee"           ; Name used in ui and for mDNS  http://Jubilee.local
;M552 P192.168.1.2 S1      ; Use Ethernet with a static IP, 0.0.0.0 for dhcp
;M553 P255.255.255.0       ; Netmask
;M554 192.168.1.1          ; Gateway


; General setup

M80 C"pson"
;-------------------------------------------------------------------------------
; DISPLAY
M575 P1 S0 B57600
; BOOT DELAY FOR TOOLBOARDS
G4 S8  

M111 S0                    ; Debug off 
M929 P"eventlog.txt" S1    ; Start logging to file eventlog.txt

; General Preferences
M555 P2                    ; Set Marlin-style output
G21                        ; Set dimensions to millimetres
G90                        ; Send absolute coordinates...
M83                        ; ...but relative extruder moves

; Kinematics
;-------------------------------------------------------------------------------
M669 K1                   ; CoreXY mode

; Kinematic bed ball locations.
; Locations are extracted from CAD model assuming lower left build plate corner
; is (0, 0) on a 305x305mm plate.
M671 X297.5:2.5:150 Y313.5:313.5:-16.5 S10 ; Front Left: (297.5, 313.5)
                                           ; Front Right: (2.5, 313.5)
                                           ; Back: (150, -16.5)
                                           ; Up to 10mm correction


; Stepper mapping
;-------------------------------------------------------------------------------
; Connected to the MB6HC as the table below.
; Note: first row is numbered left to right and second row right to left
; _________________________________
; | X(Right) | Y(Left)  | U(lock) |
; | Z(Left)  | Z(Right) | Z(Back) |

M569 P0 S1 D2                   ; Drive 0 | X stepper
M569 P1 S1 D2                   ; Drive 1 | Y Stepper
M569 P2 S0 D2                   ; Drive 2 | U Tool Changer Lock  670mA
M569 P3 S0 D3                   ; Drive 3 | Front Left Z
M569 P4 S0 D3                   ; Drive 4 | Front Right Z
M569 P5 S0 D3                   ; Drive 5 | Back Z

;--------ToolBoards
M569 P10.0 S1 D2
M569 P20.0 S1 D2
M569 P30.0 S1 D2
M569 P40.0 S1 D2

M584 X0 Y1                      ; X and Y for CoreXY
M584 U2                         ; U for toolchanger lock
M584 Z3:5:4                     ; Z has three drivers for kinematic bed suspension. 3:5:4 order to match the bed leveling order. 
;-----
M584 E10.0:20.0:30.0:40.0

M906 X1100 Y1100 Z1000 U650 I50 ; 70% of 1680mA RMS {0.7*sqrt(2)*1680}=1669 but we will use 1000
                                ; LDO XY 2000mA RMS the TMC5160 driver on duet3
                                ; generates a sinusoidal coil current so we can 
                                ; multply by sqrt(2) to get peak used for M906
                                ; Do not exceed 80% without heatsinking the XY 
                                ; steppers. {0.9*sqrt(2)*2000}=2545 but we are using 1100
                                ; 70% of 670mA RMS idle 60% {0.7*sqrt(2)*670}=663 we will use 650
                                ; Note that the idle will be shared for all drivers

M906 E800
M84 S30                         ; Idle timeout

; Axis and motor configuration 
;-------------------------------------------------------------------------------

M350 X1 Y1 Z1 U1 ;E1:1:1:1     ; Disable microstepping to simplify calculations
M92 X{1/(0.9*16/180)}  ; step angle * tooth count / 180
M92 Y{1/(0.9*16/180)}  ; The 2mm tooth spacing cancel out with diam to radius
M92 Z{360/1.8/4}       ; 1.8 deg stepper / lead (4mm) of screw 
M92 U{13.76/1.8}       ; gear ration / step angle for tool lock geared motor.

; Enable microstepping all step per unit will be multiplied by the new step def
M350 X16 Y16 U4 Z16 I1        ; 16x microstepping for CoreXY axes. Use interpolation.
M350 E16 I1         ; 16x microstepping for Extruder axes. Use interpolation.

; Set the esteps on the extruder
M92 E690               ; Extruder - BMG 0.9 deg/step



; Speed and acceleration
;-------------------------------------------------------------------------------
M201 X1100 Y1100                        ; Accelerations (mm/s^2)
M201 Z100                               ; LDO ZZZ Acceleration
M201 U800                               ; LDO U Accelerations (mm/s^2)
M201 E3000                              ; Extruder

M203 X18000 Y18000 Z800 E7200 U9000     ; Maximum axis speeds (mm/min)
;M203 X6000 Y6000 Z400 E4000 U1000     ; Max speeds while setting up
M566 X500 Y500 Z500 E300 U50           ; Maximum jerk speeds (mm/min)

; Endstops and probes 
;-------------------------------------------------------------------------------
; Connected to the MB6HC as the table below.
; | U | Z |
; | X |
; | Y |

M574 X1 S1 P"^io3.in"  ; homing position X1 = low-end, type S1 = switch
M574 Y1 S1 P"^io4.in"  ; homing position Y1 = low-end, type S1 = switch
M574 U1 S1 P"^io6.in"  ; homing position U1 = low-end, type S1 = switch


M574 Z0                ; we will use the switch as a Z probe not endstop 
M558 P8 C"io5.in" H15 F600:120 T6000 A5 S0.01 ; H = dive height F probe speed T travel speed
G31 K0 X0 Y0 Z-2    ; Set the limit switch position as the  "Control Point."
                    ; Note: the switch free (unclicked) position is 7.2mm,
                    ; but the operating position (clicked) is 6.4 +/- 0.2mm. 
                    ; A 1mm offset (i.e: 7.2-6.2 = 1mm) would be the 
                    ; Z to worst-case free position, but we add an extra 1mm
                    ; such that XY travel moves across the bed when z=0
                    ; do *not* scrape or shear the limit switch.

; Set axis software limits and min/max switch-triggering positions.
; Adjusted such that (0,0) lies at the lower left corner of a 300x300mm square 
; in the 305mmx305mm build plate.
M208 X-13.75:313.75 Y-44:341 Z0:295
M208 U0:200            ; Set Elastic Lock (U axis) max rotation angle

M557 X10:290 Y10:290 P7  ; Define Grid fir Hightmap


; Heaters and temperature sensors
;-------------------------------------------------------------------------------

; Bed
M308 S0 P"temp0" Y"thermistor" T100000 B3950 A"Bed" ; Keenovo thermistor
M950 H0 C"out0" T0                  ; H = Heater 0
;                                    ; C is output for heater itself
;                                    ; T = Temperature sensor
M143 H0 S120                        ; Set maximum temperature for bed to 130C    
M307 H0 A589.8 C589.8 D2.2 V24.1 B0 ; Keenovo 750w 230v built in thermistor
;                                    ; mandala rose bed
M140 H0                             ; Assign H0 to the bed

 ;Tools

M308 S1 P"10.temp0" Y"thermistor" T100000 B3950 A"Revo0"   ; configure sensor 1 as thermistor on pin 10.temp0
M950 H1 C"10.out0" T1                              ; create nozzle heater output on 10.out0 and map it to sensor 1
M307 H1 B0 S1.00                                    ; disable bang-bang mode for heater  and set PWM limit
M143 H1 S280                                        ; set temperature limit for heater 1 to 280C
;
M308 S2 P"20.temp0" Y"thermistor" T100000 B3950 A"Revo1"   ; configure sensor 1 as thermistor on pin 20.temp0
M950 H2 C"20.out0" T2                              ; create nozzle heater output on 20.out0 and map it to sensor 1
M307 H2 B0 S1.00                                    ; disable bang-bang mode for heater  and set PWM limit
M143 H2 S280                                        ; set temperature limit for heater 1 to 280C
;
M308 S3 P"30.temp0" Y"thermistor" T100000 B3950 A"Revo2"   ; configure sensor 1 as thermistor on pin 30.temp0
M950 H3 C"30.out0" T3                              ; create nozzle heater output on 30.out and map it to sensor 1
M307 H3 B0 S1.00                                    ; disable bang-bang mode for heater  and set PWM limit
M143 H3 S280                                        ; set temperature limit for heater 1 to 280C
;
M308 S4 P"40.temp0" Y"thermistor" T100000 B3950 A"Revo3"   ; configure sensor 1 as thermistor on pin 40.temp0
M950 H4 C"40.out0" T4                              ; create nozzle heater output on 40.out and map it to sensor 1
M307 H4 B0 S1.00                                    ; disable bang-bang mode for heater  and set PWM limit
M143 H4 S280                                        ; set temperature limit for heater 1 to 280C
; Tool 0 Fans
;-------------------------------------------------------------------------------
M950 F0 C"10.out2" Q100                            ; create fan 0 on pin 10.out2 and set its frequency
M106 P0 S0 H-1                                      ; set fan 0 value. Thermostatic control is turned off PART COOLING TOOL 0
M950 F1 C"10.out1" Q100                            ; create fan 1 on pin 10.out1 and set its frequency
M106 P1 L255 S255 H1 T45                            ; set fan 1 value. Thermostatic control is turned to hotend 45+ HEATSINK
;
M950 F2 C"20.out2" Q100                            ; create fan 0 on pin 20.out2 and set its frequency
M106 P2 S0 H-1                                      ; set fan 0 value. Thermostatic control is turned off PART COOLING TOOL 0
M950 F3 C"20.out1" Q100                            ; create fan 1 on pin 20.out1 and set its frequency
M106 P3 L255 S255 H2 T45                            ; set fan 1 value. Thermostatic control is turned to hotend 45+ HEATSINK
;
M950 F4 C"30.out2" Q100                            ; create fan 0 on pin 30.out2 and set its frequency
M106 P4 S0 H-1                                      ; set fan 0 value. Thermostatic control is turned off PART COOLING TOOL 0
M950 F5 C"30.out1" Q100                            ; create fan 1 on pin 30.out1 and set its frequency
M106 P5 L255 S255 H3 T45                            ; set fan 1 value. Thermostatic control is turned to hotend 45+ HEATSINK
;
M950 F6 C"40.out2" Q100                            ; create fan 0 on pin 40.out2 and set its frequency
M106 P6 S0 H-1                                      ; set fan 0 value. Thermostatic control is turned off PART COOLING TOOL 0
M950 F7 C"40.out1" Q100                            ; create fan 1 on pin 40.out1 and set its frequency
M106 P7 L255 S255 H4 T45                            ; set fan 1 value. Thermostatic control is turned to hotend 45+ HEATSINK
;
; Tool definitions
;-------------------------------------------------------------------------------
M563 P0 S"Tool0" D0 H1 F0  ; Px = Tool number
                            ; Dx = Drive Number
                            ; H1 = Heater Number
                            ; Fx = Fan number print cooling fan
G10  P0 S0 R150               ; Set tool 0 operating and standby temperatures
                            ; (-273 = "off")
M572 D0 S0.065              ; Set pressure advance
;
M563 P1 S"Tool1" D1 H2 F2
G10 P1 S0 R150
M572 D1 S0.065 
;
M563 P2 S"Tool2" D2 H3 F4
G10 P2 S0 R150
M572 D2 S0.065 
;
M563 P3 S"Tool3" D3 H4 F6
G10 P3 S0 R150
M572 D3 S0.065
 
M501                        ; Load saved parameters from non-volatile memory
