[org 0x100]
jmp start

clrScreen:        ;clear the screen
push ax
push es
push di

mov ax,0xb800
mov es,ax
mov di,0

cls:
mov word[es: di],0x0720
add di,2
cmp di,4000
jne cls

pop di
pop es
pop ax
ret

open_file:
push bp       
mov bp,sp
push es           ;save the registers
push ax
push bx
push dx
push di
push si

mov ax,0xb800
mov es,ax

open_file_name:
mov di,0                 ;basic file enter display
mov si,input_file_name
mov ah,0x07

o_file:
mov al,[si]
mov [es:di],ax
inc si
add di,2
cmp al,0
jne o_file

enter_name:       ;basic enter file name display to user
mov di,160        
mov si,file_name

e_name:
mov al,[si]
mov [es:di],ax
inc si
add di,2
cmp al,0
jne e_name

mov bh,0      ;page 0
mov dh,1      ;ypos of cursor
mov dl,10     ;xpos of cursor
mov ah,2
int 0x10

mov ch,3      ;set cursor shape
mov cl,4
mov ah,1
int 0x10

mov dx,input_buffer       ;input filename from user
mov ah,0x0A
int 0x21

opening:
mov ah,0x07          ;basic file opening display
mov di,320
mov si,opening_file

o1:
mov al,[si]
mov [es:di],ax
inc si
add di,2
cmp al,0
jne o1

mov bx,input_buffer      ;load address of filename input buffer in bx
add bx,1                 ;move to next byte in buffer containing input size
mov di,0
mov cx,[bx]              ;size of entered file name
mov ch,0                 ;clear upper cx byte
add bx,1                 ;point bx to filename starting in buffer
mov si,bx
cmp byte[si],13          ;if filename starting contains CR(ascii 13) means user pressed enter so load default file
je open_default_file      
mov bx,cx                 
mov byte[input_buffer + bx + 2],0    ;putting 0 in filename input buffer in place of CR to make it 0 terminated
inc cx
mov bx,0

loop_copy_name:
mov al,[si]
mov [entered_file_name + bx],al       ;copying filename input buffer to entered_file_name array
inc si
inc bx
loop loop_copy_name

mov dx,entered_file_name              ;loading address of entered_file_name array to dx
mov ah,3Dh                            ;interrupt to open file
int 0x21                 
jc error_open                         ;if carry generates then throw an error message
jnc opened                            ;if not carry means file opened successfully

open_default_file:
mov dx,fname                           ;in case user presses enter then load default filename(cave1.txt) to dx
mov ah,3Dh
int 0x21
jc error_open
jnc opened

error_open:
mov di,480                          ;if error occurs in opening file then display error message to user
mov si,error_opening           
mov ah,0x07
loop_error:
mov al,[si]                         ;basic display of error message
mov [es:di],ax
add di,2
inc si
cmp al,0
jne loop_error

program_quit:
mov di,640                        ;basic display of quitting program if error occurs in opening file
mov si,quit_program
loop_quit:
mov al,[si]
mov [es:di],ax
add di,2
inc si
cmp al,0
jne loop_quit
jmp return

opened:                   ;if file opened successfully
mov bx,ax                 ;load file handle in bx
mov di,480                ;basic open file success message to user
mov si,opened_successfully
mov ah,0x07
file_opened:
mov al,[si]
mov [es:di],ax
add di,2
inc si
cmp al,0
jne file_opened 
push bx                 ;push file handle to read_file subroutine to read file
call read_file

return:
pop si              ;release the registers
pop di
pop dx
pop bx
pop ax
pop es
pop bp
ret 

read_file:
push bp
mov bp,sp
push es           ;save the registers
push ax
push dx
push bx
push cx
push di
push si

mov dx,layout    ;loading buffer(layout) to dx to read file in it
mov al,0
mov cx,1600      ;number of bytes to read from file
mov bx,[bp+4]    ;load file handle in bx
mov ah,3Fh       ;interrupt to read file
int 0x21
cmp ax,cx        
jne error_reading   ;if ax not equals cx means some error occured in reading the whole file
je end_of_file      ;if both equals then successfuly read the file

