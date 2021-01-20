function colour
RUNTHROUGH=[1 2 3 4]; %for no practice RUNTHROUGH=4;
% 1: practice 1 (colour comb 1)
% 2: practice 2 (colour comb 2)
% 3: practice 3 (mixed together)
% 4: experiment
participant=input('participant:');
age=input('age:');
gender=input('gender: ','s');
handedness=input('handedness: ','s');

%ColourComb 1: blue-orange
%ColourComb 2: lilac-green

Practice=[1,2,3,0];%1: practice easy to hard  comb1, 2: easy to hard comb 2, 3: intermixed hard, 0: experiment

%Stimulus Settings
nr_trials_per_cond=200; % 
nr_trials_per_block=80;
nr_practice_trials=100;

%% Psychtoolbox
PsychDefaultSetup(2); %psychtoolbox setup (?)
screen_nr=max(Screen('Screens')); % returns max. of vector for number of screens
%define black & white
white=WhiteIndex(screen_nr);
black=BlackIndex(screen_nr);
%Open window, define centre, set priroty
[window, window_rect]=PsychImaging('OpenWindow',screen_nr,[0.5 0.5 0.5]);%opens black screen
[x_centre, y_centre]=RectCenter(window_rect); 
ifi=Screen('GetFlipInterval',window); 
Priority(MaxPriority(window));
HideCursor;

