function varargout = ReviewInterface(varargin)
% REVIEWINTERFACE MATLAB code for ReviewInterface.fig
%      REVIEWINTERFACE, by itself, creates a new REVIEWINTERFACE or raises the existing
%      singleton*.
%
%      H = REVIEWINTERFACE returns the handle to a new REVIEWINTERFACE or the handle to
%      the existing singleton*.
%
%      REVIEWINTERFACE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REVIEWINTERFACE.M with the given input arguments.
%
%      REVIEWINTERFACE('Property','Value',...) creates a new REVIEWINTERFACE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ReviewInterface_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ReviewInterface_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ReviewInterface

% Last Modified by GUIDE v2.5 29-Sep-2015 17:40:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ReviewInterface_OpeningFcn, ...
                   'gui_OutputFcn',  @ReviewInterface_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ReviewInterface_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ReviewInterface (see VARARGIN)

% Choose default command line output for ReviewInterface
handles.output = hObject;

% Turn off MATLAB warnings
warning('off', 'all');

% Turn off TeX processing
set(0, 'DefaulttextInterpreter', 'none');

% Set version handle
handles.version = '0.9.1';

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Store and set current directory to location of this application
cd(path);
handles.path = path;

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'IMRT QA Results Analysis Tool'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Clear temporary variables
clear separator;

% Log information
Event(string, 'INIT');

% Parse config options
handles = ParseConfigOptions(handles, 'config.txt');

%% Update UI
% Set version text
set(handles.version_text, 'String', ['Version ', handles.version]);

% Set range options, defaulting to Last 90 days (third option)
set(handles.range, 'String', SetRange());
set(handles.range, 'Value', 3);
[handles.range_high, handles.range_low] = SetRange(3);

% Initialize empty plot_stats table
set(handles.plot_stats, 'Data', cell(4, 8));

% Set plot options
set(handles.plot_types, 'String', PlotData());
set(handles.plot_types, 'Value', 1);

% Log default path
Event(['Default file path set to ', handles.path]);

%% Connect Database
% Log database load
Event(['Loading default database file ', handles.config.DATABASE]);

% Verify database file exists
if exist(fullfile(handles.path, handles.config.DATABASE), 'file') == 2

    % Initialize new connection to database
    handles.db = IMRTDatabase(fullfile(handles.path, ...
        handles.config.DATABASE));
    
    % Verify database has loaded
    if isempty(handles.db.connection.URL)
        Event(['Could not open connection to ', handles.config.DATABASE, ':', ...
            handles.db.connection.Message], 'ERROR');
    end

    % Update database summary table
    handles = UpdateSummary(handles);
else
    
    % Otherwise, execute callback to prompt user to select a different db
    handles = OpenDatabase(handles);
end

%% Connect Mobius3D
% Log database load
Event('Establishing connection to Mobius3D server');

% Add jsonlab folder to search path
addpath('./mobius_query');

% Check if MATLAB can find EstablishConnection
if exist('EstablishConnection', 'file') ~= 2
    
    % If not, throw an error
    Event(['The Mobius3D server query toolbox submodule does not exist in ', ...
        'the search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Connect to Mobius3D server
handles.server = EstablishConnection('server', ...
    handles.config.M3D_SERVER, 'user', handles.config.M3D_USER, ...
    'pass', handles.config.M3D_PASS);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = ReviewInterface_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function opendb_Callback(hObject, ~, handles)
% hObject    handle to opendb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute OpenDatabase
handles = OpenDatabase(handles);

% Update database summary table
handles = UpdateSummary(handles);

% Update plot using first option
plots = cellstr(get(handles.plot_types,'String'));
PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
    plots{get(handles.plot_types,'Value')}, 'range', ...
    [handles.range_low, handles.range_high], 'stats', handles.plot_stats);
clear plots;

% Store guidata
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function export_Callback(hObject, ~, handles)
% hObject    handle to export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ExportCSV
handles = ExportCSV(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function import_Callback(hObject, ~, handles)
% hObject    handle to import (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ImportReports
handles = ImportReports(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function import_tomo_Callback(hObject, ~, handles)
% hObject    handle to import_tomo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ImportArchives
handles = ImportArchives(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function match_records_Callback(hObject, ~, handles)
% hObject    handle to match_records (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute matchRecords
handles.db.matchRecords('delta4', 'tomo', 1440);

% Update database summary table
handles = UpdateSummary(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_stats_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to plot_stats (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property.
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

% Update cell contents
data = get(hObject, 'Data');
if data{eventdata.Indices(1), 2}
    Event([data{eventdata.Indices(1), 1}, ' display enabled']);
elseif ~data{eventdata.Indices(1), 2}
    Event([data{eventdata.Indices(1), 1}, ' display disabled']);
end
set(hObject, 'Data', data);

% Update plots
plots = cellstr(get(handles.plot_types,'String'));
PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
    plots{get(handles.plot_types,'Value')}, 'range', [handles.range_low, ...
    handles.range_high], 'stats', hObject);
clear plots;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_types_Callback(hObject, ~, handles)
% hObject    handle to plot_types (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log choice
plots = cellstr(get(hObject, 'String'));
Event(['Plot changed to ', plots{get(hObject, 'Value')}]);

% Update plots
PlotData('type', plots{get(hObject,'Value')}, 'range', [handles.range_low, ...
    handles.range_high], 'parent', handles.plot_axes, 'db', handles.db, ...
    'stats', handles.plot_stats);
clear plots;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_types_CreateFcn(hObject, ~, ~)
% hObject    handle to plot_types (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function range_Callback(hObject, ~, handles)
% hObject    handle to range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set range using SetRange()
[handles.range_low, handles.range_high] = ...
    SetRange(get(hObject, 'Value'), handles.db);

% Update plots
PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
    get(handles.plot_types,'Value'), 'range', [handles.range_low, ...
    handles.range_high], 'stats', handles.plot_stats);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function range_CreateFcn(hObject, ~, ~)
% hObject    handle to range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set background color
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_plot_Callback(hObject, ~, handles)
% hObject    handle to save_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute SavePlot
handles = SavePlot(handles);
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function copy_stats_Callback(hObject, ~, handles)
% hObject    handle to copy_stats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute CopyStats
CopyStats(handles.plot_stats);
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figure1_SizeChangedFcn(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set units to pixels
set(hObject,'Units','pixels') 

% Get table width
pos = get(handles.dbinfo, 'Position') .* ...
    get(handles.uipanel1, 'Position') .* ...
    get(hObject, 'Position');

% Update column widths to scale to new table size
set(handles.dbinfo, 'ColumnWidth', ...
    {floor(0.7*pos(3)) - 6 floor(0.3*pos(3))});

% Clear temporary variables
clear pos;