error_reading:
mov di,480             ;if error occurs in reading file show an error message to user
mov si,error_read
mov ah,0x07
loop_error_reading:              
mov al,[si]            ;basic reading error message to user
mov [es:di],ax
add di,2
inc si
cmp al,0
jne loop_error_reading

program_close:                 ;if error occurs in reading throw and error message to user
mov di,640
mov si,quit_program
loop_quit_program:
mov al,[si]
mov [es:di],ax
add di,2
inc si
cmp al,0
jne loop_quit_program
jmp exit                      ;and exit the program

end_of_file:                  ;if file read successfully 
mov bx,[bp+4]                 ;load file handle in bx
mov ah,3Eh                    ;interrupt to close file
int 0x21 
jc error_reading              ;if carry generates then show an error(caused in closing file)

mov al,0
mov ch,25              ;hide the cursor (starting line 25)
mov ah,1               ;interrupt to adjust cursor location
int 0x10

call display           ;display the layout
call clrScreen

exit:
pop si                 ;release the registers
pop di
pop cx
pop bx
pop dx
pop ax
pop es
pop bp
ret 2                  ;release the parameter

display:               ;display the game layout 
push bp
mov bp,sp
push ax                ;save the registers
push es
push di
push si
push cx
push dx

mov ax,0xb800
mov es,ax

mov si,load_game
mov ah,0x07
mov di,640

disp_loadgame:        ;basic press any key to load the game display
mov al,[si]
mov [es:di],ax
inc si
add di,2
cmp al,0
jne disp_loadgame

mov bh,0      ;page 0
mov dh,4      ;ypos of cursor
mov dl,34     ;xpos of cursor
mov ah,2
int 0x10

mov ch,3      ;set cursor shape
mov cl,4
mov ah,1
int 0x10

mov ah,0
int 0x16
call clrScreen

mov dh,25      ;remove the cursor
mov ah,2
int 0x10

display_info:        ;basic game name display at the top
mov di,50
mov ah,0x07
mov si,game_name

disp_info:
mov al,[si]
mov [es:di],ax
add di,2
inc si
cmp al,0
jne disp_info

mov di,162
mov si,keys

disp_keys:
mov al,[si]
mov [es:di],ax
add di,2
inc si
cmp al,0
jne disp_keys

mov di,300
mov si,quit

disp_quit:          ;basic press esc to quit the game display
mov al,[si]
mov [es:di],ax
add di,2
inc si
cmp al,0
jne disp_quit

mov di,3842
mov si,score

disp_score:         ;basic score of the game display at left bottom
mov al,[si]
mov [es:di],ax
add di,2
inc si
cmp al,0
jne disp_score

mov al,[SCORE]
mov [es:di],ax

mov di,3982
mov si,level

disp_level:         ;basic score of the game display at right bottom
mov al,[si]
mov [es:di],ax
add di,2
inc si
cmp al,0
jne disp_level

mov al,[LEVEL]
mov [es:di],ax

mov dx,0
mov si,layout
mov di,482
mov cx,1600
mov ah,0x15
mov al,[si]
jmp check

disp:                  ;display the layout
mov word[es: di],ax    
add dx,1               ;count of the bytes read
add di,2
inc si
jmp check              ;check for the layout 

check:                 ;detect the layout
mov al,[si]            ;load layout buffer in al
cmp al,'x'             ;check for dirt
je disp_dirt
cmp al,'B'             ;check for boulder
je disp_boulder
cmp al,'D'             ;check for diamond
je disp_diamond
cmp al,'R'             ;check for rockford
je disp_rockford
cmp al,'W'             ;check for wall
je disp_wall
cmp al,'T'             ;check for target
je disp_target         
cmp cx,dx              ;check if all 1600 bytes read
je display_walls       ;if yes then display the outer walls
cmp al,13
je disp_crlf
cmp al,10
je disp_crlf
mov ah,0xF
jne disp

disp_crlf:
mov ax,0x07B1
jmp disp

disp_dirt:
mov ax,0x07B1        ;load light gray color and dirt ascii in ax
jmp disp

