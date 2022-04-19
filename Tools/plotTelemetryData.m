T = readtable('csvscripttest_ (1).csv');       %PUT PATH FOR CSV FILE HERE
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
           if ~strcmp(current_series, "log")
                f = figure;
           end
           x_size = size(x);
           x_rows = x_size(1);
           [sortedT, sortIndex] = sort(t);
           for r = 1:x_rows
               x_graph = x(r,:);
               sortedX_graph = x_graph(sortIndex);
               if strcmp(current_series, "log")
                    sortedX_graph
               else
                    plot(sortedT, sortedX_graph)
               end
               hold on
           end
           hold off
           if ~strcmp(current_series, "log")
                title(current_series);
                xlabel("Timestamp");
                legend(fields);
           end
           current_series = T.(6)(row);
           curr_row = row;
           i = 0;
           break;
        end      
    end
end
if ~strcmp(current_series, "log")
    f = figure;
end
x_size = size(x);
x_rows = x_size(1);
[sortedT, sortIndex] = sort(t);
for r = 1:x_rows
   x_graph = x(r,:);
   sortedX_graph = x_graph(sortIndex);
   if strcmp(current_series, "log")
        sortedX_graph
   else
        plot(sortedT, sortedX_graph)
   end
   hold on
end
hold off
if ~strcmp(current_series, "log")
    title(current_series);
    xlabel("Timestamp");
    legend(fields);
end