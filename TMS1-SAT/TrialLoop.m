function [rt, accuracy,time_everything,response]=TrialLoop(file_time,signal_jitter,lvl_coherence,direction,coherence, x_centre,y_centre,window, white,file,vbl,ifi,trial,buttons,deg,signal_duration,instr,stim_time, easy_hard_condition)
%TMS VERSION

if buttons==1
    %Set Parallel port options for sending digital signal (uses scripts and mex file in
    %IO64_parallelport folder on Matlab path, plus drivers (inpoutx64.dll) in
    %c:\windows\system32
    config_io;
    address = hex2dec('B010'); %This is the address of the parallel port. You can get
    %this number (in hexidecimal) by going to control panel > device manager,
    %expanding "ports", finding the parallel port, and looking in "resources"
    %(from its properties)

    %Set up national instruments input/output card using commands from the
    %data acquisition toolbox. Only works with NI hardware.
    session = daq.createSession('ni');
    session2 = daq.createSession('ni');
    %http://uk.mathworks.com/help/daq/ref/adddigitalchannel.html#btjdzmh-1

    %addDigitalChannel(session2,'dev1', 'Port0/Line8:9', 'OutputOnly'); %for EEG/EMG markers and TMS
    addAnalogInputChannel(session,'dev1',0:3,'Voltage'); %use 0:1 for two channel, etc. 

    session.Rate = 62500;% sampling rate (how many times it checks the status of the channels per second). channels are either 0 or 5 (5 when pressed) but never exactly those
    session.NotifyWhenDataAvailableExceeds = 2 .* round(ifi.*session.Rate); %1667; % notify every 200 or so samples. gives me a matrix with 0s and times of those 0s
    session.IsContinuous = true;%keeps overwriting the matrix with the zeros continuously

    lh = session.addlistener('DataAvailable',@weirdfunction); %calls a callback function (see bottom bit)
    startBackground(session);   %acquisition trigger?
    Trigger2=GetSecs; %psychtoolbox baseline

    ResponseTime = 0;
    ResponseInput = zeros(1,2);

     outp(address,0);
    %outputSingleScan(session2,[0 0]); %output set to zero to start off
%------------------------------
else %if no buttons, use keyboard
    KbQueueCreate;
    KbQueueStart;%reconsider placement if kb is used
end

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
%% Initialise stuff for loop
%----------------------
signal_onset_time=GetSecs+1+signal_jitter+ifi; %need fake signal time in case i never make it to signal. add1 AFTER multipilication(otherwise i add a day or something); plus ifi because it takes one frame to actually start
loop_time=0;%will track time of loop
signal_started=0;%this is just needed to get the signal going later
pressed=0;%to get while loop going
counter=0;%keeps track of number of loops
nr_signal=0;%to start off with, all dots are random. no signal.
step_size=3.3*deg/85;%0;%5/85*deg;%velocity of dots
displacement=zeros(size(dot_coords));%initialise displacement matrix
missed_onset=0;
dot_colour=white;
tms_started=0;
loop_onset_time=GetSecs;
time_everything=GetSecs-1000;
actual_stim_time=0;
terminate_after_onset=false;%only used if rt <0
if ~isempty(stim_time) && stim_time < 5
    stim_time=5;
end %to make sure theres no tms times less than 5ms
    

%----------------------
%% Big fat loop
%----------------------   
while pressed==0 && loop_time<2+1+signal_jitter %+1 for random noise
    if loop_time > signal_duration+1+signal_jitter && pressed==0
        dot_colour=0; % to end signal, turn dots black
    end
        
    loop_time=GetSecs-loop_onset_time; %tracks how long loop has been going on for
    %tms_baseline = (GetSecs - signal_onset_time)*1000;%stimulus onset
    counter=counter+1;%tracks how often we've gone through loop
 
    %% Draw Dots and Fixation Cross
    Screen('DrawDots', window,dot_coords,4, dot_colour,[],2);      
    cross=15; 
    Screen('FillOval',window,[0 0 0],[x_centre-cross, y_centre-cross,x_centre+cross, y_centre+cross,],40);
    x_coords=[-cross, cross, 0, 0];
    y_coords=[0, 0, -cross, cross];
    coords=[x_coords; y_coords];
    Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
    [vbl,a,b,missed]=Screen('Flip', window,vbl+0.5*ifi);

    %----------------------
    %% Beginning of signal
    %----------------------
    if signal_started==0 && loop_time>1+signal_jitter %as soon as we reach 1 second but only if signal_started is 0
        signal_started=1;%stop loop for next time
        if isempty(easy_hard_condition)% means its not staircase(coherence)
            nr_signal=round(nr_dots * coherence(lvl_coherence));%see which lvl of coherence we want   
        else
            nr_signal=round(nr_dots*lvl_coherence);
        end
    end
    %----------------------
    if signal_started ==1
       signal_onset_time=GetSecs;%now*24*60*60;%get time in seconds (from days)
        % OUTPUT (for EMG marker)
        outp(address,1); 
        signal_started=2;
        %tms_baseline = (GetSecs - signal_onset_time)*1000;
        if terminate_after_onset==true
            WaitSecs(0.01);
            pressed=1;
        end
        %check if we missed the onset flip
        if missed>0
            missed_onset=1;
        else
            missed_onset=0;
        end
    end
    
    Screen('DrawingFinished', window);
    %----------------------
    %% TMS
    %----------------------
    tms_baseline = (GetSecs - signal_onset_time)*1000;
    if ~isempty(stim_time)
        if tms_baseline > stim_time && tms_started==0
            outp(address,2); 
            time_everything=GetSecs; %only happens when actually fired
            actual_stim_time=time_everything-signal_onset_time;
            %outputSingleScan(session2,[0 1]);
            tms_started=1;
            %outputSingleScan(session,[0 0]);
            fprintf(file_time,'\r\n %d \t %f ',trial, time_everything)
        end
    end
    

    %----------------------
    %% Re-randomise
    %----------------------
    if counter/interval==round(counter/interval)
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
            %tried to only test changed one sbut didnt work. try again later. %circle_test=sqrt((power(dot_coords(1,bound)-repmat(x_centre,1,length(bound)),2)+power(dot_coords(2,bound)-repmat(y_centre,1,length(bound)),2)))-rad<=0;%matric of 0s and 1s
            bound=find(circle_test==0);
        end
    else % if not interval loop (we didnt just re-randomise)
        
        %----------------------
        %% Add Displacement
        %----------------------
        if nr_signal ~0;
            if direction==2
                angle=pi/2; %up; angle=0;%right (0 degrees)
            else
                angle= 1.5*pi;% up; angle=pi;%left (180degrees)
            end
            
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

        %check circle
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
            %tried to only test changed one sbut didnt work. try again later. %circle_test=sqrt((power(dot_coords(1,bound)-repmat(x_centre,1,length(bound)),2)+power(dot_coords(2,bound)-repmat(y_centre,1,length(bound)),2)))-rad<=0;%matric of 0s and 1s
            bound=find(circle_test==0);
        end
    end
    
    %----------------------
    %% Response
    %----------------------
    if buttons ==1   
        if sum(ResponseInput)>0%break loop without kb
            if signal_started==2
                pressed=1;
            else %have to get rt here because if we wait until signal onset, their response isnt in the matrix anymore (gets updated all the time)
                terminate_after_onset=true;
                if ResponseInput(1)==1
                    response=1; %direction=right CHECK
                    rt = (ResponseTime - (signal_onset_time - acquisition_start));
                else ResponseInput(2)==1;
                    response=2;
                    rt = (ResponseTime - (signal_onset_time - acquisition_start));
                end
            end
        end
    else
        [pressed, firstPress]=KbQueueCheck;  %pressed: logical pressed or not% firstPress: array with time pressed for each key
    end
end
%--------------------
%% RESPONSE & SAVE
%--------------------
%Record Response
if buttons==1
    if ResponseInput(1)==1
        response=1; %direction=right CHECK
        rt = (ResponseTime - (signal_onset_time - acquisition_start));
    elseif ResponseInput(2)==1;
        response=2;
        rt = (ResponseTime - (signal_onset_time - acquisition_start));
    else
        response=0;
    end
else %keyboard responses
    for k=1:length(firstPress)
        if firstPress(k)~=0
            rt=firstPress(k)-signal_onset_time;
            if KbName(firstPress~=0) =='z'
                response = 2; % direction =left
            elseif KbName(firstPress~=0) == 'm'
                response=1; %direction=right
            else
                response=5;
            end
        end
    end
end
%if no response
if ~pressed
    rt= 2 ;
    accuracy=0;
    response=0;
end 
if response == direction
   accuracy=1;
else
   accuracy=0;
end 
if rt<0
    accuracy=0;
end 

%if they react before the stimulation
if tms_started==0 && ~isempty(stim_time)
    tms_started=5;
end
%just to have results nice and neat
if isempty(stim_time)
    stim_time=0;
end    
%Save to file
if isempty(easy_hard_condition)
    fprintf(file,'\r\n  %d \t %d \t %d \t %d \t %d  \t %f  \t %d  \t %f \t %f \t %d \t %f \t %f',trial,instr, accuracy, response, direction, coherence(lvl_coherence), missed_onset,  rt, signal_jitter,tms_started, stim_time, actual_stim_time*1000);
else
    fprintf(file,'\r\n  %d \t %d \t %d \t %d \t %d  \t %f  \t %d \t %d \t %f \t %f',trial,instr, accuracy, response, direction, lvl_coherence, missed_onset, easy_hard_condition, rt, signal_jitter);
end

%----------------------
%% Weird Function
%----------------------
function weirdfunction(src, event)
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
    %event.Data
end
 outp(address,0);
 [x,y,mousebuttons]=GetMouse([window]);
 if mousebuttons(1)==1
     KbStrokeWait;
     fprintf(file,'\r\n break \r\n');
 end
end