disp_wall:           
mov ax,0x0EDB        ;load yellow color and wall ascii in ax
jmp disp

disp_boulder:            
mov ax,0x0409        ;load red color and boulder ascii in ax
jmp disp

disp_diamond:
mov ax,0x0304        ;load cyan color and diamond ascii in ax
jmp disp

disp_rockford:
mov ax,0x0F02        ;load white color and rockford ascii in ax
jmp disp

disp_target:
mov ax,0x037F        ;load cyan color and target ascii in ax
jmp disp

display_walls:      ;display the outer walls
mov di,320          ;starting from third row
mov cx,79           ;counter for upper columns
mov ax,0x0EDB       ;yellow color and wall ascii in ax

h_walls:            ;upper outer walls of layout
mov [es:di],ax       
add di,2            ;increment for upper columns
loop h_walls

mov cx,21           ;counter for left rows

v_walls:            ;left outer walls of layout
mov [es:di],ax
add di,160          ;increment for left rows
loop v_walls

mov cx,79          ;counter for bottom columns 

h_walls2:          ;display the bottom outer layout walls
mov [es:di],ax
sub di,2           ;decrement for bottom columns
loop h_walls2

mov cx,21          ;counter for right rows

v_walls2:          ;display the left outer layout walls
mov [es:di],ax 
sub di,160         ;decrement for right rows
loop v_walls2

call Play_Game

end_disp:
pop dx
pop cx
pop si
pop di
pop es
pop ax
pop bp
ret

Play_Game:
push bp
mov bp,sp
push es
push ax
push bx
push cx
push dx
push si
push di

mov ax,0xb800
mov es,ax
mov di,0

Detect_Rockford:
add di,2
cmp word[es:di],0x0F02
jne Detect_Rockford
 
mov dx,di                 ;loc of rockford in dx
mov bx,dx

Check_Move:
mov dx,bx
mov ah,0
int 16h
cmp ah,72                 ;check for up
je UP                     
cmp ah,80                 ;check for down
je DOWN                   
cmp ah,75                 ;check for left
je LEFT                   
cmp ah,77                 ;check for right
je RIGHT                  
cmp ah,1                  ;check for esc
je exitt                  
jmp Check_Move            ;for anyother key

UP:                       ;for moving up
sub bx,160                ;move to upper row
push bx                   
call Check_Wall           ;check if there is wall above
jc wall1                  ;if carry then wall exists
jnc check_diamond1        ;if not then check if there is a diamond above
					      
wall1:                    
call Beep                 ;if there is a wall then bell will produce
clc                       
add bx,160                ;no need to move above
jmp Check_Move            
					      
check_diamond1:           
push bx                   
call Check_Diamond        ;check for diamond
jc diamond1               ;if carry means theres a diamond above
jnc check_target1         ;if not check for target
						  
diamond1:                 
push dx                   
push bx                   
add byte[SCORE],1         ;if there is a diamond then score will increment
mov ax,[SCORE]            
push ax                   
call print_score          ;shows incremented score on screen
clc                       ;clear the carry
jmp Check_Move

check_target1:
push bx                
call Check_Target         ;check for target
jc target1                ;if carry means there's target above
jnc check_boulder1        ;if not check for boulder
					     
target1:                 
push dx                   ;push rockford current location
push bx                   ;push rockford loc after moving above
call Won_Game             ;display level complete and ends game
clc                       ;clear the carry 
jmp game_end              ;game ends

check_boulder1:
sub bx,160           
push bx                   ;push the location above to rockford loc after moving above
Call Check_Boulder        ;check for boulder above
jc boulder1               ;if carry then there's boulder above 
add bx,160                ;retain the above moving location of rockford
jmp up_move               ;move up
					    
boulder1:
push dx
push bx
call Lost_Game            ;display game over 
mov di,dx                 ;prev lov of rockford in di
mov word[es:di],0x0020    ;leave blank rockford prev location
sub di,160                ;current loc of rockford in di
mov word[es:di],0xE302    ;blinking rockford
mov di,bx                 ;boulder loc in di
mov word[es:di],0xF409    ;blinking boulder
clc                       ;clear the carry
jmp game_end              ;game ends

