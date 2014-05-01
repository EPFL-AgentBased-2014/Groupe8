 ;;set mylist n-values 41 [? - 20]       ;creates list with result of calculation within brackets  ?takes every value from 0 to 41
;; ask patch-ahead 1 [ show pcolor ]
;; [pcolor] of patch-ahead 1
;; while [ white = [pcolor] of patch-adhead counter ] [ do something + set counter counter+1 ]
;; set mylist [10 20]
;; foreach mylist [
;;   ask patch ? 0 [ set pcolor white ]
;; ]
;; SAVE YOUR FILE

globals [
  frequencyWaitOver
  frequencyWait
  retardTotal
  conflicts
 
]

patches-own [
  isBlocked                    ;boolean true- only the current train can move over the patch
  terminus  
  depot           
]
turtles-own [
  waitingTime 
  canMove                      ;boolean- true, i can move
  disregardBlock               ;la métro qui a bloqué son tronçon peut quand même bouger
  counter 
  waitingTimeOver              ;;counts iterations of while loop
  turned
  goahead
  myspeed
  retard
  justcountedconflict
  
]

;;;;;;;;;;;;;;;;;;;;
;;Setup Procedures;;
;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-patches
  ask turtles [ set justcountedconflict 0]
  set frequencyWaitOver true
  set frequencyWait InjectionFrequency
  set retardTotal 0
  set conflicts 0
  reset-ticks
end  

;;PATCHES

to setup-patches                            ;Tracks - White
  foreach n-values 90 [? - 45] [            ;creates a loop for :-D
    ask patch ? -3[                         ; every patch at x positions within list is set white
      set pcolor white
      set isBlocked false
    ]
  ]
  foreach n-values 87 [? - 45] [            ;creates a loop for :-D
    ask patch ? 3[                          ;every patch at x positions within list is set white
      set pcolor white
      set isBlocked false
    ]
  ]
  
  
  foreach [44 33 15 5 -4 -27 -35 -45] [           ;list with x-positions of the stations
    ask patch ? -3 [
      set pcolor red
     ]
  ]
    foreach [-45 -33 -19 -6 3 17 30 41] [           ;list with x-positions of the stations
    ask patch ?  3 [
      set pcolor red
    ]
  ]
  ask patches [set terminus false]                 ;definir flon et Renens comme terminus- il tourne de 180degrées
  ask patch 41 3 [ set terminus true]
  ask patch 44 -3 [ set terminus true]
end

;;TURTLES
to setup-turtles
  set-default-shape turtles "train passenger car"
   create-turtles 1 [                   ;set x-coordinates of right heading metros in list
   set xcor -19
   set ycor 3
   set heading 90
   set color one-of base-colors ; random colored
   set size 2
   set disregardBlock false
   set turned false
   set WaitingTimeOver true
   set retard 0
]
  
  create-turtles 1 [
  set xcor -19
  set ycor 3
  set heading 270
  set color one-of base-colors 
  set size 2
  set disregardBlock false
  set turned false
  set WaitingTimeOver true
  set retard 0
 ]
end

;;;;;;;;;;;;;;;;;;;;;;
;;Runtime Procedures;;
;;;;;;;;;;;;;;;;;;;;;;

to go 
  create-metros
   ask turtles [
    jump-if-necessary
    turn-if-necessary
    wait-if-necessary
    move-if-you-can    
    measureRetard
    measureConflicts
   ]  
  tick
end

to create-metros
 if count turtles < NumberMetros and frequencyWaitOver = true 
   [
   setup-turtles 
   set frequencyWaitOver false 
 ]
   set frequencyWait frequencyWait - 1
    if frequencyWait = 0 [  
    set frequencyWaitOver true
    set frequencyWait InjectionFrequency
  ]
end

to jump-if-necessary
    ;; if you are on the extremities of the line
    if patch-here = patch -45 3 and heading = 270 [ jump-south ]
    if patch-here = patch -45 -3 and heading = 270 [ jump-north ]
end

to jump-south
    set xcor -45
    set ycor -3
    set heading heading - 180
end

to jump-north
   set xcor -45
   set ycor 3
   set heading heading + 180
end


to turn-if-necessary
  if [terminus] of patch-here and not turned
   [
    set heading heading - 180                     ;;Terminal Station- turn around
    set turned true
  ]
end


to wait-if-necessary                               ;;Attendre le nombre de ticks spécifiés
  if [pcolor] of patch-here = red [
    set waitingTime waitingTime + 1
    if waitingTime > waitingTimeAtStation [
      set waitingTimeOver true
  ]
]
end

to move-if-you-can
  
  set goahead true
    if [pcolor] of patch-here = red and not waitingTimeOver [ set goahead false ]     ; Si j'ai pas fini mon waiting time -> wait
    
    set canMove [not isBlocked] of patch-ahead 1                                      ;is it blocked ahead??   
    if not canMove and not disregardBlock [ set goahead false ]  ;if it is blocked and I cannot disregard the block -> wait.   ;;Injection frequency over??
  
  
  if goahead [
    block-section-if-necessary
    adjustmyspeed
    forward myspeed     ;avance de myspeed
    reset-variables
    adjustmyposition
    unblock-section-if-necessary
    set justcountedconflict 0
   ]
end

to block-section-if-necessary                                                      ;if I can move, block the rails I am on until the next station
  if [pcolor] of patch-here = red [
    set counter 1
    while [ white = [pcolor] of patch-ahead counter ][     
      ask patch-ahead counter [
        set isBlocked true
        set pcolor 88
      ]
      set counter counter + 1
    ]
    set disregardBlock true
  ]
end

