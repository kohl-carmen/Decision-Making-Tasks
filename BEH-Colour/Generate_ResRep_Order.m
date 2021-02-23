function [Order, Cond_txt]=Generate_RespRep_Order(Order_length)

%% Generate Trial Order for Response Repetition Experiment

% Experiment: Colour Discrimination Task with 2 colours. (2 colour
% combinations, e.g. red vs green, blue vs yellow -> never intermixed)
% possible trials: 
       %% Number Colour_Combination  Correct_Response
        %   1        comb1               right
        %   2        comb1               left
        %   3        comb2               right
        %   4        comb2               left
% Conditions soley determined by sequence of trials.
% Conditions
        % - Full Repetition (same comb, same resp) [1 1; 2 2; 3 3; 4 4]
        % - Full Alt (different comb, different resp) [1 4; 2 3; 3 2; 4 1];
        % - Resp Repetition (different comb, same resp) [1 3; 2 4; 3 1; 4 2]
        % - Stim Repetition (same comb, diff resp) [1 2; 3 4; 2 1; 4 3]

        
        
%% -----------------------------------------------------------------------
rng('shuffle');
% all possible combinations of sequences        
Seq.combos=[1 1; 1 2; 1 3; 1 4; 2 1; 2 2; 2 3; 2 4; 3 1; 3 2; 3 3; 3 4; 4 1; 4 2; 4 3; 4 4];
Seq.counts=zeros(length(Seq.combos),1);

Fill=nan(1,length(Seq.counts));
Trials=[1:4];

Max_count_per_combo=Order_length/(length(Trials))/4;% for 800 Trials (200 per rep condition), I want 50 per sequence (50x[1 1],50x [2 2]....)

remix=1; % just in case we need to start over
remix_count=0;
while remix
    Seq.counts=zeros(length(Seq.combos),1);
    remix_count=remix_count+1;
    remix=0;
%% Create sequence;
temp_seq=nan(1,2);
Order=nan(Order_length,1);
%pick first one randomly out of Trials
Order(1)=randi(max(Trials));
for order_i=2:Order_length
    %pick next random
    Order(order_i)=randi(max(Trials)); 
    %check what you picked (compare against sequences and check if we need more of those)
    temp_seq=[Order(order_i-1), Order(order_i)];
    temp_combo=find(sum(repmat(temp_seq,length(Seq.combos),1)== Seq.combos,2)==2);
    if Seq.counts(temp_combo)<Max_count_per_combo 
        Seq.counts(temp_combo)=Seq.counts(temp_combo)+1;
    else % if we already have all of those, exclude that trial from the possible selection and do the same thing again
        while_count=0;
        while Seq.counts(temp_combo)>=Max_count_per_combo 
            while_count=while_count+1;
            if while_count==1
                Temp_Trials=Trials;
                Temp_Trials(Order(order_i)) =[]; %exclude the one I just picked from the ones to be selected and draw again
            else
                Temp_Trials(Temp_Trials==Order(order_i)) =[];
            end
            try
                Order(order_i)=Temp_Trials(randi((length(Temp_Trials)))); 
            catch
                %There's an off-chance that the sequence will just get
                %stuck because it got awkward by chance (not enough trials
                %left to get sequence right), so then we just start over
                remix=1;
                break 
            end
            %recheck
            temp_seq=[Order(order_i-1), Order(order_i)];
            temp_combo=find(sum(repmat(temp_seq,length(Seq.combos),1)== Seq.combos,2)==2);
%             if while_count%>length(Trials)
%                 disp('fix me, I got stuck')
%                 return
%             end
        end
        if remix==1
            break
        end
        Seq.counts(temp_combo)=Seq.counts(temp_combo)+1;
    end
    
    %just to see when the numbers get filled
    for k=1:16
        if  Seq.counts(k)==Max_count_per_combo & isnan(Fill(k))
            Fill(k)=order_i;
        end
    end
end
end  
%Fill

%test how many same in a row
same_count=0;
same_count_max=0;
same_count_counter=0;
for i=1+1:length(Order)-700
    if Order(i)==Order(i-1)
        same_count=same_count+1;
    else
        if same_count>0
            if same_count>=5
                same_count_counter=same_count_counter+1;
                if same_count> same_count_max
                    same_count_max=same_count;
                end
            end
            same_count=0;
        end
    end
