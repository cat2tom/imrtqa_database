function delta4 = ParseD4report(content)


% Log start
if exist('Event', 'file') == 2
    Event('Parsing data from Delta4 report');
    tic;
end

% Initialize empty return variable
delta4 = struct;

% If plan report is from version April 2016 or later
if length(content{7}) >= 7 && strcmp(content{7}(1:7), 'Clinic:')
    
    % Store title, patient name, and ID
    delta4.title = strtrim(content{1});
    delta4.name = strtrim(content{3});
    delta4.ID = strtrim(content{5});

    % Initialize row counter
    r = 6;
    
else 
    % Store title and patient name
    fields = strsplit(content{1}, '   ');
    delta4.title = strtrim(fields{1});
    delta4.name = strtrim(fields{2});
    for i = 3:length(fields)
        delta4.name = [delta4.name, ' ', strtrim(fields{i})];
    end

    % Store patient ID
    delta4.ID = strtrim(content{3});

    % Initialize row counter
    r = 4;
end

% Loop through rows until clinic info is found
while r < length(content)
    
    % If row starts with 'Clinic:'
    if length(content{r}) >= 7 && strcmp(content{r}(1:7), 'Clinic:')
        content{r} = content{r}(8:end);
        delta4.clinic = cell(0);
        break;
    else
        r = r + 1;
    end
end

% Store clinic contact info, followed by plan name
while r < length(content)
    
    % If row starts with 'Plan:'
    if length(content{r}) >= 5 && strcmp(content{r}(1:5), 'Plan:')
        delta4.plan = strtrim(content{r}(6:end));
        break;
    else
        if ~isempty(content{r})
            delta4.clinic = vertcat(delta4.clinic, strtrim(content{r}));
        end
        r = r + 1;
    end
end

% Loop through rows until planned date info is found
while r < length(content)
    
    % If row starts with 'Planned:'
    if length(content{r}) >= 8 && strcmp(content{r}(1:8), 'Planned:')
        
        % Store planned date
        fields = strsplit(content{r});
        delta4.planDate = datetime([fields{2}, ' ', fields{3}, ' ', ...
            fields{4}], 'InputFormat', 'M/d/yyyy h:m a');
        
        % Store user, if present
        if length(fields) > 4
            delta4.planUser = fields{5};
        end
        
        break;
    else
        r = r + 1;
    end
end

% Loop through rows until measured date info is found
while r < length(content)
    
    % If row starts with 'Measured:'
    if length(content{r}) >= 9 && strcmp(content{r}(1:9), 'Measured:')
        
        % Store measured date
        fields = strsplit(content{r});
        delta4.measDate = datetime([fields{2}, ' ', fields{3}, ' ', ...
            fields{4}], 'InputFormat', 'M/d/yyyy h:m a');
        
        % Store user, if present
        if length(fields) >= 4
            delta4.measUser = fields{5};
        end
        
        break;
    else
        r = r + 1;
    end
end

% Loop through rows until reviewed status info is found
while r < length(content)
    
    % If row starts with 'Accepted:' or 'Rejected:' or 'Failed:'
    if length(content{r}) >= 9 && (strcmp(content{r}(1:9), 'Accepted:') || ...
                strcmp(content{r}(1:9), 'Rejected:') || ...
                strcmp(content{r}(1:7), 'Failed:'))
        
        % Store measured date
        fields = strsplit(content{r});
        delta4.reviewStatus = fields{1}(1:end-1);
        delta4.reviewDate = datetime([fields{2}, ' ', fields{3}, ' ', ...
            fields{4}], 'InputFormat', 'M/d/yyyy h:m a');
        
        % Store user, if present
        if length(fields) > 4
            delta4.reviewUser = fields{5};
        end
        
        % Otherwise, move to next row
        r = r + 1;
    
    % Otherwise, stop if row starts with 'Comments:'
    elseif length(content{r}) >= 9 && strcmp(content{r}(1:9), 'Comments:')
        
        content{r} = content{r}(10:end);
        break;
        
    % Otherwise, move to next row
    else
        r = r + 1;
    end
