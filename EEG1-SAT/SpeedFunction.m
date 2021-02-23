function total_reward=SpeedFunction(coherence_order, direction_order, x_centre, y_centre, window, white,ifi,window_rect,buttons,deg, coherence, File1, nr_trials,instr_order)
%this speed function is the same as in quest both but now im changing it to
%have its own quest 
%Speed Instructions
Screen('TextFont',window,'Times');
Screen('TextSize',window, 20);
text='From now on, it is really important that you try to respond as quickly as possible. \n\n You will be given points for your performance. \n\n \n\n Like before, please look at the fixation cross in the middle of the screen \n\n and indicate the direction of the movement as quickly as possible.\n\n ';
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait;%waits for user to press any key 
     
%% Initialise
total_reward=0; %sets points to zero
signal_duration=2;
instr=1;

% Deadline Staircase
q_speed=QuestCreate(0.6, 0.15, 0.75, 3.5,0.01, 0.5);
speed_deadline=0.6;


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
    if rt<speed_deadline
        if accuracy==1;
            feedback='Correct';
            reward=0.005;
            feedback_marker=6;
        else
            feedback='Incorrect';
            reward=0.0025;
            feedback_marker=7;
        end
            feedback_colour=0;
            text_colour=white;
            text_size=30;
    else
        feedback='TOO SLOW';
        feedback_colour=[1 0 0];
        text_colour=[0 1 0];
        text_size=50;
        reward=0;
        feedback_marker=8;
    end
    
    %Text setting
    Screen(window,'FillRect',feedback_colour);
    Screen('TextSize',window, text_size);
    Screen('TextFont',window,'Times');
    points_text=sprintf(' %s \n\n Reward: £ %1.4f', feedback, reward);
    DrawFormattedText(window,points_text,'center','center',text_colour);
    Screen('Flip',window);
%     imageArray = Screen('GetImage', window);
% 
% 	%imwrite is a Matlab function, not a PTB-3 function
% 	imwrite(imageArray, 'feedred1.jpg')

    %feedback marker
    outp(hex2dec('D010'), 10+feedback_marker)
    WaitSecs(0.7);
    %KbStrokeWait;%wait for kb input
    Screen(window,'FillRect',0);
    Screen('Flip',window);
    
    
    
    fprintf(File1,' \t %f ',speed_deadline);
    
    %% add 1s ITI after red screen
    if feedback_colour==[1 0 0]
        cross=15; 
        x_coords=[-cross, cross, 0, 0];
        y_coords=[0, 0, -cross, cross];
        coords=[x_coords; y_coords];
        Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
        Screen('Flip', window);
        WaitSecs(1);
    end
    
    total_reward=total_reward+reward;
    
    %% Speed Staircase
    if lvl_coherence==2 
        q_speed=QuestUpdate(q_speed, speed_deadline,accuracy);
        speed_deadline=QuestQuantile(q_speed);
        if speed_deadline>0.75
            speed_deadline=0.75;
        elseif speed_deadline<0.45
            speed_deadline=0.45;
        end
    end

    %break
    if trial/100==round(trial/100)&& trial < 400
        Screen('TextSize',window, 30);
        Screen('TextFont',window,'Times');
        points_text=sprintf(' Break');
        DrawFormattedText(window,points_text,'center','center',white);
        Screen('Flip',window);
        KbStrokeWait;%wait for kb input
    end
  outp(hex2dec('D010'),0);   
end
end