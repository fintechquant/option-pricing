function dataBreakRestore(options)
% dataBreakRestore(1:9)   -- break up
% dataBreakRestore(10:19) -- restore

dirBrkIn  = 'C:\Users\pinfuLG\Documents\MATLAB\Production\Data';
dirBrkOut = 'C:\Users\pinfuLG\Documents\MATLAB\Production\Data\test';   % data2git
dirRstIn  = dirBrkOut;   % 'H:\Production\Data';
dirRstOut = dirBrkOut;   % 'H:\Production\Data';

%  break up wPrc_Stocks  --------------------------------------------------------------------------
if ismember(10, options)
    load([dirBrkIn '\wPrc_Stocks.mat']);
    VN = fieldnames(wPrc_Stocks)';   %   VN = {'Volume';'Amt'};
    for v = VN
        vn = v{:};
        disp(['wPrc_' vn ' = wPrc_Stocks.' vn ';']);
        eval(['wPrc_' vn ' = wPrc_Stocks.' vn ';']);
        switch vn
        case 'Volume';  wPrc_Volume = modify(wPrc_Volume, 'type',{'date','cell','single'});  b=10^(floor(log(wPrc_Volume)/log(10))-2);  wPrc_Volume = iff(wPrc_Volume<=1000,wPrc_Volume,b*round(wPrc_Volume/b));
        case 'Amt';     wPrc_Amt    = modify(wPrc_Amt,    'type',{'date','cell','single'});  b=10^(floor(log(wPrc_Amt   )/log(10))-2);  wPrc_Amt    = iff(wPrc_Amt   <=1000,wPrc_Amt,   b*round(wPrc_Amt/b));
        end
        save([dirBrkOut '\wPrc_' vn '.mat'], ['wPrc_' vn]);
        pause(2);
    end
end

%  restore wPrc_Stocks
if ismember(11, options)
    VN = {'Pre_Close';'Open';'High';'Low';'Close';'Volume';'Amt';'AdjFactor';'Total_Shares';'Float_A_Shares';'Free_Float_Shares'; ...
          'Industry_SW';'Industry_Citic';'Industry_Citic2';'Dealnum'}';
    for v = VN
        vn = v{:};
        disp([dirRstIn '\wPrc_' vn ]);
        load([dirRstIn '\wPrc_' vn ]);
        wPrc_Stocks.(vn) = eval(['wPrc_' vn]);
    end
    wPrc_Stocks.Volume = wPrc_Stocks.Volume.modify('type',{'date','cell','double'});
    wPrc_Stocks.Amt    = wPrc_Stocks.Amt.modify(   'type',{'date','cell','double'});
    save([dirRstOut '\wPrc_Stocks.mat'], 'wPrc_Stocks');
end


%  break up wQtr  ---------------------------------------------------------------------------------
if ismember(20, options)
    load([dirBrkIn '\wQtr.mat']);
    VN = fieldnames(wQtr)';  
    for v = VN(27*0+1:27*1);  wQtr1.(v{:}) = wQtr.(v{:});  end;     save([dirBrkOut '\wQtr1.mat'], 'wQtr1');
    for v = VN(27*1+1:27*2);  wQtr2.(v{:}) = wQtr.(v{:});  end;     save([dirBrkOut '\wQtr2.mat'], 'wQtr2');
    for v = VN(27*2+1:27*3);  wQtr3.(v{:}) = wQtr.(v{:});  end;     save([dirBrkOut '\wQtr3.mat'], 'wQtr3');
end

%  restore wQtr
if ismember(21, options)
    load([dirRstIn '\wQtr1.mat']);                               wQtr        = wQtr1;
    load([dirRstIn '\wQtr2.mat']);  for v = fieldnames(wQtr2)';  wQtr.(v{:}) = wQtr2.(v{:});  end
    load([dirRstIn '\wQtr3.mat']);  for v = fieldnames(wQtr3)';  wQtr.(v{:}) = wQtr3.(v{:});  end
    save([dirRstOut '\wQtr.mat'], 'wQtr');
end

