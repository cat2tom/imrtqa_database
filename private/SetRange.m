function varargout = SetRange(varargin)



% Declare range options
ranges = { 
    'All Records'
    'Last 30 Days'
    'Last 90 Days'
    'Last 1 Year'
    'Custom Dates'
};

% If no input is provided, return list
if nargin == 0
    
    % Return list
    varargout{1} = ranges;

% Otherwise, assume it was an index
else
    
    % Update range limits based on selection
    switch ranges{varargin{1}}

    case 'All Records'
        [varargout{1}, varargout{2}] = varargin{2}.recordRange();

    case 'Last 30 Days'
        varargout{2} = now;
        varargout{1} = varargout{2} - 30;

    case 'Last 90 Days'
        varargout{2} = now;
        varargout{1} = varargout{2} - 90;

    case 'Last 1 Year'
        varargout{2} = now;
        varargout{1} = varargout{2} - 365;

    case 'Custom Dates'
        a = inputdlg({'Enter lower date:','Enter upper date:'}, ...
            'Custom Date Range', 1, {datestr(now-30), datestr(now)});
        if ~isempty(a)
            varargout{1} = datenum(a{1});
            varargout{2} = datenum(a{2});
        end
        
        clear a;
    otherwise
        Event('Invalid range choice selected', 'ERROR');
    end
end