up_move:
push dx
call move_Up             ;moves the rockford above
jmp Check_Move

DOWN:                    ;for moving down
add bx,160               ;move to lower row
push bx                  
call Check_Wall          ;check if there is wall down
jc wall2                 ;if carry then wall exists
jnc check_diamond2       ;if not then check if there is a diamond down

wall2:
call Beep                ;if there is a wall then bell will produce
clc
sub bx,160               ;no need to move down
jmp Check_Move           
                         
check_diamond2:          
push bx                  
call Check_Diamond       ;check for diamond
jc diamond2              ;if carry means theres a diamond down
jnc check_target2        ;if not check for target
                         
diamond2:                
push dx                  
push bx                  
add byte[SCORE],1        ;if there is a diamond then score will increment
mov ax,[SCORE]           
push ax                  
call print_score         ;shows incremented score on screen
clc                      ;clear the carry
jmp Check_Move           
                         
check_target2:           
push bx                  
call Check_Target         ;check for target
jc target2                ;if carry means there's target down
jnc check_boulder2        ;if not check for boulder
                          
target2:                  
push dx                   ;push rockford current location
push bx                   ;push rockford loc after moving down
call Won_Game             ;display level complete and ends game
clc                       ;clear the carry 
jmp  game_end             ;game ends
                          
check_boulder2:           
push bx                   ;push the location down to rockford loc 
call Check_Boulder        ;check for boulder down
jc boulder2               ;if carry then there's boulder down
jmp down_move             ;move up

boulder2:                 
call Beep                 ;produce bell sound
clc                       ;clear the carry
sub bx,160                ;no need to move downward
jmp Check_Move            
                          
down_move:                
push dx                   
call move_Down            ;move down the rockford
jmp Check_Move            
                          
LEFT:                     ;for moving left
sub bx,2                  ;move left location
push bx                   
call Check_Wall           ;check if there is wall on left
jc wall                   ;if carry then wall exists
jnc check_diamond3        ;if not then check if there is a diamond on left
                          
wall:                     
call Beep                 ;if there is a wall then bell will produce
clc                       
add bx,2                  ;no need to move left
jmp Check_Move            
                          
check_diamond3:               
push bx                   
call Check_Diamond        ;check for diamond
jc diamond3               ;if carry means theres a diamond on left
jnc check_target3         ;if not check for target
                          
diamond3:                 
push dx                   
push bx                   
add byte[SCORE],1         ;if there is a diamond then score will increment
mov ax,[SCORE]            
push ax                   
call print_score          ;shows incremented score on screen
clc                       ;clear the carry
jmp Check_Move            
                          
check_target3:            
push bx                   
call Check_Target         ;check for target
jc target3                ;if carry means there's target on left
jnc check_boulder3        ;if not check for boulder           
                          
target3:                  
push dx                   ;push rockford current location
push bx                   ;push rockford loc after moving left
call Won_Game             ;display level complete and ends game
clc                       ;clear the carry 
jmp  game_end             ;game ends
                          
check_boulder3:           
push bx                   ;push the location left to rockford 
call Check_Boulder        ;check for boulder above
jc boulder3               ;if carry then there's boulder on left
sub bx,160                ;above location of rockford after  moving left
push bx                   
call Check_Boulder        ;check if there's a boulder above after moving rockford left
jc boulder_above1         ;if carry then there's a boulder above
add bx,160                ;if not then retains bx the location of left to rockford
jmp left_move             ;and move left the rockford
                          
boulder3:                 
call Beep                 ;if there's a boulder on left bell sound produces
clc                       ;clear the carry
add bx,2                  ;no need to move left,retains the loc of rockford
jmp Check_Move            
                          
boulder_above1:           
push dx                   ;original loc of rockford before moving left
push bx                   ;boulder loc in bx which is above rockford after moving left
call Lost_Game            ;display game over 
mov di,dx                 ;prev lov of rockford in di
mov word[es:di],0x0020    ;leave blank rockford prev location 
sub di,2                  ;current loc of rockford after moving left in di
mov word[es:di],0xE302    ;blinking rockford
mov di,bx                 ;boulder loc in di
mov word[es:di],0xF409    ;blinking boulder
clc                       ;clear the carry
add bx,160                ;retains the left loc of rockford
jmp game_end              ;game ends

