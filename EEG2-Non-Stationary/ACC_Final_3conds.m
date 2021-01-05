function ACC_Final_3conds
%% dot marker repeated  (resp before signal) wont send trigger
%1 followed by two let to 3
partic='0'
practice=1;
training=0;
staircase=0;
task=0;

if practice+staircase+task+training ~= 1
    disp('select only one condition')
    return
end

if task==true | training==true
    coh1=input('Easy Coherence:'); 
    coh2=input('Hard Coherence:'); 
    Coh=[coh2 coh1];
else
    Coh=[0.8 0.8]; %high for practice and for staircase its overwritten anyway
end

nr_practice_trials=5;
nr_staircase_trials=100;
nr_training_trials=100;
nr_trials_per_cond=80;

break_after_x_trials=60;
if training==true
    break_after_x_trials=10;
end
%Files
cd='C:\Users\EEGlab\Documents\MATLAB\Carmen\InterruptionTask';
if task==true
    results_file=fopen(strcat(cd,'\',num2str(partic),'.txt'),'a');
    fprintf(results_file, '\r\n \r\n %s ', datestr(now));
else
     results_file=fopen(strcat(cd,'\',num2str(partic),'_practice.txt'),'a');
    if staircase==true
        fprintf(results_file,'\r\n \r\n Staircase: \r\n')
    elseif training==true
        fprintf(results_file,'\r\n \r\n Training: \r\n')
    end
end

%% DAQ
%Set Parallel port options for sending digital signal (uses scripts and mex file in
%IO64_parallelport folder on Matlab path, plus drivers (inpoutx64.dll) in
%c:\windows\system32
config_io;
address = hex2dec('D010'); %This is the address of the parallel port. You can get
%this number (in hexidecimal) by going to control panel > device manager,
%expanding "ports", finding the parallel port, and looking in "resources"
%(from its properties)

%% Psychtoolbox
PsychDefaultSetup(2); %psychtoolbox setup (?)
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

%% Screen %CHANGE
%for 57cm distance from screen, 1cm=1degree
%this is for 100cm away from screen (for diff distance use
%tan(angle)=opposite over adjacent(i think) to get angle and then times 2
screen_cm=37;%50;
cm_per_degree = 1.7454 ;
screen_deg=screen_cm / cm_per_degree;%50;
deg=window_rect(3)/screen_deg;%number of pixels per degree

% DAQ setup
device = daq.getDevices;

%% Welcome Screen
Screen('TextSize',window, 20);
Screen('TextFont',window,'Times');
text='Welcome!';%CHANGE
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait;%waits for user to press any key 

 %% DESIGN
 Interrupt={'cont' 'stop' 'revs'};
 Dir=[1 2];
 nr_trials=length(Coh)*length(Interrupt)*length(Dir)* nr_trials_per_cond;
 
 %% Randomise
 rng('shuffle');
 order=randperm(nr_trials); 
 conditions=ceil(order/nr_trials_per_cond); 
 interrupt_order= mod(conditions,length(Interrupt))+1;
 temp=ceil(conditions/length(Interrupt));
 dir_order=ceil(temp./length(Dir)); 
 coh_order=mod(conditions,length(Coh))+1 ;
            %just to test randomisation
            %  big_order=[order',conditions',interrupt_order',dir_order',coh_order']
            %    a=1;
            %             while a>0
            %                 a=0;
            %                 for i=1:length(big_order)-1
            %                     if big_order(i+1,3)<big_order(i,3)
            %                         smaller=big_order(i+1,:);
            %                         bigger=big_order(i,:);
            %                         big_order(i+1,:)=bigger;
            %                         big_order(i,:)=smaller;
            %                         a=1;
            %                     end
            %                 end
            %             end

%turn interruption off for non-task %initialise stairs
if task==false
    if staircase==true
        nr_trials=nr_staircase_trials;
        %% Initialise Staircase Stuff
        BetaValue = 3.5; %SLOPE. Watson&Pelli recommend 3.5 for 2AFC 
        DeltaValue = 0.01;%upper limit (Watson&Pelli approved)
        %q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,[grain],[range],[plotIt])
        % creates structure q with paameters for Weidbull psychometric function p2=delta*gamma+(1-delta)*(1-(1-gamma)*exp(-10.^(beta*(x-xThreshold))))
        q=QuestCreate(0.50,0.2,0.80,BetaValue,DeltaValue,0.5);
        stair_coherence=0.50;
    elseif practice==true
        nr_trials=nr_practice_trials;
    elseif training==true
        nr_trials=nr_training_trials;
    end
    if staircase==true | practice==true
        interrupt_order(1:nr_trials)=1;
    end
end
block_started=false; %this is just to give points per block

for trial=1:nr_trials
    if block_started==false
        block_acc=[];
        block_rt=[];
        block_started=true;
    end
    %% Pick Trial Conditions
    if staircase==false
        coh=Coh(coh_order(trial));
    else
        coh=stair_coherence;
    end
    dir=dir_order(trial);
    interrupt=Interrupt{interrupt_order(trial)};
    %% Fixation Cross
    cross=15; %length of arms
    x_coords=[-cross, cross, 0, 0];
    y_coords=[0, 0, -cross, cross];
    coords=[x_coords; y_coords];
    Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
    Screen('Flip', window);
    jitter=rand*(0.2-0.001)+0.001; %rand=uniform distribution (up to 200ms)
    pause(0.5+jitter);
    
   
    %----------------------
    %% Create Dot Coords
    %----------------------
    nr_dots=300; % 
    interval=5; %re-randomise dots every interval loops
    %create radius and random dot coordinates 
    rad=round(5*deg); %. 5 degrees visual angle. randi wants integers
    x=randi([x_centre-rad, x_centre+rad],1,nr_dots);
    y=randi([y_centre-rad, y_centre+rad],1,nr_dots);
    dot_coords=[x;y];
    %check if in circle
    for i=1:length(dot_coords)
        b = (sqrt(sum(power([dot_coords(1,i), dot_coords(2,i)] - [x_centre, y_centre], 2), 2)))- rad<=0; %Pythagoras. (x-x_cent)^2 + (y-y_cent)^2<rad^2 See "inCircle"
        while b == 0
             dot_coords(1,i)=randi([x_centre-rad, x_centre+rad]);
             dot_coords(2,i)=randi([y_centre-rad, y_centre+rad]);
             b = (sqrt(sum(power([dot_coords(1,i), dot_coords(2,i)] - [x_centre, y_centre], 2), 2)))- rad<=0; 
        end
    end
    %----------------------
    %% Initialise 
    %----------------------
    %Markers
    if interrupt==Interrupt{1}; %cont
        marker=10;
    elseif interrupt==Interrupt{2}%stop
        marker=20;
    elseif interrupt==Interrupt{3}%reverse
        marker=30;
    end
    
    %dot marker
    dot_marker=marker+1;
    
    %signal marker
    if coh==Coh(2)%easy
        if dir==1%up
            signal_marker=marker+2;
        elseif dir==2;%down
            signal_marker=marker+3;
        end
    else
        if dir==1
            signal_marker=marker+4; 
        elseif dir==2;
            signal_marker=marker+5;
        end
    end
    
    %interruption marker
    interruption_marker=marker+6;
    interruption_end_marker=marker+7;
    

    signal_jitter=gamrnd(1,150)/1000;
    while signal_jitter > 1;
        signal_jitter=gamrnd(1,150)/1000;
    end
    signal_onset_time=GetSecs+1+signal_jitter+ifi; %need fake signal time in case i never make it to signal. add1 AFTER multipilication(otherwise i add a day or something);
    loop_time=0;%will track time of loop
    signal_started=0;%this is just needed to get the signal going later
    pressed=0;%to get while loop going
    loop_counter=0;%keeps track of number of loops
    nr_signal=0;%to start off with, all dots are random. no signal.
    step_size=3.3*deg/85;%0;%5/85*deg;%velocity of dots
    displacement=zeros(size(dot_coords));%initialise displacement matrix
    missed_onset=0;
    dot_colour=white;
    interrupt_interval=200;
    interruption_started=0;
    interruption_ended=0;
    interrupt_time=200;
    reverse_on=false;
    fixation_colour=white;
    
    %% START MONITORING (NO WAITSECS FROM HERE)
    session = daq.createSession('ni');
    addAnalogInputChannel(session,'dev1',0:1,'Voltage'); %use 0:1 for two channel, etc. (Kiela used 'session.addAnalog..(dev)')
    session.Rate = 100000;%sampling rate (how many times it checks the status of the channels per second). channels are either 0 or 5 (5 when pressed) but never exactly those
    session.NotifyWhenDataAvailableExceeds = 2 .* round(ifi.*session.Rate); %1667; %notify every 200 or so samples. gives me a matrix with 0s and times of those 0s
    session.IsContinuous = true;%keeps overwriting the matrix with the zeros continuously
    lh = session.addlistener('DataAvailable',@weirdfunction); %calls a callback function (see bottom bit). no idea why lh
    startBackground(session);   %acquisition trigger?
    start_monitoring=GetSecs; %psychtoolbox baseline
    ResponseTime = 0;
    ResponseInput = zeros(1,2);
    outp(address,0);
    %----------------------
    %% Big fat loop
    %----------------------
     if staircase==true
        loop_total=1.3;
    else
        loop_total=2;
     end
   
        
    while pressed==0 && loop_time<loop_total+1+signal_jitter %+1 for random noise     
%         if loop_time > signal_duration+1+signal_jitter && pressed==0
%            dot_colour=0;
%         end
        if loop_counter==0
            loop_onset_time=GetSecs;
        end
        loop_time=GetSecs-loop_onset_time; %tracks how long loop has been going on for
        loop_counter=loop_counter+1;%tracks how often we've gone through loop

        %% Draw Dots and Fixation Cross
        Screen('DrawDots', window,dot_coords,4, dot_colour,[],2);      
        cross=15; %length of arms
        Screen('FillOval',window,[0 0 0],[x_centre-cross, y_centre-cross,x_centre+cross, y_centre+cross,],40);
        x_coords=[-cross, cross, 0, 0];
        y_coords=[0, 0, -cross, cross];
        coords=[x_coords; y_coords];
        Screen('DrawLines', window, coords,2, fixation_colour, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
        [vbl,a,b,missed]=Screen('Flip', window,vbl+0.5*ifi);
            
            
        %% Put all markers directly after flip 
        % DOT ONSET
        if loop_counter==1
            outp(address,dot_marker);
        elseif loop_counter==2
            outp(address,0)
        end
        
        %----------------------
        %% Beginning of signal
        %----------------------
        if signal_started==0 && loop_time>1+signal_jitter %as soon as we reach 1 second but only if signal_started is 0
            signal_started=1;%stop loop for next time
            nr_signal=round(nr_dots * coh);%see which lvl of coherence we want
        end
        %%----------------------

            
        % SIGNAL ONSET
        if signal_started ==1
            signal_onset_time=GetSecs;%now*24*60*60;%get time in seconds (from days)
            if training== true | practice== true 
                fixation_colour=[0.8 0.8 0.8];
            end
            %% OUTPUT
            outp(address,signal_marker);

            signal_started=2;
            if missed>0
                missed_onset=1;
            else
                missed_onset=0;
            end
        elseif signal_started==2
             outp(address,0);
        end
        %INTERRUPTION ONSET
        if interruption_started==1
           outp(address,interruption_marker);
           interruption_started=2;
        end
        %INTERRUPTION END
        if interruption_ended==1
           outp(address,interruption_end_marker);
           interruption_ended=2;
        end

        Screen('DrawingFinished', window);
        %-------------------------
        %% INTERRUPT
        %-------------------------
        if interrupt~=Interrupt{1} & GetSecs-signal_onset_time>=interrupt_time/1000 %if any itneruptoon
            if interruption_started==0
                interrupt_onset=GetSecs;%close enough really
                interruption_started=1;
            end
            if GetSecs-interrupt_onset <= interrupt_interval/1000
                %random
                if interrupt==Interrupt{2}%stop
                    nr_signal=0;
                elseif interrupt==Interrupt{3}
                    reverse_on=true;
                end
            else
                if interrupt==Interrupt{2}%back from random
                    nr_signal=round(nr_dots * coh);
                elseif interrupt==Interrupt{3}
                     reverse_on=false;
                end
                if interruption_ended==0%otherwise it sets it back to one from  2 in each loop
                    interruption_ended=1;
                end
            end
        end
        %-------------------------
        
            %----------------------
            %% Re-randomise
            %----------------------
            if loop_counter/interval==round(loop_counter/interval)
                x=randi([x_centre-rad, x_centre+rad],1,nr_dots);
                y=randi([y_centre-rad, y_centre+rad],1,nr_dots);
                dot_coords=[x;y];

                %check if in circle
                circle_test=sqrt((power(dot_coords(1,:)-repmat(x_centre,1,length(dot_coords)),2)+power(dot_coords(2,:)-repmat(y_centre,1,length(dot_coords)),2)))-rad<=0;%matric of 0s and 1s
                bound=find(circle_test==0); % gives me the positions of 0s in circle_test    
                while sum(circle_test)~=length(circle_test)
                    dot_coords(1,bound)=randi([x_centre-rad, x_centre+rad],1, length(bound));
                    dot_coords(2,bound)=randi([y_centre-rad, y_centre+rad],1, length(bound));
                    circle_test=sqrt((power(dot_coords(1,:)-repmat(x_centre,1,length(dot_coords)),2)+power(dot_coords(2,:)-repmat(y_centre,1,length(dot_coords)),2)))-rad<=0;
                    bound=find(circle_test==0);
                end
             else % if not interval loop (we didnt just re-randomise)
                %----------------------
                %% Add Displacement
                %----------------------
                if (dir==1 & reverse_on==false)| (dir==2 & reverse_on==true) %up
                    angle=2*pi;%1.5*pi;
                elseif (dir==2 & reverse_on==false)| (dir==1 & reverse_on==true) 
                    angle=pi;%pi/2;
                end
                if nr_signal ~0;
                    %displacement signal
                    dis_a=[1:nr_signal]; %fix with if, if nr=0
                    displacement(1,dis_a)=round(dot_coords(1,dis_a)+step_size*cos(angle));
                    displacement(2,dis_a)=round(dot_coords(2,dis_a)+step_size*sin(angle));
                end
                %displacementy noise
                dis_b=[nr_signal+1:length(dot_coords)];
                angle=rand(2,length(dis_b))*2*pi;
                displacement(1,dis_b)=round(dot_coords(1,dis_b)+step_size*cos(angle(1,:)));
                displacement(2,dis_b)=round(dot_coords(2,dis_b)+step_size*sin(angle(2,:)));

                dot_coords=displacement;
                %circle signal
                if nr_signal ~0;
                    circle_test=sqrt((power(dot_coords(1,dis_a)-repmat(x_centre,1,length(dis_a)),2)+power(dot_coords(2,dis_a)-repmat(y_centre,1,length(dis_a)),2)))-rad<=0;%matric of 0s and 1s
                    bound=find(circle_test==0); % gives me the positions of 0s in circle_test
                    dot_coords(1,bound)=dot_coords(1,bound)-2*dot_coords(1,bound)-x_centre;
                end
                %circle noise
                circle_test=sqrt((power(dot_coords(1,:)-repmat(x_centre,1,length(dot_coords)),2)+power(dot_coords(2,:)-repmat(y_centre,1,length(dot_coords)),2)))-rad<=0;%matric of 0s and 1s
                bound=find(circle_test==0); % gives me the positions of 0s in circle_test    
                while sum(circle_test)~=length(circle_test)
                    dot_coords(1,bound)=randi([x_centre-rad, x_centre+rad],1, length(bound));
                    dot_coords(2,bound)=randi([y_centre-rad, y_centre+rad],1, length(bound));
                    circle_test=sqrt((power(dot_coords(1,:)-repmat(x_centre,1,length(dot_coords)),2)+power(dot_coords(2,:)-repmat(y_centre,1,length(dot_coords)),2)))-rad<=0;
                    bound=find(circle_test==0);
                end
            end

        %----------------------
        %% Response
        %----------------------
        if sum(ResponseInput)>0%break loop without kb
            pressed=1;
        end
    end
    %--------------------
    %% RESPONSE & SAVE
    %--------------------
    %Record Response
    if ResponseInput(1)==1
        response=1; %direction=right CHECK
        rt = (ResponseTime - (signal_onset_time - start_monitoring));
    elseif ResponseInput(2)==1;
        response=2;
        rt = (ResponseTime - (signal_onset_time - start_monitoring));
    else
        response=0;
    end

    %if no response
    if ~pressed
        rt= 2 ;
        accuracy=0;
        response=0;
    end 
    if response == dir
       accuracy=1;
    else
       accuracy=0;
    end 

    if rt<0
        accuracy=0;
    end 

%Save to file
interrupt_save=[];
switch interrupt
    case Interrupt{1};
        interrupt_save=1;
    case Interrupt{2}
        interrupt_save=2;
    case Interrupt{3}
        interrupt_save=3;
end
fprintf(results_file,'\r\n  %d \t %d \t %d \t %d \t %d  \t %d \t %d  \t %f \t %f',trial,interrupt_save, accuracy, response, dir, round(coh*100), missed_onset,  rt, signal_jitter);

block_acc=[block_acc, accuracy];
block_rt=[block_rt, rt];
%BREAK
 if (task==1 | training==1) & ( trial/break_after_x_trials==round(trial/break_after_x_trials) | trial==nr_trials)
    Screen('TextSize',window, 30);
    Screen('TextFont',window,'Times');
    %feedback
    if length(block_acc)==length(block_rt) & length(block_rt)==break_after_x_trials & trial~=nr_trials%sanity check
        block_acc=round(sum(block_acc)/length(block_acc)*100);
        block_rt=round(sum(block_rt)/length(block_rt)*1000);
        break_text=sprintf( 'Break \r\n \r\n \r\n Average Accuracy: %d %% \r\n  \r\n Average Speed: ms %d ',block_acc, block_rt);
    elseif  trial==nr_trials%sanity check
        block_acc=round(sum(block_acc)/length(block_acc)*100);
        block_rt=round(sum(block_rt)/length(block_rt)*1000);
        break_text=sprintf( 'Done. \r\n \r\n \r\n Average Accuracy: %d %% \r\n  \r\n Average Speed: ms %d ',block_acc, block_rt);
    end
    DrawFormattedText(window,break_text,'center','center',white);
    Screen('Flip',window);
    KbStrokeWait;
    block_started=false;
 end
    
[x,y,mousebuttons]=GetMouse([window]);
if mousebuttons(1)==1
    KbStrokeWait;
    fprintf(results_file,'\r\n break \r\n');
end

          %FEEDBACK FOR PRACTICE
          if practice==true
                if accuracy==0
                    feedback='Incorrect';
                else
                    feedback='Correct';
                end
                Screen('TextSize',window, 30);
                Screen('TextFont',window,'Times');
                DrawFormattedText(window,feedback,'center','center',white);
                Screen('Flip',window);
                pause(0.7); 
                Screen('Flip',window);
          end
            
          %% STAIRCASE
          if staircase==true
            if response ~ 0;
               q=QuestUpdate(q,stair_coherence,accuracy);
               stair_coherence=QuestQuantile(q);
               if  stair_coherence > 0.99
                    stair_coherence=0.99;
                elseif  stair_coherence<0.01
                     stair_coherence=0.01;
                end
            end
          end 
          
%----------------------
    %% Weird Function
    %----------------------
end
    function weirdfunction(src, event)
        if any(event.Data(:,1) > 3) %AI 0 (pinch)
            ResponseInput(1) = 1;
            first_response=min(find(event.Data(:,1)>3));
            ResponseTime = event.TimeStamps(first_response,1);
        else
            ResponseInput(1) = 0;
        end

        if any(event.Data(:,2) > 3)%AI 1 (grip)
            ResponseInput(2) = 1;
            first_response=min(find(event.Data(:,2)>3));
            ResponseTime = event.TimeStamps(first_response,1);
        else
            ResponseInput(2) = 0;         
        end
    end
 





  
%staircase end
if staircase==true
    quest_output=QuestMean(q);
    if quest_output > 0.99
        quest_output=0.99;
    elseif quest_output<0.01
        quest_output=0.01;
    end
    Hard_Coh=round(quest_output*100);
    if Hard_Coh < 50
        Easy_Coh=Hard_Coh+round(Hard_Coh/2);
    else
        Easy_Coh=99;
    end
end
%byebye
if practice==true
    screen_text='Practice done.';
elseif training==true
    screen_text='Training done.';
elseif staircase==true
    screen_text=strcat('Easy:', num2str(Easy_Coh),'  Hard: ', num2str(Hard_Coh));
    disp(char(screen_text))
else
    screen_text='Thank you!';
end
Screen('TextSize',window, 30);
Screen('TextFont',window,'Times');
DrawFormattedText(window,screen_text,'center','center',white);
Screen('Flip',window);
KbStrokeWait;
Screen('Flip',window);


ShowCursor;
daq.reset;
fclose('all');
sca

end

