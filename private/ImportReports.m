function handles = ImportReports(handles)
% ImportReports is called by ReviewInterface when the user selects to scan
% a directory for new reports to import.
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

% Open a dialog box for the user to select a directory
Event('UI window opened to select QA reports path');
path = uigetdir(handles.path, ...
    'Select the directory of IMRT QA reports to scan');

% If a directory was selected
if ~isequal(path, 0)

    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Retrieve list of reports and types
    ScanReports(path, 'db', handles.db, 'server', handles.server, ...
        'machines', handles.machines);
   
    % Update database summary table
    handles = UpdateSummary(handles);
    
    % Update plots
    plots = cellstr(get(handles.plot_types,'String'));
    PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
        plots{get(handles.plot_types,'Value')}, 'range', ...
        [handles.range_low, handles.range_high], 'stats', ...
        handles.plot_stats);
    clear plots;
   
else
    Event('User did not select a path');
end