left_move:
push dx
call move_Left            ;moves the rockford left
jmp Check_Move

RIGHT:                    ;for moving right
add bx,2                  ;move lright location
push bx                   
call Check_Wall           ;check if there is wall on right
jc wall4                  ;if carry then wall exists
jnc check_diamond4        ;if not then check if there is a diamond on right
                          
wall4:                    
call Beep                 ;if there is a wall then bell will produce 
clc                       
sub bx,2                  ;no need to move right
jmp Check_Move            
                          
check_diamond4:               
push bx                   
call Check_Diamond        ;check for diamond
jc diamond4               ;if carry means theres a diamond on left
jnc check_target4         ;if not check for target
                          
diamond4:                 
push dx                   
push bx                   
add byte[SCORE],1         ;if there is a diamond then score will increment
mov ax,[SCORE]            
push ax                   
call print_score          ;shows incremented score on screen
clc                       ;clear the carry
jmp Check_Move            
                          
check_target4:            
push bx                   ;load right loc of rockford
call Check_Target         ;check for target
jc target4                ;if carry means there's target on right
jnc check_boulder4        ;if not check for boulder                   
                          
target4:                  
push dx                   ;push rockford current location
push bx                   ;push rockford loc after moving right
call Won_Game             ;display level complete and ends game
clc                       ;clear the carry 
jmp  game_end             ;game ends
                          
check_boulder4:           
push bx                   ;push the location right to rockford 
call Check_Boulder        ;check for boulder above
jc boulder4               ;if carry then there's boulder on right
sub bx,160                ;above location of rockford after  moving right
push bx                  
call Check_Boulder        ;check if there's a boulder above after moving rockford right
jc boulder_above2         ;if carry then there's a boulder above
add bx,160                ;if not then retains bx the location of right to rockford
jmp right_move            ;and move right the rockford 
                          
boulder4:                 
call Beep                 ;if there's a boulder on left bell sound produces
clc                       ;clear the carry
sub bx,2                  ;no need to move right,retains the loc of rockford
jmp Check_Move            
                          
boulder_above2:           
push dx                   ;original loc of rockford before moving right
push bx                   ;boulder loc in bx which is above rockford after moving right
call Lost_Game            ;display game over 
mov di,dx                 ;prev lov of rockford in di
mov word[es:di],0x0020    ;leave blank rockford prev location 
add di,2                  ;current loc of rockford after moving right in di
mov word[es:di],0xE302    ;blinking rockford
mov di,bx                 ;boulder loc in di
mov word[es:di],0xF409    ;blinking boulder
clc                       ;clear the carry
jmp game_end              ;game ends
                         
right_move:              
push dx                  
call move_Right           ;moves the rockford right
jmp Check_Move

game_end:
mov ah,0
int 0x16                  ;keyboard input interrupt
cmp ah,1                  ;if press esc then game exits
jne game_end

exitt:
pop di
pop si
pop dx
pop cx
pop bx
pop ax
pop es
pop bp 
ret

move_Up:
push bp 
mov bp,sp          
push es                         ;save the registers
push ax                         
push di                         
					            
mov ax,0xb800                   
mov es,ax                       
mov di,[bp+4]                   ;rockford loc in di

mov word[es:di],0x0020          ;leave blank on rockford location
sub di,160                      ;move rockford above
mov word[es:di],0x0F02          ;display rockford above

pop di                          ;release the registers
pop ax
pop es
pop bp
ret 2                           ;release parameter

move_Down:
push bp 
mov bp,sp
push es                         ;save the registers
push ax                         
push di                         
                                
mov ax,0xb800                   
mov es,ax                       
mov di,[bp+4]                   ;rockford loc in di
                                
mov word[es:di],0x0020          ;leave blank on rockford location
add di,160                      ;move rockford down
mov word[es:di],0x0F02          ;display rockford down
                                
