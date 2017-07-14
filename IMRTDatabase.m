classdef IMRTDatabase
    
% Requires database toolbox
    
% Object variables
properties
    connection
end

% Functions
methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function obj = IMRTDatabase(db)
    % Constructor function

        % Add SQLite JDBC driver (current database is 3.8.5)
        javaaddpath('./sqlite-jdbc-3.8.5-pre1.jar');
    
        % Verify database file exists
        if exist(db, 'file') == 2
        
            % Store database, username, and password
            obj.connection = database(db, '', '', 'org.sqlite.JDBC', ...
                ['jdbc:sqlite:',db]);

            % Set the data return format to support strings
            setdbprefs('DataReturnFormat', 'cellarray');
        else
            if exist('Event', 'file') == 2
                Event(['The SQLite3 database file is missing: ', db], ...
                    'ERROR');
            else
                error(['The SQLite3 database file is missing: ', db]);
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function close(obj)
        
        % Close the database
        close(obj.connection);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = countReports(obj, varargin)
    % Returns the size of the QA report cell array based on an optional 
    % machine name

        % If a type was not provided
        if nargin == 1

            % Return the size of the delta4 table
            sql = 'SELECT COUNT(uid) FROM delta4';
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = cursor.Data{1};
            close(cursor);
            
        % Otherwise, count only the given type
        else
         
            % Return the size of the delta4 table
            sql = ['SELECT COUNT(uid) FROM delta4 WHERE machinetype = ''', ...
                varargin{1}, ''''];
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = cursor.Data{1};
            close(cursor);
        end
        
        % Clear temporary variables
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = countMatchedRecords(obj)
    % Returns the number of records in the reports tables that contain 
    % linked plan data
        
        % Return the size of the delta4 table
        sql = ['SELECT COUNT(uid) FROM delta4 WHERE linacuid IS NULL AND', ...
            ' tomouid IS NULL'];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        n = cursor.Data{1};
        sql = 'SELECT COUNT(uid) FROM delta4';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor); 
        n = 1 - n/cursor.Data{1};
        close(cursor);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = countPlans(obj, varargin)
    % Returns the size of the plan cell array based on an optional 
    % table and/or SQL where statement

        % If a type was not provided
        if nargin == 1

            % Query the size of the tomo table
            sql = 'SELECT COUNT(uid) FROM tomo';
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = cursor.Data{1};
            
            % Query the size of the linac table
            sql = 'SELECT COUNT(uid) FROM linac';
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = n + cursor.Data{1};
            close(cursor);
            
        % Otherwise, count only the given type
        else
         
            % Return the size of the listed table
            sql = ['SELECT COUNT(uid) FROM ', varargin{1}];
            
            % Add where statement
            if nargin == 3
                sql = [sql, ' WHERE ', varargin{2}];
            end
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = cursor.Data{1};
            close(cursor);
        end
        
        % Clear temporary variables
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function data = queryColumns(obj, varargin)
    % Returns an array of associated database parameters within the set 
    % filter range given a list of table/column pairs. If multiple columns
    % are queried, only results that include matching data (across all
    % tables/columns are returned). Note, the first table/column must be a 
    % report table that contains uid reference columns to the other tables.
   
        % Loop through the arguments, prepending the table name to the col
        sql = 'SELECT ';
        for i = 1:2:nargin-1
            if strcmpi(varargin{i}, 'where')
                varargin{i+2} = [varargin{i+1}, '.', varargin{i+2}];
                break;
            else
                varargin{i+1} = [varargin{i}, '.', varargin{i+1}];
                sql = [sql, varargin{i+1}, ', '];
            end
        end
        
        % Initialize SQL query string
        sql = [sql(1:end-2), ' FROM ', varargin{1}];
        
        % Initialize join flag
        where = false;

        % Add join statements if second db doesn't match first one
        for i = 3:2:nargin-1
            if strcmpi(varargin{i}, 'where')
                if where
                    sql = [sql, ' AND ', varargin{i+2}];
                else
                    sql = [sql, ' WHERE ', varargin{i+2}];
                    where = true;
                end

                if length(varargin{i+3}) == 1
                    sql = [sql, ' = ''', strrep(varargin{i+3}, '''', ''), ...
                        ''''];
                elseif length(varargin{i+3}) == 2
                    sql = [sql, ' > ', sprintf('%0.32f', varargin{i+3}(1)), ...
                        ' AND ', varargin{i+2}, ' < ', ...
                        sprintf('%0.32f', varargin{i+3}(2))];
                else
                    if exist('Event', 'file') == 2
                        Event('Invalid format for WHERE clause', 'ERROR');
                    else
                        error('Invalid format for WHERE clause');
                    end
                end
                break;
            elseif ~strcmp(varargin{i-2}, varargin{i})
                where = true;
                sql = [sql, ' LEFT JOIN ', varargin{i}, ' ON ', varargin{i}, ...
                    '.uid = ', varargin{1}, '.', varargin{i}, 'uid']; %#ok<*AGROW>
            end
        end
        
        % Add where statements
        if where
            sql = [sql, ' AND ', varargin{2}, ' IS NOT NULL'];
        else
            sql = [sql, ' WHERE ', varargin{2}, ' IS NOT NULL'];
        end
        sql = [sql, ' AND ', varargin{2}, ' <> ''NaN'''];
        
        for i = 3:2:nargin-1
            if strcmpi(varargin{i}, 'where')
                break;
            else
                sql = [sql, ' AND ', varargin{i+1}, ' IS NOT NULL'];
                sql = [sql, ' AND ', varargin{i+1}, ' <> ''NaN'''];
            end
        end
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);
        if strcmp(cursor.Data, 'No Data')
            data = [];
        else
            data = cursor.Data;
        end
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function data = queryRecords(obj, table, varargin)
    % Returns an array of name/value structure pairs from a specified table
    % that matches one or more provided column name/value pairs.
    
        % Retrieve column names and data types
        sql = ['PRAGMA table_info(', table, ')'];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        cols = cursor.Data;
        
        % Initialize select statement
        sql = ['SELECT ', strjoin(cols(:,2), ', '), ' FROM ', table];
        
        % If where arguments are provided
        if nargin >= 4
            
            % Add first where statement
            if ~isempty(varargin{2})
                sql = [sql, ' WHERE ', varargin{1}, ' = ''', ...
                    strrep(varargin{2}, '''', ''), ''''];
            else
                sql = [sql, ' WHERE ', varargin{1}, ' IS NULL'];
            end
            
            % Add subsequent where statements
            for i = 3:2:nargin-2
                if ~isempty(varargin{i+1})
                    sql = [sql, ' AND ', varargin{i}, ' = ''', ...
                        strrep(varargin{i+1}, '''', ''), ''''];
                else
                    sql = [sql, ' AND ', varargin{i}, ' IS NULL'];
                end
            end
        end
        
        % Execute query
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);
        
        % Store return data a cell array of structures
        if ~strcmp(cursor.Data{1,1}, 'No Data')
            data = cell(size(cursor.Data,1),1);
            for i = 1:size(cursor.Data,1)
                for j = 1:size(cols,1)
                    data{i}.(cols{j,2}) = cursor.Data{i,j};
                end
            end
        else
            data = cell(0);
        end
        
        % Clear temporary variables
        clear sql cursor cols;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function deleteRecords(obj, table, varargin)
    % Returns an array of name/value structure pairs from a specified table
    % that matches one or more provided column name/value pairs.
        
        % Initialize select statement
        sql = ['DELETE FROM ', table];
        
        % If where arguments are provided
        if nargin >= 4
            
            % Add first where statement
            sql = [sql, ' WHERE ', varargin{1}, ' = ''', ...
                strrep(varargin{2}, '''', ''), ''''];
            
            % Add subsequent where statements
            for i = 3:2:nargin-2
                
                sql = [sql, ' AND ', varargin{i}, ' = ''', ...
                    strrep(varargin{i+1}, '''', ''), ''''];
            end
        end
        
        % Execute delete
        exec(obj.connection, sql);
        
        % Clear temporary variables
        clear sql;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function matchRecords(obj, table1, table2, range)
    % Searches for records in table1 that matches table2 within the same
    % range. Users will be prompted with listdlg inputs with the
    % opportunity to match records
    
        % Initialize select statement
        sql = ['SELECT ', table1, '.id, ', table1, '.uid, ', table1, ...
            '.plan, ', table1, '.plandate, ', table2, '.plan, ', table2, ...
            '.plandate, ', table2, '.uid FROM ', table1, ' LEFT JOIN ', table2, ' ON ', ...
            table1, '.id = ', table2, '.id AND ', table1, '.measdate > ', ...
            table2, '.plandate-', sprintf('%0.3f', range/24), ' AND ', ...
            table1, '.measdate < ', table2, '.plandate+', ...
            sprintf('%0.3f', range/24), ' WHERE ', table2, '.plan IS NOT ', ...
            'NULL AND ', table1, '.', table2, 'uid IS NULL'];
        
        % Execute query
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);
        data = cursor.Data;
        
        % Loop through results
        i = 1;
        while i <= length(data)
            
            % Add option to not match anything
            opts = cell(2,2);
            opts{1,1} = 'Do not match';
            
            % Add first option
            opts{2,1} = [data{i,5}, ' (', datestr(data{i,6}), ')'];
            opts{2,2} = data{i,7};
            
            % Add remaining options
            for j = i+1:length(data)
                if strcmp(data{i,1}, data{j,1}) && strcmp(data{i,3}, ...
                        data{j,3}) && data{i,4} == data{j,4}
                   opts{size(opts,1)+1,1} = [data{j,5}, ' (', ...
                       datestr(data{j,6}), ')'];
                   opts{size(opts,1),2} = data{j,7};
                else
                    i = j-1;
                    break;
                end
            end
            
            % Open listdlg
            [s, ok] = listdlg('PromptString', ['One or more ', table2, ...
                ' plans matched the ', table1, ' QA report for patient ', ...
                data{i,1}, ' plan ', data{i,3}, ' (', datestr(data{i,4}), ...
                '):'], 'SelectionMode', 'single',...
                'ListString', opts(:,1), 'ListSize', [600 100]);
            
            % Parse response
            if ok
                if s > 1
                    sql = ['UPDATE ', table1, ' SET ', table2, 'uid = ''', ...
                        opts{s,2}, ''' WHERE uid = ''', data{i,2}, ''''];
                    exec(obj.connection, sql);
                end
            else
                break;
            end
            
            % Update index
            i = i + 1;
        end
        
        % Display completion
        if ok
            msgbox('All QA reports have been matched to RT plans');
        end
        
        % Clear temporary variables
        clear sql cursor data opts i j s ok;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateRecords(obj, table, colnames, data, varargin)
    % Updates one or more table column names with data where the row
    % matches one or more provided column name/value pairs.
   
        % If where arguments are provided
        sql = '';
        if nargin >= 6
            
            % Add first where statement
            sql = [sql, ' WHERE ', varargin{1}, ' = ''', ...
                strrep(varargin{2}, '''', ''), ''''];
            
            % Add subsequent where statements
            for i = 3:2:nargin-4
                
                sql = [sql, ' AND ', varargin{i}, ' = ''', ...
                    strrep(varargin{i+1}, '''', ''), ''''];
            end
        end
        
        % Update table
        update(obj.connection, table, colnames, data, sql);
        
        % Clear temporary variables
        clear sql;
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = fileExists(obj, file)
    % Retrieves the high and low filter ranges 
        
        % Query the record based on the patient ID, plan, and date
        sql = ['SELECT COUNT(fullfile) FROM scannedfiles WHERE fullfile = ''', ...
            file, ''''];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        n = cursor.Data{1};
        close(cursor);
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function addScannedFile(obj, file)
        
        % Insert row into database
        datainsert(obj.connection, 'scannedfiles', {'fullfile'}, {file});
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [low, high] = recordRange(obj)
    % Retrieves the range of timestamps for plan
        
        % Query the highest and lowest plan dates from delta4 table
        sql = 'SELECT MIN(plandate), MAX(plandate) FROM delta4';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        low = cursor.Data{1};
        high = cursor.Data{2};
        
        % Query the highest and lowest plan dates from tomo table
        sql = 'SELECT MIN(plandate), MAX(plandate) FROM tomo';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        low = min(low, cursor.Data{1});
        high = max(high, cursor.Data{2});
        
        % Query the highest and lowest plan dates from linac table
        sql = 'SELECT MIN(plandate), MAX(plandate) FROM linac';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        low = min(low, cursor.Data{1});
        high = max(high, cursor.Data{2});
        
        % Query the highest and lowest plan dates from mobius table
        sql = 'SELECT MIN(plandate), MAX(plandate) FROM mobius';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        low = min(low, cursor.Data{1});
        high = max(high, cursor.Data{2});
        
        close(cursor);
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = dataExists(obj, record, type)
    % Searches the database for a record of given type, returning 0 or 1    
    
        % Initialize return variable
        n = 0;
        
        % Query table based on record type
        switch type
            
        case 'delta4'

            % If the fields exist
            if isfield(record, 'ID') && isfield(record, 'plan') && ...
                    isfield(record, 'planDate')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM delta4 WHERE id = ''', ...
                    record.ID, ''' AND plan = ''', record.plan, ''' AND ', ...
                    'plandate = ''', sprintf('%0.10f', ...
                    datenum(record.planDate)), ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
            end

        case 'tomo'

            % If the tomo_extract fields exist
            if isfield(record, 'patientID') && isfield(record, 'planLabel') && ...
                    isfield(record, 'timestamp')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM tomo WHERE id = ''', ...
                    record.patientID, ''' AND plan = ''', ...
                    record.planLabel, ''' AND plandate = ''', ...
                    sprintf('%0.10f', datenum(record.timestamp)), ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
               
            % Otherwise, if the RT plan fields exist
            elseif isfield(record, 'PatientID') && isfield(record, 'RTPlanName') ...
                    && isfield(record, 'RTPlanDate') ...
                    && isfield(record, 'RTPlanTime')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM tomo WHERE id = ''', ...
                    record.PatientID, ''' AND plan = ''', record.RTPlanName, ...
                    ''' AND plandate = ''', sprintf('%0.10f', ...
                    datenum([record.RTPlanDate, '-', record.RTPlanTime], ...
                    'yyyymmdd-HHMMSS')), ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
            end

        case 'linac'

            % If the fields exist
            if isfield(record, 'PatientID') && isfield(record, 'RTPlanName') ...
                    && isfield(record, 'RTPlanDate') ...
                    && isfield(record, 'RTPlanTime')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM linac WHERE id = ''', ...
                    record.PatientID, ''' AND plan = ''', record.RTPlanName, ...
                    ''' AND plandate = ''', sprintf('%0.10f', ...
                    datenum([record.RTPlanDate, '-', record.RTPlanTime], ...
                    'yyyymmdd-HHMMSS')), ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
            end

        case 'mobius'

            % If the fields exist
            if isfield(record, 'settings')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM mobius WHERE id = ''', ...
                    record.settings.planInfo_dict.Patient.PatientID, ...
                    ''' AND plan = ''', ...
                    record.settings.planInfo_dict.RTGeneralPlan.RTPlanName, ...
                    ''' AND plandate = ''', sprintf('%0.10f', datenum(...
                    [record.settings.planInfo_dict.RTGeneralPlan.RTPlanDate, ...
                    '-', ...
                    record.settings.planInfo_dict.RTGeneralPlan.RTPlanDate])), ...
                    ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
            end

        otherwise
            n = 0;
        end
        
        % Clear cursor
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function uid = addRecord(obj, record, type, varargin)
    % Adds a record of given type to the database     
        
        % Initialize data cell array
        data = cell(0);
        uid = [];
    
        % Query table based on record type
        switch type
            
        case 'delta4'

            % Generate cell array of table columns and data
            data{1,1} = 'uid';
            if nargin == 4
                uid = varargin{1};
            else
                uid = dicomuid;
            end
            data{1,2} = uid;
            data{2,1} = 'id';
            if isfield(record, 'ID')
                data{2,2} = record.ID;
            end
            data{3,1} = 'name';
            if isfield(record, 'name')
                data{3,2} = record.name;
            end
            data{4,1} = 'clinic';
            if isfield(record, 'clinic')
                data{4,2} = strjoin(record.clinic, '\n');
            end
            data{5,1} = 'plan';
            if isfield(record, 'plan')
                data{5,2} = record.plan;
            end
            data{6,1} = 'plandate';
            if isfield(record, 'planDate')
                data{6,2} = sprintf('%0.10f', datenum(record.planDate));
            end
            data{7,1} = 'planuser';
            if isfield(record, 'planUser')
                data{7,2} = record.planUser;
            end
            data{8,1} = 'measdate';
            if isfield(record, 'measDate')
                data{8,2} = sprintf('%0.10f', datenum(record.measDate));
            end
            data{9,1} = 'measuser';
            if isfield(record, 'measUser')
                data{9,2} = record.measUser;
            end
            data{10,1} = 'reviewstatus';
            if isfield(record, 'reviewStatus')
                data{10,2} = record.reviewStatus;
            end
            data{11,1} = 'reviewdate';
            if isfield(record, 'reviewDate')
                data{11,2} = sprintf('%0.10f', ...
                    datenum(record.reviewDate));
            end
            data{12,1} = 'reviewuser';
            if isfield(record, 'reviewUser')
                data{12,2} = record.reviewUser;
            end
            data{13,1} = 'comments';
            if isfield(record, 'comments')
                data{13,2} = strjoin(record.comments, '\n');
            end
            data{14,1} = 'phantom';
            if isfield(record, 'phantom')
               data{14,2} = record.phantom;
            end
            data{15,1} = 'students';
            if isfield(record, 'students')
                data{15,2} = record.students;
            end
            data{16,1} = 'cumulativemu';
            if isfield(record, 'cumulativeMU')
                data{16,2} = record.cumulativeMU;
            end
            data{17,1} = 'expectedmu';
            if isfield(record, 'expectedMU')
                data{17,2} = record.expectedMU;
            end
            data{18,1} = 'machine';
            if isfield(record, 'machine')
                data{18,2} = record.machine;
            end
            data{19,1} = 'temperature';
            if isfield(record, 'temperature')
                data{19,2} = record.temperature;
            end
            data{20,1} = 'reference';
            if isfield(record, 'reference')
                data{20,2} = record.reference;
            end
            data{21,1} = 'normdose';
            if isfield(record, 'normDose')
                data{21,2} = record.normDose;
            end
            data{22,1} = 'abs';
            if isfield(record, 'abs')
                data{22,2} = record.abs;
            end
            data{23,1} = 'dta';
            if isfield(record, 'dta')
                data{23,2} = record.dta;
            end
            data{24,1} = 'abspassrate';
            if isfield(record, 'absPassRate')
                data{24,2} = record.absPassRate;
            end
            data{25,1} = 'dtapassrate';
            if isfield(record, 'dtaPassRate')
                data{25,2} = record.dtaPassRate;
            end
            data{26,1} = 'gammapassrate';
            if isfield(record, 'gammaPassRate')
                data{26,2} = record.gammaPassRate;
            end
            data{27,1} = 'dosedev';
            if isfield(record, 'doseDev')
                data{27,2} = record.doseDev;
            end
            data{28,1} = 'report';
            if isfield(record, 'report')
                 data{28,2} = jsonencode(record.report);
            end
            data{29,1} = 'machinetype';
            if isfield(record, 'machineType')
                 data{29,2} = record.machineType;
            end
            data{30,1} = 'mobiusuid';
            if isfield(record, 'mobiusuid')
                 data{30,2} = record.mobiusuid;
            end
            data{31,1} = 'tomouid';
            if isfield(record, 'tomouid')
                 data{31,2} = record.tomouid;
            end
            data{32,1} = 'linacuid';
            if isfield(record, 'linacuid')
                 data{32,2} = record.linacuid;
            end

            % Insert row into database
            datainsert(obj.connection, 'delta4', data(:,1)', data(:,2)');
        
        case 'tomo'
        
            % Generate cell array of table columns and data
            data{1,1} = 'uid';
            if nargin == 4
                uid = varargin{1};
            else
                uid = dicomuid;
            end
            data{1,2} = uid;
            data{2,1} = 'id';
            if isfield(record, 'patientID')
                data{2,2} = record.patientID;
            elseif isfield(record, 'PatientID')
                data{2,2} = record.PatientID;
            end
            data{3,1} = 'name';
            if isfield(record, 'patientName')
                data{3,2} = record.patientName;
            elseif isfield(record, 'PatientName')
                data{3,2} = record.PatientName;
            end
            data{4,1} = 'plan';
            if isfield(record, 'planLabel')
                data{4,2} = record.planLabel;
            elseif isfield(record, 'RTPlanName')
                data{4,2} = record.RTPlanName;
            end
            data{5,1} = 'plandate';
            if isfield(record, 'timestamp')
                data{5,2} = sprintf('%0.10f', datenum(record.timestamp));
            elseif isfield(record, 'RTPlanDate')
                data{5,2} = sprintf('%0.10f', datenum([record.RTPlanDate, ...
                    '-', record.RTPlanTime], 'yyyymmdd-HHMMSS'));
            end
            data{6,1} = 'machine';
            if isfield(record, 'machine')
                data{6,2} = record.machine;
            elseif isfield(record, 'BeamSequence') && ...
                    length(record.BeamSequence) == 1 && ...        
                    isfield(record.BeamSequence, ...
                    'TreatmentMachineName')
                data{6,2} = record.BeamSequence.TreatmentMachineName;
            elseif isfield(record, 'BeamSequence') && ...
                    length(record.BeamSequence) > 1 && ...        
                    isfield(record.BeamSequence(1), ...
                    'TreatmentMachineName')
                data{6,2} = record.BeamSequence(1).TreatmentMachineName;
            end
            data{7,1} = 'gantrymode';
            if isfield(record, 'planType')
                data{7,2} = record.planType;
            elseif isfield(record, 'BeamSequence')
                if length(fieldnames(record.BeamSequence)) > 1
                    data{7,2} = 'Fixed_Angle';
                else
                    data{7,2} = 'Helical';
                end    
            end
            data{8,1} = 'jawmode';
            if isfield(record, 'jawType')
                data{8,2} = record.jawType;
            end
            data{9,1} = 'pitch';
            if isfield(record, 'pitch')
                data{9,2} = record.pitch;
            end
            data{10,1} = 'fieldwidth';
            if isfield(record, 'fieldWidth')
                data{10,2} = record.fieldWidth;
            elseif isfield(record, 'frontField') && ...
                    isfield(record, 'backField')
                data{10,2} = abs(record.frontField) + abs(record.backField);
            end
            data{11,1} = 'period';
            if isfield(record, 'scale') && isfield(record, 'planType') ...
                        && strcmp(record.planType, 'Helical')
                data{11,2} = record.scale * 51;
            end
            data{12,1} = 'couchspeed';
            if isfield(record, 'events') && isfield(record, 'scale') 
                for i = 1:size(record.events, 1)
                    if strcmp(record.events{i,2}, 'isoZRate')
                        data{12,2} = abs(record.events{i,3}) / record.scale;
                        break
                    end
                end
            end
            data{13,1} = 'couchlength';
            if isfield(record, 'events') && isfield(record, 'totalTau') ...
                    && isfield(record, 'scale')  
                for i = 1:size(record.events, 1)
                    if strcmp(record.events{i,2}, 'isoZRate')
                        data{13,2} = abs(record.events{i,3}) / record.scale * ...
                            (record.totalTau * record.scale + 10);
                        break
                    end
                end
            end
            data{14,1} = 'planmod';
            if isfield(record, 'modFactor')
                data{14,2} = record.modFactor;
            end
            data{15,1} = 'optimod';
            if isfield(record, 'sinogram')
                lots = reshape(record.sinogram, 1, []);
                lots(lots == 0) = [];
                data{15,2} = max(lots)/mean(lots);
                clear lots;
            end
            data{16,1} = 'actualmod';
            if isfield(record, 'sinogram') && isfield(record, 'scale')
                lots = reshape(record.sinogram, 1, []) * record.scale;
                lots(lots < 0.018) = []; % 18 msec
                data{16,2} = max(lots) / mean(lots);
                clear lots;
            end
            data{17,1} = 'rxdose';
            if isfield(record, 'rxDose')
                data{17,2} = record.rxDose;
            end
            data{18,1} = 'fractions';
            if isfield(record, 'fractions')
                data{18,2} = record.fractions;
            end
            data{19,1} = 'txtime';
            if isfield(record, 'scale') && isfield(record, 'totalTau')
                data{19,2} = record.scale * record.totalTau + 10;
            end
            data{20,1} = 'projtime';
            if isfield(record, 'scale')
                data{20,2} = record.scale;
            end
            data{21,1} = 'numprojections';
            if isfield(record, 'totalTau')
                data{21,2} = record.totalTau;
            end
            data{22,1} = 'doseperfx';
            if isfield(record, 'rxDose') && isfield(record, 'fractions') && ...
                    record.fractions > 0
                data{22,2} = record.rxDose / record.fractions;
            end
            data{23,1} = 'sinogram';
            if isfield(record, 'sinogram')
                data{23,2} = sprintf('%0.4f', record.sinogram);
            end
            data{24,1} = 'birthdate';
            if isfield(record, 'patientBirthDate')
                data{24,2} = datenum(record.patientBirthDate, 'YYYYMMDD');
            elseif isfield(record, 'PatientBirthDate')
                data{24,2} = datenum(record.PatientBirthDate, 'YYYYMMDD');
            end
            data{25,1} = 'sex';
            if isfield(record, 'patientSex')
                data{25,2} = record.patientSex(1);
            elseif isfield(record, 'PatientSex')
                data{25,2} = record.PatientSex(1);
            end
            data{26,1} = 'iterations';
            if isfield(record, 'iterations')
                data{26,2} = record.iterations;
            end
            data{27,1} = 'optigrid';
            if isfield(record, 'optimizationCalcGrid')
                data{27,2} = record.optimizationCalcGrid;
            end
            data{28,1} = 'calcgrid';
            if isfield(record, 'calcGrid')
                data{28,2} = record.calcGrid;
            end
            data{29,1} = 'laserx';
            if isfield(record, 'movableLaser')
                data{29,2} = record.movableLaser(1);
            end
            data{30,1} = 'lasery';
            if isfield(record, 'movableLaser')
                data{30,2} = record.movableLaser(2);
            end
            data{31,1} = 'laserz';
            if isfield(record, 'movableLaser')
                data{31,2} = record.movableLaser(3);
            end
            
            % Insert row into database
            datainsert(obj.connection, 'tomo', data(:,1)', data(:,2)');
            
        case 'linac'
            
            % Generate cell array of table columns and data
            data{1,1} = 'uid';
            if nargin == 4
                uid = varargin{1};
            else
                uid = dicomuid;
            end
            data{1,2} = uid;
            data{2,1} = 'id';
            if isfield(record, 'PatientID')
                data{2,2} = record.PatientID;
            end
            data{3,1} = 'name';
            if isfield(record, 'PatientName')
                data{3,2} = record.PatientName;
            end
            data{4,1} = 'plan';
            if isfield(record, 'RTPlanName')
                data{4,2} = record.RTPlanName;
            end
            data{5,1} = 'plandate';
            if isfield(record, 'RTPlanDate')
                data{5,2} = sprintf('%0.10f', datenum([record.RTPlanDate, ...
                    '-', record.RTPlanTime], 'yyyymmdd-HHMMSS'));
            end
            data{6,1} = 'machine';
            if isfield(record, 'BeamSequence') && ...
                    length(record.BeamSequence) == 1 && ...
                    isfield(record.BeamSequence, ...
                    'TreatmentMachineName')
                data{6,2} = record.BeamSequence.TreatmentMachineName;
            elseif isfield(record, 'BeamSequence') && ...
                    length(record.BeamSequence) > 1 && ...
                    isfield(record.BeamSequence(1), ...
                    'TreatmentMachineName')
                data{6,2} = record.BeamSequence(1).TreatmentMachineName;
            end
            data{7,1} = 'tps';
            if isfield(record, 'ManufacturerModelName')
                data{7,2} = record.ManufacturerModelName;
            end
            data{8,1} = 'mode';
            if isfield(record, 'BeamSequence') && ...
                    length(record.BeamSequence) == 1 && ...
                    isfield(record.BeamSequence, ...
                    'BeamType')
                data{8,2} = record.BeamSequence.BeamType;
            elseif isfield(record, 'BeamSequence') && ...
                    length(record.BeamSequence) > 1 && ...
                    isfield(record.BeamSequence(1), ...
                    'BeamType')
                data{8,2} = record.BeamSequence(1).BeamType;
            end
            data{9,1} = 'numbeams';
            if isfield(record, 'BeamSequence')
                data{9,2} = length(record.BeamSequence);
            end
            data{10,1} = 'numcps';
            if isfield(record, 'BeamSequence')
                if length(record.BeamSequence) == 1
                    cps = record.BeamSequence.NumberOfControlPoints;
                else
                    cps = 0;
                    for i = 1:length(record.BeamSequence)
                        if isfield(record.BeamSequence(i), ...
                                'NumberOfControlPoints')
                            cps = cps + record.BeamSequence(i)...
                                .NumberOfControlPoints;
                        end
                    end
                end
                data{10,2} = cps;
            end
            data{11,1} = 'doseperfx';
            if isfield(record, 'FractionGroupSequence') && ...
                    length(record.FractionGroupSequence) == 1 && ...
                    isfield(record.FractionGroupSequence, ...
                    'ReferencedBeamSequence')
                if length(record.FractionGroupSequence...
                        .ReferencedBeamSequence) == 1 && ...
                        isfield(record.FractionGroupSequence...
                        .ReferencedBeamSequence, 'BeamDose')
                    d = record.FractionGroupSequence...
                        .ReferencedBeamSequence.BeamDose;
                elseif length(record.FractionGroupSequence...
                        .ReferencedBeamSequence) > 1
                    d = 0;
                    for i = 1:length(record.FractionGroupSequence...
                            .ReferencedBeamSequence)
                        d = d + record.FractionGroupSequence...
                            .ReferencedBeamSequence(i)...
                            .BeamDose;
                    end
                end
                data{11,2} = d;
            elseif isfield(record, 'FractionGroupSequence') && ...
                    length(record.FractionGroupSequence) > 1 && ...
                    isfield(record.FractionGroupSequence, ...
                    'ReferencedBeamSequence')
                if length(record.FractionGroupSequence(1)...
                        .ReferencedBeamSequence) == 1 && ...
                        isfield(record.FractionGroupSequence(1)...
                        .ReferencedBeamSequence, 'BeamDose')
                    d = record.FractionGroupSequence...
                        .ReferencedBeamSequence.BeamDose;
                elseif length(record.FractionGroupSequence(1)...
                        .ReferencedBeamSequence) > 1
                    d = 0;
                    for i = 1:length(record.FractionGroupSequence(1)...
                            .ReferencedBeamSequence)
                        d = d + record.FractionGroupSequence(1)...
                            .ReferencedBeamSequence(i)...
                            .BeamDose;
                    end
                end
                data{11,2} = d;
            end
            data{12,1} = 'fractions';
            if isfield(record, 'FractionGroupSequence') && ...
                    length(record.FractionGroupSequence) == 1 && ...
                    isfield(record.FractionGroupSequence, ...
                    'NumberOfFractionsPlanned')
                data{12,2} = record.FractionGroupSequence...
                    .NumberOfFractionsPlanned;
            elseif isfield(record, 'FractionGroupSequence') && ...
                    length(record.FractionGroupSequence) > 1 && ...
                    isfield(record.FractionGroupSequence, ...
                    'NumberOfFractionsPlanned')
                data{12,2} = record.FractionGroupSequence(1)...
                    .NumberOfFractionsPlanned;
            end
            data{13,1} = 'rxdose';
            if ~isempty(data{11,2}) && ~isempty(data{12,2})
                data{13,2} = data{11,2} * data{12,2};
            end
            data{14,1} = 'rtplan';
            data{14,2} = jsonencode(record);
            data{15,1} = 'birthdate';
            if isfield(record, 'PatientBirthDate')
                data{15,2} = datenum(record.PatientBirthDate, 'YYYYMMDD');
            end
            data{16,1} = 'sex';
            if isfield(record, 'PatientSex')
                data{16,2} = record.PatientSex(1);
            end
            
            % Insert row into database
            datainsert(obj.connection, 'linac', data(:,1)', data(:,2)');
            
        case 'mobius'
            
            % Generate cell array of table columns and data
            data{1,1} = 'uid';
            if nargin == 4
                uid = varargin{1};
            else
                uid = dicomuid;
            end
            data{1,2} = uid;
            data{2,1} = 'id';
            if isfield(record, 'settings') && isfield(record.settings, ...
                    'planInfo_dict')
                data{2,2} = ...
                    record.settings.planInfo_dict.Patient.PatientID;
            end
            data{3,1} = 'name';
            if isfield(record, 'settings') && isfield(record.settings, ...
                    'planInfo_dict')
                data{3,2} = ...
                    record.settings.planInfo_dict.Patient.PatientsName;
            end
            data{4,1} = 'plan';
            if isfield(record, 'settings') && isfield(record.settings, ...
                    'planInfo_dict')
                data{4,2} = ...
                    record.settings.planInfo_dict.RTGeneralPlan.RTPlanName;
            end
            data{5,1} = 'plandate';
            if isfield(record, 'settings') && isfield(record.settings, ...
                    'planInfo_dict')
                data{5,2} = sprintf('%0.10f', datenum([record.settings...
                    .planInfo_dict.RTGeneralPlan.RTPlanDate, '-', ...
                    record.settings.planInfo_dict.RTGeneralPlan.RTPlanTime], ...
                    'yyyymmdd-HHMMSS'));
            end
            data{6,1} = 'abs';
            if isfield(record, 'data') && isfield(record.data, ...
                    'gamma_result') && ~isempty(record.data.gamma_result)
                data{6,2} = ...
                    record.data.gamma_result.criteria.dose.value * 100;
            end
            data{7,1} = 'dta';
            if isfield(record, 'data') && isfield(record.data, ...
                    'gamma_result') && ~isempty(record.data.gamma_result)
                data{7,2} = ...
                    record.data.gamma_result.criteria.maxDTA_mm.value;
            end
            data{8,1} = 'gammapassrate';
            if isfield(record, 'data') && isfield(record.data, ...
                    'gamma_result') && ~isempty(record.data.gamma_result)
                data{8,2} = ...
                    record.data.gamma_result.passingRate.value * 100;
            end
            data{9,1} = 'version';
            if isfield(record, 'version')
                data{9,2} = record.version{4};
            end
            data{10,1} = 'dvh';
            if isfield(record, 'dvh')
                data{10,2} = jsonencode(record.dvh);
                record = rmfield(record, 'dvh');
            end
            data{11,1} = 'plancheck';
            data{11,2} = jsonencode(record);
            
            % Insert row into database
            datainsert(obj.connection, 'mobius', data(:,1)', data(:,2)');
        end
        
        % Clear temporary variables
        clear data d i;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function exportCSV(obj, table, file)
        
        % Open handle to file
        fid = fopen(file, 'w');
        
        % Retrieve column names and data types
        sql = ['PRAGMA table_info(', table, ')'];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        cols = cursor.Data;
        
        % Write column names to first row
        fprintf(fid, '%s,\n', strjoin(cols(:,2), ', '));
        
        % Query data
        sql = ['SELECT ', strjoin(cols(:,2), ', '), ' FROM ', table];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor); 
        
        % Write data
        for i = 1:size(cursor.Data,1)
            for j = 1:size(cursor.Data,2)
                if ~isempty(regexp(cols{j,2}, 'date', 'ONCE'))
                    if cursor.Data{i,j} > 0
                        fprintf(fid, '%s,', datestr(cursor.Data{i,j}));
                    else
                        fprintf(fid, ',');
                    end
                elseif strcmp(cols{j,3}, 'float')
                    fprintf(fid, '%f,', cursor.Data{i,j});
                elseif strcmp(cols{j,3}, 'int')
                    fprintf(fid, '%i,', cursor.Data{i,j});
                elseif strcmp(cols{j,3}, 'blob')
                    fprintf(fid, ',');
                else
                    fprintf(fid, '%s,', regexprep(cursor.Data{i,j}, ...
                       '[\n\,]', ' '));
                end
            end
            fprintf(fid, '\n');
        end
        
        % Close file handle
        fclose(fid);
        
        % Clear temporary variables
        clear fid sql cursor cols;
    end
end
end
                