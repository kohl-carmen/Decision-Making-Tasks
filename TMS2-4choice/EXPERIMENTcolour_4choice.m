function colour
 
RUNTHROUGH=4;
Practice=[1 2 3 0] ;
% 1: start really easy and go down. 4 choice only.no distractors.feedback. targets stay on for first 10 trials
% 2: start really easy and go down. 2 and 4 choice only.no distractors.feedback.
% 3: like task but with feedback
participant=input('participant:');
age=input('age:');
gender=input('gender: ','s');
%Stimulus Settings
nr_trials_per_cond=1; % 
nr_trials_per_block=50;
nr_practice_trials=50;
%% Output

%results file    
directory=strcat(cd, '\',num2str(participant),'_results.txt'); % create path(cd=current directory)
File=fopen(directory,'a'); % opens for appending; File1=handle
fprintf(File, '\r\n Trial \t Target \t Alt \t Acc \t Resp  \t Diff  \t  DomCol \t DistCol \t RT \t RT from target \t TMS \t stim time \t actual stim time \t array-target \n');%just to give my following columns headings
%practice file
details_directory=strcat(cd, '\',num2str(participant),'_details.txt'); % create path(cd=current directory)
File2=fopen(details_directory,'a');   
fprintf(File2, '\r\n \r\n %s ', datestr(now));
fprintf(File2, '\r\n Participant: %d \n Age: %d \n Gender: %s \n ', participant, age, gender);
fprintf(File2, '\r\n Trial \t Target \t Alt \t Acc \t Resp  \t Diff  \t  DomCol \t DistCol \t RT \t RT from target \t TMS \t stim time \t actual stim time \t array-target \n');%just to give my following columns headings

%tms time file
tms_file=fopen(strcat(cd,'\',num2str(participant),'_tms.txt'),'a');
    
%% Psychtoolbox
PsychDefaultSetup(2); %psychtoolbox setup 
screen_nr=max(Screen('Screens')); % returns max. of vector for number of screens
%define black & white
white=WhiteIndex(screen_nr);
black=BlackIndex(screen_nr);
%Open window, define centre, set priroty
[window, window_rect]=PsychImaging('OpenWindow',screen_nr,[0 0 0]);%opens black screen
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
if window_rect(4)>768 %| ifi<0.011 | ifi>0.012
   sca;
   disp('Check Screen Resolution (1204x768) and Refresh Rate (85Hz)');
end
        
%% Screen %CHANGE
% for 57cm distance from screen, 1cm=1degree
% this is for 100cm away from screen (for diff distance use
screen_cm=37;
cm_per_degree = 1.7454 ;
screen_deg=screen_cm / cm_per_degree;;
deg=window_rect(3)/screen_deg;%number of pixels per degree


%% DESIGN
Trial_Time=2;
fix_time=0.5;
target_time=0.5;
Distraction=0;
clear

Dominant=[1,2,3,4]; 
Alt={'4AFC', '2AFCw', '2AFCb'};
Alt_txt={'AFC4','AFC2w1','AFC2w2','AFC2b1','AFC2b2'}; %only to save names later

Difficulty=[0.3, 0.33]; 

% TMS
%now stimulations hould start only 200ms befor the dot onset
tms_in_target_interval=200;
target_time_for_tms_onset=target_time*1000-tms_in_target_interval;
RTMean=700+tms_in_target_interval;
tms_bins=linspace(RTMean/4,RTMean,4)+target_time_for_tms_onset;
tms_bins=[tms_bins,zeros(1,3)];%add zeros for non-TMS trials
bin_interval=tms_bins(2)-tms_bins(1);%returns length of one bin


nr_altcond=length(Alt);
nr_difficulty=length(Difficulty); 
nr_dominant=length(Dominant);
nr_distraction=length(Distraction);
nr_conditions=nr_difficulty*nr_dominant*nr_distraction; 
nr_trials=nr_difficulty*nr_altcond*nr_dominant*length(tms_bins)*nr_trials_per_cond; 

%% Setup Visual
pixel_size= 2;
nr_pixels= round(6*deg/2);% size 6 degrees of visaul angle 
size_box=pixel_size*nr_pixels;
%counterbalance colours between people?
colours=[hsv2rgb([0.3333 1 .6]);hsv2rgb([0 1 mean([.8642 .7692 .7575])]);hsv2rgb([0.1333  1  mean([1.0933 0.9117 .7667])]);hsv2rgb([0.666667  0.8    mean([0.6667 0.63333 .5167])])];
colour_txt={'green','red','yellow','blue'};
possible_orders=perms(Dominant); %max24
try
    colour_order=possible_orders(participant,:);
catch
    colour_order=possible_orders(randi(length(possible_orders)),:);
    colour_order=possible_orders(1,:);
end
colour1=colours(colour_order(1),:);
colour2=colours(colour_order(2),:);
colour3=colours(colour_order(3),:);
colour4=colours(colour_order(4),:);
coords_box=[x_centre-size_box/2 y_centre-size_box/2 x_centre+size_box/2 y_centre+size_box/2];
fix_size=5;
count=0;
for i=1:nr_pixels
    for j=1:nr_pixels
        count=count+1;
        pix_coords(count,:)=[coords_box(1)+ pixel_size*(i-1) coords_box(2)+pixel_size*(j-1) coords_box(1)+ pixel_size*i coords_box(2)+pixel_size*j];
    end
end
%target
target_size=30;
distance_from_corner=300;
topleft_coords=[window_rect(1)+distance_from_corner, window_rect(2)+distance_from_corner/3*2];
topright_coords=[window_rect(3)-distance_from_corner, window_rect(2)+distance_from_corner/3*2];
bottomleft_coords=[window_rect(1)+distance_from_corner, window_rect(4)-distance_from_corner/3*2];
bottomright_coords=[window_rect(3)-distance_from_corner, window_rect(4)-distance_from_corner/3*2];
target_coords.target_order_0=[topleft_coords(1), topright_coords(1), bottomleft_coords(1), bottomright_coords(1); topleft_coords(2), topright_coords(2), bottomleft_coords(2), bottomright_coords(2)];
target_coords.target_order_1=[ topleft_coords(1), bottomleft_coords(1); topleft_coords(2), bottomleft_coords(2)];
target_coords.target_order_2=[topright_coords(1), bottomright_coords(1); topright_coords(2), bottomright_coords(2)];
target_coords.target_order_3=[topleft_coords(1), topright_coords(1); topleft_coords(2), topright_coords(2)];
target_coords.target_order_4=[bottomleft_coords(1), bottomright_coords(1); bottomleft_coords(2), bottomright_coords(2)];
target_colours.target_order_0=[colour1;colour2;colour3;colour4]';
target_colours.target_order_1=[colour1;colour3]';
target_colours.target_order_2=[colour2;colour4]';
target_colours.target_order_3=[colour1;colour2]';
target_colours.target_order_4=[colour3;colour4]';



for runthrough=RUNTHROUGH
    practice=Practice(runthrough);
%% Randomise Order 
rng('shuffle');
order=randperm(nr_trials); 
conditions=ceil(order/nr_trials_per_cond);
bin_order= mod(conditions,length(tms_bins))+1;
dominant_order=mod(conditions,length(Dominant))+1;
alt_order=mod(conditions,length(Alt))+1;
temp_order=ceil(conditions/length(Dominant));
diff_order=mod(temp_order,length(Difficulty))+1;
% now I have 3 conditions (4AFC, 2AFCwithin 2AFCbetween) and need to
% searate the two 2AFCs out into two different direction-combos

Alt_txt_directions.AFC4=Dominant; % 1 2 3 4
Alt_txt_directions.AFC2within.One={'topleft' 'bottomleft'};% 1 3
Alt_txt_directions.AFC2within.Two={'topright' 'bottomright'}; % 2 4
Alt_txt_directions.AFC2between.One={'topleft' 'topright'}; % 1 2
Alt_txt_directions.AFC2between.Two={'bottomleft' 'bottomright'}; % 3 4

%so we need to split 2AFC conditions into 2 each (do it using directions.
%so where dir is one or two, it becomes AFC2_.One, if dir is 3 or 4, it
%becomes AFC2_.Two
target_order=zeros(1,length(conditions));%0=4choice
target_order(alt_order==2 & dominant_order<3)= 1; %1: Alt_txt_directions.AFC2within.One
target_order(alt_order==2 & dominant_order>=3)= 2; %2: Alt_txt_directions.AFC2within.Two
target_order(alt_order==3 & dominant_order<3)= 3; %3: Alt_txt_directions.AFC2between.One
target_order(alt_order==3 & dominant_order>=3)= 4; %4: Alt_txt_directions.AFC2between.Two


%now change directions accordingly
%for 1: (2AFCwithin.One[dir 1 and 3]) are represented by directions 1 and 2
%for now. So chnage 2 to 3
dominant_order(target_order==1 & dominant_order==2)=3;
%for 2: (2AFCwithin.Two[dir 2 and 4]) are represented by directions 3 and 4
%for now. so change 3 to 2
dominant_order(target_order==2 & dominant_order==3)=2;
%for 3: (AFCbetween.One [dir 1 and 2] are representen by directions 1 and
%2 already
%for 3: (AFCbetween.Two [dir 3 and 4] are representen by directions 3 and
%4 already

                            %to test order
                             %big_order=[conditions',dir_order', coh_order',bin_order',target_order']; 
                             %save('big_order1', 'big_order')
                             
%                              big_order=[alt_order',target_order',dir_order',coh_order',bin_order']
%                 
%                               a=1;
%                             while a>0
%                                 a=0;
%                                 for i=1:length(big_order)-1
%                                     if big_order(i+1,2)<big_order(i,2)
%                                         smaller=big_order(i+1,:);
%                                         bigger=big_order(i,:);
%                                         big_order(i+1,:)=bigger;
%                                         big_order(i,:)=smaller;
%                                         a=1;
%                                     end
%                                 end
%                             end
                            %save('big_order1_sorted', 'big_order')

%% Welcome Screen
if runthrough==1
Screen('TextSize',window, 20);
Screen('TextFont',window,'Times');
text='Welcome! \n\n \n\n  You will be presented with an array of \n \n red, green, blue, and yellow pixels.  \n\n  We''d like you to identify which of the colours is  \n\n most valent and press the matching button.\n\n ';
instruction_coords=[window_rect(1)+100, window_rect(3)-100, window_rect(1)+100, window_rect(3)-100; window_rect(2)+100/3*2,window_rect(2)+100/3*2,window_rect(4)-100/3*2, window_rect(4)-100/3*2];
DrawFormattedText(window,'Left Pinch',instruction_coords(1,1)-50,instruction_coords(2,1)+50,white)
DrawFormattedText(window,'Right Pinch',instruction_coords(1,2)-60,instruction_coords(2,2)+50,white)
DrawFormattedText(window,'Left Grasp',instruction_coords(1,3)-50,instruction_coords(2,3)-80,white)
DrawFormattedText(window,'Right Grasp',instruction_coords(1,4)-60,instruction_coords(2,4)-80,white)
DrawFormattedText(window,text,'center','center',white);
Screen('DrawDots', window,instruction_coords,target_size, target_colours.(strcat('target_order_',num2str(0))))
            
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait;%waits for user to press any key 
end

Screen('TextSize',window, 20);
Screen('TextFont',window,'Times');
if practice
    text=strcat('Practice ', num2str(practice));
else
    text='Experiment';
end
instruction_coords=[window_rect(1)+100, window_rect(3)-100, window_rect(1)+100, window_rect(3)-100; window_rect(2)+100/3*2,window_rect(2)+100/3*2,window_rect(4)-100/3*2, window_rect(4)-100/3*2];
DrawFormattedText(window,'Left Pinch',instruction_coords(1,1)-50,instruction_coords(2,1)+50,white)
DrawFormattedText(window,'Right Pinch',instruction_coords(1,2)-60,instruction_coords(2,2)+50,white)
DrawFormattedText(window,'Left Grasp',instruction_coords(1,3)-50,instruction_coords(2,3)-80,white)
DrawFormattedText(window,'Right Grasp',instruction_coords(1,4)-60,instruction_coords(2,4)-80,white)
DrawFormattedText(window,text,'center','center',white);
Screen('DrawDots', window,instruction_coords,target_size, target_colours.(strcat('target_order_',num2str(0))))
vbl=Screen('Flip',window);%flip to screen
KbStrokeWait;%waits for user to press any key 


 %TMS_timing: <0.2Hz
 most_recent_tms_time=[];
 shuffle_counter=0;
 fake_trial_counter=0;
 trial=1;
 %for feedback
 accuracy_tracker=[];
 rt_tracker=[];
 if practice
     conditions=conditions(1:nr_practice_trials);%controls how many trials are given
     bin_order=ones(1,nr_practice_trials)*7;%no tms
 end
     
while trial<=length(conditions)
    fake_trial=false;
    %% TMS
    tms_bin=tms_bins(bin_order(trial));
     if tms_bin>0 
          stim_time=randi([tms_bin-bin_interval,tms_bin], [1 1]);
          if stim_time < 5
              stim_time=5;
          end
          if ~isempty(most_recent_tms_time) && GetSecs+1+stim_time/1000-most_recent_tms_time<5 %if too close (last tms has to be at least 5 away from now+fixation+next stimtime)
              %shuffle:
              switch_trial=find(bin_order(trial:end)>4,1)+trial-1;%%% CHANGE IF BINS CHANGE!!!!!!!(this only works if bins bigger than 4 are 0
              if ~isempty(switch_trial)
                  shuffle_counter=shuffle_counter+1;
                  temp1=bin_order(switch_trial);
                  temp2=diff_order(switch_trial);
                  temp3=dominant_order(switch_trial);
                  temp4=target_order(switch_trial);
                  temp5=conditions(switch_trial);

                  bin_order(switch_trial)=bin_order(trial);
                  diff_order(switch_trial)=diff_order(trial);
                  dominant_order(switch_trial)=dominant_order(trial);
                  target_order(switch_trial)=target_order(trial);
                  conditions(switch_trial)=conditions(trial);
                  
                  target_order(trial)=temp4; 
                  dominant_order(trial)=temp3;
                  diff_order(trial)=temp2;
                  bin_order(trial)=temp1;
                  conditions(trial)=temp5;
              else %no trials left to shuffle
                  %move skipped trial to end:
                  bin_order(end+1)=bin_order(trial);
                  diff_order(end+1)=diff_order(trial);
                  dominant_order(end+1)=dominant_order(trial);
                  target_order(end+1)=target_order(trial);
                  conditions(end+1)=conditions(trial);
                  %make up fake one
                  fake_trial_counter=fake_trial_counter+1;
%                   dominant_order(trial)=randi(4,[1,1]);
                  target_order(trial)=randi(5,[1,1])-1;
                  %pick dom based on target:
                  switch target_order(trial)
                      case 0
                          possible_doms=[1 2 3 4];   
                      case 1 %target 1 -> 2 within -> has to be colour 1 or 3
                          possible_doms=[1 3];   
                      case 2
                          possible_doms=[2 4];
                      case 3
                          possible_doms=[1 2];
                      case 4 
                          possible_doms=[3 4];
                  end
                  pick=randi(length(possible_doms),[1,1]);
                  dominant_order(trial)= possible_doms(pick);
                  
                  
                  diff_order(trial)=randi(2,[1,1]);
                  bin_order(trial)=length(tms_bins);   
                  fake_trial=true;
              end
              stim_time=[];
          end
     else
          stim_time=[];
     end
     
    %% Pick trial visual
    target=target_order(trial); 
    Diff=Difficulty(diff_order(trial));
    dom=Dominant(dominant_order(trial));

    if practice<3 & practice>0 %no distractor in practice
        if practice==1
            target=0;
        end
        if trial<nr_practice_trials/3
            Diff=0.45;
        elseif trial<nr_practice_trials/3*2
            Diff=0.35;
        else
            Diff=Diff; %normal easy/hard
        end
        diff=nan(1,4);
        diff(:)=(1-(Diff))/3;     
        diff(dom)=Diff;
        dis_col=0;
    else
        %pcik distractor colour
        Cols=Dominant;
        Cols(dom)=[];
        %dis_col=Cols(randi(3,[1,1]));
    %         diff(:)=((1-Diff)/4);
    %         diff(dom)=Diff;       
    %         diff(dis_col)=((1-Diff)/4)*2; % so the distractor colour is just the colour that'll be dominant in two trials time (thats just now bs)
    %        
        diff=nan(1,4);
        %diff(:)=(1-(Diff+(Diff-Diff/5)))/2;
        diff(:)=(1-(Diff))/3;
        diff(dom)=Diff;
        %diff(dis_col)=Diff-Diff/5;   
        dis_col=0;
        diff
    end
        
        
    nr_pix=nan(1,4);
    nr_pix(:)=(nr_pixels^2)*diff(:); %nr pixels for each colour

    pix_tmp=zeros(nr_pixels); 
    start=0;
    for col=Dominant
        pix_tmp(start+1:start+nr_pix(col))=col;
        start=start+nr_pix(col);
    end
    
    rng('shuffle');
    order=randperm(nr_pixels^2); 
    pix_tmp=reshape(pix_tmp(order),size(pix_tmp));
    pix_tmp=pix_tmp(order); 
    
    pix_coords1=pix_coords((pix_tmp==1),:);
    pix_coords2=pix_coords((pix_tmp==2),:);
    pix_coords3=pix_coords((pix_tmp==3),:);
    pix_coords4=pix_coords((pix_tmp==4),:);
    
    


    %% Response tracking
    session = daq.createSession('ni');
    %addAnalogInputChannel(session,'dev1',0:3,'Voltage'); %to use AI 0 to 3
    
    %because I need to stick so many cables in, go for AI 0,1, 4,5 instead
    addAnalogInputChannel(session,'dev1',[0,1,4,5],'Voltage'); %to use AI 0,1,3,4
    
    session.Rate = 62500;
    %'rate connat exceed 62500 in the current configuration' 100000;% sampling rate (how many times it checks the status of the channels per second). channels are either 0 or 5 (5 when pressed) but never exactly those
    session.NotifyWhenDataAvailableExceeds = 2 .* round(ifi.*session.Rate); %1667; % notify every 200 or so samples. gives me a matrix with 0s and times of those 0s
    session.IsContinuous = true;%keeps overwriting the matrix with the zeros continuously
    lh = session.addlistener('DataAvailable',@monitor_response); %listener class defines listenever objects(lh) which respond to the specidied event ('datavailable') and identify the callback function to invoke when the event is triggered
    startBackground(session);   %acquisition trigger
    start_monitoring=GetSecs;
    ResponseTime = 0;
    ResponseInput = zeros(1,4);
    outp(address,0);
    %before I put it to 0 here and to 1 for trigger but for some reason it
     
    whole_trial_onset_time=GetSecs;
    trial_time=0;
    whole_trial_time=0;
    pressed=0;
    array_onset_time=0;
    target_onset_time=0;
    tms_started=0;
    actual_stim_time=0;
    array_loop=0;
    fix_loop=0;
    target_loop=0;
    while pressed==0 && whole_trial_time<=Trial_Time+fix_time+target_time
%         loop_counter=loop_counter+1;%tracks how often we've gone through loop
        whole_trial_time=GetSecs-whole_trial_onset_time;
        if whole_trial_time<fix_time-ifi
            fix_loop=fix_loop+1;
            %fix dot
            Screen('FillRect',window,[0.5 0.5 0.5], [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
            vbl=Screen('Flip',window,vbl+0.5*ifi);    
            if fix_loop==1
                whole_trial_onset_time=GetSecs;
            end
        elseif (whole_trial_time<fix_time+target_time-ifi) & trial_time< target_time-ifi
            target_loop=target_loop+1;
            %target
            Screen('DrawDots', window,target_coords.(strcat('target_order_',num2str(target))),target_size, target_colours.(strcat('target_order_',num2str(target))))
            Screen('FillRect',window,[0.5 0.5 0.5], [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
            vbl=Screen('Flip',window,vbl+0.5*ifi);  
            if target_loop==1
                target_onset_time=GetSecs;
                array_onset_time=target_onset_time+target_time ; %fake onset time in case i never reach it
                outp(address,1); 
            else
                trial_time=GetSecs-target_onset_time; %tracks how long loop has been going on for
            end
            
            %% Response
            if sum(ResponseInput)>0%break loop without kb
                pressed=1; 
            end
        else
            trial_time=GetSecs-target_onset_time;
            if practice & trial <=10
                Screen('DrawDots', window,target_coords.(strcat('target_order_',num2str(target))),target_size, target_colours.(strcat('target_order_',num2str(target))))
            end
            %task
            array_loop=array_loop+1;
            Screen('FillRect', window, colour1,pix_coords1'  )
            Screen('FillRect', window, colour2,pix_coords2'  )
            Screen('FillRect', window, colour3,pix_coords3'  )
            Screen('FillRect', window, colour4,pix_coords4'  )
            Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
            vbl=Screen('Flip',window,vbl+0.5*ifi); 
            if array_loop==1
                array_onset_time=GetSecs;
            end
            

            %% Response
            if sum(ResponseInput)>0%break loop without kb
                pressed=1; 
            end
        end
         %----------------------
        %% TMS
        %----------------------
        if ~isempty(stim_time)
            if trial_time*1000 >= stim_time && tms_started==0
                outp(address,2); 
                actual_stim_time=(GetSecs-target_onset_time);
                tms_started=1;
                most_recent_tms_time=GetSecs;
                fprintf(tms_file,'\r\n %d \t %f ',trial, most_recent_tms_time);
            end
        end
    end
    
    [x,y,mousebuttons]=GetMouse([window]);
     if mousebuttons(1)==1
         KbStrokeWait;
     end
    %--------------------
    %% RESPONSE & SAVE
    %--------------------
    %Record Response
    response=0;
        if ResponseInput(1)==1
            response=1; 
        elseif ResponseInput(2)==1;
            response=2;
        elseif ResponseInput(3)==1;
            response=3;
        elseif ResponseInput(4)==1;
            response=4;
        end
        rt = (ResponseTime - (array_onset_time -  start_monitoring));% ResponseTime is given by event.Timestamp, which starts counting as soon as i start monitoring. But i want the time from the loop_onset only. So i subtract the difference from the ResponseTime to get real RT
        rt_from_target=(ResponseTime - (target_onset_time -  start_monitoring));

        %if no response
        if ~pressed
            rt= Trial_Time ;
            rt_from_target=Trial_Time+target_time;
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
    
        if fake_trial==false
            trial_nr=trial-fake_trial_counter;
        else
            trial_nr=0;
        end
        if practice
           fprintf(File2,'\r\n  %d \t %d \t %s \t %d \t %d  \t %d \t %d \t %d \t %f \t %f \t %d \t %d \t %f \t %f ', trial_nr,target, strcat('(',Alt_txt{target+1},')'), accuracy,response, round(Diff*100), dom, dis_col,rt*1000, (rt_from_target)*1000, tms_started, stim_time, actual_stim_time*1000, (array_onset_time-target_onset_time)*1000);
        else
            if isempty(stim_time)
                stim_time_to_save=0;
            else
                stim_time_to_save=stim_time;
            end
           fprintf(File,'\r\n  %d \t %d \t %s \t %d \t %d  \t %d \t %d \t %d \t %f \t %f \t %d \t %d \t %f \t %f ', trial_nr,target, strcat('(',Alt_txt{target+1},')'), accuracy,response, round(Diff*100), dom, dis_col,rt*1000, (rt_from_target)*1000, tms_started, stim_time_to_save, actual_stim_time*1000, (array_onset_time-target_onset_time)*1000);
        end
        
           %BREAK 
         if (trial/nr_trials_per_block==round(trial/nr_trials_per_block) & (nr_trials+fake_trial_counter)-trial>15 ) & ~practice %(so it doesnt break when theres less than 15 trials left)
            Screen('TextSize',window, 30);
            Screen('TextFont',window,'Times');
            text=sprintf(' Break \n \n \n \n Accuracy: %d %% \n \n Response Time: %d ms ', round(mean(accuracy_tracker)*100), round(mean(rt_tracker)*1000));
            DrawFormattedText(window,text,'center','center',white);
            vbl=Screen('Flip',window,vbl+0.5*ifi);
            KbStrokeWait;
            accuracy_tracker=[];
            rt_tracker=[];
         end
     
        
        if practice
            %% Feedback
            if accuracy==0
                feedback='Incorrect';
            else
                feedback=strcat('Correct');
            end
            Screen('TextSize',window, 30);
            Screen('TextFont',window,'Times');
            DrawFormattedText(window,feedback,'center','center',white);
            vbl=Screen('Flip',window,vbl+0.5*ifi);
            pause(0.5); 
        end
        Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])   
        vbl=Screen('Flip',window,vbl+0.5*ifi);
        
          %screen
          if trial==length(conditions)
              if practice
                  text=sprintf('  Accuracy: %d %% \n \n Response Time: %d ms ', round(mean(accuracy_tracker)*100), round(mean(rt_tracker)*1000));
              else
                  text=sprintf(' Thank You! \n \n  \n \n Accuracy: %d %% \n \n Response Time: %d ms ', round(mean(accuracy_tracker)*100), round(mean(rt_tracker)*1000));
              end
            Screen('TextSize',window, 30);
            Screen('TextFont',window,'Times');
            DrawFormattedText(window,text,'center','center',white);
            vbl=Screen('Flip',window,vbl+0.5*ifi);
            KbStrokeWait;
            accuracy_tracker=[];
            rt_tracker=[];
         end
        
        trial=trial+1;
end
  
end
%----------------------
%% Listener Function
%----------------------
function monitor_response(src, event)
   %event.Data
     %need to find out when TimeStamps starts counting
     % it looks for whats going on on my channels ever ms and puts it into event.Data. So in there, I have one column for each channel, and when a button is pressed, the numbers in that column go up to 5 
    if any(event.Data(:,1) > 3) %AI 0 (pinch)
        ResponseInput(1) = 1;% so if the first channel is ever 5 (is pressed), we set responseinput 1 to 1
        first_response=min(find(event.Data(:,1)>3));
        ResponseTime = event.TimeStamps(first_response,1);
    else
        ResponseInput(1) = 0;           
    end
    if any(event.Data(:,2) > 3)%AI 1 (pinchII)
        ResponseInput(2) = 1;
        first_response=min(find(event.Data(:,2)>3));
        ResponseTime = event.TimeStamps(first_response,1);
     else
        ResponseInput(2) = 0;
    end
    if any(event.Data(:,3) > 3)%AI 2 (grip)
        ResponseInput(3) = 1;
        first_response=min(find(event.Data(:,3)>3));
        ResponseTime = event.TimeStamps(first_response,1);
     else
        ResponseInput(3) = 0;
     end
     if any(event.Data(:,4) > 3)%AI 3 (gripII)
        ResponseInput(4) = 1;
        first_response=min(find(event.Data(:,4)>3));
        ResponseTime = event.TimeStamps(first_response,1);
     else
        ResponseInput(4) = 0;
     end
     
end
ShowCursor;
daq.reset;
fclose('all');
sca

    
    
end
    
    
    
    