pop di                          ;release the registers
pop ax                          
pop es                          
pop bp                          
ret 2                           ;release parameter

move_Left:
push bp 
mov bp,sp
push es                         ;save the registers
push ax                         
push di                         
                                
mov ax,0xb800                   
mov es,ax                       
mov di,[bp+4]                   ;rockford loc in di
                                
mov word[es:di],0x0020          ;leave blank on rockford location
sub di,2                        ;move rockford left
mov word[es:di],0x0F02          ;display rockford left
                                
pop di                          ;release the registers
pop ax                          
pop es                          
pop bp                          
ret 2                           ;release parameter

move_Right:
push bp 
mov bp,sp
push es                         ;save the registers
push ax                         
push di                         
                                
mov ax,0xb800                   
mov es,ax                       
mov di,[bp+4]                   ;rockford loc in di
                                
mov word[es:di],0x0020          ;leave blank on rockford location
add di,2                        ;move rockford right
mov word[es:di],0x0F02          ;display rockford right
                                
pop di                          ;release the registers
pop ax                          
pop es                          
pop bp                          
ret 2                           ;release parameter

Check_Wall:                     ;check for wall
push bp 
mov bp,sp
push es                         ;save the registers
push ax
push di

mov ax,0xb800
mov es,ax
mov di,[bp+4]                  ;check wall loc in di

cmp word[es:di],0x0EDB         ;cmp loc with wall
je set_carry                   ;if equals then generates carry
jne clear_carry                ;if not then clear carry

set_carry:
stc                            ;set carry
jmp exit_check_wall

clear_carry:
clc                            ;clear carry
jmp exit_check_wall

exit_check_wall:
pop di                         ;release registers
pop ax
pop es
pop bp
ret 2                          ;release parameter

Check_Diamond:                 ;check for diamond
push bp                       
mov bp,sp                     
push es                        ;save the registers
push ax                       
push di                       
                              
mov ax,0xb800                 
mov es,ax                     
mov di,[bp+4]                 ;check diamond loc in di 
                              
cmp word[es:di],0x0304        ;cmp loc with diamond
je st_carry                   ;if equals then generates carry
jne cl_carry                  ;if not then clear carry
                              
st_carry:                     
stc                           ;set carry
jmp exit_check_diamond        
                              
cl_carry:                     
clc                           ;clear carry
jmp exit_check_diamond        
                              
exit_check_diamond:           
pop di                        ;release registers
pop ax                        
pop es                        
pop bp                        
ret 2                         ;release parameter

Check_Target:                 ;check for target
push bp                      
mov bp,sp                    
push es                       ;save the registers
push ax                      
push di                      
                             
mov ax,0xb800                
mov es,ax                    
mov di,[bp+4]                 ;check target loc in di
                              
cmp word[es:di],0x037F        ;cmp loc with target
je st_carry                   ;if equals then generates carry
jne cl_carry                  ;if not then clear carry
                              
stt_carry:                    
stc                           ;set carry
jmp exit_check_target         
                              
clr_carry:                    
clc                           ;clear carry
jmp exit_check_target         
                              
exit_check_target:            
pop di                        ;release registers
pop ax                        
pop es                        
pop bp                        
ret 2                         ;release parameter

Check_Boulder:                ;check for boulder
push bp                       
mov bp,sp                     
push es                       ;save the registers
push ax                       
push di                       
                              
mov ax,0xb800                 
mov es,ax                     
mov di,[bp+4]                 ;check boulder loc in di
                              
cmp word[es:di],0x0409        ;cmp loc with boulder
je sett_carry                 ;if equals then generates carry
jne clrr_carry                ;if not then clear carry
                              
sett_carry:                   
stc                           ;set carry
jmp exit_check_boulder        
                              
clrr_carry:                   
clc                           ;clear carry
jmp exit_check_boulder        
                              
exit_check_boulder:           
pop di                        ;release registers
pop ax                        
pop es                        
pop bp                        
ret 2                         ;release parameter

Beep:
push bp
mov bp,sp
push dx            ;save the registers
push ax
push bx

mov bh,0           ;resetting the cursor
mov dh,1
mov dl,0
mov ah,2
int 0x10

