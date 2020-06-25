function result = num2str2(x, FORMAT)
    result = num2str(x, FORMAT);
    if  size(x,1)==1
        ndig   = str2num(strtok(FORMAT,{'%','.','f'}));
        result = [repmat(' ',1, ndig*size(x,2)-length(result)) result];
    end
end