end


%give labels
Cond_txt={};
for i=2:length(Order)
    if Order(i)==Order(i-1)
        Cond_txt{i}='Full_Rep';
    else
    switch Order(i)
        case 1
            switch Order(i-1)
                case 2
                    Cond_txt{i}='Stim_Rep';
                case 3
                    Cond_txt{i}='Resp_Rep';
                case 4
                    Cond_txt{i}='Full_Alt';
            end
        case 2
            switch Order(i-1)
                case 1
                    Cond_txt{i}='Stim_Rep';
                case 3
                    Cond_txt{i}='Full_Alt';
                case 4
                    Cond_txt{i}='Resp_Rep';
            end
        case 3
            switch Order(i-1)
                case 1
                    Cond_txt{i}='Resp_Rep';
                case 2
                    Cond_txt{i}='Full_Alt';
                case 4
                    Cond_txt{i}='Stim_Rep';
            end
        case 4
            switch Order(i-1)
                case 1
                    Cond_txt{i}='Full_Alt';
                case 2
                    Cond_txt{i}='Resp_Rep';
                case 3
                     Cond_txt{i}='Stim_Rep';
            end
    end
    end
end

%sanity check
Full_Rep_count=0;
Full_Alt_count=0;
Resp_Rep_count=0;
Stim_Rep_count=0;
for i=2:length(Order)   
    if Cond_txt{i}=='Full_Rep'
        Full_Rep_count=Full_Rep_count+1;
    elseif Cond_txt{i}=='Full_Alt'
        Full_Alt_count=Full_Alt_count+1;
    elseif Cond_txt{i}=='Resp_Rep'
        Resp_Rep_count=Resp_Rep_count+1;
    elseif Cond_txt{i}=='Stim_Rep'
        Stim_Rep_count=Stim_Rep_count+1;
    end
end



%% different method: Just shuffle and count sequences and shuffle again til you got it
%% use this to check order (uncomment once)
% % shuf=1
% % count=0
% % while shuf%randomise a
% %     count=count+1
% %     shuf=0;
% % %rng('shuffle');
% % order=randperm(length(a)); 
% % a=a(order);

try
    a=Order;
catch
end
R11=0;R12=0;R13=0;R14=0;R21=0;R22=0;R23=0;R24=0;R31=0;R32=0;R33=0;R34=0;R41=0;R42=0;R43=0;R44=0;
temp=nan(1,2);
for i=1:length(a)-1
    temp(1)=a(i);
    temp(1,2)=a(i+1);
    if temp==[1,1]
        R11=R11+1;
        elseif temp==[2,2]
        R22=R22+1;
        elseif temp==[3,3]
        R33=R33+1;
        elseif temp==[4,4]
        R44=R44+1;
        elseif temp==[1,4]
        R14=R14+1;
        elseif temp==[2,3]
        R23=R23+1;
        elseif temp==[3,2]
        R32=R32+1;
        elseif temp==[4,1]
        R41=R41+1;
        elseif temp==[1,3]
        R13=R13+1;
        elseif temp==[2,4]
        R24=R24+1;
        elseif temp==[3,1]
        R31=R31+1;
        elseif temp==[4,2]
        R42=R42+1;
        elseif temp==[1,2]
        R12=R12+1;
        elseif temp==[3,4]
        R34=R34+1;
        elseif temp==[2,1]
        R21=R21+1;
        elseif temp==[4,3]
        R43=R43+1;
    end
    
    o=4;
end
% % if R11>=o & R12>=o & R13>=o & R14>=o & R21>=o & R22>=o & R23>=o & R24>=o & R31>=o & R32>=o & R33>=o & R34>=o & R41>=o & R42>=o & R43>=o & R44>=o & R11<o+2 & R12<o+2 & R13<o+2 & R14<o+2 & R21<o+2 & R22<o+2 & R23<o+2 & R24<o+2 & R31<o+2 & R32<o+2 & R33<o+2 & R34<o+2 & R41<o+2 & R42<o+2 & R43<o+2 & R44<o+2 
% % else
% %     shuf=1;
% % end
% % end
end