%Set Parallel port options for sending digital signal (uses scripts and mex file in
%IO64_parallelport folder on Matlab path, plus drivers (inpoutx64.dll) in
%c:\windows\system32
device = daq.getDevices;
config_io;
address = hex2dec('B010'); %This is the address of the parallel port. You can get
%this number (in hexidecimal) by going to control panel > device manager,
%expanding "ports", finding the parallel port, and looking in "resources"
%(from its properties)

%Check Screen Settings
if window_rect(4)>768 | ifi<0.009 | ifi>0.011
   sca;
   disp('Check Screen Resolution (1204x768) and Refresh Rate (85Hz)');
end
        
%% Screen %CHANGE
%for 57cm distance from screen, 1cm=1degree
%this is for 100cm away from screen (for diff distance use
%tan(angle)=opposite over adjacent(i think) to get angle and then times 2
screen_cm=37;%50;
cm_per_degree = 1.7454 ;
screen_deg=screen_cm / cm_per_degree;%50;
deg=window_rect(3)/screen_deg;%number of pixels per degree


%% DESIGN
Diff=[0.52]; % no longer a condition!!
Trial_Time=1;
fix_time=0.3;
Comb=[1,2]; % either red-green or blue-yellow
Dominant=[1,2];% right, left
%counterbalance which partic get's which colour (red=left or right?)

nr_combs=length(Comb);
nr_dominant=length(Dominant);
nr_conditions=nr_combs*nr_dominant; 
nr_trials=nr_combs*nr_dominant*nr_trials_per_cond; 

%% Setup Visual
%% 4 potential combinations (A== RIGHT  B== LEFT)
% 1: orange(B) green(B)  -   blue(A) lilac (A)
% 2: blue(B) green(B)    -   orange(A) lilac(A)
% 3: orange(B) lilac(B)  -   blue(A) green(A)
% 4: lilac(B) blue(B)    -   green(A) orange(A)
if any(participant==[1 5 9 13 17])
    Comb=struct();
    Comb.comb1.colour_A=hsv2rgb([0.5833    0.7497    0.5750]);%blue
    Comb.comb1.colour_B=hsv2rgb([0.0845    0.7600    (0.8623+0.8350)/2]);%orange
    Comb.comb2.colour_A=hsv2rgb([0.8333    0.4520    0.500]);%purple
    Comb.comb2.colour_B=hsv2rgb([0.3300    0.5000    (0.6933+0.7249)/2]);%green
    colour_txts={'blue','ornge';'lilac','green'};
elseif any(participant==[2 6 10 14 18])
    Comb=struct();
    Comb.comb1.colour_B=hsv2rgb([0.5833    0.7497    0.5750]);%blue
    Comb.comb1.colour_A=hsv2rgb([0.0845    0.7600    (0.8623+0.8350)/2]);%orange
    Comb.comb2.colour_A=hsv2rgb([0.8333    0.4520    0.500]);%purple
    Comb.comb2.colour_B=hsv2rgb([0.3300    0.5000    (0.6933+0.7249)/2]);%green
    colour_txts={'ornge','blue';'lilac','green'};
elseif any(participant==[3 7 11 15 19])
    Comb=struct();
    Comb.comb1.colour_A=hsv2rgb([0.5833    0.7497    0.5750]);%blue
    Comb.comb1.colour_B=hsv2rgb([0.0845    0.7600    (0.8623+0.8350)/2]);%orange
    Comb.comb2.colour_B=hsv2rgb([0.8333    0.4520    0.500]);%purple
    Comb.comb2.colour_A=hsv2rgb([0.3300    0.5000    (0.6933+0.7249)/2]);%green
    colour_txts={'blue','ornge';'green','lilac'};
else
    Comb=struct();
    Comb.comb1.colour_B=hsv2rgb([0.5833    0.7497    0.5750]);%blue
    Comb.comb1.colour_A=hsv2rgb([0.0845    0.7600    (0.8623+0.8350)/2]);%orange
    Comb.comb2.colour_B=hsv2rgb([0.8333    0.4520    0.500]);%purple
    Comb.comb2.colour_A=hsv2rgb([0.3300    0.5000    (0.6933+0.7249)/2]);%green
    colour_txts={'ornge', 'blue';'green','lilac'};
end

%% Welcome Screen
Screen('TextSize',window, 20);
Screen('TextFont',window,'Times');
text='Welcome! \n\n \n\n  You will be presented with an array of \n \n either red and green or blue and yellow pixels.  \n\n  We''d like you to identify which of the two colours is most valent \n\n and press the matching button.\n\n \n\n Press LEFT for                       Press RIGHT for';
Screen('DrawDots', window,[window_rect(3)/3-15, window_rect(4)/4*3],25,Comb.comb1.colour_B);
Screen('DrawDots', window,[window_rect(3)/3+15, window_rect(4)/4*3],25,Comb.comb2.colour_B);
Screen('DrawDots', window,[window_rect(3)/3*2-15, window_rect(4)/4*3],25,Comb.comb1.colour_A);
Screen('DrawDots', window,[window_rect(3)/3*2+15, window_rect(4)/4*3],25,Comb.comb2.colour_A);
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);%flip to screen

pixel_size= 2;
nr_pixels= round(6*deg/2);
size_box=pixel_size*nr_pixels;
coords_box=[x_centre-size_box/2 y_centre-size_box/2 x_centre+size_box/2 y_centre+size_box/2];
fix_size=5;
count=0;
for i=1:nr_pixels
    for j=1:nr_pixels
        count=count+1;
        pix_coords(count,:)=[coords_box(1)+ pixel_size*(i-1) coords_box(2)+pixel_size*(j-1) coords_box(1)+ pixel_size*i coords_box(2)+pixel_size*j];
    end
end

%% Get Trial Order
%So now we want to do it so each block is counterbalanced within itself
Order=[];
Cond_txt=[];
for blocks=1:nr_trials/nr_trials_per_block
    [order, cond_txt]=Generate_ResRep_Order(nr_trials_per_block);
    Order=[Order;order];
    Cond_txt=[Cond_txt cond_txt];
end

KbStrokeWait;%waits for user to press any key 

accuracy_tracker=[];
rt_tracker=[];    
for runthrough=RUNTHROUGH
    practice=Practice(runthrough);
  
    %% Output
    if ~practice
        nr_trials=nr_combs*nr_dominant*nr_trials_per_cond; 
        Screen('TextSize',window, 30);
        Screen('TextFont',window,'Times');
        text='Experiment';
        Screen('DrawDots', window,[window_rect(3)/3-15, window_rect(4)/2+10],25,Comb.comb1.colour_B);
        Screen('DrawDots', window,[window_rect(3)/3+15, window_rect(4)/2+10],25,Comb.comb2.colour_B);
        Screen('DrawDots', window,[window_rect(3)/3*2-15, window_rect(4)/2+10],25,Comb.comb1.colour_A);
        Screen('DrawDots', window,[window_rect(3)/3*2+15, window_rect(4)/2+10],25,Comb.comb2.colour_A);
        DrawFormattedText(window,text,'center','center',white);
        vbl=Screen('Flip',window);%flip to screen
        KbStrokeWait
        results_directory=strcat(cd, '\',num2str(participant),'_results.txt'); % create path(cd=current directory)
        File=fopen(results_directory,'a'); % opens for appending; File1=handle
        fprintf(File, '\r\n Trial \t Cond  \t Acc \t Resp \t Comb \t Dom \t RT  \t \t Condtxt \t Coltxt  Domtxt\n');%just to give my following columns headings
    else
        nr_trials=nr_practice_trials;
        Screen('TextSize',window, 30);
        Screen('TextFont',window,'Times');
        if practice==1
            text='Practice 1';
            Screen('DrawDots', window,[window_rect(3)/3-15, window_rect(4)/2+10],25,Comb.comb1.colour_B);
            Screen('DrawDots', window,[window_rect(3)/3*2-15, window_rect(4)/2+10],25,Comb.comb1.colour_A);
        elseif practice==2
            text='Practice 2';
            Screen('DrawDots', window,[window_rect(3)/3+15, window_rect(4)/2+10],25,Comb.comb2.colour_B);
            Screen('DrawDots', window,[window_rect(3)/3*2+15, window_rect(4)/2+10],25,Comb.comb2.colour_A);
        else
            text='Practice 3';
            Screen('DrawDots', window,[window_rect(3)/3-15, window_rect(4)/2+10],25,Comb.comb1.colour_B);
            Screen('DrawDots', window,[window_rect(3)/3+15, window_rect(4)/2+10],25,Comb.comb2.colour_B);
            Screen('DrawDots', window,[window_rect(3)/3*2-15, window_rect(4)/2+10],25,Comb.comb1.colour_A);
            Screen('DrawDots', window,[window_rect(3)/3*2+15, window_rect(4)/2+10],25,Comb.comb2.colour_A);
        end
        DrawFormattedText(window,text,'center','center',white);
        vbl=Screen('Flip',window);%flip to screen
        KbStrokeWait
        details_directory=strcat(cd, '\',num2str(participant),'_details.txt'); % create path(cd=current directory)
        File2=fopen(details_directory,'a'); % opens for appending; File1=handle
        fprintf(File2, '\r\n \r\n %s ', datestr(now));
        fprintf(File2, '\r\n Participant: %d \n Age: %d \n Gender: %s \n Handedness: %s', participant, age, gender, handedness);
        fprintf(File2, '\r\n Trial \t Cond  \t Acc \t Resp \t Comb \t Dom \t RT \t \t Condtxt \t Coltxt  Domtxt\n');
    end
    for trial=1:nr_trials
        %% Pick trial visual
        switch Order(trial)
            case 1
                comb=1;
                dom=1;%right
            case 2
                comb=1;
                dom=2;%left
            case 3
                comb=2;
                dom=1;%right
            case 4
                comb=2;
                dom=2;%left
        end
        if practice==1
            comb=1;
        elseif practice==2
            comb=2;
        end
        colour_A=Comb.(strcat('comb',num2str(comb))).colour_A;
        colour_B=Comb.(strcat('comb',num2str(comb))).colour_B;
        diff=Diff;
        if practice==1 | practice==2
            if trial<nr_trials/5*2
                diff=0.7;
            elseif trial<nr_trials/5*3.5
                diff=0.6;
            else
                diff=Diff;
            end
        end

        if dom==2
            diff=1-diff;
        end
        nr_pix_A=(nr_pixels^2)*diff;
        nr_pix_B=(nr_pixels^2)*(1-diff);

        pix_AB_tmp=zeros(nr_pixels);
        pix_AB_tmp(1:nr_pix_A)=1;
        rng('shuffle');
        order=randperm(nr_pixels^2); 
        pix_AB_tmp=reshape(pix_AB_tmp(order),size(pix_AB_tmp));
        pix_AB_tmp=pix_AB_tmp(order); 

        pix_coords_A=pix_coords((pix_AB_tmp==1),:);
        pix_coords_B=pix_coords((pix_AB_tmp==0),:);

        %% Response tracking
        %Set up national instruments input/output card using commands from the
        %data acquisition toolbox. Only works with NI hardware.
        session = daq.createSession('ni');
        %http://uk.mathworks.com/help/daq/ref/adddigitalchannel.html#btjdzmh-1
        addAnalogInputChannel(session,'dev1',0:1,'Voltage'); %use 0:1 for two channel, etc. 

        session.Rate = 62500;% sampling rate (how many times it checks the status of the channels per second). channels are either 0 or 5 (5 when pressed) but never exactly those
        session.NotifyWhenDataAvailableExceeds = 2 .* round(ifi.*session.Rate); %1667; % notify every 200 or so samples. gives me a matrix with 0s and times of those 0s
        session.IsContinuous = true;%keeps overwriting the matrix with the zeros continuously

        lh = session.addlistener('DataAvailable',@weirdfunction); %calls a callback function (see bottom bit)
        startBackground(session);   %acquisition trigger?
        Trigger2=GetSecs; %psychtoolbox baseline

        ResponseTime = 0;
        ResponseInput = zeros(1,2);

        %outp(address,0);

        trial_onset_time=GetSecs;
        trial_time=0;
        pressed=0;
        loop=0;
        stim_onset_time=0;
        missed_onset=0;
    
        while pressed==0 && trial_time<=Trial_Time+fix_time
            trial_time=GetSecs-trial_onset_time;
            if trial_time<=fix_time-ifi
                %fix dot
                Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
                [vbl]=Screen('Flip', window,vbl+0.5*ifi);
            else
                %task
                loop=loop+1;
                Screen('FillRect', window, colour_A,pix_coords_A'  )
                Screen('FillRect', window, colour_B,pix_coords_B'  )
                Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
                [vbl,a,b,missed]=Screen('Flip', window,vbl+0.5*ifi);
                
                if loop==1
                    stim_onset_time=GetSecs;
%                     outp(address,1);
%                     if missed>0
%                         missed_onset=1;
%                     else
%                         missed_onset=0;
%                     end             
                end

                % Response
                if sum(ResponseInput)>0%break loop without kb
                    pressed=1; 
                end
            end
        end
          [x,y,mousebuttons]=GetMouse([window]);
         if mousebuttons(1)==1
             KbStrokeWait;
             Cond_txt{trial+1}='Start_Seq';
         end
         
        %--------------------
        %% RESPONSE & SAVE
        %--------------------
        %Record Response

        if ResponseInput(1)==1
            response=2; %RIGHT (on screen and on national instr
            rt = (ResponseTime - (stim_onset_time - acquisition_start));
        elseif ResponseInput(2)==1;
            response=1;
            rt = (ResponseTime - (stim_onset_time - acquisition_start));
        else
            response=0;
        end

        %if no response
        if ~pressed
            rt= 1 ;
            accuracy=0;
            response=0;
        end 
        if response == dom
           accuracy=1;
        else
           accuracy=0;
        end 
        if rt<0
            accuracy=0;
        end 
        
        accuracy_tracker=[accuracy_tracker, accuracy];
        rt_tracker=[rt_tracker, rt];
        
        if dom==1
            dom_txt='right';
        else
            dom_txt='left';
        end
        if isempty(Cond_txt{trial})
            Cond_txt{trial}='Start_Seq';
        end
        
        if practice
            fprintf(File2,'\r\n  %d \t %d \t %d \t %d \t %d \t %d\t %f  \t %s \t %s \t %s  ', trial,Order(trial),accuracy,response, comb, dom, rt, Cond_txt{trial},colour_txts{comb,dom}, dom_txt);
        else
            fprintf(File,'\r\n  %d \t %d \t %d \t %d \t %d \t %d\t %f  \t %s \t %s \t %s  ', trial,Order(trial),accuracy,response, comb, dom, rt, Cond_txt{trial},colour_txts{comb,dom}, dom_txt);
        end
        
        %% Feedback
        if accuracy==0
            feedback='Incorrect';
        else
            feedback='Correct';
        end
        Screen('TextSize',window, 30);
        Screen('TextFont',window,'Times');
        if practice
            feedback_colour=[1 1 1];
        else
            feedback_colour=[0.5 0.5 0.5];
        end
        DrawFormattedText(window,feedback,'center','center',feedback_colour);
        Screen('Flip',window);
        if practice
            pause(0.5); 
        else
            pause(0.2);
        end
        Screen('Flip',window);
        
         %BREAK 
         if (~practice & trial/nr_trials_per_block==round(trial/nr_trials_per_block) & trial~=nr_trials) | (practice & nr_practice_trials==trial)
            Screen('TextSize',window, 30);
            Screen('TextFont',window,'Times');
            if practice
                points_text=sprintf(' Accuracy: %d %% \n \n Response Time: %d ms ', round(mean(accuracy_tracker)*100), round(mean(rt_tracker)*1000));
                if practice==3
                    points_text=sprintf(' Practice Done \n \n \n \n Accuracy: %d %% \n \n Response Time: %d ms ', round(mean(accuracy_tracker)*100), round(mean(rt_tracker)*1000));
                end
            else
                points_text=sprintf(' Break \n \n \n \n Accuracy: %d %% \n \n Response Time: %d ms ', round(mean(accuracy_tracker)*100), round(mean(rt_tracker)*1000));
            end
            DrawFormattedText(window,points_text,'center','center',white);
            Screen('Flip',window);
            KbStrokeWait;
            Cond_txt{trial+1}='Start_Seq';
            accuracy_tracker=[];
            rt_tracker=[];
         end
    end
end

%----------------------
%% Weird Function
%----------------------
function weirdfunction(src, event)
    %event.Data
    if any(event.Data(:,1) > 3) %AI 0 (pinch)
        ResponseInput(1) = 1;
        acquisition_start = Trigger2;%event.TriggerTime*24*60*60;
        first_response=min(find(event.Data(:,1)>3));
        ResponseTime = event.TimeStamps(first_response,1);
    else
        ResponseInput(1) = 0;           
    end
    if any(event.Data(:,2) > 3)%AI 1 (grip)
        ResponseInput(2) = 1;
        acquisition_start =Trigger2;%event.TriggerTime*24*60*60;
        first_response=min(find(event.Data(:,2)>3));
        ResponseTime = event.TimeStamps(first_response,1);
     else
        ResponseInput(2) = 0;
    end
end
     
 Screen('TextSize',window, 30);
Screen('TextFont',window,'Times');
text='Thank you';
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait
ShowCursor;
daq.reset;
fclose('all');
sca

  
    
end
    
    
    
    