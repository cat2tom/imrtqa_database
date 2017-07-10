function handles = SavePlot(handles)
% SavePlot is called by ReviewInterface when the user clicks "Save Plot",
% and saves the current plot to file.
% 
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2017 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Retrieve string text for plots and ranges
plots = cellstr(get(handles.plot_types, 'String'));
ranges = cellstr(get(handles.range, 'String'));

% Prompt user to select a file to save the plot to
Event('UI window opened to save plot');
[file, path] = uiputfile([plots{get(handles.plot_types, 'Value')}, '.png'], ...
    'Save plot as');

% If a directory was selected
if ~isequal(file, 0)

    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Open new figure
    f = figure('Color', [1 1 1], 'Position', [100 100 400 300]);
    figure(f);

    % Plot data in new figure
    PlotData('parent', f, 'db', handles.db, 'type', ...
        get(handles.plot_types,'Value'), 'range', [handles.range_low, ...
        handles.range_high], 'stats', handles.plot_stats);
    
    % Add title to plot
    set(f, 'NextPlot', 'add');
    axes('FontSize', 12, 'FontName', 'Arial');
    h = title(sprintf('%s, %s\n', plots{get(handles.plot_types, 'Value')}, ...
        ranges{get(handles.range, 'Value')}));
    set(gca, 'Visible', 'off');
    set(h, 'Visible', 'on');
    
    % Save plot
    set(f, 'PaperUnits', 'centimeters');
    set(f, 'PaperPosition', [0 0 20 15]);
    saveas(f, fullfile(path, file));

    % Close figure
    close(f);
    
    % Display message box
    msgbox(sprintf('Figure exported successfully to %s', file), ...
        'Save Completed');
else
    Event('User did not select a save file');
end

% Clear temporary variables
clear file path plots ranges f a;


