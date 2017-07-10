function handles = UpdateSummary(handles)

table{1,1} = 'Number of QA Reports';
table{1,2} = sprintf('%i', handles.db.countReports());

table{size(table,1)+1,1} = 'QA Reports with RTPlans';
table{size(table,1),2} = sprintf('%0.1f%%', ...
    handles.db.countMatchedRecords() * 100);
table{size(table,1)+1,1} = 'Linac Reports';
table{size(table,1),2} = sprintf('%0.1f%%', ...
    handles.db.countReports('linac') / (handles.db.countReports()) * 100);
table{size(table,1)+1,1} = 'TomoTherapy Reports';
table{size(table,1),2} = sprintf('%0.1f%%', ...
    handles.db.countReports('tomo') / (handles.db.countReports()) * 100);
table{size(table,1)+1,1} = 'TomoTherapy RT Plans';
table{size(table,1),2} = sprintf('%i', handles.db.countPlans('tomo'));
table{size(table,1)+1,1} = 'Plans with Sinogram Data';
table{size(table,1),2} = sprintf('%0.1f%%', handles.db.countPlans('tomo', ...
    'sinogram IS NOT NULL') / handles.db.countPlans('tomo') * 100);

[low, high] = handles.db.recordRange();
table{size(table,1)+1,1} = 'Earliest Record';
if ~strcmp(low, 'null')
    table{size(table,1),2} = datestr(low, 'yyyy-mm-dd');
else
    table{size(table,1),2} = '';
end
table{size(table,1)+1,1} = 'Latest Record';
if ~strcmp(high, 'null')
    table{size(table,1),2} = datestr(high, 'yyyy-mm-dd');
else
    table{size(table,1),2} = '';
end
table{size(table,1)+1,1} = 'Database File';
table{size(table,1),2} = handles.config.DATABASE;
table{size(table,1)+1,1} = 'Mobius3D Server';
table{size(table,1),2} = handles.config.M3D_SERVER;
set(handles.dbinfo, 'Data', table);
clear table low high;