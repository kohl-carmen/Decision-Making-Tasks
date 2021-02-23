%% task to establish colours perceived to be equally salient

participant='0'

Combs=[1 2];
nr_trials=10*length(Combs);
rng('shuffle')
comb_order=randperm(nr_trials);
comb_order=mod(comb_order,length(Combs))+1;
starting_point=rand(1,nr_trials)/3;
neg=randperm(length(starting_point));
neg=neg(1:length(starting_point)/2);
starting_point(neg)=-starting_point(neg);


%% Psychtoolbox
PsychDefaultSetup(2); 
screen_nr=max(Screen('Screens')); 
white=WhiteIndex(screen_nr);
black=BlackIndex(screen_nr);
[window, window_rect]=PsychImaging('OpenWindow',screen_nr,[0 0 0]);
[x_centre, y_centre]=RectCenter(window_rect); 
ifi=Screen('GetFlipInterval',window); 
Priority(MaxPriority(window));
HideCursor;

%% Screen %CHANGE
% for 57cm distance from screen, 1cm=1degree
% this is for 100cm away from screen (for diff distance use
screen_cm=37;
cm_per_degree = 1.7454 ;
screen_deg=screen_cm / cm_per_degree;
deg=window_rect(3)/screen_deg;%number of pixels per degree



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


collect_V.comb1=[];
collect_V.comb2=[];
for trial=1:nr_trials
    nr_pix_A=(nr_pixels^2)*0.5;
    nr_pix_B=(nr_pixels^2)*0.5;

    pix_AB_tmp=zeros(nr_pixels);
    pix_AB_tmp(1:nr_pix_A)=1;
    
    rng('shuffle');
    order=randperm(nr_pixels^2); 
    pix_AB_tmp=reshape(pix_AB_tmp(order),size(pix_AB_tmp));
    pix_AB_tmp=pix_AB_tmp(order); 

    pix_coords_A=pix_coords((pix_AB_tmp==1),:);
    pix_coords_B=pix_coords((pix_AB_tmp==0),:);

    Comb.comb1.V_A=0.5750;
    Comb.comb1.V_B= 0.6750;
    Comb.comb2.V_A= 0.500;
    Comb.comb2.V_B=0.5000;
    
    Comb.comb1.S_A=0.7497;
    Comb.comb1.S_B= 0.760;
    Comb.comb2.S_A= 0.4520;
    Comb.comb2.S_B=0.5000;
    
    Comb.comb1.H_A=0.58330;
    Comb.comb1.H_B= 0.084550;
    Comb.comb2.H_A= 0.83300;
    Comb.comb2.H_B=0.33000;
    
    comb=comb_order(trial);
    colour_A=hsv2rgb([Comb.(strcat('comb',num2str(comb))).H_A,Comb.(strcat('comb',num2str(comb))).S_A, Comb.(strcat('comb',num2str(comb))).V_A]);
    colour_B=hsv2rgb([Comb.(strcat('comb',num2str(comb))).H_B,Comb.(strcat('comb',num2str(comb))).S_B, (Comb.(strcat('comb',num2str(comb))).V_B+starting_point(trial))]);

    KbQueueCreate;
    KbQueueStart;%reconsider placement if kb is used
    done=0;
    while ~done
        Screen('FillRect', window, colour_A,pix_coords_A'  )
        Screen('FillRect', window, colour_B,pix_coords_B'  )
        Screen('FillRect',window,black, [x_centre-fix_size y_centre-fix_size x_centre+fix_size y_centre+fix_size])
        Screen('Flip', window);

        [pressed, firstPress]=KbQueueCheck;  %pressed: logical pressed or not% firstPress: array with time pressed for each key
        for k=1:length(firstPress)
            if firstPress(k)~=0
                if length(KbName(firstPress~=0))==6 
                    if KbName(firstPress~=0) =='Return'
                        done=1;
                    end
                elseif length(KbName(firstPress~=0))==7
                    if KbName(firstPress~=0) == 'UpArrow'
                        Comb.(strcat('comb',num2str(comb))).V_B=Comb.(strcat('comb',num2str(comb))).V_B+0.05;
                        if Comb.(strcat('comb',num2str(comb))).V_B+starting_point(trial)>1.5
                            Comb.(strcat('comb',num2str(comb))).V_B=1.5-starting_point(trial);
                        end
                        colour_B=hsv2rgb([Comb.(strcat('comb',num2str(comb))).H_B,Comb.(strcat('comb',num2str(comb))).S_B, Comb.(strcat('comb',num2str(comb))).V_B+starting_point(trial)]);
                    end
                elseif length(KbName(firstPress~=0))==9
                    if KbName(firstPress~=0) == 'DownArrow'
                        Comb.(strcat('comb',num2str(comb))).V_B=Comb.(strcat('comb',num2str(comb))).V_B-0.05;
                        if  Comb.(strcat('comb',num2str(comb))).V_B+starting_point(trial) <0.25
                            Comb.(strcat('comb',num2str(comb))).V_B=0.25-starting_point(trial);
                        end
                        colour_B=hsv2rgb([Comb.(strcat('comb',num2str(comb))).H_B,Comb.(strcat('comb',num2str(comb))).S_B, Comb.(strcat('comb',num2str(comb))).V_B+starting_point(trial)]);
                    end
                 end
            end
        end
    end
    collect_V.(strcat('comb',num2str(comb)))=[collect_V.(strcat('comb',num2str(comb))),Comb.(strcat('comb',num2str(comb))).V_B+starting_point(trial)];
end
collect_V_2=collect_V;
save(strcat(participant,num2str(2)),'collect_V_2')
sca