end

% Store comments and look for treatment summary
delta4.comments = cell(0);
while r < length(content)
    
    % If row is Treatment Summary
    if ~isempty(regexp(content{r}, 'Treatment Summary', 'ONCE'))
        break;
    else
        if ~isempty(content{r})
            delta4.comments = vertcat(delta4.comments, ...
                strtrim(content{r}));
        end
        r = r + 1;
    end
end

% Initialize unknown phantom
delta4.phantom = 'Unknown';

% Search for specific tags in comments
for i = 1:length(delta4.comments)
    if regexp(delta4.comments{i}, 'Performed by:?(.+)') > 0
        fields = regexp(delta4.comments{i}, 'Performed by:?(.+)', 'tokens');
        delta4.students = strtrim(fields{1}{1});
    elseif size(strfind(lower(delta4.comments{i}), 'red'), 1) > 0
        delta4.phantom = 'Delta4 Red';
    elseif size(strfind(lower(delta4.comments{i}), 'black'), 1) > 0
        delta4.phantom = 'Delta4 Black'; 
    elseif size(strfind(lower(delta4.comments{i}), 'delta4+'), 1) > 0
        delta4.phantom = 'Delta4+'; 
    elseif regexp(delta4.comments{i}, '([0-9]+)[ ]?/[ ]?([0-9]+)') > 0
        
        fields = regexp(delta4.comments{i}, ...
            '([0-9]+)[ ]?/[ ]?([0-9]+)', 'tokens');
        delta4.cumulativeMU = str2double(fields{1}(1));
        delta4.expectedMU = str2double(fields{1}(2));
    end
end

% Look for and store radiation device
while r < length(content)
    
    % If row starts with 'Radiation Device:'
    if length(content{r}) >= 17 && ...
            strcmp(content{r}(1:17), 'Radiation Device:')
        delta4.machine = strtrim(content{r}(18:end));
        break;
    else
        r = r + 1;
    end
end

% Look for and store temperature
while r < length(content)
    
    % If row starts with 'Temperature:'
    if length(content{r}) >= 12 && strcmp(content{r}(1:12), 'Temperature:')
        fields = regexp(content{r}(13:end), '([0-9\.]+)', 'tokens');
        
        if ~isempty(fields)
            delta4.temperature = str2double(fields{1}(1));
        end
        break;
    else
        r = r + 1;
    end
end

% Look for and store dose reference
while r < length(content)
    
    % If row starts with 'Reference:'
    if length(content{r}) >= 10 && ...
            strcmp(content{r}(1:10), 'Reference:')
        delta4.reference = strtrim(content{r}(11:end));
        break;
    else
        r = r + 1;
    end
end

% Look for and store fraction statistics
while r < length(content)
    
    % If row starts with 'Fraction'
    if length(content{r}) >= 8 && ...
            strcmp(content{r}(1:8), 'Fraction')
        fields = regexp(content{r}(9:end), ['([0-9\.]+) +(c?Gy) +([0-9\.]', ...
            '+)% +([0-9\.]+)% +([0-9\.]+)% +(-?[0-9\.]+)%'], 'tokens');
        if strcmp(fields{1}(2), 'cGy')
            delta4.normDose = str2double(fields{1}(1)) / 100;
        else
            delta4.normDose = str2double(fields{1}(1));
        end
        delta4.absPassRate = str2double(fields{1}(3));
        delta4.dtaPassRate = str2double(fields{1}(4));
        delta4.gammaPassRate = str2double(fields{1}(5));
        delta4.doseDev = str2double(fields{1}(6));
        r = r + 1;
        break;
    else
        r = r + 1;
    end
end

% Initialize beams counter
b = 0;

