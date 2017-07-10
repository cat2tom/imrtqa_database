function handles = ExportCSV(handles)
% ExportCSV is called by ReviewInterface when the user selects to export 
% the database to a CSV file.
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
Event('UI window opened to select export path');
path = uigetdir(handles.path, ...
    'Select the directory of export the database to');

% If a directory was selected
if ~isequal(path, 0)

    % Start timer
    t = tic;
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Export delta4, tomo, linac, and mobius tables
    tables = {'delta4', 'linac', 'tomo', 'mobius'};
    for i = 1:length(tables)
        Event(['Exporting ', tables{i}, ' table contents to ', ...
            fullfile(path, [tables{i}, '.csv'])]);
        handles.db.exportCSV(tables{i}, fullfile(path, [tables{i}, '.csv']));
    end

    % Display message box and log event
    Event(sprintf('Tables exported successfully to %s in %0.3f seconds', ...
        path, toc(t)));
    msgbox(sprintf('Tables exported successfully to %s', path), ...
        'Export Completed');
    
else
    Event('User did not select a path');
end

