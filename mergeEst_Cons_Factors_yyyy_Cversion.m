function mergeEst_Cons_Factors_yyyy_Cversion(yyyy)

    dirData0 = [getDir('Data')];
    dirData  = [getDir('Data') '\Test1']; 
    
    TimeStart = cellstr(datestr(now(), 'yyyymmdd HH:MM:SS')) ;
    TimePlan  = cellstr([datestr(today(), 'yyyymmdd') ' ' datestr(0/1440, 'HH:MM:SS')]);

    Year = num2str(yyyy);
    mpower = (0.5)^(1/45);
    
    load([dirData '\mEstSql_FY' Year '.mat'], 'mEstSql');                                 % tbl0A
    yyyy0 = yyyy - 2; if yyyy>=2023; yyyy0 = 2020; end
    idx = mEstSql.entry_datetime>=datenum(yyyy0, 1, 1) & mEstSql.entry_datetime<=datenum(yyyy+1, 5, 1);
    mEstSql(~idx, :) = [];
    
%     用last_update_time当做可获取时间
    load([dirData0 '\TradingDateList.mat']);
    trddim1 = cell2mat(TradingDateList.Day(:,2)) + 8.5/24;
    mEstSql.entry_datetime = [];
    mEstSql.entry_datetime = mEstSql.last_update_time;
    idx00 = strcmp(mEstSql.entry_datetime, 'NaN');
    mEstSql(idx00,:) = [];
    a = datenum(mEstSql.entry_datetime, 'yyyy-mm-dd HH:MM:SS.fff');
    newdim1 = NaN(length(a),1);
    for i = 1:length(newdim1)
        idx = find(a(i) <= trddim1);
        newdim1(i) = trddim1(idx(1));
    end
    mEstSql.trd_datetime = cellstr(datestr(newdim1, 'yyyy-mm-dd HH:MM:SS'));
    mEstSql.trd_datenum = newdim1;
    mEstSql.wind_id =  cellstr(str2mat(mEstSql.wind_id));
    
    mEstSql = sortrows(mEstSql, {'trd_datenum','entry_datetime','report_date','broker_id'});
    [~,idx01,~] = unique(mEstSql(:, [3, 6, 23]), 'rows', 'last');
    idx01 = sort(idx01);
    mEstSqlsub = mEstSql(idx01,[3,6,12,23,20]);
    mEstSqlCell = table2cell(mEstSqlsub);
    stockididx  = cell2mat(mEstSqlCell(:,1));
    
    stockid = unique(mEstSql.stock_id);
    tableresult = table();
    tableresult1 = table();
    tableresult2 = table();
%     tableresult3 = table();
    
    for i = 1:length(stockid)
        
        
        sub_a_ = mEstSqlCell(stockididx == stockid(i),:);
%         sub_a_TdT0 = TdT(num2str(Year), 'merge', sub_a_(:, [4 2 3]), 'mattbl', 'tbl', 'type', {'numeric','numeric','double'});
        sub_a_mat = cell2mat(sub_a_(:, [4 2 3]));
        sub_a_TdT.Dim1    = sort(unique(sub_a_mat(:,1)));
        sub_a_TdT.Dim2    = sort(unique(sub_a_mat(:,2)));
        sub_a_TdT.Data = for_matlab_pivot(sub_a_mat, sub_a_TdT.Dim1, sub_a_TdT.Dim2);        
        data_cal = for_matlab_computewgt(sub_a_TdT.Data, sub_a_TdT.Dim1, mpower);
        temptab = table();
        temptab.datenum  = sub_a_TdT.Dim1;
        temptab.ID = repmat(stockid(i), [size(data_cal,1), 1]);
        temptab.avgvalue = data_cal(:,1);
        temptab.cntvalue = data_cal(:,2);
        
        sub_a_wind = sub_a_(cell2mat(sub_a_(:,5)) == 6 | cell2mat(sub_a_(:,5)) == 96, :);
        if ~isempty(sub_a_wind)
%             sub_a_wind_TdT = TdT(num2str(Year), 'merge', sub_a_wind(:, [4 2 3]), 'mattbl', 'tbl', 'type', {'numeric','numeric','double'});
            sub_a_wind_mat = cell2mat(sub_a_wind(:, [4 2 3]));
            sub_a_wind_TdT.Dim1    = sort(unique(sub_a_wind_mat(:,1)));
            sub_a_wind_TdT.Dim2    = sort(unique(sub_a_wind_mat(:,2)));
            sub_a_wind_TdT.Data = for_matlab_pivot(sub_a_wind_mat, sub_a_wind_TdT.Dim1, sub_a_wind_TdT.Dim2);    
            data_cal_wind = for_matlab_computewgt1(sub_a_wind_TdT.Data, sub_a_wind_TdT.Dim1, data_cal(:,1), sub_a_TdT.Dim1);
            temptab1 = table();
            temptab1.datenum = sub_a_wind_TdT.Dim1;
            temptab1.ID = repmat(stockid(i), [size(data_cal_wind,1), 1]);
            temptab1.event_wind = data_cal_wind(:,1);
            temptab1.evetnum_wind = data_cal_wind(:,2);
        end
        
        sub_a_sunt = sub_a_(cell2mat(sub_a_(:,5)) == 9 | cell2mat(sub_a_(:,5)) == 96, :);
        if ~isempty(sub_a_sunt)
