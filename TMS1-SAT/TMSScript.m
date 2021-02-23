%% Random Dot Motion Task
% TMS version
% Number of trials: nr_trial_per_cond 10 for 800 task trials
%   (10 => 400 trials per function (*coh*dir*bins))
%now: 24 conditions -> nr_trial_per_cond=17 =>408 trials
       
%if error in disp a and b: make sure coherence is 0.3 not 3!
%% Constants        
participant=input('participant:','s');
age=input('age: ');
gender=input('gender: ','s');
session_nr=input('session nr: ');
instr_order=input('instr order: '); %1=speed first, 2=accuracy first
if session_nr ~=1
    coherence75=input('75 coherence: ');
    coherence95=input('95 coherence: ');
    coherence=[coherence95, coherence75];
end
    

%Stimulus Settings
nr_trials_per_cond=9; %9 for 216 trials

%% Output
directory1=strcat(cd, '\',participant,'_results.txt'); % create path(cd=current directory)
directory2=strcat(cd,'\' ,participant,'_details.txt');
directory3=strcat(cd,'\',participant,'_staircase.txt');
File1=fopen(directory1,'a'); % opens for appending; File1=handle
File2=fopen(directory2,'a');
File3=fopen(directory3,'a');
fprintf(File2, '\r\n \r\n %s ', datestr(now)); %saves date and time
fprintf(File2, '\r\n Participant: %s \n Age: %d \n Gender: %s Session: %d', participant, age, gender, session_nr);
fprintf(File1, '\r\n Trial \t Condition \t Accuracy \t Response \t Direction \t Lvl of Coherence \t Missed Flips \t RT \t jitter \t tms \t stim_time \t actual_stim_time \t deadline\n');%deadlien always last cause its saved in the accuracy/speed function
fprintf(File3, '\r\n Trial \t Condition \t Accuracy \t Response \t Direction \t Lvl of Coherence \t Missed Flips \t easy/hard \t RT \t signal jitter \t deadline\n');


%% Psychtoolbox
PsychDefaultSetup(2); %psychtoolbox setup
screen_nr=max(Screen('Screens')); % returns max. of vector for number of screens
%define black & white
white=WhiteIndex(screen_nr);
black=BlackIndex(screen_nr);
%Open window, define centre, set priroty
[window, window_rect]=PsychImaging('OpenWindow',screen_nr,black);%opens black screen
[x_centre, y_centre]=RectCenter(window_rect); 
ifi=Screen('GetFlipInterval',window); 
Priority(MaxPriority(window));
HideCursor;

%Check Screen Settings
if window_rect(4)>768 | ifi<0.011 | ifi>0.012
  sca;
  disp('Check Screen Resolution (1204x768) and Refresh Rate (85Hz)');
end
        
%% Screen %CHANGE
%for 57cm distance from screen, 1cm=1degree
%this is for 100cm away from screen 
screen_cm=37;
cm_per_degree = 1.7454 ;
screen_deg=screen_cm / cm_per_degree;
deg=window_rect(3)/screen_deg;%number of pixels per degree

%% DAQ setup
device = daq.getDevices;
if isempty(device)
    buttons = 0;
else
    buttons = 1;
end

%% Welcome Screen
%TextSettings

Screen('TextSize',window, 20);
Screen('TextFont',window,'Times');
text='Welcome! \n\n \n\n Once you''re happy to start, you will see an array of randomly moving dots. \n\n After around one second, a proportion of the dots \n\n will begin to move either up or down.\n\n \n\n Please indicate the direction of the movement using the response buttons:\n\nPinch: Upward Movement \n\n Grip: Downward Movement \n\n \n\n (Press any key to continue)';%CHANGE
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);
KbStrokeWait;

try
for block_nr=1:2
    if instr_order==1  %if instr is 1, first run through loop is block 1 (=speed)
        if block_nr==1
            block=1; %speed
        else
            block=2; %accuracy
        end
    else
        if block_nr==1
            block=2; %accuracy
        else
            block=1; %speed
        end
    end

    %% DESIGN
    nr_factors=3; %coherence,direction,tms bins
    nr_bins=6; %1/3 TMS trials
    directions=[1,2]; 
    nr_direction=length(directions);
    nr_coherence=2;%length(coherence);
    nr_conditions=nr_coherence*nr_direction*nr_bins; 
    nr_trials=nr_bins*nr_coherence*nr_direction*nr_trials_per_cond; 

    % TMS
     if block==1
        RTMean=500;
    elseif block ==2
        RTMean=600;
    end
    %if you wana change the bins, you have to change bin=6 in speed and
    %accuray to get zero
    tms_bins=[linspace(0,RTMean,5)];
    tms_bins=[tms_bins(2:5),zeros(1,2)];
    bin_interval=(tms_bins(2)-tms_bins(1))-1;%returns length of one bin

    %% Randomise Order 
    rng('shuffle');
    order=randperm(nr_trials);
    conditions=ceil(order/nr_trials_per_cond); 
    bin_order=mod(conditions,nr_bins)+1;
    temp_order= ceil(conditions/nr_bins);
    coherence_order=ceil(temp_order/nr_coherence);
    direction_order=mod(temp_order,nr_coherence)+1 ;

    original_order=[order', conditions', bin_order', coherence_order', direction_order'];

    %Function Input
    par.coherence_order=coherence_order;
    par.direction_order=direction_order;
    par.x_centre=x_centre;
    par.y_centre=y_centre;
    par.window=window;
    par.white=white;
    par.ifi=ifi;
    par.window_rect=window_rect;
    par.buttons=buttons;
    par.deg=deg;
    par.File2=File2;
    par=struct2cell(par);
    
    if block_nr==1 %only first time we run through loop
        if session_nr==1
            mousebuttons=0;
        while mousebuttons==0
            PracticeFunction(par{:},[0.99 0.99])
                Screen('TextFont',window,'Times');
                Screen('TextSize',window, 30);
                text='Break';
                DrawFormattedText(window,text,'center','center',white);
                vbl=Screen('Flip',window);%flip to screen
                KbStrokeWait
                [x,y,mousebuttons]=GetMouse([window]);
        end  
         mousebuttons=0;
        while mousebuttons==0
                PracticeFunction(par{:},[0.5 0.5])
                Screen('TextFont',window,'Times');
                Screen('TextSize',window, 30);
                text='Break';
                DrawFormattedText(window,text,'center','center',white);
                vbl=Screen('Flip',window);%flip to screen
                KbStrokeWait
                [x,y,mousebuttons]=GetMouse([window]);
        end  
            [quest_output_75, quest_output_95]=StaircaseFunction(par{:},File3);
        else
           %PracticeFunction(par{:},[0.5 0.5]);
        end
    end
    
    if session_nr==1
        coherence=[quest_output_95, quest_output_75];%easy has to come first
    end

    par1.bin_order=bin_order;
    par1.tms_bins=tms_bins;
    par1.bin_interval=bin_interval;
    par1.coherence=coherence;
    par1.File1=File1;
    par1.nr_trials=nr_trials;
    par1.instr_order=instr_order;
    
    
    par1=struct2cell(par1);

    if block==1
        total_reward_speed=SpeedFunction(par{:},par1{:});
    else
        total_reward_acc=AccuracyFunction(par{:},par1{:});
    end

end
catch
    psychrethrow(psychlasterror);
    %RestoreCluts;
    ShowCursor;    
    Priority(0);     
    istatus = fclose('all');
    Screen('CloseAll');
end
total_reward=total_reward_speed+total_reward_acc;

Screen('TextSize',window, 30);
Screen('TextFont',window,'Times');
text=sprintf('Thank you! \n\n You''ve earned £ %1.2f !', total_reward);%CHANGE
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait;%waits for user to press any key 

ShowCursor;
daq.reset;
fclose('all');
sca