; For an 18M2
input C.1
input C.0
input C.7
input C.6
input B.7

output B.2
output B.3
output B.4
   
Symbol Photocell  = C.1
Symbol FanPot     = C.0
Symbol UseSensors = pinC.7
Symbol LEDEnabled = pinC.6
Symbol FanEnabled = pinB.7
Symbol FanMOSFET  = B.2
Symbol FanPWM     = B.3
Symbol LEDMOSFET  = B.4

Symbol LidOpen     = 0
Symbol LidClosed   = 1
Symbol PWMPeriod   = 39 ; 25KHz
Symbol PWMPeriodX4 = PWMPeriod * 4
Symbol LightCutoff = 40 ; 100 and even 60 is too high, at night fan stays on unless the bar light is on 
Symbol PWMTurnOff  = 20 ; Doesn't turn off at 30

Symbol PWMCycles  = w0 ;b0,b1
Symbol LidState   = b2 ;w1
Symbol LightLevel = b3 ;w1
Symbol FanSpeed   = b4 ;w2
Symbol Prev       = b5 ;w2
Symbol Lights     = b6 ;w3
Symbol Fan        = b7 ;w3
Symbol SumTemp    = w4 ;b8,b9

main:
  setfreq m4 ; Set the internal resonator to 4 MHz
  goto main_loop

main_loop:
  if UseSensors = 1 then gosub check_lid
  let Prev = Lights
  gosub get_light_state
  if Lights <> Prev then
    if Lights = 1 then
      gosub enable_lights
    else
      gosub disable_lights
    endif
  endif
  let Prev = Fan
  gosub get_fan_state
  if Fan <> Prev then
    if Fan = 1 then
      gosub enable_fan
    else
      gosub disable_fan
    endif
  endif
  if Fan = 1 then 
    gosub fan_pwm
    pause 1
  else
    pause 50
  endif
  goto main_loop

check_lid:
  readadc Photocell, LightLevel
  sertxd ("\nLight ", #LightLevel, " ", #LightCutoff)
  if LightLevel > LightCutoff then
    let LidState = LidOpen
  else
    let LidState = LidClosed
  endif
  return

get_light_state:
  if UseSensors = 1 then
    if LidState = LidOpen then
      ;sertxd("\nLights on (sensor)")
      let Lights = 1
    else
      ;sertxd("\nLights off (sensor)")
      let Lights = 0
    endif
  else
    if LEDEnabled = 1 then
      ;sertxd("\nLights on (no sensor)")
      let Lights = 1
    else 
      ;sertxd("\nLights off (no sensor)")
      let Lights = 0
    endif
  endif
  return

get_fan_state:
  if UseSensors = 1 then
    if LidState = LidClosed then
      ;sertxd("\nFan on (sensor)")
      let Fan = 1
    else
      ;sertxd("\nFan off (sensor)")
      let Fan = 0
    endif
  else
    if FanEnabled = 1 then
      ;sertxd("\nFan on (no sensor)")
      let Fan = 1
    else 
      ;sertxd("\nFan off (no sensor)")
      let Fan = 0
    endif
  endif
  return   

enable_lights:
  high LEDMOSFET
  return

disable_lights:
  low LEDMOSFET
  return

enable_fan:
  high FanMOSFET
  pwmout FanPWM, PWMPeriod, 0
  return
  
disable_fan:
  low FanMOSFET
  pwmout FanPWM, off
  return
  
fan_pwm:
  readadc FanPot, FanSpeed
  let SumTemp = 255 - FanSpeed
  let PWMCycles = SumTemp * PWMTurnOff
  let SumTemp = FanSpeed * PWMPeriodX4 ; Upper bits, equiv to FS*PWMPX4/255
  let PWMCycles = PWMCycles + SumTemp
  let PWMCycles = PWMCycles / 255
  sertxd (" Pot ", #FanSpeed, " ", #PWMCycles)
  pwmduty FanPWM, PWMCycles
  return
  