%  break up CDSys_Var1 ----------------------------------------------------------------------------
if ismember(30, options)
    load([dirBrkIn '\CDSys_Var3.mat']);
    CDSys_Var = CDSys_Var;
    DF_IntraDay0 = CDSys_Var.Type_Price_Name_Twap0930_FormTime_0930_0930;  
    DF_IntraDay1 = CDSys_Var.Type_Price_Name_Twap1000_FormTime_0930_1000; 
    DF_IntraDay2 = CDSys_Var.Type_Price_Name_Twap1430_FormTime_1400_1430; 
    DF_IntraDay0 = DF_IntraDay0.subset(DF_IntraDay0.Dim1(DF_IntraDay0.Dim1>datenum(2012,1,1)), DF_IntraDay0.Dim2).modify('type',{'date','cell','single'});
    DF_IntraDay1 = DF_IntraDay1.subset(DF_IntraDay1.Dim1(DF_IntraDay1.Dim1>datenum(2012,1,1)), DF_IntraDay1.Dim2).modify('type',{'date','cell','single'});
    DF_IntraDay2 = DF_IntraDay2.subset(DF_IntraDay2.Dim1(DF_IntraDay2.Dim1>datenum(2012,1,1)), DF_IntraDay2.Dim2).modify('type',{'date','cell','single'});
    save([dirBrkOut '\DF_IntraDay0.mat'],'DF_IntraDay0');
    save([dirBrkOut '\DF_IntraDay1.mat'],'DF_IntraDay1');
    save([dirBrkOut '\DF_IntraDay2.mat'],'DF_IntraDay2');
end

%  restore  CDSys_Var1
if ismember(31, options)
    load([dirRstIn '\DF_IntraDay0.mat']);   CDSys_Var.Type_Price_Name_Twap0930_FormTime_0930_0930 = DF_IntraDay0.modify('type',{'date','cell','double'});
    load([dirRstIn '\DF_IntraDay1.mat']);   CDSys_Var.Type_Price_Name_Twap1000_FormTime_0930_1000 = DF_IntraDay1.modify('type',{'date','cell','double'});
    load([dirRstIn '\DF_IntraDay2.mat']);   CDSys_Var.Type_Price_Name_Twap1430_FormTime_1400_1430 = DF_IntraDay2.modify('type',{'date','cell','double'});
    save([dirRstOut '\CDSys_Var1.mat'], 'CDSys_Var');
end