mov al,0
mov ch,25         ;hide the cursor (starting line 25)
mov ah,1
int 0x10

mov dl,7          ;bell character in dl
mov ah,2
int 0x21          ;produces bell sound by printing it

pop bx            ;release the registers
pop ax
pop dx
pop bp
ret

Won_Game:
push bp
mov bp,sp
push es                      ;save the registers
push ax                      
push di                      
push si                      
                             
mov ax,0xb800                
mov es,ax                    
mov di,160                   
mov ah,0x07                  
mov si,level_complete        
                             
w_game:                      ;simple level complete display
add di,2                     
mov al,[si]                  
mov [es:di],ax               
inc si                       
cmp al,0                     
jne w_game                   
add di,2                     
mov [es:di],ax               
                             
mov di,[bp+6]                ;rockford loc in di
mov word[es:di],0x0020       ;leave a blank at rockford loc
mov di,[bp+4]                ;target loc in di
mov word[es:di],0xE302       ;blinking rockford
                             
pop si                       ;release the registers
pop di                       
pop ax                       
pop es                       
pop bp                       
ret 4                        ;release parameters

Lost_Game:
push bp
mov bp,sp
push es                ;save the registers
push ax
push di
push si

mov ax,0xb800
mov es,ax
mov di,160
mov ah,0x07
mov si,game_over

l_game:                ;simple game over display
add di,2
mov al,[si]
mov [es:di],ax
inc si
cmp al,0
jne l_game
add di,2
mov [es:di],ax

pop si                 ;release the registers
pop di
pop ax
pop es
pop bp
ret 4                  ;release parameters

print_score: 
push bp
mov bp, sp
push es                  ;save the registers
push ax
push bx
push cx
push dx
push di

mov ax,0xb800
mov es,ax               ;point es to video base
mov ax,[bp+4]           ;load number in ax
mov bx,10               ;use base 10 for division
mov cx,0                ;initialize count of digits

nextdigit: 
mov dx,0                ;zero upper half of dividend
div bx                  ;divide by 10
add dl,0x30             ;convert digit into ascii value
push dx                 ;save ascii value on stack
inc cx                  ;increment count of values
cmp ax,0                ;is the quotient zero
jnz nextdigit           ;if no divide it again
mov di,3856

nextpos:
pop dx                  ;remove a digit from the stack
mov dh,0x07             ;use normal attribute
mov [es:di],dx          ;print char on screen
add di,2                ;move to next screen location
loop nextpos            ;repeat for all digits on stack

mov dx,[bp+6]           ;diamond loc in dx
mov di,dx
mov ax,0x0F02           
mov [es:di],ax          ;move rockford at diamond location

mov di,[bp+8]           ;rockford loc in di
mov ax,0x0020
mov [es:di],ax          ;leave a blank at rockford location

pop di                  ;release the registers
pop dx
pop cx
pop bx
pop ax
pop es
pop bp
ret 6                   ;release parameters

start:
call clrScreen
call open_file

mov bh,0                ;resetting the cursor
mov dh,5
mov dl,0
mov ah,2
int 0x10

terminate:
mov ax,0x4c00
int 0x21

fname: dw 'cave1.txt',0
input_file_name: dw 'Enter the cave file name or press Enter to use the default (cave1.txt)',0
file_name: dw 'File name:',0
opening_file: dw 'Opening file now...',0
error_opening: dw 'ERROR: Could not open input file',0
quit_program: dw 'Program will now quit',0
opened_successfully: dw 'Done.',0
load_game: dw 'Press any key to load the game....',0
layout: times 1600 db 0  
error_read: dw 'ERROR: Incomplete data in file',0
game_name: dw 'Boulder Dash * HA EDITION',0
keys: dw 'Arrow keys: move',0
quit: dw 'Esc: quit',0
score: dw 'Score: 0',0
SCORE: dw 0
level: dw 'Level:',0
LEVEL: dw 49
input_buffer: db 30
              db 0
              times 30 db 0
entered_file_name: times 30 db 0
level_complete: dw 'Level Complete',0
game_over: dw 'Game Over !!!!',0