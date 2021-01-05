function fixation(window,colour,x_centre,y_centre)
%creates fixation cross (using Screen('DrawLines'))        
cross=15; 
%coords (relative to set centre)
x_coords=[-cross, cross, 0, 0];
y_coords=[0, 0, -cross, cross];
coords=[x_coords; y_coords];
%Draw Lines
Screen('DrawLines', window, coords,2, colour, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
Screen('Flip', window);
jitter=rand*(0.2-0.001)+0.001; %rand=uniform distribution (between 100 and 200ms)
WaitSecs(0.5+jitter);%
end
