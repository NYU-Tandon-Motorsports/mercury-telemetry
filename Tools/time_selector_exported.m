classdef time_selector_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        SelectdateandtimeUIFigure    matlab.ui.Figure
        DatePicker                   matlab.ui.control.DatePicker
        SelectDateandTimerangeLabel  matlab.ui.control.Label
        Hour                         matlab.ui.control.DropDown
        Minute                       matlab.ui.control.DropDown
        Second                       matlab.ui.control.DropDown
        Export                       matlab.ui.control.Button
        SelectedTime                 matlab.ui.control.Label
        DatePicker_2                 matlab.ui.control.DatePicker
        Hour_2                       matlab.ui.control.DropDown
        Minute_2                     matlab.ui.control.DropDown
        Second_2                     matlab.ui.control.DropDown
        StartLabel                   matlab.ui.control.Label
        EndLabel                     matlab.ui.control.Label
        SelectedTime_2               matlab.ui.control.Label
    end

    properties (Access = private)
        MainProp
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, MainProp)
            app.DatePicker.Value = datetime('now');
            app.DatePicker_2.Value = datetime('now');
            app.Hour.Items = cellfun(@(x)sprintf('%02.0f',x),num2cell(0:24),'UniformOutput',false);
            app.Hour.Value = '00';
            app.Hour_2.Items = cellfun(@(x)sprintf('%02.0f',x),num2cell(0:24),'UniformOutput',false);
            app.Hour_2.Value = '00';
            app.Minute.Items = cellfun(@(x)sprintf('%02.0f',x),num2cell(0:60),'UniformOutput',false);
            app.Minute.Value = '00';
            app.Minute_2.Items = cellfun(@(x)sprintf('%02.0f',x),num2cell(0:60),'UniformOutput',false);
            app.Minute_2.Value = '00';
            app.Second.Items = cellfun(@(x)sprintf('%02.0f',x),num2cell(0:60),'UniformOutput',false);
            app.Second.Value = '00';
            app.Second_2.Items = cellfun(@(x)sprintf('%02.0f',x),num2cell(0:60),'UniformOutput',false);
            app.Second_2.Value = '00';
            app.SelectedTime.Text = sprintf('%s %s:%s:%s',datestr(app.DatePicker.Value,'yyyy-mm-dd'),app.Hour.Value,app.Minute.Value,app.Second.Value);
            app.SelectedTime_2.Text = sprintf('%s %s:%s:%s',datestr(app.DatePicker_2.Value,'yyyy-mm-dd'),app.Hour_2.Value,app.Minute_2.Value,app.Second_2.Value);
            if ~exist('MainProp','var')
                MainProp = app.SelectedTime;
                
            end
            app.MainProp = MainProp; % The caller field if called from inside an app
        end

        % Value changed function: DatePicker, DatePicker_2, Hour, 
        % Hour_2, Minute, Minute_2, Second, Second_2
        function DatePickerValueChanged(app, event)
            app.SelectedTime.Text = sprintf('%s %s:%s:%s',datestr(app.DatePicker.Value,'yyyy-mm-dd'),app.Hour.Value,app.Minute.Value,app.Second.Value);
            app.SelectedTime_2.Text = sprintf('%s %s:%s:%s',datestr(app.DatePicker_2.Value,'yyyy-mm-dd'),app.Hour_2.Value,app.Minute_2.Value,app.Second_2.Value);
        end

        % Callback function: Export, SelectdateandtimeUIFigure
        function UIFigureCloseRequest(app, event)
            app.MainProp.Text = app.SelectedTime.Text;
            start_time = datetime(app.SelectedTime.Text);
            end_time = datetime(app.SelectedTime_2.Text);
            delete(app);
            [file, path] = uigetfile('*.csv');
            T = readtable(strcat(path,file));       %PUT PATH FOR CSV FILE HERE
            T = sortrows(T,6);
            table_size = size(T);
            rows = table_size(1);
            current_series = T.(6)(1);
            fields = [];
            i = 0;
            curr_row = 1;
            while(curr_row ~= rows)
                for row = curr_row:rows
                    if strcmp(current_series, T.(6)(row))
                        i = i + 1;
                    else
                        break;
                    end
                end
                if strcmp(current_series, "log")
                    x = strings(1,i);
                else
                    x = zeros(1,i);
                end
                t = NaT(1,i);
                j = 1;
                for row = curr_row:rows
                    if strcmp(current_series, T.(6)(row))
                       timestamp = T.(7)(row);
                       t(j) = timestamp;
                       data = string(T.(8)(row));
                       newstr = replace(data,"'",char(34));
                       datastruct = jsondecode(newstr);
                       result = datastruct.result;
                       fields = cell2mat(fieldnames(result));
                       values = cell2mat(struct2cell(result));
                       values_size = size(values);
                       values_rows = values_size(1);
                       x_size = size(x);
                       x_rows = x_size(1);
                       if values_rows ~= x_rows
                           x = zeros(values_rows, i);
                       end
                       x(:,j) = values;
                       j = j + 1;
                       curr_row = row;
                    else
                       generatePlot(current_series, x, t, fields, start_time, end_time);
                       current_series = T.(6)(row);
                       curr_row = row;
                       i = 0;
                       break;
                    end      
                end
            end
            generatePlot(current_series, x, t, fields, start_time, end_time);
        end 
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create SelectdateandtimeUIFigure and hide until all components are created
            app.SelectdateandtimeUIFigure = uifigure('Visible', 'off');
            app.SelectdateandtimeUIFigure.Position = [400 200 435 340];
            app.SelectdateandtimeUIFigure.Name = 'Select date and time';
            app.SelectdateandtimeUIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create DatePicker
            app.DatePicker = uidatepicker(app.SelectdateandtimeUIFigure);
            app.DatePicker.DisplayFormat = 'uuuu-MM-dd';
            app.DatePicker.ValueChangedFcn = createCallbackFcn(app, @DatePickerValueChanged, true);
            app.DatePicker.Position = [71 277 105 22];

            % Create SelectDateandTimerangeLabel
            app.SelectDateandTimerangeLabel = uilabel(app.SelectdateandtimeUIFigure);
            app.SelectDateandTimerangeLabel.HorizontalAlignment = 'center';
            app.SelectDateandTimerangeLabel.FontName = 'Bahnschrift';
            app.SelectDateandTimerangeLabel.FontSize = 16;
            app.SelectDateandTimerangeLabel.FontWeight = 'bold';
            app.SelectDateandTimerangeLabel.FontAngle = 'italic';
            app.SelectDateandTimerangeLabel.Position = [102 306 203 22];
            app.SelectDateandTimerangeLabel.Text = 'Select Date and Time range';

            % Create Hour
            app.Hour = uidropdown(app.SelectdateandtimeUIFigure);
            app.Hour.Items = {};
            app.Hour.ValueChangedFcn = createCallbackFcn(app, @DatePickerValueChanged, true);
            app.Hour.Tag = 'hour';
            app.Hour.Position = [198 277 54 22];
            app.Hour.Value = {};

            % Create Minute
            app.Minute = uidropdown(app.SelectdateandtimeUIFigure);
            app.Minute.Items = {};
            app.Minute.ValueChangedFcn = createCallbackFcn(app, @DatePickerValueChanged, true);
            app.Minute.Tag = 'hour';
            app.Minute.Position = [269 277 54 22];
            app.Minute.Value = {};

            % Create Second
            app.Second = uidropdown(app.SelectdateandtimeUIFigure);
            app.Second.Items = {};
            app.Second.ValueChangedFcn = createCallbackFcn(app, @DatePickerValueChanged, true);
            app.Second.Tag = 'hour';
            app.Second.Position = [332 277 54 22];
            app.Second.Value = {};

            % Create Export
            app.Export = uibutton(app.SelectdateandtimeUIFigure, 'push');
            app.Export.ButtonPushedFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.Export.Position = [138 20 175 77];
            app.Export.Text = 'Select Time';

            % Create SelectedTime
            app.SelectedTime = uilabel(app.SelectdateandtimeUIFigure);
            app.SelectedTime.Position = [234 249 124 22];
            app.SelectedTime.Text = 'Selected Time';

            % Create DatePicker_2
            app.DatePicker_2 = uidatepicker(app.SelectdateandtimeUIFigure);
            app.DatePicker_2.DisplayFormat = 'uuuu-MM-dd';
            app.DatePicker_2.ValueChangedFcn = createCallbackFcn(app, @DatePickerValueChanged, true);
            app.DatePicker_2.Position = [71 228 105 22];

            % Create Hour_2
            app.Hour_2 = uidropdown(app.SelectdateandtimeUIFigure);
            app.Hour_2.Items = {};
            app.Hour_2.ValueChangedFcn = createCallbackFcn(app, @DatePickerValueChanged, true);
            app.Hour_2.Tag = 'hour';
            app.Hour_2.Position = [198 228 54 22];
            app.Hour_2.Value = {};

            % Create Minute_2
            app.Minute_2 = uidropdown(app.SelectdateandtimeUIFigure);
            app.Minute_2.Items = {};
            app.Minute_2.ValueChangedFcn = createCallbackFcn(app, @DatePickerValueChanged, true);
            app.Minute_2.Tag = 'hour';
            app.Minute_2.Position = [269 228 54 22];
            app.Minute_2.Value = {};

            % Create Second_2
            app.Second_2 = uidropdown(app.SelectdateandtimeUIFigure);
            app.Second_2.Items = {};
            app.Second_2.ValueChangedFcn = createCallbackFcn(app, @DatePickerValueChanged, true);
            app.Second_2.Tag = 'hour';
            app.Second_2.Position = [332 228 54 22];
            app.Second_2.Value = {};

            % Create StartLabel
            app.StartLabel = uilabel(app.SelectdateandtimeUIFigure);
            app.StartLabel.Position = [17 277 31 22];
            app.StartLabel.Text = 'Start';

            % Create EndLabel
            app.EndLabel = uilabel(app.SelectdateandtimeUIFigure);
            app.EndLabel.Position = [21 228 27 22];
            app.EndLabel.Text = 'End';

            % Create SelectedTime_2
            app.SelectedTime_2 = uilabel(app.SelectdateandtimeUIFigure);
            app.SelectedTime_2.Position = [234 198 124 22];
            app.SelectedTime_2.Text = 'Selected Time';

            % Show the figure after all components are created
            app.SelectdateandtimeUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = time_selector_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.SelectdateandtimeUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.SelectdateandtimeUIFigure)
        end
    end