to adjustmyspeed                                                                  ;in order to not sto twice on a station (if speed <1) set the speed to 1 if I am on a station
  ifelse [pcolor] of patch-here = red [                                           ;in the next step set it on speed again
    set myspeed 1
  ][
    set myspeed speed / 50
  ]
end

to reset-variables                                                               ;to be sure that he doesn't continue a started waiting time on a next stop
    set turned false
    set waitingTimeOver false
    set waitingTime 0
end

to adjustmyposition
  if [pcolor] of patch-here = red [
    set xcor [pxcor] of patch-here
  ]
end

to unblock-section-if-necessary                                                  ;unblock the section behind me so other metros can pass
  if [pcolor] of patch-here = red [                                      
      set counter 1
      
      while [ 88 = [pcolor] of patch-ahead (- counter) ] [
        ask patch-ahead (- counter) [
          set pcolor white
          set isBlocked false
        ]
        set counter counter + 1
      ]
      set disregardBlock false                           
      

    ]
end


to measureConflicts                                              ;if the maximal value of the list of how many turtles are on each station is bigger than 2 -> conflict
  if  count turtles-here > 2  and justcountedconflict = 0 [
    set conflicts conflicts + 1
   ask turtles-here [set justcountedconflict 1]
    set justcountedconflict 1
  ]
end


to measureRetard
  if waitingTimeOver = true and [isBlocked = true] of patch-ahead 1  and not disregardBlock [
    set retard retard + 1
  ]
 set retardTotal sum [retard] of turtles 
  
end
@#$#@#$#@
GRAPHICS-WINDOW
35
11
1228
211
45
6
13.0
1
10
1
1
1
0
1
1
1
-45
45
-6
6
1
1
1
ticks
30.0

BUTTON
39
251
102
284
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
114
251
177
284
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
188
251
251
284
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
25
394
197
427
NumberMetros
NumberMetros
2
16
16
2
1
NIL
HORIZONTAL

TEXTBOX
1185
131
1214
149
FLON
11
46.0
1

TEXTBOX
219
337
353
360
Scale: 1 Station = 50m 
11
0.0
1

SLIDER
28
353
203
386
waitingTimeAtStation
waitingTimeAtStation
30
180
30
5
1
s
HORIZONTAL

TEXTBOX
35
336
185
354
Time Metro waits at Station
11
0.0
1

TEXTBOX
1140
47
1215
65
RENENS
11
45.0
1

SLIDER
216
354
388
387
speed
speed
0
50
50
2
1
m/s
HORIZONTAL

TEXTBOX
1003
48
1153
66
EPENEX
11
45.0
1

TEXTBOX
833
51
983
69
CROCHY
11
45.0
1

TEXTBOX
649
52
799
70
CERISAIE
11
45.0
1

TEXTBOX
524
51
674
69
BASSENGES
11
45.0
1

TEXTBOX
377
44
527
72
EPFL\nDEPOT
11
26.0
1

TEXTBOX
1047
130
1197
148
VIGIE
11
45.0
1

TEXTBOX
804
132
954
150
MONTELLY
11
45.0
1

TEXTBOX
673
132
823
150
PROVENCE
11
45.0
1

TEXTBOX
561
132
711
150
MALLEY
11
45.0
1

TEXTBOX
247
133
397
151
BOURDONNETTE
11
45.0
1

TEXTBOX
143
132
293
150
UNIL DORIGNY
11
45.0
1

TEXTBOX
45
132
195
150
UNIL MOULINE
11
45.0
1

TEXTBOX
44
55
194
73
UNIL MOULINE
11
45.0
1

TEXTBOX
180
55
330
73
UNIL SORGE
11
45.0
1

PLOT
619
254
1204
492
Max Metros at each station
Time (s)
# Metros
0.0
1000.0
0.0
15.0
true
true
"" ""
PENS
"max Metros" 1.0 0 -16777216 true "" "plot max [count turtles-here] of patches with [pcolor = red]"
"2 Metros" 1.0 0 -10899396 true "" "plot 2"
"4 Metros" 1.0 0 -2674135 true "" "plot 4"
"6 Metros" 1.0 0 -5825686 true "" "plot 6"

TEXTBOX
221
392
371
420
Velocity Max. M1 = 17m/s ->  60km/h
11
0.0
1

TEXTBOX
216
320
366
338
1Tick = 1s
11
0.0
1

SLIDER
27
434
199
467
InjectionFrequency
InjectionFrequency
0
900
60
60
1
s
HORIZONTAL

MONITOR
385
228
608
273
Total delay of all Metros together (s)
retardTotal
17
1
11

MONITOR
384
281
442
326
NIL
conflicts
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

train passenger car
false
0
Polygon -7500403 true true 15 206 15 150 15 135 30 120 270 120 285 135 285 150 285 206 270 210 30 210
Circle -16777216 true false 240 195 30
Circle -16777216 true false 210 195 30
Circle -16777216 true false 60 195 30
Circle -16777216 true false 30 195 30
Rectangle -16777216 true false 30 140 268 165
Line -7500403 true 60 135 60 165
Line -7500403 true 60 135 60 165
Line -7500403 true 90 135 90 165
Line -7500403 true 120 135 120 165
Line -7500403 true 150 135 150 165
Line -7500403 true 180 135 180 165
Line -7500403 true 210 135 210 165
Line -7500403 true 240 135 240 165
Rectangle -16777216 true false 5 195 19 207
Rectangle -16777216 true false 281 195 295 207
Rectangle -13345367 true false 15 165 285 173
Rectangle -2674135 true false 15 180 285 188

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="8000"/>
    <metric>retardTotal</metric>
    <metric>conflicts</metric>
    <enumeratedValueSet variable="InjectionFrequency">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendre">
      <value value="40"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed" first="20" step="5" last="60"/>
    <enumeratedValueSet variable="NumberMetros">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