%             sub_a_sunt_TdT = TdT(num2str(Year), 'merge', sub_a_sunt(:, [4 2 3]), 'mattbl', 'tbl', 'type', {'numeric','numeric','double'});
            sub_a_sunt_mat = cell2mat(sub_a_sunt(:, [4 2 3]));
            sub_a_sunt_TdT.Dim1    = sort(unique(sub_a_sunt_mat(:,1)));
            sub_a_sunt_TdT.Dim2    = sort(unique(sub_a_sunt_mat(:,2)));
            sub_a_sunt_TdT.Data = for_matlab_pivot(sub_a_sunt_mat, sub_a_sunt_TdT.Dim1, sub_a_sunt_TdT.Dim2);
            data_cal_sunt = for_matlab_computewgt1(sub_a_sunt_TdT.Data, sub_a_sunt_TdT.Dim1, data_cal(:,1), sub_a_TdT.Dim1);
            temptab2 = table();
            temptab2.datenum = sub_a_sunt_TdT.Dim1;
            temptab2.ID = repmat(stockid(i), [size(data_cal_sunt,1), 1]);
            temptab2.event_sunt = data_cal_sunt(:,1);
            temptab2.evetnum_sunt = data_cal_sunt(:,2);   
        end
        
% %         生产暂时不用n1
%         sub_a_both = sub_a_(cell2mat(sub_a_(:,5)) == 96, :);
%         if ~isempty(sub_a_both)
%             sub_a_both_TdT = TdT(num2str(Year), 'merge', sub_a_both(:, [4 2 3]), 'mattbl', 'tbl', 'type', {'numeric','numeric','double'});
%             data_cal_both = for_matlab_computewgt1(sub_a_both_TdT.Data, sub_a_both_TdT.Dim1, data_cal(:,1), sub_a_TdT.Dim1);
%             temptab3 = table();
%             temptab3.datenum = sub_a_both_TdT.Dim1;
%             temptab3.ID = repmat(stockid(i), [size(data_cal_both,1), 1]);
%             temptab3.event_sunt = data_cal_both(:,1);
%             temptab3.evetnum_sunt = data_cal_both(:,2);   
%         end
%         tableresult3 = [tableresult3 ; temptab3];
        
        tableresult = [tableresult ; temptab];
        tableresult1 = [tableresult1 ; temptab1];
        tableresult2 = [tableresult2 ; temptab2];
        
         
    end
    
    IDstr = cell(length(tableresult.ID),1);
    for i = 1:length(tableresult.ID)
        temp = ['000000' num2str(tableresult.ID(i))]; temp = temp(end-5:end);
        if tableresult.ID(i) >= 600000
            IDstr{i} = [temp '.SH'];
        else
            IDstr{i} = [temp '.SZ'];
        end
    end
    tableresult.IDstr = IDstr;
    
    mEstConsus.NIs.avg = TdT('NIsavg', 'merge', table2cell(tableresult(:, [1 5 3])), 'mattbl', 'tbl', 'type', {'date','cell','double'});
    mEstConsus.NIs.num = TdT('NIsnum', 'merge', table2cell(tableresult(:, [1 5 4])), 'mattbl', 'tbl', 'type', {'date','cell','double'});
    
    IDstr1 = cell(length(tableresult1.ID),1);
    for i = 1:length(tableresult1.ID)
        temp = ['000000' num2str(tableresult1.ID(i))]; temp = temp(end-5:end);
        if tableresult1.ID(i) >= 600000
            IDstr1{i} = [temp '.SH'];
        else
            IDstr1{i} = [temp '.SZ'];
        end
    end
    tableresult1.IDstr = IDstr1;
    
    mEstFactorsWind.NIs.f1 = TdT('WindNIsf1', 'merge', table2cell(tableresult1(:, [1 5 3])), 'mattbl', 'tbl', 'type', {'date','cell','double'});
    mEstFactorsWind.NIs.n1 = TdT('WindNIsn1', 'merge', table2cell(tableresult1(:, [1 5 4])), 'mattbl', 'tbl', 'type', {'date','cell','double'});
    
    IDstr2 = cell(length(tableresult2.ID),1);
    for i = 1:length(tableresult2.ID)
        temp = ['000000' num2str(tableresult2.ID(i))]; temp = temp(end-5:end);
        if tableresult2.ID(i) >= 600000
            IDstr2{i} = [temp '.SH'];
        else
            IDstr2{i} = [temp '.SZ'];
        end
    end
    tableresult2.IDstr = IDstr2;
    
    mEstFactorsSunt.NIs.f1 = TdT('SuntNIsf1', 'merge', table2cell(tableresult2(:, [1 5 3])), 'mattbl', 'tbl', 'type', {'date','cell','double'});
    mEstFactorsSunt.NIs.n1 = TdT('SuntNIsn1', 'merge', table2cell(tableresult2(:, [1 5 4])), 'mattbl', 'tbl', 'type', {'date','cell','double'});  
    