%  break up CDSys_Var1 ----------------------------------------------------------------------------
if ismember(34, options)
    files = dir([dirBrkIn '\data2git\Type_Price_Name_Twap*.mat']);
    files = {files.name};
    for fn = files
        fn = fn{:};
        load([dirBrkIn '\data2git\' fn]);
        tdt = tdt.subset(tdt.Dim1(tdt.Dim1>datenum(2012,1,1)), tdt.Dim2);
        tdt = tdt.modify('type',{'date','cell','single'});
        save([dirBrkOut '\' fn],'tdt');
        clear tdt;
    end
end

%  restore  CDSys_Var
if ismember(35, options)
    files = dir([dirBrkOut '\Type_Price_Name_Twap*.mat']);
    files = {files.name};
    for fn = files
        fn = fn{:};   fn = fn(1:strfind(fn,'.mat')-1);
        load([dirBrkOut '\' fn '.mat']);
        tdt = tdt.subset(tdt.Dim1(tdt.Dim1>datenum(2012,1,1)), tdt.Dim2);
        CDSys_Var.(fn) = tdt.modify('type',{'date','cell','double'});
        clear tdt;
    end
    save([dirBrkOut '\CDSys_Var.mat'],'CDSys_Var');
end


% break up factos
if ismember(40, options)
    load([dirRstIn '\DF_IntraDay0.mat']);   CDSys_Var.Type_Price_Name_Twap0930_FormTime_0930_0930 = DF_IntraDay0.modify('type',{'date','cell','double'});
    load([dirData '\factors_lqy\SUE.mat']); 
    load([dirData '\factors_lqy\RROE.mat']); 
    load([dirData '\factors_lqy\DROE.mat']); 
    load([dirData '\factors_lqy\RE2P.mat']);
    load([dirData '\factors_lqy\DE2P.mat']); 
    load([dirData '\factors_lqy\turnover3d.mat']); 
    load([dirData '\factors_lqy\seasonality2.mat']);

    load([dirBrkIn '\TN_Oper_Rev.mat']);   TN_Oper_Rev = TN_Oper_Rev.modify('type',{'date','cell','single'});   save([dirRstOut, '\TN_Oper_Rev.mat'],'TN_Oper_Rev'); 
    load([dirBrkIn '\TN_ROIC.mat']);       TN_ROIC     = TN_ROIC.modify('type',{'date','cell','single'});       save([dirRstOut, '\TN_ROIC.mat'],    'TN_ROIC'); 
    load([dirBrkIn '\CFPA.mat']);          CFPA        = CFPA.modify('type',{'date','cell','single'});          save([dirRstOut, '\CFPA.mat'],       'CFPA'); 
    
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Growth_ROAG.mat']); 
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Momentum1_SUE.mat']);
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Momentum1_SURI.mat']); 
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Momentum1_SUOI.mat']); 
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Momentum2_BIAS.mat']);
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Quality_QDROA.mat']); 
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Sentiment_VOL.mat']); 
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Sentiment_VOL5D.mat']); 
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Sentiment_VOL3M.mat']);  
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Sentiment_BETA.mat']); 
    load([dirData '\factors_zyd\normalizeAll_winsorize_AdT2_Size_Size.mat']);
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Value1_DE2P.mat']);
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Value2_RE2P.mat']);
    load([dirData '\factors_zyd\orthogonalize_normalizeAll_winsorize_AdT2_Sentiment_FFRsqrA1.mat']);
end

% restore factors
if ismember(41, options)
    load([dirBrkIn '\TN_Oper_Rev.mat']);   TN_Oper_Rev = TN_Oper_Rev.modify('type',{'date','cell','double'});   save([dirRstOut, '\TN_Oper_Rev.mat'],'TN_Oper_Rev'); 
    load([dirBrkIn '\TN_ROIC.mat']);       TN_ROIC     = TN_ROIC.modify(    'type',{'date','cell','double'});   save([dirRstOut, '\TN_ROIC.mat'],    'TN_ROIC'); 
    load([dirBrkIn '\CFPA.mat']);          CFPA        = CFPA.modify(       'type',{'date','cell','double'});   save([dirRstOut, '\CFPA.mat'],       'CFPA'); 
end

%  break up wdbTable1571, windAnalystTable, wConsensusFY0123  -------------------------------------
if ismember(60, options)
%  break up wdbTable1571
    load([dirBrkIn  '\wdbTable1571.mat']);
    wdbTable1571 = wdbTable1571(wdbTable1571.F4_1571>20191231,:);
    save([dirBrkOut '\wdbTable1571.mat'], 'wdbTable1571');

%  break up windAnalystTable
    load([dirBrkIn  '\windAnalystTable.mat']);
    windAnalystTable = windAnalystTable(windAnalystTable.F4_1571>=20181231,:);
    save([dirBrkOut '\windAnalystTable.mat'], 'windAnalystTable');

%  break up wConsensusFY0123
    load([dirBrkIn '\wConsensusFY0123.mat']);
    factors = {'f1','f2','avg'};      fiscals = {'FY0','FY1','FY2','FY3'};
    for fy = fiscals
        for fn = factors
%           eval(['wConsensus_NIs_' fy{:} '.' fn{:} ' = wConsensus.NIs.' fn{:} '.' fy{:} ';']);
            eval(['x = wConsensus.NIs.' fn{:} '.' fy{:} ';']);
            x = x.subset(x.Dim1(x.Dim1>datenum(2010,1,1)), x.Dim2);
            eval(['wConsensus_NIs_' fy{:} '.' fn{:} ' = x;']);
        end
        save([dirBrkOut '\wConsensus_NIs_' fy{:} '.mat'], ['wConsensus_NIs_' fy{:}]);
    end
end

%  restore  wConsensusFY0123
if ismember(61, options)
    load([dirRstIn '\wConsensus_NIs_FY0.mat']);      load([dirRstIn '\wConsensus_NIs_FY1.mat']);  
    load([dirRstIn '\wConsensus_NIs_FY2.mat']);      load([dirRstIn '\wConsensus_NIs_FY3.mat']); 
    wConsensus.NIs.f1.FY0 = wConsensus_NIs_FY0.f1;   wConsensus.NIs.f2.FY0 = wConsensus_NIs_FY0.f2;   wConsensus.NIs.avg.FY0 = wConsensus_NIs_FY0.avg;
    wConsensus.NIs.f1.FY1 = wConsensus_NIs_FY1.f1;   wConsensus.NIs.f2.FY1 = wConsensus_NIs_FY1.f2;   wConsensus.NIs.avg.FY1 = wConsensus_NIs_FY1.avg;
    wConsensus.NIs.f1.FY2 = wConsensus_NIs_FY2.f1;   wConsensus.NIs.f2.FY2 = wConsensus_NIs_FY2.f2;   wConsensus.NIs.avg.FY2 = wConsensus_NIs_FY2.avg;
    wConsensus.NIs.f1.FY3 = wConsensus_NIs_FY3.f1;   wConsensus.NIs.f2.FY3 = wConsensus_NIs_FY3.f2;   wConsensus.NIs.avg.FY3 = wConsensus_NIs_FY3.avg;
    save([dirRstOut '\wConsensusFY0123.mat'], 'wConsensus');
end

end
