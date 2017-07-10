function handles = OpenDatabase(handles)
% OpenDatabase is called by ReviewInterface when the user selects a new
% database to open. It prompts the user to select the file, then 
% establishes a SQL connection.
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

% Prompt user to select a new database file
Event('UI window opened to select database');
[file, path] = uigetfile('*.db','Select a database to open');

% If a directory was selected
if ~isequal(file, 0)

    % Update DB file name
    handles.config.DATABASE = file;
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Initialize new connection to database
    Event(['Loading database file ', fullfile(path, file)]);
    handles.db = IMRTDatabase(fullfile(path, file));
    
    % Verify database has loaded
    if isempty(handles.db.connection.URL)
        Event(['Could not open connection to ', handles.config.DATABASE, ':', ...
            handles.db.connection.Message], 'ERROR');
    end
else
    Event('User did not select a database');
end

% Clear temporary variables
clear file path;