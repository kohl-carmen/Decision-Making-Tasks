function [rt, accuracy,response]=TrialLoop(lvl_coherence,direction,coherence, x_centre,y_centre,window, white,file,vbl,ifi,trial,buttons,deg,signal_duration,instr,easy_hard_condition)
% EEG VERSION
if buttons==1
    %Set Parallel port options for sending digital signal (uses scripts and mex file in
    %IO64_parallelport folder on Matlab path, plus drivers (inpoutx64.dll) in
    %c:\windows\system32
    config_io;
    address = hex2dec('D010'); %This is the address of the parallel port. You can get
    %this number (in hexidecimal) by going to control panel > device manager,
    %expanding "ports", finding the parallel port, and looking in "resources"
    %(from its properties)

    %Set up national instruments input/output card using commands from the
    %data acquisition toolbox. This stuff only works with NI hardware.
    session = daq.createSession('ni');
    %http://uk.mathworks.com/help/daq/ref/adddigitalchannel.html#btjdzmh-1

    %addDigitalChannel(session2,'dev1', 'Port0/Line8:9', 'OutputOnly'); %for EEG/EMG markers and TMS
    addAnalogInputChannel(session,'dev1',0:1,'Voltage'); %use 0:1 for two channel, etc. (for analog: 'session.addAnalog..(dev)')

    session.Rate = 100000;%sampling rate (how many times it checks the status of the channels per second). channels are either 0 or 5 (5 when pressed) but never exactly those
    session.NotifyWhenDataAvailableExceeds = 2 .* round(ifi.*session.Rate); %1667; %notify every 200 or so samples. gives me a matrix with 0s and times of those 0s
    session.IsContinuous = true;%keeps overwriting the matrix with the zeros continuously

    lh = session.addlistener('DataAvailable',@listenerfunction); %calls a callback function (see bottom bit)
    startBackground(session);   %acquisition trigger
    Trigger2=GetSecs; %psychtoolbox baseline
    ResponseTime = 0;
    ResponseInput = zeros(1,2);

    outp(address,0);

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
marker=0; %for practice and staircase ?
if instr==1%speed
    marker=10;
elseif instr==2%acc
    marker=20;
end
dot_marker=marker+1;

if lvl_coherence==1
    if direction==1
        signal_marker=marker+2;
    elseif direction==2;
        signal_marker=marker+3;
    end
else
    if direction==1
        signal_marker=marker+4; 
    elseif direction==2;
        signal_marker=marker+5;
    end
end

signal_jitter=gamrnd(1,150)/1000;
while signal_jitter > 1;
    signal_jitter=gamrnd(1,150)/1000;
end
signal_onset_time=GetSecs+1+signal_jitter+ifi; %need fake signal time in case i never make it to signal. add1 AFTER multipilication(otherwise i add a day or something);
loop_time=0;%will track time of loop
signal_started=0;%this is just needed to get the signal going later
pressed=0;%to get while loop going
counter=0;%keeps track of number of loops
nr_signal=0;%to start off with, all dots are random. no signal.
step_size=3.3*deg/85;%0;%5/85*deg;%velocity of dots
displacement=zeros(size(dot_coords));%initialise displacement matrix
missed_onset=0;
dot_colour=white;
loop_onset_time=GetSecs;

%----------------------
%% Big fat loop
%----------------------
while pressed==0 && loop_time<2+1+signal_jitter %+1 for random noise     
    if loop_time > signal_duration+1+signal_jitter && pressed==0
       dot_colour=0;
    end
    loop_time=GetSecs-loop_onset_time; %tracks how long loop has been going on for
    counter=counter+1;%tracks how often we've gone through loop

    %% Draw Dots and Fixation Cross
    Screen('DrawDots', window,dot_coords,4, dot_colour,[],2);      
    cross=15; %length of arms
    Screen('FillOval',window,[0 0 0],[x_centre-cross, y_centre-cross,x_centre+cross, y_centre+cross,],40);
    x_coords=[-cross, cross, 0, 0];
    y_coords=[0, 0, -cross, cross];
    coords=[x_coords; y_coords];
    Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
    [vbl,a,b,missed]=Screen('Flip', window,vbl+0.5*ifi);

    
%     	imageArray = Screen('GetImage', window);
% 
% 	%imwrite is a Matlab function, not a PTB-3 function
% 	imwrite(imageArray, 'test.jpg')
    
    %Dot onset marker
    if counter==1 && buttons==1
        outp(address,dot_marker);
    end
    if counter==2 
        outp(address,0);
    end
%             	imageArray = Screen('GetImage', window);
% 
% 	%imwrite is a Matlab function, not a PTB-3 function
% 	imwrite(imageArray, 'dot7.jpg')

    %----------------------
    %% Beginning of signal
    %----------------------
    if signal_started==0 && loop_time>1+signal_jitter %as soon as we reach 1 second but only if signal_started is 0
        signal_started=1;%stop loop for next time
        if isempty(easy_hard_condition)% means its staircase(coherence)
            nr_signal=round(nr_dots * coherence(lvl_coherence));%see which lvl of coherence we want
        else
            nr_signal=round(nr_dots*lvl_coherence);
        end
    end
    %%----------------------
 
    if signal_started ==1
        signal_onset_time=GetSecs;%now*24*60*60;%get time in seconds (from days)
        %% OUTPUT
        if buttons==1
            outp(address,signal_marker);
        end
                    
        signal_started=2;
        if missed>0
            missed_onset=1;
        else
            missed_onset=0;
        end
    end
    Screen('DrawingFinished', window);
    
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
            . %circle_test=sqrt((power(dot_coords(1,bound)-repmat(x_centre,1,length(bound)),2)+power(dot_coords(2,bound)-repmat(y_centre,1,length(bound)),2)))-rad<=0;%matric of 0s and 1s
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
            %circle_test=sqrt((power(dot_coords(1,bound)-repmat(x_centre,1,length(bound)),2)+power(dot_coords(2,bound)-repmat(y_centre,1,length(bound)),2)))-rad<=0;%matric of 0s and 1s
            bound=find(circle_test==0);
        end
    end
    
    %----------------------
    %% Response
    %----------------------
    if buttons ==1   
        if sum(ResponseInput)>0%break loop without kb
            pressed=1;
        end
    else
        
        [pressed, firstPress]=KbQueueCheck;
        %pressed: logical pressed or not
        % firstPress: array with time pressed for each key
    end
end
%--------------------
%% RESPONSE & SAVE
%--------------------
%Record Response
if buttons==1
    if ResponseInput(1)==1
        ResponseTime
        signal_onset_time
        acquisition_start
        (signal_onset_time - acquisition_start)
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

%Save to file
if isempty(easy_hard_condition)
    fprintf(file,'\r\n  %d \t %d \t %d \t %d \t %d  \t %f \t %d  \t %f \t %f',trial,instr, accuracy, response, direction, coherence(lvl_coherence), missed_onset,  rt, signal_jitter);
else
    fprintf(file,'\r\n  %d \t %d \t %d \t %d \t %d  \t %f  \t %d \t %d \t %f \t %f',trial,instr, accuracy, response, direction, lvl_coherence, missed_onset, easy_hard_condition, rt, signal_jitter);
end

%----------------------
%% Listener Function
%----------------------

function listenerfunction(src, event)
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
if buttons==1
    outp(address,0);
end

[x,y,mousebuttons]=GetMouse([window]);
if mousebuttons(1)==1
    KbStrokeWait;
    fprintf(file,'\r\n break \r\n');
end

end