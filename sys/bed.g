if state.currentTool!=-1   ; Never Run this if there is an active tool!
    abort "Active tool!!!"

M290 R0 S0                 ; Reset baby stepping
M561                       ; Disable any Mesh Bed Compensation
M400

if !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed
    echo "not all axes homed, homing axes first"
    G28

G30 P0 X295 Y295 Z-99999   ; probe near front left leadscrew
G30 P1 X152.5 Y5 Z-99999   ; probe near back leadscrew
G30 P2 X5 Y295 Z-99999 S3  ; probe near front right leadscrew and calibrate 3 motors
echo "Current rough pass deviation: " ^ move.calibration.initial.deviation

M558 H7 F120
while move.calibration.initial.deviation > 0.005
    if iterations >= 5
        echo "Error: Max attemps failed. Deviation: " ^ move.calibration.initial.deviation
        break
    echo "Deviation over threshold. Executing pass" , iterations+1, "deviation", move.calibration.initial.deviation
    G30 P0 X295 Y295 Z-99999   ; probe near front left leadscrew
    G30 P1 X152.5 Y5 Z-99999   ; probe near back leadscrew
    G30 P2 X5 Y295 Z-99999 S3  ; probe near front right leadscrew and calibrate 3 motors
    echo "Current deviation: " ^ move.calibration.initial.deviation
    continue

echo "Final deviation: " ^ move.calibration.initial.deviation
G1 X150 Y130 Z15 F18000

G28 Z   

