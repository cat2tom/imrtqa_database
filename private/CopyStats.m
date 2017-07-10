function CopyStats(handle)
% CopyStats is called by ReviewInterface and saves the provided table
% handle contents to the clipboard.
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

% Retrieve table contents
table = vertcat(get(handle, 'ColumnName')', get(handle, 'Data'));

% Remove "show" column
table = horzcat(table(:,1), table(:,3:end));

% Create tab delimited char array of table contents
str = [];
for i = 1:size(table,1)
    r = sprintf('%s\t', table{i,:});
    r(end) = sprintf('\n');
    str = [str r]; %#ok<AGROW>
end
clipboard('copy', str);

% Display message box
msgbox('Plot statistics have been copied to the clipboard', ...
    'Copy Statistics');

% Clear temporary variables
clear table str i r;

