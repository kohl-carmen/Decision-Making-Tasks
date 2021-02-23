function total_reward=AccuracyFunction(coherence_order, direction_order, x_centre, y_centre, window, white,ifi,window_rect,buttons,deg, coherence, File1, nr_trials,instr_order)

%Accuracy Instructions
Screen('TextFont',window,'Times');
Screen('TextSize',window, 20);
text='From now on, it is really important that you try to respond as accurately as possible. \n\n You will be given points for your performance. \n\n \n\n Like before, please look at the fixation cross in the middle of the screen \n\n and indicate the direction of the movement as accurately as possible.';
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait;%waits for user to press any key 
     
%% Initialise
total_reward=0; %sets points to zero
signal_duration=2;
instr=2;%ACCURACY CONDITION

%% Accuracy Deadline Staircase
q_accuracy=QuestCreate(1.0,0.15,0.9, 3.5,0.01,0.5);
accuracy_deadline=1;

%% Trial Loop
for trial=1:nr_trials

    %take appropriate conditions from randomisation 
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
    par2.File1=File1;
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

    %% Feedback
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
    if accuracy==1
        feedback_colour=0;
        text_colour=white;
        text_size=30;
        if rt<accuracy_deadline
            reward=0.005;
            feedback='Correct';
            feedback_marker=6;
        else
            feedback='Too slow';
            reward=0.0025;
            feedback_marker=8;
        end
    else
        feedback='INCORRECT';
        feedback_colour=[1 0 0];
        text_colour=[0 1 0];
        text_size=50;
        reward=0;  
        feedback_marker=7;
    end
    
    %Text setting
    Screen(window,'FillRect',feedback_colour);
    Screen('TextSize',window, text_size);
    Screen('TextFont',window,'Times');
    points_text=sprintf(' %s \n\n Reward: £ %1.4f', feedback, reward);
    DrawFormattedText(window,points_text,'center','center',text_colour);
    Screen('Flip',window);
%         imageArray = Screen('GetImage', window);
% 
% 	%imwrite is a Matlab function, not a PTB-3 function
% 	imwrite(imageArray, 'feedred2.jpg')

    %feedback marker
    outp(hex2dec('D010'), 20+feedback_marker)
    WaitSecs(0.7);
    %KbStrokeWait;%wait for kb input
    Screen(window,'FillRect',0);
    Screen('Flip',window);

    
    %save deadline
    fprintf(File1,' \t %f ', accuracy_deadline);
    
    % add 1s ITI after red screen
    if feedback_colour==[1 0 0]
        cross=15; 
        x_coords=[-cross, cross, 0, 0];
        y_coords=[0, 0, -cross, cross];
        coords=[x_coords; y_coords];
        Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
        Screen('Flip', window);
        WaitSecs(1);
    end
    
    %% Staircase
    if lvl_coherence==2 
        q_accuracy=QuestUpdate(q_accuracy, accuracy_deadline,accuracy);
        accuracy_deadline=QuestQuantile(q_accuracy);
        if accuracy_deadline>1.3
            accuracy_deadline=1.3;
        elseif accuracy_deadline<0.7
            accuracy_deadline=0.7;
        end
    end

    %break
    if trial/100==round(trial/100) && trial < 400
        Screen('TextSize',window, 30);
        Screen('TextFont',window,'Times');
        points_text=sprintf(' Break');
        DrawFormattedText(window,points_text,'center','center',white);
        Screen('Flip',window);
        KbStrokeWait;%wait for kb input
    end

    total_reward=total_reward+reward;

    %points_function(window, score, white, feedback); %just the screen with the score 
    outp(hex2dec('D010'),0);   
end
end