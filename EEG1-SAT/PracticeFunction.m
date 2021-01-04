function PracticeFunction(coherence_order, direction_order, x_centre, y_centre, window, white,ifi,window_rect,buttons,deg, File2,coherence)%, nr_trials,instr_order)
%changed nr _trials 
%Accuracy Instructions
Screen('TextFont',window,'Times');
Screen('TextSize',window, 20);
text='You will now be given some practice trials. \n\n Please look at the fixation cross in the middle of the screen \n\n and indicate the direction of the movement \n\n  using the right (=up) and left (=down) response buttons. ';
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait;%waits for user to press any key 
 
%coherence=[0.99 0.99];
total_score=0; %sets points to zero
accuracy_counter=0;
signal_duration=2;
practice_round=1;
nr_trials=100;
instr=0;

%% Trial Loop
for trial=1:nr_trials

    %take appropriate conditions from randomisation thingy earlier
    %see ConditionsOrder.mat
    lvl_coherence=coherence_order(trial);
    direction=direction_order(trial); %direcions randomly drawn. not part of initial randomisation

    fixation(window,white,x_centre,y_centre); %fixation cross function

    %loop input (see script)
    par2.lvl_coherence=lvl_coherence;
    par2.direction=direction;
    par2.coherence=coherence;%vector with all possible lvls of coherence
    par2.x_centre=x_centre;
    par2.y_centre=y_centre;
    par2.window=window;
    par2.white=white;
    par2.File2=File2;
    par2.vbl=vbl;
    par2.ifi=ifi;
    par2.trial=trial;
    par2.buttons=buttons;
    par2.deg=deg;
    par2.signal_duration=signal_duration;
    par2.instr=instr;
    par2.easy_hard_condition=[];
    par2=struct2cell(par2);

    [rt, accuracy]=TrialLoop(par2{:});
        
    %Delay
    Screen(window,'FillRect',0);
    cross=15; %length of arms
    %coords (relative to set centre)
    x_coords=[-cross, cross, 0, 0];
    y_coords=[0, 0, -cross, cross];
    coords=[x_coords; y_coords];
    %Draw Lines
    Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
    Screen('Flip', window);
    WaitSecs(0.3);
    
    % Give points
    feedback_colour=0;
    text_colour=white;
    text_size=30;
    if accuracy==1
        feedback='Correct';
    else
        feedback='Incorrect';
    end
    
    %Text setting
    Screen(window,'FillRect',feedback_colour);
    Screen('TextSize',window, text_size);
    Screen('TextFont',window,'Times');
    points_text=sprintf(' %s ' , feedback);
    DrawFormattedText(window,points_text,'center','center',text_colour);
    Screen('Flip',window);
    WaitSecs(0.7);
    %KbStrokeWait;%wait for kb input
    Screen(window,'FillRect',0);
    Screen('Flip',window);

    if accuracy==1
        accuracy_counter=accuracy_counter+1;
    else
        accuracy_counter=0;
    end
    
    if accuracy_counter==5 && practice_round==1
        signal_duration=1;
        accuracy_counter=0;
        practice_round=2;
    end
        
    if accuracy_counter==5 && practice_round==2;
        break
    end  
    
end
end