%       生产暂时不用n1
%     IDstr3 = cell(length(tableresult3.ID),1);
%     for i = 1:length(tableresult3.ID)
%         temp = ['000000' num2str(tableresult3.ID(i))]; temp = temp(end-5:end);
%         if tableresult3.ID(i) >= 600000
%             IDstr3{i} = [temp '.SH'];
%         else
%             IDstr3{i} = [temp '.SZ'];
%         end
%     end
%     tableresult3.IDstr = IDstr3;
%     
%     mEstFactorsBoth.NIs.n1 = TdT('SuntNIsn1', 'merge', table2cell(tableresult3(:, [1 5 4])), 'mattbl', 'tbl', 'type', {'date','cell','double'});     
    
    Dim1    = unique(mEstSql.trd_datenum);
    Dim2    = unique(mEstSql.wind_id);
    
    mEstConsus.NIs.avg = ttlast(mEstConsus.NIs.avg, {-9999, 0}, Dim1, Dim2);
    mEstConsus.NIs.num = subset(mEstConsus.NIs.num, Dim1, Dim2);
    
    mEstFactors.NIs.avg = subset(mEstConsus.NIs.avg, Dim1, Dim2);
    windf1 = subset(mEstFactorsWind.NIs.f1, Dim1, Dim2);
    suntf1 = subset(mEstFactorsSunt.NIs.f1, Dim1, Dim2);
    mEstFactors.NIs.f1  = iff(isnan(windf1)&~isnan(suntf1), suntf1, iff(~isnan(windf1)&isnan(suntf1), windf1, iff(~isnan(windf1)&~isnan(suntf1), (windf1+suntf1)/2, NaN)));
    mEstFactors.NIs.n1  = iff(mEstFactors.NIs.f1, 0, 0);
%     mEstFactors.NIs.n1  = iff(isnan(mEstFactorsWind.NIs.n1), 0, mEstFactorsWind.NIs.n1) + iff(isnan(mEstFactorsSunt.NIs.n1), 0, mEstFactorsSunt.NIs.n1) - iff(isnan(mEstFactorsBoth.NIs.n1), 0, mEstFactorsBoth.NIs.n1);
    Temp1 = ttlast(mEstConsus.NIs.avg, {-20, -10});
    Temp  = (mEstConsus.NIs.avg - Temp1) / abs(Temp1) + 1;
    mEstFactors.NIs.f2 = subset(Temp, Dim1, Dim2);

%%     saving mEstConsus_FY & mEstFactors_FY
    status = 0;
    while status(1) == 0
        pause(5); status = dlmread([dirData '\mEstConsus_FY' Year '.status'], ',', [1 0 1 2]); 
    end
    status = readtable([dirData '\mEstConsus_FY' Year '.status'], 'ReadVariableNames', true, 'delimiter', ',', 'filetype', 'text');
    status.TimePlan(1) = {'0'};
    writetable(status, [dirData '\mEstConsus_FY' Year '.status'], 'WriteVariableNames', true, 'delimiter', ',', 'filetype', 'text');
    writetable(status, [dirData '\mEstFactors_FY' Year '.status'], 'WriteVariableNames', true, 'delimiter', ',', 'filetype', 'text');
    
    save([dirData '\mEstConsus_FY' Year '.mat'],  'mEstConsus');
    save([dirData '\mEstFactors_FY' Year '.mat'], 'mEstFactors');
    
    s1 = 15; if size(status,1)>s1; status([2:end-s1], :) = []; end
    status = [status; TimePlan TimeStart cellstr(datestr(now(), 'yyyymmdd HH:MM:SS'))];
    status.TimePlan(1) = {'1'};
    writetable(status, [dirData '\mEstFactors_FY' Year '.status'], 'WriteVariableNames', true, 'delimiter', ',', 'filetype', 'text');
    writetable(status, [dirData '\mEstConsus_FY' Year '.status'], 'WriteVariableNames', true, 'delimiter', ',', 'filetype', 'text');
    
    
    
    

end