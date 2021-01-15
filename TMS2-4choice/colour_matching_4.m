participant='0'
Cols=[1 2 3 4];
col_order=perms(Cols(2:end));
col_order=[ones(length(col_order),1),col_order];%green fixed;
nr_trials=10*length(col_order);
col_order=repmat(col_order,nr_trials/length(col_order),1);

%either keep A fixed an adjust B. Or: keep one fixed and adjust all 3;
%others?

%% Psychtoolbox

PsychDefaultSetup(2); %psychtoolbox setup (?)
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

%% Screen %CHANGE
% for 57cm distance from screen, 1cm=1degree
% this is for 100cm away from screen (for diff distance use
% tan(angle)=opposite over adjacent(i think) to get angle and then times 2
screen_cm=37;%50;
cm_per_degree = 1.7454 ;
screen_deg=screen_cm / cm_per_degree;%50;
deg=window_rect(3)/screen_deg;%number of pixels per degree

% ORIGINAL COLOUR ORDER

colour1.H=0.3333000;%green
colour2.H= 0;%red
colour3.H= 0.133;%yellow
colour4.H=0.6667;%blue

colour1.S=1;%green
colour2.S= 1;%red
colour3.S= 1;%yellow
colour4.S=0.8;%blue

colour1.V=.6;%green 0.8642
colour2.V=.8;%red
colour3.V= .9;%yellow 1.0933
colour4.V=.8;%blue 0.6667

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

% SAVES in accordance with orignal colour numbers (not colour numbers
% during trials)
% c1== 1st colour during trial --  colour1== 1st colour by definition (=blue)
collect_V.colour1=[];%green
collect_V.colour2=[];%red
collect_V.colour3=[];% yellow
collect_V.colour4=[];% blue
for trial=1:nr_trials
    % INITIALISE PIXEL ORDER 9 FOR ALL COMBOS)
        %2 ----------------
        nr_pix_1=(nr_pixels^2)*0.5;
        nr_pix_2=(nr_pixels^2)*0.5;

        pix_tmp=zeros(nr_pixels);
        pix_tmp(1:nr_pix_1)=1;

        rng('shuffle');
        order=randperm(nr_pixels^2); 
        pix_tmp=reshape(pix_tmp(order),size(pix_tmp));
        pix_tmp=pix_tmp(order); 

        pix_coords_2_1=pix_coords((pix_tmp==1),:);
        pix_coords_2_2=pix_coords((pix_tmp==0),:);
        
        %3 ----------------
        nr_pix_1=(nr_pixels^2)*0.33;
        nr_pix_2=(nr_pixels^2)*0.33;
        nr_pix_3=(nr_pixels^2)*0.34;

        pix_tmp=zeros(nr_pixels);
        pix_tmp(1:nr_pix_1)=1;
        pix_tmp(nr_pix_1+1:nr_pix_1+nr_pix_2)=2;

        rng('shuffle');
        order=randperm(nr_pixels^2); 
        pix_tmp=reshape(pix_tmp(order),size(pix_tmp));
        pix_tmp=pix_tmp(order); 

        pix_coords_3_1=pix_coords((pix_tmp==1),:);
        pix_coords_3_3=pix_coords((pix_tmp==0),:);
        pix_coords_3_2=pix_coords((pix_tmp==2),:);
        
        %4 ----------------
        nr_pix=nan(1,4);
        nr_pix(:)=(nr_pixels^2)*[0.25 0.25 0.25 0.25]; %nr pixels for each colour

        pix_tmp=zeros(nr_pixels); 
        start=0;
        for col=1:4
            pix_tmp(start+1:start+nr_pix(col))=col;
            start=start+nr_pix(col);
        end
        rng('shuffle');
        order=randperm(nr_pixels^2); 
        pix_tmp=reshape(pix_tmp(order),size(pix_tmp));
        pix_tmp=pix_tmp(order); 

        pix_coords_4_1=pix_coords((pix_tmp==1),:);
        pix_coords_4_2=pix_coords((pix_tmp==2),:);
        pix_coords_4_3=pix_coords((pix_tmp==3),:);
        pix_coords_4_4=pix_coords((pix_tmp==4),:);
    %INITILAISE COLOURS
%     colour.(strcat('c',num2str(col_order(trial,1)))).V=0.5750;
%     colour.(strcat('c',num2str(col_order(trial,2)))).V= 0.6750;
%     colour.(strcat('c',num2str(col_order(trial,3)))).V= 0.500;
%     colour.(strcat('c',num2str(col_order(trial,4)))).V=0.5000;
% 
%     colour.(strcat('c',num2str(col_order(trial,1)))).S=0.7497;
%     colour.(strcat('c',num2str(col_order(trial,2)))).S= 0.760;
%     colour.(strcat('c',num2str(col_order(trial,3)))).S= 0.4520;
%     colour.(strcat('c',num2str(col_order(trial,4)))).S=0.5000;
% 
%     colour.(strcat('c',num2str(col_order(trial,1)))).H=0.58330;
%     colour.(strcat('c',num2str(col_order(trial,2)))).H= 0.084550;
%     colour.(strcat('c',num2str(col_order(trial,3)))).H= 0.83300;
%     colour.(strcat('c',num2str(col_order(trial,4)))).H=0.33000;
colour.(strcat('c',num2str(col_order(trial,1)))).V=colour1.V%.8;
colour.(strcat('c',num2str(col_order(trial,2)))).V=colour2.V% .8;
colour.(strcat('c',num2str(col_order(trial,3)))).V=colour3.V% .9;
colour.(strcat('c',num2str(col_order(trial,4)))).V=colour4.V%.6;%0.4;

