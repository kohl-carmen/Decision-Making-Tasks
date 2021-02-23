function [quest_output_75, quest_output_95]=StaircaseFunction(coherence_order, direction_order, x_centre, y_centre, window, white,ifi,window_rect,buttons,deg,File3)
%Staircase to establish thresholds (75 and 95%)

%% Staircase Instructions
Screen('TextFont',window,'Times');
Screen('TextSize',window, 20);
text='Well done! \n\n \n\n In the following trials, the duration of the movement will be a little shorter. \n\n Like before, please look at the fixation cross in the middle of the screen \n\n and indicate the direction of the movement \n\n  using the right (=up) and left (=down) responses.';
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);
KbStrokeWait;
              
%% Initialise Staircase Stuff
instr=0;
signal_duration=0.3;
stair_trials_per_cond=100;
practice_trials=10;%ich you change this, change break
stair_trials=practice_trials+(2*stair_trials_per_cond);
BetaValue = 3.5; %SLOPE. Watson&Pelli recommend 3.5 for 2AFC (was 5 before?)
DeltaValue = 0.01;%upper limit (Watson&Pelli approved)
%Randomise order
easy_hard_order=randperm(stair_trials);
easy_hard_order=ceil(easy_hard_order/stair_trials_per_cond);

%q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,[grain],[range],[plotIt])
% creates structure q with paameters for Weidbull psychometric function p2=delta*gamma+(1-delta)*(1-(1-gamma)*exp(-10.^(beta*(x-xThreshold))))
q_75=QuestCreate(0.2,0.2,0.75,BetaValue,DeltaValue,0.5);
q_95=QuestCreate(0.4,0.2,0.95,BetaValue,DeltaValue,0.5);

trial_coherence_75=0.2;
trial_coherence_95=0.4;

%% Trial Loop
for trial=1:stair_trials

    %take appropriate conditions from randomisation 
    direction=direction_order(trial); %direcions randomly drawn. not part of initial randomisation
    easy_hard_condition=easy_hard_order(trial); % 1=easy
    
    if easy_hard_condition==1
        trial_coherence=trial_coherence_95;
    else
        trial_coherence=trial_coherence_75;
    end
    
    if trial_coherence <0.01
        trial_coherence=0.01;
    elseif trial_coherence>0.99
        trial_coherence=0.99;
    end
    
    lvl_coherence=trial_coherence;
    fixation(window,white,x_centre,y_centre); %fixation cross function

    par2.lvl_coherence=lvl_coherence;
    par2.direction=direction;
    par2.coherence=[];%vector with all possible lvls of coherence
    par2.x_centre=x_centre;
    par2.y_centre=y_centre;
    par2.window=window;
    par2.white=white;
    par2.File3=File3;
    par2.vbl=vbl;
    par2.ifi=ifi;
    par2.trial=trial;
    par2.buttons=buttons;
    par2.deg=deg;
    par2.signal_duration=signal_duration;
    par2.instr=instr;
    par2.easy_hard_condition=easy_hard_condition;
    par2=struct2cell(par2);

    [rt, accuracy, response]=TrialLoop(par2{:});
     
    %% Feedback
    %Delay
    Screen(window,'FillRect',0);
    cross=15; %length of arms
    x_coords=[-cross, cross, 0, 0];
    y_coords=[0, 0, -cross, cross];
    coords=[x_coords; y_coords];
    Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
    Screen('Flip', window);
    WaitSecs(0.3);
    % Give points
    if accuracy==1;
        feedback='Correct';
    else
        feedback='Incorrect';
    end
    feedback_colour=0;
    text_colour=white;
    text_size=30;
    %Text setting
    Screen(window,'FillRect',feedback_colour);
    Screen('TextSize',window, text_size);
    Screen('TextFont',window,'Times');
    points_text=sprintf(' %s ', feedback);
    DrawFormattedText(window,points_text,'center','center',text_colour);
    Screen('Flip',window);
    WaitSecs(0.7);
    Screen(window,'FillRect',0);
    Screen('Flip',window);
    
    %% Break
    if trial/110==round(trial/110)
        Screen('TextSize',window, 30);
        Screen('TextFont',window,'Times');
        points_text=sprintf(' Break ');
        DrawFormattedText(window,points_text,'center','center',white);
        Screen('Flip',window);
        KbStrokeWait;
    end
            
    %% STAIRCASE
    if trial>practice_trials
        if response ~ 0
           if easy_hard_condition==1
               q_95=QuestUpdate(q_95,trial_coherence,accuracy);
               trial_coherence_95=QuestQuantile(q_95);
           else
               q_75=QuestUpdate(q_75,trial_coherence,accuracy);
               trial_coherence_75=QuestQuantile(q_75);   
           end
        end
    end

end

quest_output_75=QuestMean(q_75);
quest_output_95=QuestMean(q_95);

if quest_output_75 > 0.99
    quest_output_75= 0.99;
elseif quest_output_75 < 0.01
    quest_output_75=0.01;
end

if quest_output_95 > 0.99
    quest_output_95=0.99;
elseif quest_output_95<0.01
    quest_output_95=0.01;
end

%% End Staircase Screen
Screen(window,'FillRect',feedback_colour);
Screen('TextSize',window, 20);
Screen('TextFont',window,'Times');
points_text=sprintf('Well done! \n\n \n\n Now let''s start the reaction time task. \n\n From now on, you only have a limited time to respond. \n\n There will be further instructions to explain what exactly we want you to do.\n\n \n\n Threshold75: %f \n\n Threshold95: %f', quest_output_75, quest_output_95);
DrawFormattedText(window,points_text,'center','center',text_colour);
Screen('Flip',window);
KbStrokeWait;

end