% Look for and store beam statistics
while r < length(content)
    
    % If row is 'Histograms'
    if ~isempty(regexp(content{r}, 'Histograms', 'ONCE'))
        break
    else
        if ~isempty(regexp(content{r}, ['([0-9\.]+) +([0-9\.]+) +(c?Gy) ', ...
                '+([0-9\.]+)% +([0-9\.]+)% +([0-9\.]+)% +(-?[0-9\.]+)%'], ...
                'ONCE'))
            
            b = b + 1;
            
            fields = regexp(content{r}, ['([0-9\.]+) +([0-9\.]+) +(c?Gy) ', ...
                '+([0-9\.]+)% +([0-9\.]+)% +([0-9\.]+)% +(-?[0-9\.]+)%'], ...
                'tokens');
            
            delta4.beams{b,1}.dailyCF = str2double(fields{1}(1));
            if strcmp(fields{1}(3), 'cGy')
                delta4.beams{b,1}.normDose = str2double(fields{1}(1)) / 100;
            else
                delta4.beams{b,1}.normDose = str2double(fields{1}(1));
            end
            delta4.beams{b,1}.absPassRate = str2double(fields{1}(4));
            delta4.beams{b,1}.dtaPassRate = str2double(fields{1}(5));
            delta4.beams{b,1}.gammaPassRate = str2double(fields{1}(6));
            delta4.beams{b,1}.doseDev = str2double(fields{1}(7));
        end
        r = r + 1;
    end
end

% Look for and store dose deviation parameters
while r < length(content)
    
    % If row starts with 'Dose Deviation'
    if length(content{r}) >= 14 && ...
            strcmp(content{r}(1:14), 'Dose Deviation')
        fields = regexp(content{r}(15:end), ['([0-9\.]+)%[^0-9]+([0-9\.]', ...
            '+)%[^0-9]+([0-9\.]+)%[^0-9]+([0-9\.]+)%'], 'tokens');
        
        delta4.absRange(1) = str2double(fields{1}(1));
        delta4.absRange(2) = str2double(fields{1}(2));
        delta4.absPassLimit(1) = str2double(fields{1}(3));
        delta4.absPassLimit(2) = str2double(fields{1}(4));
        r = r + 1;
        break;
    else
        r = r + 1;
    end
end

% Look for and store DTA parameters
while r < length(content)
    
    % If row starts with 'Dist to Agreement'
    if length(content{r}) >= 17 && ...
            strcmp(content{r}(1:17), 'Dist to Agreement')
        fields = regexp(content{r}(18:end), ['([0-9\.]+)%[^0-9]+([0-9\.]', ...
            '+)%[^0-9]+([0-9\.]+)'], 'tokens');
        
        delta4.dtaRange(1) = str2double(fields{1}(1));
        delta4.dtaRange(2) = inf;
        delta4.dtaPassLimit(1) = str2double(fields{1}(2));
        delta4.dtaPassLimit(2) = str2double(fields{1}(3));
        r = r + 1;
        break;
    else
        r = r + 1;
    end
end

% Look for and store Gamma Index parameters
while r < length(content)
    
    % If row starts with 'Gamma Index'
    if length(content{r}) >= 11 && ...
            strcmp(content{r}(1:11), 'Gamma Index')
        fields = regexp(content{r}(12:end), ['([0-9\.]+)%[^0-9]+([0-9\.]', ...
            '+)%[^0-9]+([0-9\.]+)%[^0-9]+([0-9\.]+)[^0-9]+([0-9\.]+)', ...
            '%[^0-9]+([0-9\.]+)'], 'tokens');
        
        delta4.gammaRange(1) = str2double(fields{1}(1));
        delta4.gammaRange(2) = str2double(fields{1}(2));
        delta4.abs = str2double(fields{1}(3));
        delta4.dta = str2double(fields{1}(4));
        delta4.gammaPassLimit(1) = str2double(fields{1}(5));
        delta4.gammaPassLimit(2) = str2double(fields{1}(6));
        break;
    else
        r = r + 1;
    end
end

% Clear temporary variables
clear fields;

% Log finish
if exist('Event', 'file') == 2
    Event(sprintf('Delta4 report parsed successfully in %0.3f seconds', toc));
end

end