colour.(strcat('c',num2str(col_order(trial,1)))).S= colour1.S%0.8;
colour.(strcat('c',num2str(col_order(trial,2)))).S= colour2.S%1;
colour.(strcat('c',num2str(col_order(trial,3)))).S=colour3.S% 1;
colour.(strcat('c',num2str(col_order(trial,4)))).S=colour4.S%1;

colour.(strcat('c',num2str(col_order(trial,1)))).H=colour1.H%0.6667;
colour.(strcat('c',num2str(col_order(trial,2)))).H= colour2.H%0;
colour.(strcat('c',num2str(col_order(trial,3)))).H=  colour3.H%0.1333;
colour.(strcat('c',num2str(col_order(trial,4)))).H= colour4.H%0.3333;
    
    
    KbQueueCreate;
    KbQueueStart;%reconsider placement if kb is used
    done=0;
    return_press=1;
    while ~done 
        colours=[];
        for i=1:4
            colours=[colours;hsv2rgb([colour.(strcat('c',num2str(i))).H colour.(strcat('c',num2str(i))).S  colour.(strcat('c',num2str(i))).V])];
        end
        if return_press==1
            %% 2 COLOURS
            Screen('FillRect', window, colours(1,:),pix_coords_2_1'  )
            Screen('FillRect', window, colours(2,:),pix_coords_2_2'  )
            Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
            Screen('Flip', window);
        elseif return_press==2
            Screen('FillRect', window, colours(1,:),pix_coords_3_1'  )
            Screen('FillRect', window, colours(2,:),pix_coords_3_2'  )
            Screen('FillRect', window, colours(3,:),pix_coords_3_3'  )
            Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
            Screen('Flip', window);
        elseif return_press==3
            Screen('FillRect', window, colours(1,:),pix_coords_4_1'  )
            Screen('FillRect', window, colours(2,:),pix_coords_4_2'  )
            Screen('FillRect', window, colours(3,:),pix_coords_4_3'  )
            Screen('FillRect', window, colours(4,:),pix_coords_4_4'  )
            Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
            Screen('Flip', window);
        end

        [pressed, firstPress]=KbQueueCheck;  %pressed: logical pressed or not% firstPress: array with time pressed for each key
        for k=1:length(firstPress)
            if firstPress(k)~=0
                if length(KbName(firstPress~=0))==6 
                    if KbName(firstPress~=0) =='Return'
                        %selected one:
                        collect_V.(strcat('colour',num2str(find(col_order(trial,:)==return_press+1))))=[collect_V.(strcat('colour',num2str(find(col_order(trial,:)==return_press+1)))),colour.(strcat('c',num2str(return_press+1))).V];  
                        return_press=return_press+1;
                        if return_press==4
                            done=1;
                            %fixed one(starting colour):
                        collect_V.(strcat('colour',num2str(find(col_order(trial,:)==1))))=[collect_V.(strcat('colour',num2str(find(col_order(trial,:)==1)))), nan];
                        end
                    end
                elseif length(KbName(firstPress~=0))==7
                    if KbName(firstPress~=0) == 'UpArrow'
                        colour.(strcat('c',num2str(return_press+1))).V=colour.(strcat('c',num2str(return_press+1))).V+0.05;
                        if colour.(strcat('c',num2str(return_press+1))).V>1.5
                           colour.(strcat('c',num2str(return_press+1))).V=1.5;
                        end
                    end
                elseif length(KbName(firstPress~=0))==9
                    if KbName(firstPress~=0) == 'DownArrow'
                        colour.(strcat('c',num2str(return_press+1))).V=colour.(strcat('c',num2str(return_press+1))).V-0.05;
                        if  colour.(strcat('c',num2str(return_press+1))).V <0.25
                            colour.(strcat('c',num2str(return_press+1))).V=0.25;
                        end
                     end
                 end
            end
        end
    end
end

%% End choice
Screen('TextSize',window, 20);
Screen('TextFont',window,'Times');
text='Result:';
DrawFormattedText(window,text,'center',100,[1 1 1]);
if isnan(nanmean(collect_V.colour1))
   collect_V.colour1(1)=colour1.V;
end
    
colours=nan(4,3);
colours(1,:)=hsv2rgb([colour1.H, colour1.S, nanmean(collect_V.colour1)]);
colours(2,:)=hsv2rgb([colour2.H, colour2.S, nanmean(collect_V.colour2)]);
colours(3,:)=hsv2rgb([colour3.H, colour3.S, nanmean(collect_V.colour3)]);
colours(4,:)=hsv2rgb([colour4.H, colour4.S, nanmean(collect_V.colour4)]);
Screen('FillRect', window, colours(1,:),pix_coords_4_1'  )
Screen('FillRect', window, colours(2,:),pix_coords_4_2'  )
Screen('FillRect', window, colours(3,:),pix_coords_4_3'  )
Screen('FillRect', window, colours(4,:),pix_coords_4_4'  )
Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
Screen('Flip', window);
KbStrokeWait;
sca
save(participant,'collect_V')