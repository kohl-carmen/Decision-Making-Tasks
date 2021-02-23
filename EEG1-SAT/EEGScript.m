%% Random Dot Motion Task
% EEG version
% Number of trials: nr_trial_per_cond 100 for 800 task trials
%   (100 => 400 trials per function (*coh*dir))


%% Constants        
participant=input('participant: ','s');
age=input('age: ');
gender=input('gender: ','s');
instr_order=input('instruction order (1 =speed first): '); %1=speed first, 2=accuracy first

%Stimulus Settings
nr_trials_per_cond=50; % dont go under staircase
   
%% Output
%Creates 3 files. Details for participant information and practice trials.
%Staircase for Staircase trials. Results for Speed and Accuracy Trials
directory1=strcat(cd, '\',participant,'_results.txt'); % create path(cd=current directory)
directory2=strcat(cd,'\' ,participant,'_details.txt');
directory3=strcat(cd,'\',participant,'_staircase.txt');
File1=fopen(directory1,'a'); % opens for appending; File1=handle
File2=fopen(directory2,'a');
File3=fopen(directory3,'a');
fprintf(File2, '\r\n \r\n %s ', datestr(now)); %saves date and time
fprintf(File2, '\r\n Participant: %s \n Age: %d \n Gender: %s \n', participant, age, gender);
fprintf(File1, '\r\n Trial \t Condition \t Accuracy \t Response \t Direction \t Lvl of Coherence \t Missed Flips \t RT \t jitter \t deadline \n');%just to give my following columns headings
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

% %Check Screen Settings
% if window_rect(4)>768 | ifi<0.011 | ifi>0.012
%    sca;
%    disp('Check Screen Resolution (1204x768) and Refresh Rate (85Hz)');
% end
%         
%% Screen %CHANGE
%for 57cm distance from screen, 1cm=1degree
%this is for 100cm away from screen (for diff distance use
screen_cm=37;
cm_per_degree = 1.7454 ;
screen_deg=screen_cm / cm_per_degree;
deg=window_rect(3)/screen_deg;%number of pixels per degree

% DAQ setup
device = daq.getDevices;
if isempty(device)
    buttons = 0;
else
    buttons = 1;
end

%% Welcome Screen
Screen('TextSize',window, 20);
Screen('TextFont',window,'Times');
text='Welcome! \n\n \n\n Once you''re happy to start, you will see an array of randomly moving dots. \n\n After around one second, a proportion of the dots \n\n will begin to move either up or down.\n\n \n\n Please indicate the direction of the movement using the response buttons:\n\n Right Button: Upward Movement \n\n Left Button: Downward Movement ';%CHANGE
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait;%waits for user to press any key 

for block_nr=2
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
    nr_factors=2; 
    directions=[1,2]; 
    coherence=[0.4, 0.4]; 
    nr_coherence=length(coherence); 
    nr_direction=length(directions);
    nr_conditions=nr_coherence*nr_direction; 
    nr_trials=nr_coherence*nr_direction*nr_trials_per_cond; 
    %% Randomise Order 
    rng('shuffle');
    order=randperm(nr_trials); 
    conditions=ceil(order/nr_trials_per_cond); 
    direction_order=ceil(conditions./nr_coherence); 
    coherence_order=mod(conditions,nr_coherence)+1 ;
    %see ConditionOrder file

    par.coherence_order=coherence_order;
    par.direction_order=direction_order;%random order of directions to pick each trial from
    par.x_centre=x_centre;%defines x value of middle of screen
    par.y_centre=y_centre;%defines y value of middle of screen
    par.window=window;%window. See Screen
    par.white=white;
    par.ifi=ifi;%inter frame interval
    par.window_rect=window_rect;%rect. See Screen
    par.buttons=buttons;%logical. whether or not we have buttons
    par.deg=deg;%pixels per one degree
    par=struct2cell(par);

    if block_nr==1
        mousebuttons=0;
        while mousebuttons==0
            PracticeFunction(par{:},File2,[0.8 0.8])
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
                PracticeFunction(par{:},File2,[0.5 0.5])
                Screen('TextFont',window,'Times');
                Screen('TextSize',window, 30);
                text='Break';
                DrawFormattedText(window,text,'center','center',white);
                vbl=Screen('Flip',window);%flip to screen
                KbStrokeWait
                [x,y,mousebuttons]=GetMouse([window]);
        end  
%         [quest_output_75, quest_output_95]=StaircaseFunction(par{:},File3);
    end
    
    coherence=[0.67 0.30]%quest_output_95, quest_output_75];%easy has to come first
%     coherence=[quest_output_95, quest_output_75];%easy has to come first
    
    
    if block==1
        total_reward_speed=SpeedFunction(par{:},coherence,File1,nr_trials,instr_order);
    else
        total_reward_acc=AccuracyFunction(par{:},coherence,File1,nr_trials,instr_order);
    end
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