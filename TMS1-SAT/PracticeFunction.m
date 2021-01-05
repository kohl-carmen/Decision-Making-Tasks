function PracticeFunction(coherence_order, direction_order, x_centre, y_centre, window, white,ifi,window_rect,buttons,deg, File2,coherence)
% Practice trials. Starts with 2000ms signal. If 5 correct, 1000ms. If 5
% correct, break.

%% Instruction Screen
Screen('TextFont',window,'Times');
Screen('TextSize',window, 20);
text='You will now be given some practice trials. \n\n Please look at the fixation cross in the middle of the screen \n\n and indicate the direction of the movement \n\n  using the pinch (=up) and grip (=down) responses. \n\n \n\n (Press any key to start the practice)';
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);
KbStrokeWait; 

%% Initialise
%coherence=[0.4 0.4];
total_score=0;
accuracy_counter=0;
signal_duration=2;
practice_round=1;
nr_trials=50;
instr=0;

%% Trial Loop
for trial=1:nr_trials

    signal_jitter=gamrnd(1,150)/1000;
    while signal_jitter > 1;
        signal_jitter=gamrnd(1,150)/1000;
    end%take appropriate conditions from randomisation thingy earlier
    lvl_coherence=coherence_order(trial);
    direction=direction_order(trial); %direcions randomly drawn. not part of initial randomisation

    fixation(window,white,x_centre,y_centre); 

    %loop input (see script)
    par2.file_time=File2;
    par2.signal_jitter=signal_jitter;
    par2.lvl_coherence=lvl_coherence;
    par2.direction=direction;
    par2.coherence=coherence;%vector with all possible lvls of coherence
    par2.x_centre=x_centre;
    par2.y_centre=y_centre;
    par2.window=window;
    par2.white=white;
    par2.file=File2;
    par2.vbl=vbl;
    par2.ifi=ifi;
    par2.trial=trial;
    par2.buttons=buttons;
    par2.deg=deg;
    par2.signal_duration=signal_duration;
    par2.instr=instr;
    par2.stim_time=[];
    par2.easy_hard_condition=[];
    par2=struct2cell(par2);

    [rt, accuracy]=TrialLoop(par2{:});
    
    %% Feedback
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
    Screen(window,'FillRect',0);
    Screen('Flip',window);

    %% Terminate Practice
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