end


function generatePlot(seriesStr, x, t, fieldArr, s, e)
    if ~strcmp(seriesStr, "log")
        f = figure;
    end
    x_size = size(x);
    x_rows = x_size(1);
    [sortedT, sortIndex] = sort(t);
    for r = 1:x_rows
        x_graph = x(r,:);
        sortedX_graph = x_graph(sortIndex);
        if strcmp(seriesStr, "log")
            fprintf('%s\n', sortedX_graph)
        elseif strcmp(seriesStr, "hall sensor")
            plot(sortedT, filloutliers(sortedX_graph, 'nearest','mean'))
        else
            plot(sortedT, sortedX_graph)
        end
        hold on
    end
    hold off
    if ~strcmp(seriesStr, "log")
        title(seriesStr);
        xlabel("Timestamp");
        for c = 1:x_size(2)
            if(sortedT(c) >= s)
                s = sortedT(c);
                break;
            end
        end
        for c = x_size(2):-1:1
            if(sortedT(c) <= e)
                e = sortedT(c);
                break;
            end
        end
        xlim([s e]);
        legend(fieldArr);
        x_matrix = transpose(x(:, sortIndex));
        t_matrix = transpose(sortedT);
        x_table = array2table(x_matrix);
        t_table = cell2table(cellstr(t_matrix));
        x_table.Properties.VariableNames = cellstr(fieldArr);
        uif = uifigure;
        uit = uitable(uif, 'Data',[t_table,x_table]);
        writetable([t_table,x_table],strcat(seriesStr{1},".xlsx"),"WriteMode","append","AutoFitWidth",false);
    end
    return;
end