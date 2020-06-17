function FactorLab(checkdate,adjustTime)
% checkdate 需要检测的交易日
% FACTORLAB incremental computation
% FactorLab(1)
% FactorLab(2)
% 提供2种计算方法： adjustTime == 1，财务报告数据在报告期截止日统一调整
%                  adjustTime == 2，确保每日生成的因子使用次日开盘前的最新数据（财报 T日公告 T日开盘前披露）

%% LoadData %
    dirRoot = getDir('Production');  dirData = [dirRoot '/Data'];
    controlswitch = checkdate;
%% Parameter
    load([dirData '/AShareEODPrices.mat']);
    load([dirData '/AShareCapitalization.mat']);
    load([dirData '/AShareFreeFloat.mat']);
    load([dirData '/AShareCapitalization.mat']);
    load([dirData '/AShareIncome.mat']);
    load([dirData '/AShareCashFlow.mat']);
    load([dirData '/AShareBalanceSheet.mat']);
    load([dirData '/AShareFinancialIndicator.mat']);
    load([dirData '/AShareDividend.mat']);
    load([dirData '/AShareStaff.mat']);
    load([dirData '/AShareHolderNumber.mat']);
    varWDS = wind2WDSmap();
    varKey = varWDS.keys;
    
%% Parameter
    BackwardDays = 365;
    QtrDim1      = eval([varWDS('wQtr.ACCT_PAYABLE') '.Dim1;']);
    Dim2         = eval([varWDS('wQtr.ACCT_PAYABLE') '.Dim2;']);
    Dim1         = eval([varWDS('wPrc_Stocks.Close') '.Dim1;']);
    Dim1         = Dim1(Dim1>=datenum('20050101','yyyymmdd'));
    for key = varKey
        key = key{:};
        if strcmpi(key(1:5),'wQtr.')
           wQtr.(key) = eval(['subset(' varWDS(key) ',QtrDim1,Dim2;']);
        end
        if strcmpi(key(1:12),'wPrc_Stocks.')
           wPrc_Stocks.(key) = eval(['subset(' varWDS(key) ',Dim1,Dim2;']);
        end
        if strcmpi(key(1:12),'wPrc_Indices.')
           wPrc_Indices.(key) = eval(varWDS(key));
        end
        if strcmpi(key(1:12),'wIdx.')
           wIdx.(key) = eval(varWDS(key));
        end
    end
    wPrc_Stocks.Float_A_Shares    = iff(wPrc_Stocks.Float_A_Shares==0,NaN,wPrc_Stocks.Float_A_Shares);
    wPrc_Stocks.Free_Float_Shares = iff(wPrc_Stocks.Free_Float_Shares==0,NaN,wPrc_Stocks.Free_Float_Shares);
    wPrc_Stocks.Total_Shares      = iff(wPrc_Stocks.Total_Shares==0,NaN,wPrc_Stocks.Total_Shares);
    wPrc_Stocks.FAClose           = wPrc_Stocks.Close * wPrc_Stocks.AdjFactor;

    load([dirRoot '\Data\TradingDateList']);
    dateidx = find(cell2mat(TradingDateList.Day(:,2))<=today()&cell2mat(TradingDateList.Day(:,2))>=datenum('20030101','yyyymmdd'));
    TradeDateList = cell2mat(TradingDateList.Day(dateidx,2));
%     w = windmatlab;
%     [td,~,~,~,~,~]            = w.tdaysoffset(1,datestr(Dim1(end),'yyyy-mm-dd'));
%     [TradeDateList,~,~,~,~,~] = w.tdays('2003-01-01',datestr(td,'yyyy-mm-dd'));
%     try
%         TradeDateList             = datenum(TradeDateList,'yyyy/mm/dd');
%     catch
%         TradeDateList             = datenum(TradeDateList,'yyyy-mm-dd');
%     end
    Stm_IssuingDateList = unique(wQtr.Stm_IssuingDate.Data(isnan(wQtr.Stm_IssuingDate.Data)==0));
    for i =1:length(Stm_IssuingDateList)
        temp = TradeDateList(Stm_IssuingDateList(i)>TradeDateList);
        Stm_PublishDateList(i,1) = temp(end);
    end
    wQtr.Stm_PublishDate = wQtr.Stm_IssuingDate;
    Temp = wQtr.Stm_IssuingDate.Data;
    for i = 1:size(Temp,1)
        for j =1:size(Temp,2)
            if isnan(Temp(i,j))==0
                Temp(i,j) = Stm_PublishDateList(Stm_IssuingDateList==Temp(i,j));
            end
        end
    end
    wQtr.Stm_PublishDate.Data = Temp;
    disp(datestr(Dim1(end)))
%%     

if controlswitch
%% Value1
%DE2P Done 市盈率同比变化   
    DE2P  = iff(monthTdT(wQtr.NP_BELONGTO_PARCOMSH)==3,wQtr.NP_BELONGTO_PARCOMSH,wQtr.NP_BELONGTO_PARCOMSH-tshift(wQtr.NP_BELONGTO_PARCOMSH,-1));  
    DE2P  = DE2P-tshift(DE2P,-4);
    if adjustTime==1
        DE2P.Dim1   = qtr2trd(DE2P.Dim1);
        DE2P = ttlast(DE2P,{-BackwardDays,-0},Dim1,Dim2) / subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);   
    elseif adjustTime==2
        DE2P = ttlast(latestTdT(wQtr.Stm_PublishDate,DE2P),{-BackwardDays,0},Dim1,Dim2) / subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    end
    DE2P.Name = 'DE2P';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_DE2P' '.mat'],'DE2P');
    clear DE2P
end
if controlswitch
%DB2P Done 市盈率同比变化
    DB2P  = wQtr.Tot_Equity-tshift(wQtr.Tot_Equity,-1);  
    DB2P  = DB2P-tshift(DB2P,-4);
    if adjustTime==1
        DB2P.Dim1   = qtr2trd(DB2P.Dim1);
        DB2P = ttlast(DB2P,{-BackwardDays,-0},Dim1,Dim2) / subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);   
    elseif adjustTime==2
        DB2P = ttlast(latestTdT(wQtr.Stm_PublishDate,DB2P),{-BackwardDays,0},Dim1,Dim2) / subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    end
    DB2P.Name = 'DB2P';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_DB2P' '.mat'],'DB2P');
    clear DB2P
end
if controlswitch
%DS2EV Done
    Tot_Oper_Rev  = sum4q(subset(wQtr.Tot_Oper_Rev,QtrDim1,Dim2));
    DS  = Tot_Oper_Rev-tshift(Tot_Oper_Rev,-4);
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        DS.Dim1   = qtr2trd(DS.Dim1);
        DS  = ttlast(DS,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        DS  = ttlast(latestTdT(wQtr.Stm_PublishDate,DS),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
    end          
    DS2EV   = DS/(Lia+ subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2));
    DS2EV.Name = 'DS2EV'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_DS2EV' '.mat'],'DS2EV');
    clear Tot_Oper_Rev DS Lia DS2EV
end
if controlswitch
%AEB2EV Done
    Net_Cash_Flows_Oper_Act    = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2));
    pay_all_typ_tax            = sum4q(subset(wQtr.pay_all_typ_tax,QtrDim1,Dim2));
    recp_tax_rends             = sum4q(subset(wQtr.recp_tax_rends,QtrDim1,Dim2));
    CASH_PAY_ACQ_CONST_FIOLTA  = sum4q(subset(wQtr.CASH_PAY_ACQ_CONST_FIOLTA,QtrDim1,Dim2));
    NET_CASH_RECP_DISP_FIOLTA  = sum4q(subset(wQtr.NET_CASH_RECP_DISP_FIOLTA,QtrDim1,Dim2));
    ADP                        = iff(isnan(CASH_PAY_ACQ_CONST_FIOLTA)==1,0,CASH_PAY_ACQ_CONST_FIOLTA) - iff(isnan(NET_CASH_RECP_DISP_FIOLTA)==1,0,NET_CASH_RECP_DISP_FIOLTA);
    Temp3   = iff(isnan(iff(monthTdT(ADP)==3,ADP,NaN))==1, NaN,trmean(iff(monthTdT(ADP)==3,ADP,NaN),{-23,0}));
    Temp6   = iff(isnan(iff(monthTdT(ADP)==6,ADP,NaN))==1, NaN,trmean(iff(monthTdT(ADP)==6,ADP,NaN),{-23,0}));
    Temp9   = iff(isnan(iff(monthTdT(ADP)==9,ADP,NaN))==1, NaN,trmean(iff(monthTdT(ADP)==9,ADP,NaN),{-23,0}));
    Temp12  = iff(isnan(iff(monthTdT(ADP)==12,ADP,NaN))==1,NaN,trmean(iff(monthTdT(ADP)==12,ADP,NaN),{-23,0}));
    ADP = merge(Temp3,Temp6,Temp9,Temp12);
    Temp                       = Net_Cash_Flows_Oper_Act + iff(isnan(pay_all_typ_tax)==1,0,pay_all_typ_tax) - iff(isnan(recp_tax_rends)==1,0,recp_tax_rends) -ADP;
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        Temp.Dim1   = qtr2trd(Temp.Dim1);
        Temp  = ttlast(Temp,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Temp  = ttlast(latestTdT(wQtr.Stm_PublishDate,Temp),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
    end          
    AEB2EV   = Temp/(Lia+ subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2));
    AEB2EV.Name = 'AEB2EV';  
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_AEB2EV' '.mat'],'AEB2EV');
    clear Net_Cash_Flows_Oper_Act DS pay_all_typ_tax recp_tax_rends CASH_PAY_ACQ_CONST_FIOLTA NET_CASH_RECP_DISP_FIOLTA Temp3 Temp6 Temp9 Temp12 ADP Temp Lia AEB2EV     
end
if controlswitch
%CFO2P Done
    Net_Cash_Flows_Oper_Act = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2));
    if adjustTime==1
        Net_Cash_Flows_Oper_Act.Dim1   = qtr2trd(Net_Cash_Flows_Oper_Act.Dim1);
        Net_Cash_Flows_Oper_Act = ttlast(Net_Cash_Flows_Oper_Act,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Net_Cash_Flows_Oper_Act = ttlast(latestTdT(wQtr.Stm_PublishDate,Net_Cash_Flows_Oper_Act),{-BackwardDays,-0},Dim1,Dim2);
    end       
    CFO2P = Net_Cash_Flows_Oper_Act/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    CFO2P.Name = 'CFO2P'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_CFO2P' '.mat'],'CFO2P');
    clear Net_Cash_Flows_Oper_Act CFO2P
end
if controlswitch
%B2P Done
    Tot_Equity = wQtr.Tot_Equity;
    if adjustTime==1
        Tot_Equity.Dim1   = qtr2trd(Tot_Equity.Dim1);
        Tot_Equity = ttlast(Tot_Equity,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Equity = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Equity),{-BackwardDays,-0},Dim1,Dim2);
    end  
    B2P = Tot_Equity/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    B2P.Name = 'B2P';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_B2P' '.mat'],'B2P');
    clear Tot_Equity B2P
end
if controlswitch
%CFO2EV Done
    Net_Cash_Flows_Oper_Act = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2));
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        Net_Cash_Flows_Oper_Act.Dim1   = qtr2trd(Net_Cash_Flows_Oper_Act.Dim1);
        Net_Cash_Flows_Oper_Act = ttlast(Net_Cash_Flows_Oper_Act,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Net_Cash_Flows_Oper_Act = ttlast(latestTdT(wQtr.Stm_PublishDate,Net_Cash_Flows_Oper_Act),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
    end          
    CFO2EV   = Net_Cash_Flows_Oper_Act/(Lia+ subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2));
    CFO2EV.Name = 'CFO2EV';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_CFO2EV' '.mat'],'CFO2EV');
    clear Net_Cash_Flows_Oper_Act Lia CFO2EV
end
if controlswitch
%E2P Done
    NP_BELONGTO_PARCOMSH = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
    if adjustTime==1
        NP_BELONGTO_PARCOMSH.Dim1   = qtr2trd(NP_BELONGTO_PARCOMSH.Dim1);
        NP_BELONGTO_PARCOMSH = ttlast(NP_BELONGTO_PARCOMSH,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        NP_BELONGTO_PARCOMSH = ttlast(latestTdT(wQtr.Stm_PublishDate,NP_BELONGTO_PARCOMSH),{-BackwardDays,-0},Dim1,Dim2);
    end       
    E2P = NP_BELONGTO_PARCOMSH/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    E2P.Name = 'E2P'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_E2P' '.mat'],'E2P');
    clear NP_BELONGTO_PARCOMSH E2P
end
if controlswitch
%SE2P Done
    NP_BELONGTO_PARCOMSH = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
    MkV                  = ttlast(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),{-180,0},QtrDim1,Dim2);
    SE2P                 = NP_BELONGTO_PARCOMSH/MkV;
    SE2P                 = (SE2P-trmean(SE2P,{-11,0}))/trstd(SE2P,{-11,0})*iff(trcount(SE2P,{-11,0})>=4,1,NaN);
    if adjustTime==1
        SE2P.Dim1   = qtr2trd(SE2P.Dim1);
        SE2P        = ttlast(SE2P,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        SE2P = ttlast(latestTdT(wQtr.Stm_PublishDate,SE2P),{-BackwardDays,-0},Dim1,Dim2);
    end       
    SE2P.Name = 'SE2P';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_SE2P' '.mat'],'SE2P');
    clear NP_BELONGTO_PARCOMSH MkV SE2P   
end
if controlswitch
%DA2EV Done
    Tot_Assets = subset(wQtr.Tot_Assets,QtrDim1,Dim2) - tshift(subset(wQtr.Tot_Assets,QtrDim1,Dim2),-4);
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        Tot_Assets.Dim1   = qtr2trd(Tot_Assets.Dim1);
        Tot_Assets = ttlast(Tot_Assets,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Assets = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Assets),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
    end          
    DA2EV   = Tot_Assets/(Lia+ subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2));
    DA2EV.Name = 'DA2EV';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_DA2EV' '.mat'],'DA2EV');
    clear Tot_Assets Lia DA2EV
end
if controlswitch
%SALE2EV Done
    Oper_Rev = sum4q(subset(wQtr.Oper_Rev,QtrDim1,Dim2));
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        Oper_Rev.Dim1   = qtr2trd(Oper_Rev.Dim1);
        Oper_Rev = ttlast(Oper_Rev,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Oper_Rev = ttlast(latestTdT(wQtr.Stm_PublishDate,Oper_Rev),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
    end          
    SALE2EV   = Oper_Rev/(Lia+ subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2));
    SALE2EV.Name = 'SALE2EV';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_SALE2EV' '.mat'],'SALE2EV');
    clear Oper_Rev Lia SALE2EV    
end
if controlswitch
%TA2EV Done
    Tot_Assets    = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        Tot_Assets.Dim1   = qtr2trd(Tot_Assets.Dim1);
        Tot_Assets = ttlast(Tot_Assets,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Assets = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Assets),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
    end    
    TA2EV   = Tot_Assets/(Lia+ subset(wPrc_Stocks.Total_Shares*wPrc_Stocks.Close,Dim1,Dim2));
    TA2EV.Name = 'TA2EV';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value1_TA2EV' '.mat'],'TA2EV');
    clear Lia Tot_Assets TA2EV
end
if controlswitch
%% Value2
%RB2P Done
    Tot_Equity = wQtr.Tot_Equity;
    if adjustTime==1
        Tot_Equity.Dim1   = qtr2trd(Tot_Equity.Dim1);
        Tot_Equity = ttlast(Tot_Equity,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Equity = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Equity),{-BackwardDays,-0},Dim1,Dim2);
    end      
    RB2P = Tot_Equity/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    RB2P = (RB2P - ttmean(RB2P,{-364,0})) / ttstd(RB2P,{-364,0});
    RB2P.Name = 'RB2P'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value2_RB2P' '.mat'],'RB2P');
    clear Tot_Equity RB2P
end
if controlswitch
%R3YB2P Done
    Tot_Equity = wQtr.Tot_Equity;
    if adjustTime==1
        Tot_Equity.Dim1   = qtr2trd(Tot_Equity.Dim1);
        Tot_Equity = ttlast(Tot_Equity,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Equity = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Equity),{-BackwardDays,-0},Dim1,Dim2);
    end      
    R3YB2P = Tot_Equity/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    R3YB2P = (R3YB2P - ttmean(R3YB2P,{-1094,0})) / ttstd(R3YB2P,{-1094,0});
    R3YB2P.Name = 'R3YB2P'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value2_R3YB2P' '.mat'],'R3YB2P');
    clear Tot_Equity R3YB2P
end
if controlswitch
%RCFO2P Done
    Net_Cash_Flows_Oper_Act = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2));
    if adjustTime==1
        Net_Cash_Flows_Oper_Act.Dim1   = qtr2trd(Net_Cash_Flows_Oper_Act.Dim1);
        Net_Cash_Flows_Oper_Act = ttlast(Net_Cash_Flows_Oper_Act,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Net_Cash_Flows_Oper_Act = ttlast(latestTdT(wQtr.Stm_PublishDate,Net_Cash_Flows_Oper_Act),{-BackwardDays,-0},Dim1,Dim2);
    end      
    RCFO2P = Net_Cash_Flows_Oper_Act/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    RCFO2P = (RCFO2P - ttmean(RCFO2P,{-364,0})) / ttstd(RCFO2P,{-364,0});
    RCFO2P.Name = 'RCFO2P'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value2_RCFO2P' '.mat'],'RCFO2P');
    clear Net_Cash_Flows_Oper_Act RCFO2P   
end
if controlswitch
%R3YCFO2P Done
    Net_Cash_Flows_Oper_Act = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2));
    if adjustTime==1
        Net_Cash_Flows_Oper_Act.Dim1   = qtr2trd(Net_Cash_Flows_Oper_Act.Dim1);
        Net_Cash_Flows_Oper_Act = ttlast(Net_Cash_Flows_Oper_Act,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Net_Cash_Flows_Oper_Act = ttlast(latestTdT(wQtr.Stm_PublishDate,Net_Cash_Flows_Oper_Act),{-BackwardDays,-0},Dim1,Dim2);
    end      
    R3YCFO2P = Net_Cash_Flows_Oper_Act/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    R3YCFO2P = (R3YCFO2P - ttmean(R3YCFO2P,{-1094,0})) / ttstd(R3YCFO2P,{-1094,0});
    R3YCFO2P.Name = 'R3YCFO2P'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value2_R3YCFO2P' '.mat'],'R3YCFO2P');
    clear Net_Cash_Flows_Oper_Act R3YCFO2P    
end
if controlswitch
%RE2P Done 环比E2P
    NP_BELONGTO_PARCOMSH = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
    if adjustTime==1
        NP_BELONGTO_PARCOMSH.Dim1   = qtr2trd(NP_BELONGTO_PARCOMSH.Dim1);
        NP_BELONGTO_PARCOMSH = ttlast(NP_BELONGTO_PARCOMSH,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        NP_BELONGTO_PARCOMSH = ttlast(latestTdT(wQtr.Stm_PublishDate,NP_BELONGTO_PARCOMSH),{-BackwardDays,-0},Dim1,Dim2);
    end       
    RE2P = NP_BELONGTO_PARCOMSH/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    RE2P = (RE2P - ttmean(RE2P,{-364,0})) / ttstd(RE2P,{-364,0});
    RE2P.Name = 'RE2P'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value2_RE2P' '.mat'],'RE2P');
    clear NP_BELONGTO_PARCOMSH RE2P
end
if controlswitch
%R3YE2P Done
    NP_BELONGTO_PARCOMSH = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
    if adjustTime==1
        NP_BELONGTO_PARCOMSH.Dim1   = qtr2trd(NP_BELONGTO_PARCOMSH.Dim1);
        NP_BELONGTO_PARCOMSH = ttlast(NP_BELONGTO_PARCOMSH,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        NP_BELONGTO_PARCOMSH = ttlast(latestTdT(wQtr.Stm_PublishDate,NP_BELONGTO_PARCOMSH),{-BackwardDays,-0},Dim1,Dim2);
    end      
    R3YE2P = NP_BELONGTO_PARCOMSH/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2);
    R3YE2P = (R3YE2P - ttmean(R3YE2P,{-1094,0})) / ttstd(R3YE2P,{-1094,0});
    R3YE2P.Name = 'R3YE2P'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Value2_R3YE2P' '.mat'],'R3YE2P');
    clear NP_BELONGTO_PARCOMSH R3YE2P
end
if controlswitch
%% Sentiment
%ILLIQ
    Amt         = iff(wPrc_Stocks.Amt==0,NaN,wPrc_Stocks.Amt);
    CloseDelta  = iff(wPrc_Stocks.Close==0,NaN,wPrc_Stocks.Close) - iff(wPrc_Stocks.Pre_Close==0,NaN,wPrc_Stocks.Pre_Close);
    CloseDelta  = iff(Amt>0,CloseDelta,NaN);
    CloseDelta  = abs(CloseDelta);
    ILLIQ1W     = trmean(CloseDelta/Amt*100000000,{-5+1,0},Dim1,Dim2);
    ILLIQ1M     = trmean(CloseDelta/Amt*100000000,{-22+1,0},Dim1,Dim2);
    ILLIQ3M     = trmean(CloseDelta/Amt*100000000,{-65+1,0},Dim1,Dim2);
    ILLIQ6M     = trmean(CloseDelta/Amt*100000000,{-125+1,0},Dim1,Dim2);
    ILLIQ12M    = trmean(CloseDelta/Amt*100000000,{-250+1,0},Dim1,Dim2);
    ILLIQ1W.Name  = 'ILLIQ1W';
    ILLIQ1M.Name  = 'ILLIQ1M';
    ILLIQ3M.Name  = 'ILLIQ3M';
    ILLIQ6M.Name  = 'ILLIQ6M';
    ILLIQ12M.Name = 'ILLIQ12M';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_ILLIQ1W' '.mat'],'ILLIQ1W');
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_ILLIQ1M' '.mat'],'ILLIQ1M');
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_ILLIQ3M' '.mat'],'ILLIQ3M');
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_ILLIQ6M' '.mat'],'ILLIQ6M');
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_ILLIQ12M' '.mat'],'ILLIQ12M');
    clear Amt CloseDelta ILLIQ1W ILLIQ1M ILLIQ3M ILLIQ6M ILLIQ12M
end
if controlswitch
% Liquidity
    M    = trmean(wPrc_Stocks.Volume/wPrc_Stocks.Float_A_Shares,{-21,0},Dim1,Dim2);
    M    = iff(M>0,M,NaN);
    STOM = log(M);
    STOQ = log(trmean(M,{-65,0}));
    STOA = log(trmean(M,{-249,0}));
%     STOM = M;
%     STOQ = trmean(M,{-65,0});
%     STOA = trmean(M,{-249,0});
    Liquidity = -(0.35*STOM + 0.35*STOQ + 0.30*STOA);
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_Liquidity' '.mat'],'Liquidity');
    clear M STOM STOQ STOA Liquidity
    
%     Ret  = (tshift(subset(wPrc_Stocks.Close,Dim1,Dim2)*subset(wPrc_Stocks.AdjFactor,Dim1,Dim2),20)/tshift(subset(wPrc_Stocks.Open,Dim1,Dim2)*subset(wPrc_Stocks.AdjFactor,Dim1,Dim2),1)-1)/20;
%     tcumsum(xgpmean(Ret*iff(abs(subset(wPrc_Stocks.Open,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1)<0.092,1,NaN),xrank(VOL,10)));
%     tcumsum(xgpmean(Ret*iff(tshift(abs(subset(wPrc_Stocks.Open,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1),1)<0.092,1,NaN),xrank(STOM,50)));
%     tcumsum(xgpmean(Ret*iff(tshift(abs(subset(wPrc_Stocks.Open,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1),1)<0.092,1,NaN),xrank(VOL,10)));
% %SmartMoney
%     try
%         clear SmartMoney
%         SmartMoney = FactorLab.Sentiment.SmartMoney;
%         Dim1Done   = FactorLab.Sentiment.SmartMoney.Dim1;
%         loopDim1   = Dim1(ismember(Dim1,Dim1Done)==0);
%         if isempty(loopDim1)==0
%             loopDim1 = Dim1(find(loopDim1(1)==Dim1)-22:find(loopDim1(1)==Dim1));
%         elseif isempty(loopDim1)==1
%             loopDim1 = Dim1(end-22:end);
%         end
%     catch
%         clear SmartMoney
%         Dim1Done   = [];
%         loopDim1       = Dim1(ismember(Dim1,Dim1Done)==0);
%     end
%     yearlist       = (unique([year(loopDim1);year(loopDim1)-1]))';
%     for yearnum = yearlist
%         try
%         load([dirRoot '\Data\HFDATAs_' num2str(yearnum) '.mat']);
%         if exist('Last','var')==0
%             Last   = modify(HFDATAs.Last,'Type',{'date' 'cell' 'double'});                    Volume = modify(HFDATAs.Volume,'Type',{'date' 'cell' 'double'});                      Amount = modify(HFDATAs.Amount,'Type',{'date' 'cell' 'double'});
%         elseif exist('Last','var')==1
%             Last   = merge(modify(HFDATAs.Last,'Type',{'date' 'cell' 'double'}),Last);        Volume = merge(modify(HFDATAs.Volume,'Type',{'date' 'cell' 'double'}),Volume);        Amount = merge(modify(HFDATAs.Amount,'Type',{'date' 'cell' 'double'}),Amount);        
%         end
%         clear HFDATAs
%         catch
%         end
%     end
%     Last = subset(Last,Last.Dim1,Dim2);                                                       Volume = subset(Volume,Volume.Dim1,Dim2);                                             Amount = subset(Amount,Amount.Dim1,Dim2);
%     for i = 1:length(loopDim1)
%         if find(loopDim1(i)==Dim1)>=11
%             Dim1T  = loopDim1(i);
%             Dim1OB = Dim1(find(loopDim1(i)==Dim1)-10:find(loopDim1(i)==Dim1)-1);
%             Dim1Min = Last.Dim1(Last.Dim1>=min(Dim1OB)&Last.Dim1<Dim1T);
%             if isempty(Dim1Min)==0&&length(unique(floor(Dim1Min)))==10
%                 oblast   = subset(Last,Dim1Min);
%                 obvolume = subset(Volume,Dim1Min);
%                 obamount = subset(Amount,Dim1Min);
%                 adjF     = ttlast(wPrc_Stocks.AdjFactor,{-inf,0},Dim1Min);
%                 preclose = ttlast(wPrc_Stocks.Pre_Close,{-inf,0},Dim1Min);
%                 faclose  = adjF*oblast;
%                 Ret      = faclose/tshift(faclose,-1)-1;  
%                 RetC     = oblast/preclose-1;
%                 % 剔除
%                 Vprctile = prctile(obvolume.Data,20);
%                 SelectOb = iff(obvolume>=Vprctile,1,NaN);
%                 SelectOb1= iff(sum(double(obvolume.Data>=0&abs(RetC.Data)<=0.098))>length(obvolume.Dim1)*0.50==1,1,NaN); % 50%分钟有成交量数据 并且不是持续涨跌停才计算
%                 obvolume = obvolume*SelectOb;
%                 obvolume.Data = obvolume.Data.*repmat(SelectOb1,length(obvolume.Dim1),1);
%                 obamount = obamount*SelectOb;
%                 obamount.Data = obamount.Data.*repmat(SelectOb1,length(obamount.Dim1),1);
%                 S        = iff(obvolume>0,abs(Ret)/(obvolume)^(1/2),NaN);          % 有成交量才计算
%                 S        = iff(isnan(S)==1,-999,S);
%                 [A,B]    = sort(S.Data,'descend');
%                 obvolume = iff(isnan(obvolume)==1,0,obvolume);
%                 obamount = iff(isnan(obamount)==1,0,obamount);
%                 vtemp    = obvolume.Data(repmat((0:size(A,2)-1).*size(A,1),size(A,1),1) + B);
%                 atemp    = obamount.Data(repmat((0:size(A,2)-1).*size(A,1),size(A,1),1) + B);
%                 adjftemp = adjF.Data(repmat((0:size(A,2)-1).*size(A,1),size(A,1),1) + B);
%                 vtempcunsum = cumsum(vtemp);
%                 vtempP      = vtempcunsum./repmat(vtempcunsum(end,:),size(A,1),1);
%                 Pselect     = double(vtempP<=0.15);
%                 smv         = Pselect.*vtemp;
%                 sma         = Pselect.*atemp;
%                 allv        = vtemp;
%                 alla        = atemp;
%                 smPrice     = sum(sma.*adjftemp)./sum(smv);      %使用复权价
%                 allPrice    = sum(alla.*adjftemp)./sum(allv);    %使用复权价     
%                 SmartMoneyQ = smPrice./allPrice;
%                 if isempty(SmartMoneyQ(SmartMoneyQ==inf))==0
%                     SmartMoneyQ(SmartMoneyQ==inf) = NaN;
%                 end
%                 tempSM       = TdT( 'Last',      'merge', [num2cell(repmat(Dim1T,length(SmartMoneyQ),1)) Dim2' num2cell(SmartMoneyQ')], 'mattbl', 'tbl', 'type', {'date','cell','double'});
%                 if exist('SmartMoney','var')==1
%                     SmartMoney = merge(-tempSM,SmartMoney);
%                     SmartMoney.Name = 'SmartMoney';
%                 else
%                     SmartMoney = -tempSM;
%                 end
%             end
%             clear Dim1T Dim1OB Dim1Min oblast obvolume obamount adjF faclose Ret S A B obvolume obamount vtemp atemp adjftemp vtempcunsum vtempP Pselect
%             clear smv sma allv alla smPrice allPrice SmartMoneyQ tempSM SelectOb
%         end
%     end
%     FactorLab.Sentiment.SmartMoney = subset(SmartMoney,Dim1,Dim2);
%     FactorLab.Sentiment.SmartMoney.Name = 'SmartMoney';
%     clear Last Volume Amount year SmartMoney Dim1Done loopDim1 i yearlist
end
if controlswitch
%DAVOL26 Done
    Volume     = iff(wPrc_Stocks.Volume==0,NaN,wPrc_Stocks.Volume);
    ifcount    = iff(subset(Volume,Dim1,Dim2)==0|abs(subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1)<0.08,1,NaN );
    Volume     = subset(Volume,Dim1,Dim2)*ifcount;
    DAVOL26    = subset(Volume,Dim1,Dim2)/subset(wPrc_Stocks.Float_A_Shares,Dim1,Dim2);
    DAVOL26    = -1*trmean(DAVOL26,{-19,0})/trmean(DAVOL26,{-59,0});
    DAVOL26    = iff(trcount(ifcount,{-19,0})>20*0.75&trcount(ifcount,{-59,0})>60*0.75,DAVOL26,NaN);
    DAVOL26.Name = 'DAVOL26';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_DAVOL26' '.mat'],'DAVOL26');
    clear Volume DAVOL26 ifcount
end
if controlswitch
%PD
    Volume     = iff(wPrc_Stocks.Volume==0,NaN,wPrc_Stocks.Volume);
    TurnOver   = subset(Volume,Dim1,Dim2)/subset(wPrc_Stocks.Total_Shares,Dim1,Dim2);   %换手率
    STOM       = log(trmean(TurnOver,{-20,0}));
    STOQ       = log(trmean(TurnOver,{-62,0}));
    STOA       = log(trmean(TurnOver,{-251,0}));
    PD         = 0.35*STOM+0.35*STOQ+0.30*STOA;
    PD         = -iff(trcount(TurnOver,{-20,0})<21*0.75|trcount(TurnOver,{-62,0})<63*0.5|trcount(TurnOver,{-251,0})<252*0.5,NaN,PD);
    PD.Name    = 'PD';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_PD' '.mat'],'PD');
    clear Volume TurnOver STOM STOQ STOA PD
end
if controlswitch
%AMT1M Done
    Amt     = iff(wPrc_Stocks.Amt==0,NaN,wPrc_Stocks.Amt);
    ifcount = iff(subset(Amt,Dim1,Dim2)==0|abs(subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1)<0.09,1,NaN );
    Amt     = subset(Amt,Dim1,Dim2)*ifcount;
    Amt1M   = -trmean(Amt,{-21,0});
    Amt1M   = iff(trcount(ifcount,{-21,0})>22*0.75,Amt1M,NaN);
    Amt1M.Name    = 'Amt1M';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_Amt1M' '.mat'],'Amt1M');
    clear Volume Amt Amt1M
end
if controlswitch
%AMT6M Done
    Amt     = iff(wPrc_Stocks.Amt==0,NaN,wPrc_Stocks.Amt);
    ifcount = iff(subset(Amt,Dim1,Dim2)==0|abs(subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1)<0.09,1,NaN );
    Amt     = subset(Amt,Dim1,Dim2)*ifcount;
    Amt6M   = -trmean(Amt,{-124,0});
    Amt6M   = iff(trcount(ifcount,{-124,0})>125*0.75,Amt6M,NaN);
    Amt6M.Name    = 'Amt6M';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_Amt6M' '.mat'],'Amt6M');
    clear Volume Amt Amt6M
end
if controlswitch
%AMT12M Done
    Amt     = iff(wPrc_Stocks.Amt==0,NaN,wPrc_Stocks.Amt);
    ifcount = iff(subset(Amt,Dim1,Dim2)==0|abs(subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1)<0.09,1,NaN );
    Amt     = subset(Amt,Dim1,Dim2)*ifcount;
    Amt12M   = -trmean(Amt,{-249,0});
    Amt12M   = iff(trcount(ifcount,{-249,0})>250*0.75,Amt12M,NaN);
    Amt12M.Name    = 'Amt12M';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_Amt12M' '.mat'],'Amt12M');
    clear Volume Amt Amt12M
end
if controlswitch
%AMT3M Done
    Amt     = iff(wPrc_Stocks.Amt==0,NaN,wPrc_Stocks.Amt);
    ifcount = iff(subset(Amt,Dim1,Dim2)==0|abs(subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1)<0.09,1,NaN );
    Amt     = subset(Amt,Dim1,Dim2)*ifcount;
    Amt3M   = -trmean(Amt,{-65,0});
    Amt3M   = iff(trcount(ifcount,{-65,0})>66*0.75,Amt3M,NaN);
    Amt3M.Name    = 'Amt3M';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_Amt3M' '.mat'],'Amt3M');
    clear Volume Amt Amt3M
end
if controlswitch
%REVS Done
    m = (0.5)^(1/20);                                            % 衰减系数
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchange  = iff(Volume>0,1,NaN);
    attenuation = ((1/m).^(0:length(FAClose.Dim1)-1))';           % 衰减序列
    AttenuationTdT = FAClose;
    AttenuationTdT.Data = repmat(attenuation,1,length(FAClose.Dim2));
    Ret         = FAClose/tshift(FAClose,-1)-1;
    REVS    = trsum(Ret*AttenuationTdT,{-39,-0})/trsum(iff(ifexchange==1,AttenuationTdT,NaN),{-39,-0});
    REVS    = iff(trcount(ifexchange,{-39,-0})>40*0.75,REVS,NaN)*-1;  
    REVS    = iff(abs(FAClose/tshift(FAClose,-10)-1)<5&abs(FAClose/tshift(FAClose,-42)-1)<10,REVS,NaN);
    REVS.Name = 'REVS';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_REVS' '.mat'],'REVS');
    clear m attenuation AttenuationTdT FAClose Volume ifexchange TurnOver Ret REVS
end
if controlswitch
%VOL
    m = (0.5)^(1/40);                                           % 衰减系数
    Close       = subset(wPrc_Stocks.Close,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchange  = iff(Volume>0,1,NaN);
    attenuation = ((1/m).^(0:length(Close.Dim1)-1))';           % 衰减序列
    AttenuationTdT = Close;
    AttenuationTdT.Data = repmat(attenuation,1,length(Close.Dim2));
    TurnOver    = subset(wPrc_Stocks.Volume/wPrc_Stocks.Float_A_Shares,Dim1,Dim2);
    VOL    = trsum(TurnOver*AttenuationTdT,{-39,-0})/trsum(iff(ifexchange==1,1,NaN)*AttenuationTdT,{-39,-0});
    VOL    = -iff(trcount(ifexchange,{-39,-0})>=40*0.75,VOL,NaN);       
    VOL.Name = 'VOL';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_VOL' '.mat'],'VOL');
    clear m attenuation AttenuationTdT Close Volume ifexchange TurnOver VOL
end
if controlswitch
%VOL5D
    days = 5;
    m = (0.5)^(1/days);                                           % 衰减系数
    Close       = subset(wPrc_Stocks.Close,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchange  = iff(Volume>0,1,NaN);
    attenuation = ((1/m).^(0:length(Close.Dim1)-1))';           % 衰减序列
    AttenuationTdT = Close;
    AttenuationTdT.Data = repmat(attenuation,1,length(Close.Dim2));
    TurnOver    = subset(wPrc_Stocks.Volume/wPrc_Stocks.Float_A_Shares,Dim1,Dim2);
    VOL5D    = trsum(TurnOver*AttenuationTdT,{-days+1,-0})/trsum(iff(ifexchange==1,1,NaN)*AttenuationTdT,{-days+1,-0});
    VOL5D    = -iff(trcount(ifexchange,{-days+1,-0})>=days*0.75,VOL5D,NaN);       
    VOL5D.Name = 'VOL5D';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_VOL5D' '.mat'],'VOL5D');
    clear m attenuation AttenuationTdT Close Volume ifexchange TurnOver VOL5D
end
if controlswitch
%VOL22D
    days = 22;
    m = (0.5)^(1/days);                                           % 衰减系数
    Close       = subset(wPrc_Stocks.Close,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchange  = iff(Volume>0,1,NaN);
    attenuation = ((1/m).^(0:length(Close.Dim1)-1))';           % 衰减序列
    AttenuationTdT = Close;
    AttenuationTdT.Data = repmat(attenuation,1,length(Close.Dim2));
    TurnOver    = subset(wPrc_Stocks.Volume/wPrc_Stocks.Float_A_Shares,Dim1,Dim2);
    VOL22D    = trsum(TurnOver*AttenuationTdT,{-days+1,-0})/trsum(iff(ifexchange==1,1,NaN)*AttenuationTdT,{-days+1,-0});
    VOL22D    = -iff(trcount(ifexchange,{-days+1,-0})>=days*0.75,VOL22D,NaN);       
    VOL22D.Name = 'VOL22D';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_VOL22D' '.mat'],'VOL22D');
    clear m attenuation AttenuationTdT Close Volume ifexchange TurnOver VOL22D
end
if controlswitch
%VOL3M
    days = 60;
    m = (0.5)^(1/days);                                           % 衰减系数
    Close       = subset(wPrc_Stocks.Close,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchange  = iff(Volume>0,1,NaN);
    attenuation = ((1/m).^(0:length(Close.Dim1)-1))';           % 衰减序列
    AttenuationTdT = Close;
    AttenuationTdT.Data = repmat(attenuation,1,length(Close.Dim2));
    TurnOver    = subset(wPrc_Stocks.Volume/wPrc_Stocks.Float_A_Shares,Dim1,Dim2);
    VOL3M    = trsum(TurnOver*AttenuationTdT,{-days+1,-0})/trsum(iff(ifexchange==1,1,NaN)*AttenuationTdT,{-days+1,-0});
    VOL3M    = -iff(trcount(ifexchange,{-days+1,-0})>=days*0.75,VOL3M,NaN);       
    VOL3M.Name = 'VOL3M';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_VOL3M' '.mat'],'VOL3M');
    clear m attenuation AttenuationTdT Close Volume ifexchange TurnOver VOL3M
end
if controlswitch
%VOLA
    n           = 22;
    Ret         = subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1;
    Ret         = iff(subset(wPrc_Stocks.Volume,Dim1,Dim2)>0,Ret,NaN);
    VOLA        = trstd(Ret,{-n+1,0});
    VOLA        = -iff(trcount(Ret,{-n+1,0})>=n*0.75,VOLA,NaN);
    VOLA.Name = 'VOLA';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_VOLA' '.mat'],'VOLA');
    clear VOLA  Ret n
end
if controlswitch
%FFRsqr
% FFRsqr = FactorLab.Sentiment.FFRsqr;
% save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqr' '.mat'],'FFRsqr');
tic
    GetStockPool = compact(iff(wIdx.CSI800>0,1,NaN));                                     % 以CSI800 估计
    GetStockPool = iff(isnan(GetStockPool)==1,815,GetStockPool);
    GetStockPool = ttlast(GetStockPool,{-inf,0},Dim1,Dim2);
    GetStockPool = iff(GetStockPool==815,NaN,GetStockPool);
    StockRet0    = wPrc_Stocks.Close/wPrc_Stocks.Pre_Close-1;              
    StockRet    = StockRet0*GetStockPool;
    StockRet    = wPrc_Stocks.FAClose/tshift(wPrc_Stocks.FAClose,-1)-1;
    % X1 市场
    MarketRet = subset(wPrc_Indices.Close, wPrc_Indices.Close.Dim1, {'000300.SH'});      
    MarketRet = subset(MarketRet/tshift(MarketRet,-1) - 1,Dim1);           MarketRet.Dim2 = {'MarketRet'};
    % X2 Size
    freemarket  = subset(wPrc_Stocks.Free_Float_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    totalmarket = subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    tmrank      = xrank(trmean(totalmarket,{-21,-0}),2);
    SumMarket   = xgpsum(freemarket,tmrank);
    weight      = freemarket/xgpmap(tmrank,SumMarket);
    Temp        = xgpsum(StockRet*weight,tmrank);
    SizeRet     = MarketRet; 
    SizeRet.Data= Temp.Data(:,1) - Temp.Data(:,2);                         SizeRet.Dim2= {'SizeRet'};
    LCap        = iff(tmrank==2,1,NaN);
    SCap        = iff(tmrank==1,1,NaN); 
    % X3 Value
    Tot_Equity = wQtr.Tot_Equity;
    if adjustTime==1
        Tot_Equity.Dim1   = qtr2trd(Tot_Equity.Dim1);
        Tot_Equity = ttlast(Tot_Equity,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Equity = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Equity),{-BackwardDays,-0},Dim1,Dim2);
    end  
    B2P = Tot_Equity/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    LCapB2P = LCap*trmean(B2P,{-21,-0});                                   SCapB2P = SCap*trmean(B2P,{-21,-0});
    LCapB2PRank = xrank(LCapB2P,3);                                        SCapB2PRank = xrank(SCapB2P,3);
    B2PRank     = iff(LCapB2PRank==3|SCapB2PRank==3,2,iff(LCapB2PRank==1|SCapB2PRank==1,1,NaN));  %2 B2P大 PB小
    SumMarket   = xgpsum(freemarket,B2PRank);                       
    weight      = freemarket/xgpmap(B2PRank,SumMarket);
    Temp        = xgpsum(StockRet*weight,B2PRank);
    B2PRet      = MarketRet; 
    B2PRet.Data = Temp.Data(:,1) - Temp.Data(:,2);                         B2PRet.Dim2 = {'B2PRet'};
    % Rsquare
    try
        clear FFRsqr
        load([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqr' '.mat']);
        Dim1Done    = FFRsqr.Dim1;
        loopDim1   = Dim1(ismember(Dim1,Dim1Done)==0);
        if isempty(loopDim1)==0
            loopDim1 = Dim1(find(loopDim1(1)==Dim1)-22:find(loopDim1(1)==Dim1));
        elseif isempty(loopDim1)==1
            loopDim1 = Dim1(end-22:end);
        end
    catch
        clear FFRsqr
        Dim1Done    = [];
        loopDim1       = Dim1(ismember(Dim1,Dim1Done)==0);
    end
    try
        FFRsqr      = subset(FFRsqr,StockRet.Dim1,StockRet.Dim2);
    catch
        FFRsqr      = iff(StockRet==1,NaN,NaN);
    end
%     disp(['FFRsqr:' datestr(loopDim1,'yyyymmdd')]);
    TempData    = FFRsqr.Data;
%     for i = 1:size(TempData,2)
%         for k = 22:length(loopDim1)
%             try
%                 j = find(loopDim1(k)==FFRsqr.Dim1);
%                 Y = StockRet0.Data(j-22+1:j,i);
%                 n = find(wPrc_Stocks.Volume.Data(j-22+1:j,i)>0&isnan(StockRet0.Data(j-22+1:j,i))~=1);
%                 if length(n)>22*0.75
%                     mr = MarketRet.Data(j-22+1:j,1);
%                     sr = SizeRet.Data(j-22+1:j,1);
%                     br = B2PRet.Data(j-22+1:j,1);
%                     X  = [ones(length(n),1) mr(n) sr(n) br(n)];
%                     y  =Y(n);
%                     [~,~,~,~,stats]=regress(y,X);
%                     TempData(j,i) = stats(1);
%                 end
%                 clear Y n mr sr br X y b bint r rint stats
%             catch
%             end
%         end
%         disp(['StcNum:' repmat(' ',1,5-numel(num2str(i))) num2str(i) '    stats:' num2str(nanmean(TempData(:,i))) '    toc:' num2str(toc) ]);
%     end
    
%     StockVolume = iff(wPrc_Stocks.Volume==0, NaN, wPrc_Stocks.Volume);
%     for i = 1:size(TempData,2)
%         for k = 22:length(loopDim1)
%             try
%                 j = find(loopDim1(k)==FFRsqr.Dim1);
%                 Z = [StockVolume.Data(j-22+1:j,i) StockRet0.Data(j-22+1:j,i) MarketRet.Data(j-22+1:j,1) SizeRet.Data(j-22+1:j,1) B2PRet.Data(j-22+1:j,1)];
%                 idx = find(~isnan(mean(Z,2)));    n = numel(idx);
%                 if  n > 22*0.75
%                     X  = [ones(n,1) Z(idx,3:5)];
%                     y  = Z(idx,2);
%                     TempData(j,i) = (y'*X)/(X'*X) * (X'*y)/(y'*y);   % R2 matrix formula
%                 end
%             catch
%             end
%         end
%         disp(['StcNum:' repmat(' ',1,5-numel(num2str(i))) num2str(i) '    stats:' num2str(nanmean(TempData(:,i))) '    toc:' num2str(toc) ]);
%     end
%     clear n Z X y idx
    StockVolume = iff(wPrc_Stocks.Volume==0, NaN, wPrc_Stocks.Volume);
    for i = 1:size(TempData,2)
        Z = [(1:size(MarketRet.Data,1))' StockVolume.Data(:,i) StockRet0.Data(:,i)  ones(size(MarketRet.Data)) MarketRet.Data SizeRet.Data B2PRet.Data];
        Z = Z(~isnan(mean(Z,2)),:);
        for k = 23:length(loopDim1)
            try
                j = find(loopDim1(k)==FFRsqr.Dim1);
                idx = find(Z(:,1)>=j-22+1 & Z(:,1)<=j);
                if  numel(idx) > 22*0.75
                    y = Z(idx,3);   X = Z(idx,4:7);
                    TempData(j,i) = (y'*X)/(X'*X) * (X'*y)/(y'*y);   % R2 matrix formula
                end
            catch
            end
        end
        disp(['StcNum:' repmat(' ',1,5-numel(num2str(i))) num2str(i) '    stats:' num2str(nanmean(TempData(:,i))) '    toc:' num2str(toc) ]);
    end
    clear Z X y idx
    FFRsqr.Data  = TempData;
    FFRsqr.Name    = 'FFRsqr';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqr' '.mat'],'FFRsqr');
    clear FFRsqr GetStockPool StockRet0 StockRet MarketRet freemarket totalmarket tmrank SumMarket weight Temp SizeRet LCap SCap SCapB2P SCapB2PRank
    clear Tot_Equity B2P LCapB2P LCapB2PRank B2PRank SumMarket totalmarket tmrank SumMarket B2PRet Temp TempData temp i j k loopDim1 Dim1Done N
toc
end
%% 
if controlswitch
%FFRsqrA
% FFRsqrA = FactorLab.Sentiment.FFRsqrA;
% save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqrA' '.mat'],'FFRsqrA');
tic
    GetStockPool = compact(iff(trcount(iff(wPrc_Stocks.Volume>0,1,NaN),{-inf,0})>125,1,NaN));
    GetStockPool = iff(isnan(GetStockPool)==1,815,GetStockPool);
    GetStockPool = ttlast(GetStockPool,{-inf,0},Dim1,Dim2);
    GetStockPool = iff(GetStockPool==815,NaN,GetStockPool);
    StockRet0    = wPrc_Stocks.Close/wPrc_Stocks.Pre_Close-1;              
    StockRet    = StockRet0*GetStockPool;
    StockRet    = wPrc_Stocks.FAClose/tshift(wPrc_Stocks.FAClose,-1)-1;
    % X1 市场
    MarketRet = subset(wPrc_Indices.Close, wPrc_Indices.Close.Dim1, {'000300.SH'});      
    MarketRet = subset(MarketRet/tshift(MarketRet,-1) - 1,Dim1);           MarketRet.Dim2 = {'MarketRet'};
    % X2 Size
    freemarket  = subset(wPrc_Stocks.Free_Float_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    totalmarket = subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    tmrank      = xrank(trmean(totalmarket,{-21,-0}),2);
    SumMarket   = xgpsum(freemarket,tmrank);
    weight      = freemarket/xgpmap(tmrank,SumMarket);
    Temp        = xgpsum(StockRet*weight,tmrank);
    SizeRet     = MarketRet; 
    SizeRet.Data= Temp.Data(:,1) - Temp.Data(:,2);                         SizeRet.Dim2= {'SizeRet'};
    LCap        = iff(tmrank==2,1,NaN);
    SCap        = iff(tmrank==1,1,NaN); 
    % X3 Value
    Tot_Equity = wQtr.Tot_Equity;
    if adjustTime==1
        Tot_Equity.Dim1   = qtr2trd(Tot_Equity.Dim1);
        Tot_Equity = ttlast(Tot_Equity,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Equity = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Equity),{-BackwardDays,-0},Dim1,Dim2);
    end  
    B2P = Tot_Equity/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    LCapB2P = LCap*trmean(B2P,{-21,-0});                                   SCapB2P = SCap*trmean(B2P,{-21,-0});
    LCapB2PRank = xrank(LCapB2P,3);                                        SCapB2PRank = xrank(SCapB2P,3);
    B2PRank     = iff(LCapB2PRank==3|SCapB2PRank==3,2,iff(LCapB2PRank==1|SCapB2PRank==1,1,NaN));  %2 B2P大 PB小
    SumMarket   = xgpsum(freemarket,B2PRank);                       
    weight      = freemarket/xgpmap(B2PRank,SumMarket);
    Temp        = xgpsum(StockRet*weight,B2PRank);
    B2PRet      = MarketRet; 
    B2PRet.Data = Temp.Data(:,1) - Temp.Data(:,2);                         B2PRet.Dim2 = {'B2PRet'};
    clear tmrank SumMarket weight Temp LCap SCap Tot_Equity B2P LCapB2P SCapB2P LCapB2PRank SCapB2PRank B2PRank
    % Rsquare
    try
        clear FFRsqrA
        load([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqrA' '.mat']);
        Dim1Done    = FFRsqrA.Dim1;
        loopDim1   = Dim1(ismember(Dim1,Dim1Done)==0);
        if isempty(loopDim1)==0
            loopDim1 = Dim1(find(loopDim1(1)==Dim1)-22:find(loopDim1(1)==Dim1));
        elseif isempty(loopDim1)==1
            loopDim1 = Dim1(end-22:end);
        end
    catch
        clear FFRsqrA
        Dim1Done    = [];
        loopDim1       = Dim1(ismember(Dim1,Dim1Done)==0);
    end
    try
        FFRsqrA      = subset(FFRsqrA,StockRet.Dim1,StockRet.Dim2);
    catch
        FFRsqrA      = iff(StockRet==1,NaN,NaN);
    end
%     disp(['FFRsqr:' datestr(loopDim1,'yyyymmdd')]);
    TempData    = FFRsqrA.Data;
    StockVolume = iff(wPrc_Stocks.Volume==0, NaN, wPrc_Stocks.Volume);
    for i = 1:size(TempData,2)
        Z = [(1:size(MarketRet.Data,1))' StockVolume.Data(:,i) StockRet0.Data(:,i)  ones(size(MarketRet.Data)) MarketRet.Data SizeRet.Data B2PRet.Data];
        Z = Z(~isnan(mean(Z,2)),:);
        for k = 23:length(loopDim1)
            try
                j = find(loopDim1(k)==FFRsqrA.Dim1);
                idx = find(Z(:,1)>=j-22+1 & Z(:,1)<=j);
                if  numel(idx) > 22*0.75
                    y = Z(idx,3);   X = Z(idx,4:7);
                    TempData(j,i) = (y'*X)/(X'*X) * (X'*y)/(y'*y);   % R2 matrix formula
                end
            catch
            end
        end
        disp(['StcNum:' repmat(' ',1,5-numel(num2str(i))) num2str(i) '    stats:' num2str(nanmean(TempData(:,i))) '    toc:' num2str(toc) ]);
    end
    clear Z X y idx
%     for i = 1:size(TempData,2)
%         disp(['StcNum:' num2str(i)]);
%         for k = 1:1:length(loopDim1)
%             try
%             j = find(loopDim1(k)==FFRsqrA.Dim1);
%             Y = StockRet0.Data(j-22+1:j,i);
%             n = find(wPrc_Stocks.Volume.Data(j-22+1:j,i)>0&isnan(StockRet0.Data(j-22+1:j,i))~=1);
%             if length(n)>22*0.75
%                 mr = MarketRet.Data(j-22+1:j,1);
%                 sr = SizeRet.Data(j-22+1:j,1);
%                 br = B2PRet.Data(j-22+1:j,1);
%                 X  = [ones(length(n),1) mr(n) sr(n) br(n)];
%                 y  =Y(n);
%                 [~,~,~,~,stats]=regress(y,X);
%                 TempData(j,i) = stats(1);
%             end
%             clear Y n mr sr br X y b bint r rint stats
%             catch
%             end
%         end
%     end
    FFRsqrA.Data  = TempData;
    FFRsqrA.Name  = 'FFRsqrA';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqrA' '.mat'],'FFRsqrA');
    clear FFRsqrA GetStockPool StockRet0 StockRet MarketRet freemarket totalmarket tmrank SumMarket weight Temp SizeRet LCap SCap SCapB2P SCapB2PRank
    clear Tot_Equity B2P LCapB2P LCapB2PRank B2PRank SumMarket totalmarket tmrank SumMarket B2PRet Temp TempData temp i j k loopDim1 Dim1Done N
toc
end
if controlswitch
%FFRsqrA1
tic
% FFRsqrA1 = FactorLab.Sentiment.FFRsqrA1;
% save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqrA1' '.mat'],'FFRsqrA1');
    GetStockPool = compact(iff(trcount(iff(wPrc_Stocks.Volume>0,1,NaN),{-inf,0})>125,1,NaN));
    GetStockPool = iff(isnan(GetStockPool)==1,815,GetStockPool);
    GetStockPool = ttlast(GetStockPool,{-inf,0},Dim1,Dim2);
    GetStockPool = iff(GetStockPool==815,NaN,GetStockPool);
    StockRet0    = wPrc_Stocks.Close/wPrc_Stocks.Pre_Close-1;              
    StockRet     = StockRet0*GetStockPool;
    StockRet     = wPrc_Stocks.FAClose/tshift(wPrc_Stocks.FAClose,-1)-1;
    % X1 X2 市场
    MarketRet    = subset(wPrc_Indices.Close, wPrc_Indices.Close.Dim1, {'000300.SH'});      
    MarketRet    = subset(MarketRet/tshift(MarketRet,-1) - 1,Dim1);          MarketRet.Dim2  = {'MarketRet'};
    MarketRet1   = subset(wPrc_Indices.Close, wPrc_Indices.Close.Dim1, {'000905.SH'});      
    MarketRet1   = subset(MarketRet1/tshift(MarketRet1,-1) - 1,Dim1);        MarketRet1.Dim2 = {'MarketRet1'};    
    % X3 Size X4 B2P 
    freemarket   = subset(wPrc_Stocks.Free_Float_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    totalmarket  = subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    tmrank       = xrank(totalmarket,2);                   % 股票池内 总市值分组
    Tot_Equity   = wQtr.Tot_Equity;
    if adjustTime==1
        Tot_Equity.Dim1   = qtr2trd(Tot_Equity.Dim1);
        Tot_Equity = ttlast(Tot_Equity,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Equity = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Equity),{-BackwardDays,-0},Dim1,Dim2);
    end  
    B2P         = Tot_Equity/subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2)*GetStockPool;
    B2Prank     = xrank(B2P,10);
    B2Prank     = iff(B2Prank<=3,1,iff(B2Prank>=8,3,iff(B2Prank>3&B2Prank<8,2,NaN)));
    
    tmrankR     = xrank(totalmarket,B2Prank,2);                            % 市值分组
    SumMarket   = xgpsum(freemarket,tmrankR);                              % 市值分组流通市值
    weight      = freemarket/xgpmap(tmrankR,SumMarket);                    % 市值分组权重
    Temp        = xgpsum(StockRet*weight,tmrankR);                         % 市值分组
    SizeRet     = MarketRet; 
    SizeRet.Data= Temp.Data(:,1) - Temp.Data(:,2);                         SizeRet.Dim2= {'SizeRet'};
    
    B2PrankR    = xrank(B2P        ,tmrank ,10);                              % B2P分组
    B2PrankR    = iff(B2PrankR<=4,1,iff(B2PrankR>=7,2,NaN));
    SumMarket   = xgpsum(freemarket,B2PrankR);                             % 
    weight      = freemarket/xgpmap(B2PrankR,SumMarket);
    Temp        = xgpsum(StockRet*weight,B2PrankR);
    B2PRet      = MarketRet; 
    B2PRet.Data = Temp.Data(:,1) - Temp.Data(:,2);                         B2PRet.Dim2 = {'B2PRet'};    
    % X5 Indu
    indexCode    = { 'CI005001.WI','CI005002.WI','CI005003.WI','CI005004.WI','CI005005.WI','CI005006.WI','CI005007.WI',...
                     'CI005008.WI','CI005009.WI','CI005010.WI','CI005011.WI','CI005012.WI','CI005013.WI','CI005014.WI',...
                     'CI005015.WI','CI005016.WI','CI005017.WI','CI005018.WI','CI005019.WI','CI005020.WI','CI005021.WI',...
                     'CI005022.WI','CI005023.WI','CI005024.WI','CI005025.WI','CI005026.WI','CI005027.WI','CI005028.WI',...
                     'CI005029.WI' };
    temp = subset(wPrc_Indices.Close, Dim1, indexCode);                          %中信29个行业日收益率
    temp = temp/tshift(temp,-1) - 1;
    temp = modify(temp,'Dim2',cellfun(@str2num,regexprep(temp.Dim2,'CI00|[.]WI','')),'Type',{'date','numeric','double'});
    InduRet      = xgpmap(subset(ttlast(wPrc_Stocks.Industry_Citic,{-inf,0}),Dim1,Dim2),subset(temp,Dim1));
    % Rsquare
    try
        clear FFRsqrA1
        load([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqrA1' '.mat']);
        Dim1Done     = FFRsqrA1.Dim1;
        loopDim1     = Dim1(ismember(Dim1,Dim1Done)==0);
        if isempty(loopDim1)==0
            loopDim1 = Dim1(find(loopDim1(1)==Dim1)-22:find(loopDim1(1)==Dim1));
        elseif isempty(loopDim1)==1
            loopDim1 = Dim1(end-22:end);
        end
    catch
        clear FFRsqrA1
        Dim1Done    = [];
        loopDim1       = Dim1(ismember(Dim1,Dim1Done)==0);
    end
    try
        FFRsqrA1      = subset(FFRsqrA1,StockRet.Dim1,StockRet.Dim2);
    catch
        FFRsqrA1      = iff(StockRet==1,NaN,NaN);
    end
    %disp(['FFRsqr:' datestr(loopDim1,'yyyymmdd')]);
    TempData    = FFRsqrA1.Data;
    StockVolume = iff(wPrc_Stocks.Volume==0, NaN, wPrc_Stocks.Volume);
    for i = 1:size(TempData,2)
        Z = [(1:size(MarketRet.Data,1))' StockVolume.Data(:,i) StockRet0.Data(:,i)  ones(size(MarketRet.Data)) MarketRet.Data MarketRet1.Data SizeRet.Data B2PRet.Data InduRet.Data(:,i)];
        Z = Z(~isnan(mean(Z,2)),:);
        for k = 23:length(loopDim1)
            try
                j = find(loopDim1(k)==FFRsqrA1.Dim1);
                idx = find(Z(:,1)>=j-22+1 & Z(:,1)<=j);
                if  numel(idx) > 22*0.75
                    y = Z(idx,3);   X = Z(idx,4:9);
                    TempData(j,i) = (y'*X)/(X'*X) * (X'*y)/(y'*y);   % R2 matrix formula
                end
            catch
            end
        end
        disp(['StcNum:' repmat(' ',1,5-numel(num2str(i))) num2str(i) '    stats:' num2str(nanmean(TempData(:,i))) '    toc:' num2str(toc) ]);
    end
    clear Z X y idx
%     for i = 1:size(TempData,2)
%         disp(['StcNum:' num2str(i)]);
%         for k = 1:1:length(loopDim1)
%             try
%             j = find(loopDim1(k)==FFRsqrA1.Dim1);
%             Y = StockRet0.Data(j-22+1:j,i);
%             n = find(wPrc_Stocks.Volume.Data(j-22+1:j,i)>0&isnan(StockRet0.Data(j-22+1:j,i))~=1);
%             if length(n)>22*0.75
%                 mr  = MarketRet.Data(j-22+1:j,1);
%                 mr1 = MarketRet1.Data(j-22+1:j,1);
%                 sr = SizeRet.Data(j-22+1:j,1);
%                 br = B2PRet.Data(j-22+1:j,1);
%                 Id = InduRet.Data(j-22+1:j,i);
%                 X  = [ones(length(n),1) mr(n) mr1(n) sr(n) br(n) Id(n)];
%                 y  = Y(n);
%                 [~,~,~,~,stats]=regress(y,X);
%                 TempData(j,i) = stats(1);
%             end
%             clear Y n mr mr1 sr br Id X y b bint r rint stats
%             catch
%             end
%         end
%     end
    FFRsqrA1.Data  = TempData;
    FFRsqrA1.Name  = 'FFRsqrA1';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_FFRsqrA1' '.mat'],'FFRsqrA1');
    clear FFRsqrA1 GetStockPool StockRet0 StockRet MarketRet freemarket totalmarket tmrank SumMarket weight Temp SizeRet LCap SCap SCapB2P SCapB2PRank B2Prank B2PrankR
    clear Tot_Equity B2P LCapB2P LCapB2PRank B2PRank SumMarket totalmarket tmrank SumMarket B2PRet Temp TempData temp i j k loopDim1 Dim1Done indexCode InduRet MarketRet1 tmrankR N
toc
end
if controlswitch
%CORREL
    n           = 22;
    Ret         = subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1;
    Ret         = iff(subset(wPrc_Stocks.Volume,Dim1,Dim2)>0,Ret,NaN);
    RetAll      = xmean(Ret);
    X           = Ret;
    N           = trcount(X,{-n+1,0});                                     % modified by zhiyd at 20161018
    Y           = RetAll;
    X2          = X*X;
    Y2          = Y*Y;
    s           = N*trsum(X*Y,{-n+1,0})-trsum(X,{-n+1,0})*trsum(Y,{-n+1,0});                                                  % modified by zhiyd at 20161018
    m           = ((N*trsum(X2,{-n+1,0})-(trsum(X,{-n+1,0}))^2)^(1/2))*((N*trsum(Y2,{-n+1,0})-(trsum(Y,{-n+1,0}))^2)^(1/2));  % modified by zhiyd at 20161018
    CORREL      = s/m;
    CORREL      = iff(trcount(Ret,{-n+1,0})>=n*0.75,CORREL,NaN);
    CORREL.Name = 'CORREL';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_CORREL' '.mat'],'CORREL');
    clear Nn Ret RetAll X Y X2 Y2 s m CORREL
%Beta
    n           = 22;
    Ret         = subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1;
    Ret         = iff(subset(wPrc_Stocks.Volume,Dim1,Dim2)>0,Ret,NaN);
    RetAll      = xmean(Ret);
    one         = iff(isnan(Ret)==0,1,NaN);
    Temp        = Ret;
    Temp.Data   = repmat(RetAll.Data,1,length(Temp.Dim2));
    RetAll      = Temp;
    ifq       = iff(isnan(one)==1|isnan(RetAll)==1|isnan(Ret)==1,NaN,1);
    Ret       = Ret*ifq;
    one       = one*ifq;
    RetAll    = RetAll*ifq;    
    y      = Ret;   
    x0     = one;
    x1     = RetAll;
    x1sqr  = x1*x1;
    ysqr   = y*y;
    x1mean = trmean(x1,{-n+1,0});
    ymean  = trmean(y,{-n+1,0});
    beta      = ((trcount(y,{-n+1,0})*(trsum(y*x1,{-n+1,0}))-trsum(x1,{-n+1,0})*trsum(y,{-n+1,0}))/(trcount(y,{-n+1,0})*trsum(x1sqr,{-n+1,0}) - trsum(x1,{-n+1,0})*trsum(x1,{-n+1,0})));
    alpha     = (ymean - beta*x1mean);   
    beta      = iff(trcount(y,{-n+1,0})>=n*0.75,beta,NaN);
    alpha     = iff(trcount(y,{-n+1,0})>=n*0.75,alpha,NaN);
    BETA        = beta;
    BETA.Name   = 'BETA';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_BETA' '.mat'],'BETA');
    clear Nn Ret RetAll X Y X2 Y2 s m BETA y x0 x1 x1sqr ysqr x1mean ymean beta alpha
%Beta2M
    n           = 250;
    Ret         = subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Pre_Close,Dim1,Dim2)-1;
    Ret         = iff(subset(wPrc_Stocks.Volume,Dim1,Dim2)>0,Ret,NaN);
    RetAll      = subset(wPrc_Indices.Close,Dim1,{'000300.SH'});
    RetAll      = RetAll/tshift(RetAll,-1)-1;
    Temp        = Ret;
    Temp.Data   = repmat(RetAll.Data,1,length(Temp.Dim2));
    RetAll      = Temp;
    one         = iff(isnan(Ret)==0,1,NaN);
    ifq       = iff(isnan(one)==1|isnan(RetAll)==1|isnan(Ret)==1|iff(abs(Ret)>0.095,1,NaN)==1|iff(abs(Ret-RetAll)>0.05,1,NaN)==1,NaN,1);
    Ret       = Ret*ifq;
    one       = one*ifq;
    RetAll    = RetAll*ifq;    
    y      = Ret;   
    x0     = one;
    x1     = RetAll;
    x1sqr  = x1*x1;
    ysqr   = y*y;
    x1mean = trmean(x1,{-n+1,0});
    ymean  = trmean(y,{-n+1,0});
    beta      = ((trcount(y,{-n+1,0})*(trsum(y*x1,{-n+1,0}))-trsum(x1,{-n+1,0})*trsum(y,{-n+1,0}))/(trcount(y,{-n+1,0})*trsum(x1sqr,{-n+1,0}) - trsum(x1,{-n+1,0})*trsum(x1,{-n+1,0})));
    alpha     = (ymean - beta*x1mean);   
    beta      = iff(trcount(y,{-n+1,0})>=n*0.75,beta,NaN);
    alpha     = iff(trcount(y,{-n+1,0})>=n*0.75,alpha,NaN);
    Beta2M        = beta;
    Beta2M.Name   = 'Beta2M';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_Beta2M' '.mat'],'Beta2M');
    clear Nn Ret RetAll X Y X2 Y2 s m BETA y x0 x1 x1sqr ysqr x1mean ymean beta alpha    
%BetaYear
    for weekdays  = 2:6
        n         = 52;
        tempDim1  = Dim1(weekday(Dim1)==weekdays);
        tempClose = ttlast(iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),{-inf,0},tempDim1,Dim2)*ttlast(wPrc_Stocks.AdjFactor,{-inf,0},tempDim1,Dim2);
        Amt       = ttsum(wPrc_Stocks.Amt,{-6,0},tempDim1);
        Ret       = tempClose/tshift(tempClose,-1)-1;
        Ret       = iff(Amt>0,Ret,NaN);
        RetAll    = subset(wPrc_Indices.Close,tempDim1,{'000300.SH'});
        RetAll    = RetAll/tshift(RetAll,-1)-1;
        Temp      = Ret;
        Temp.Data = repmat(RetAll.Data,1,length(Temp.Dim2));
        RetAll    = Temp;
        one       = iff(isnan(Ret)==0,1,NaN);
        ifq       = iff(isnan(one)==1|isnan(RetAll)==1|isnan(Ret)==1,NaN,1);
        Ret       = Ret*ifq;
        one       = one*ifq;
        RetAll    = RetAll*ifq;
        y      = Ret;   
        x0     = one;
        x1     = RetAll;
        x1sqr  = x1*x1;
        ysqr   = y*y;
        x1mean = trmean(x1,{-n+1,0});
        ymean  = trmean(y,{-n+1,0});
        beta      = ((trcount(y,{-n+1,0})*(trsum(y*x1,{-n+1,0}))-trsum(x1,{-n+1,0})*trsum(y,{-n+1,0}))/(trcount(y,{-n+1,0})*trsum(x1sqr,{-n+1,0}) - trsum(x1,{-n+1,0})*trsum(x1,{-n+1,0})));
        alpha     = (ymean - beta*x1mean);   
        beta      = iff(trcount(y,{-n+1,0})>=n*0.75,beta,NaN);
        alpha     = iff(trcount(y,{-n+1,0})>=n*0.75,alpha,NaN);       
        if exist('BetaYear','var')==0
            BetaYear = beta;
            BetaYear.Name   = 'BetaYear';
        else
            BetaYear = merge(BetaYear,beta);
            BetaYear.Name   = 'BetaYear';
        end  
        clear N n Ret RetAll X Y X2 Y2 s m BETA y x0 x1 x1sqr ysqr x1mean ymean beta alpha ifq tempDim1 tempClose Temp
    end
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Sentiment_BetaYear' '.mat'],'BetaYear');
    clear BetaYear
%% Quality
%EPS Done
    NP_BELONGTO_PARCOMSH   = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
    if adjustTime==1
        NP_BELONGTO_PARCOMSH.Dim1   = qtr2trd(NP_BELONGTO_PARCOMSH.Dim1);
        NP_BELONGTO_PARCOMSH = ttlast(NP_BELONGTO_PARCOMSH,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        NP_BELONGTO_PARCOMSH = ttlast(latestTdT(wQtr.Stm_PublishDate,NP_BELONGTO_PARCOMSH),{-BackwardDays,-0},Dim1,Dim2);
    end        
    EPS = NP_BELONGTO_PARCOMSH/subset(wPrc_Stocks.Total_Shares,Dim1,Dim2);
    EPS.Name = 'EPS';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_EPS' '.mat'],'EPS');
    clear NP_BELONGTO_PARCOMSH EPS     
%ACCA Done
    ACCA = ( sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2)) - sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2)))  / ((subset(wQtr.Tot_Assets,QtrDim1,Dim2) + tshift(subset(wQtr.Tot_Assets,QtrDim1,Dim2),-4))/2);    
    if adjustTime==1
        ACCA.Dim1   = qtr2trd(ACCA.Dim1);
        ACCA = ttlast(ACCA,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        ACCA = ttlast(latestTdT(wQtr.Stm_PublishDate,ACCA),{-BackwardDays,0},Dim1,Dim2);
    end  
    ACCA.Name = 'ACCA'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_ACCA' '.mat'],'ACCA');
    clear ACCA
%DSP Done 人均产出
    temp = sum4q(subset(wQtr.Tot_Oper_Rev,QtrDim1,Dim2))/wQtr.employee;
    Temp3   = iff(isnan(iff(monthTdT(temp)==3,temp,NaN))==1, NaN,trmean(iff(monthTdT(temp)==3,temp,NaN),{-19,0}));
    Temp6   = iff(isnan(iff(monthTdT(temp)==6,temp,NaN))==1, NaN,trmean(iff(monthTdT(temp)==6,temp,NaN),{-19,0}));
    Temp9   = iff(isnan(iff(monthTdT(temp)==9,temp,NaN))==1, NaN,trmean(iff(monthTdT(temp)==9,temp,NaN),{-19,0}));
    Temp12  = iff(isnan(iff(monthTdT(temp)==12,temp,NaN))==1,NaN,trmean(iff(monthTdT(temp)==12,temp,NaN),{-19,0}));
    tempmean = merge(Temp3,Temp6,Temp9,Temp12);
    DSP  = (temp-tshift(temp,-4))/tempmean;
    if adjustTime==1
        DSP.Dim1   = qtr2trd(DSP.Dim1);
        DSP = ttlast(DSP,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        DSP = ttlast(latestTdT(wQtr.Stm_PublishDate,DSP),{-BackwardDays,-0},Dim1,Dim2);
    end   
    DSP.Name = 'DSP';  
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_DSP' '.mat'],'DSP');
    clear temp Temp3 Temp6 Temp9 Temp12 tempmean DSP
%GPR Done 毛利率
    OpProfit = sum4q(subset(wQtr.OpProfit,QtrDim1,Dim2));
    Tot_Oper_Rev  = sum4q(subset(wQtr.Tot_Oper_Rev,QtrDim1,Dim2));
    GPR           = OpProfit/Tot_Oper_Rev;
    if adjustTime==1
        GPR.Dim1   = qtr2trd(GPR.Dim1);
        GPR = ttlast(GPR,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        GPR = ttlast(latestTdT(wQtr.Stm_PublishDate,GPR),{-BackwardDays,-0},Dim1,Dim2);
    end   
    GPR.Name = 'GPR';  
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_GPR' '.mat'],'GPR');
    clear OpProfit Tot_Oper_Rev GPR 
%NPR Done 净利率
    Net_Profit_Is = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2));
    Tot_Oper_Rev  = sum4q(subset(wQtr.Tot_Oper_Rev,QtrDim1,Dim2));
    NPR           = Net_Profit_Is/Tot_Oper_Rev;
    if adjustTime==1
        NPR.Dim1   = qtr2trd(NPR.Dim1);
        NPR = ttlast(NPR,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        NPR = ttlast(latestTdT(wQtr.Stm_PublishDate,NPR),{-BackwardDays,-0},Dim1,Dim2);
    end   
    NPR.Name = 'NPR';  
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_NPR' '.mat'],'NPR');
    clear Net_Profit_Is Tot_Oper_Rev NPR     
%DGPR Done 净利润同比变化
    OpProfit = sum4q(subset(wQtr.OpProfit,QtrDim1,Dim2));
    Tot_Oper_Rev  = sum4q(subset(wQtr.Tot_Oper_Rev,QtrDim1,Dim2));
    DGPR          = OpProfit/Tot_Oper_Rev;
    DGPR          = DGPR-tshift(DGPR,-4);
    if adjustTime==1
        DGPR.Dim1   = qtr2trd(DGPR.Dim1);
        DGPR = ttlast(DGPR,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        DGPR = ttlast(latestTdT(wQtr.Stm_PublishDate,DGPR),{-BackwardDays,-0},Dim1,Dim2);
    end   
    DGPR.Name = 'DGPR';  
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_DGPR' '.mat'],'DGPR');
    clear OpProfit Tot_Oper_Rev DGPR 
    
%LGPR Done 净利润环比
    LGPR    = sum4q(subset(wQtr.OpProfit,QtrDim1,Dim2)) / sum4q(subset(iff(wQtr.Tot_Oper_Rev==0,1,wQtr.Tot_Oper_Rev),QtrDim1,Dim2));
    Temp3   = iff(isnan(iff(monthTdT(LGPR)==3,LGPR,NaN))==1, NaN,trmean(iff(monthTdT(LGPR)==3,LGPR,NaN),{-20,-1}));
    Temp6   = iff(isnan(iff(monthTdT(LGPR)==6,LGPR,NaN))==1, NaN,trmean(iff(monthTdT(LGPR)==6,LGPR,NaN),{-20,-1}));
    Temp9   = iff(isnan(iff(monthTdT(LGPR)==9,LGPR,NaN))==1, NaN,trmean(iff(monthTdT(LGPR)==9,LGPR,NaN),{-20,-1}));
    Temp12  = iff(isnan(iff(monthTdT(LGPR)==12,LGPR,NaN))==1,NaN,trmean(iff(monthTdT(LGPR)==12,LGPR,NaN),{-20,-1}));
    LGPR = LGPR - merge(Temp3,Temp6,Temp9,Temp12);
    if adjustTime==1
        LGPR.Dim1   = qtr2trd(LGPR.Dim1);
        LGPR = ttlast(LGPR,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        LGPR = ttlast(latestTdT(wQtr.Stm_PublishDate,LGPR),{-BackwardDays,-0},Dim1,Dim2);
    end   
    LGPR.Name = 'LGPR';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_LGPR' '.mat'],'LGPR');
    clear Temp3 Temp6 Temp9 Temp12 LGPR
    
%DEGM Done 净利润同比变化
    Net_Profit_Is = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2));
    Tot_Oper_Rev  = sum4q(subset(wQtr.Tot_Oper_Rev,QtrDim1,Dim2));
    DEGM          = Net_Profit_Is/Tot_Oper_Rev;
    DEGM          = DEGM-tshift(DEGM,-4);
    if adjustTime==1
        DEGM.Dim1   = qtr2trd(DEGM.Dim1);
        DEGM = ttlast(DEGM,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        DEGM = ttlast(latestTdT(wQtr.Stm_PublishDate,DEGM),{-BackwardDays,-0},Dim1,Dim2);
    end   
    DEGM.Name = 'DEGM';  
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_DEGM' '.mat'],'DEGM');
    clear Net_Profit_Is Tot_Oper_Rev DEGM 
%DGM Done 净利润环比
    DGM     = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2)) / sum4q(subset(iff(wQtr.Tot_Oper_Rev==0,1,wQtr.Tot_Oper_Rev),QtrDim1,Dim2));
    Temp3   = iff(isnan(iff(monthTdT(DGM)==3,DGM,NaN))==1, NaN,trmean(iff(monthTdT(DGM)==3,DGM,NaN),{-20,-1}));
    Temp6   = iff(isnan(iff(monthTdT(DGM)==6,DGM,NaN))==1, NaN,trmean(iff(monthTdT(DGM)==6,DGM,NaN),{-20,-1}));
    Temp9   = iff(isnan(iff(monthTdT(DGM)==9,DGM,NaN))==1, NaN,trmean(iff(monthTdT(DGM)==9,DGM,NaN),{-20,-1}));
    Temp12  = iff(isnan(iff(monthTdT(DGM)==12,DGM,NaN))==1,NaN,trmean(iff(monthTdT(DGM)==12,DGM,NaN),{-20,-1}));
    DGM = DGM - merge(Temp3,Temp6,Temp9,Temp12);
    if adjustTime==1
        DGM.Dim1   = qtr2trd(DGM.Dim1);
        DGM = ttlast(DGM,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        DGM = ttlast(latestTdT(wQtr.Stm_PublishDate,DGM),{-BackwardDays,-0},Dim1,Dim2);
    end   
    DGM.Name = 'DGM';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_DGM' '.mat'],'DGM');
    clear Temp3 Temp6 Temp9 Temp12 DGM
%CFO Done
    CFO = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2)) / ((subset(wQtr.Tot_Assets,QtrDim1,Dim2) + tshift(subset(wQtr.Tot_Assets,QtrDim1,Dim2),-4))/2);
    if adjustTime==1
        CFO.Dim1   = qtr2trd(CFO.Dim1);
        CFO = ttlast(CFO,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        CFO = ttlast(latestTdT(wQtr.Stm_PublishDate,CFO),{-BackwardDays,-0},Dim1,Dim2);
    end   
    CFO.Name    = 'CFO';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_CFO' '.mat'],'CFO');
    clear CFO
%DATO Done
    Oper_Rev     = sum4q(subset(wQtr.Oper_Rev,QtrDim1,Dim2));
    Tot_Assets   = ((subset(wQtr.Tot_Assets,QtrDim1,Dim2) + tshift(subset(wQtr.Tot_Assets,QtrDim1,Dim2),-4))/2);
    Tot_AssetsTO = Oper_Rev/Tot_Assets;
    Temp3   = iff(isnan(iff(monthTdT(Tot_AssetsTO)==3,Tot_AssetsTO,NaN))==1, NaN,trmean(iff(monthTdT(Tot_AssetsTO)==3,Tot_AssetsTO,NaN),{-20,-1}));
    Temp6   = iff(isnan(iff(monthTdT(Tot_AssetsTO)==6,Tot_AssetsTO,NaN))==1, NaN,trmean(iff(monthTdT(Tot_AssetsTO)==6,Tot_AssetsTO,NaN),{-20,-1}));
    Temp9   = iff(isnan(iff(monthTdT(Tot_AssetsTO)==9,Tot_AssetsTO,NaN))==1, NaN,trmean(iff(monthTdT(Tot_AssetsTO)==9,Tot_AssetsTO,NaN),{-20,-1}));
    Temp12  = iff(isnan(iff(monthTdT(Tot_AssetsTO)==12,Tot_AssetsTO,NaN))==1,NaN,trmean(iff(monthTdT(Tot_AssetsTO)==12,Tot_AssetsTO,NaN),{-20,-1}));
    Temp = merge(Temp3,Temp6,Temp9,Temp12);
    DATO         = Tot_AssetsTO - Temp;
    if adjustTime==1
        DATO.Dim1   = qtr2trd(DATO.Dim1);
        DATO = ttlast(DATO,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        DATO = ttlast(latestTdT(wQtr.Stm_PublishDate,DATO),{-BackwardDays,-0},Dim1,Dim2);
    end   
    DATO.Name    = 'DATO'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_DATO' '.mat'],'DATO');
    clear Oper_Rev Tot_Assets Tot_AssetsTO Temp3 Temp6 Temp9 Temp12 Temp DATO
%FCF Done
    Net_Cash_Flows_Oper_Act   = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2));
    CASH_PAY_ACQ_CONST_FIOLTA = sum4q(subset(iff(isnan(wQtr.CASH_PAY_ACQ_CONST_FIOLTA)==1,0,wQtr.CASH_PAY_ACQ_CONST_FIOLTA),QtrDim1,Dim2));
    NET_CASH_PAY_AQUIS_SOBU   = sum4q(subset(iff(isnan(wQtr.NET_CASH_PAY_AQUIS_SOBU)==1,0,wQtr.NET_CASH_PAY_AQUIS_SOBU),QtrDim1,Dim2));
    NET_CASH_RECP_DISP_FIOLTA = sum4q(subset(iff(isnan(wQtr.NET_CASH_RECP_DISP_FIOLTA)==1,0,wQtr.NET_CASH_RECP_DISP_FIOLTA),QtrDim1,Dim2));
    NET_CASH_RECP_DISP_SOBU   = sum4q(subset(iff(isnan(wQtr.NET_CASH_RECP_DISP_SOBU)==1,0,wQtr.NET_CASH_RECP_DISP_SOBU),QtrDim1,Dim2));
    FreeCashFlow              = Net_Cash_Flows_Oper_Act - CASH_PAY_ACQ_CONST_FIOLTA - NET_CASH_PAY_AQUIS_SOBU + NET_CASH_RECP_DISP_FIOLTA + NET_CASH_RECP_DISP_SOBU;
    FCF                       = FreeCashFlow/((subset(wQtr.Tot_Assets,QtrDim1,Dim2) + tshift(subset(wQtr.Tot_Assets,QtrDim1,Dim2),-4))/2);
    if adjustTime==1
        FCF.Dim1   = qtr2trd(FCF.Dim1);
        FCF = ttlast(FCF,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        FCF = ttlast(latestTdT(wQtr.Stm_PublishDate,FCF),{-BackwardDays,-0},Dim1,Dim2);
    end   
    FCF.Name    = 'FCF';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_FCF' '.mat'],'FCF');
    clear Net_Cash_Flows_Oper_Act CASH_PAY_ACQ_CONST_FIOLTA NET_CASH_PAY_AQUIS_SOBU NET_CASH_RECP_DISP_FIOLTA NET_CASH_RECP_DISP_SOBU FreeCashFlow FCF
%FCFE Done
    fcfeps = sum4q(subset(wQtr.fcfeps,QtrDim1,Dim2))*ttlast(wPrc_Stocks.Total_Shares,{-BackwardDays,0},QtrDim1,Dim2); 
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        fcfeps.Dim1   = qtr2trd(fcfeps.Dim1);
        fcfeps = ttlast(fcfeps,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        fcfeps = ttlast(latestTdT(wQtr.Stm_PublishDate,fcfeps),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
    end    
    FCFE   = fcfeps/(Lia+ subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2));
    FCFE.Name = 'FCFE';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_FCFE' '.mat'],'FCFE');
    clear fcfeps Lia FCFE
%FCFF Done
    fcffps = sum4q(subset(wQtr.fcffps,QtrDim1,Dim2))*ttlast(wPrc_Stocks.Total_Shares,{-BackwardDays,0},QtrDim1,Dim2); 
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        fcffps.Dim1   = qtr2trd(fcffps.Dim1);
        fcffps = ttlast(fcffps,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        fcffps = ttlast(latestTdT(wQtr.Stm_PublishDate,fcffps),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
    end    
    FCFF   = fcffps/(Lia+ subset(wPrc_Stocks.Total_Shares*iff(isnan(wPrc_Stocks.Close)==1,wPrc_Stocks.Pre_Close,wPrc_Stocks.Close),Dim1,Dim2));
    FCFF.Name = 'FCFF';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_FCFF' '.mat'],'FCFF');
    clear fcffps Lia FCFF
%PIO Done 
    ROA           = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2))/(subset(wQtr.Tot_Assets,QtrDim1,Dim2)+tshift(subset(wQtr.Tot_Assets,QtrDim1,Dim2),-4)/2);
    DROA          = ROA - tshift(ROA,-4);
    Net_Profit_Is = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2));
    OpProfit      = sum4q(subset(wQtr.OpProfit,QtrDim1,Dim2));
    CFO           = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2));
    CFOMPROFIT    = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2)) - sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2));
    DCurrentRatio = subset(wQtr.Tot_Cur_Assets,QtrDim1,Dim2)/subset(wQtr.Tot_Cur_Liab,QtrDim1,Dim2)-tshift(subset(wQtr.Tot_Cur_Assets,QtrDim1,Dim2)/subset(wQtr.Tot_Cur_Liab,QtrDim1,Dim2),-4);
    DD2Aratio     = subset(wQtr.Tot_Liab,QtrDim1,Dim2)/subset(wQtr.Tot_Assets,QtrDim1,Dim2)-tshift(subset(wQtr.Tot_Liab,QtrDim1,Dim2)/subset(wQtr.Tot_Assets,QtrDim1,Dim2),-4);
    SalesMargins  = (sum4q(subset(wQtr.Oper_Rev,QtrDim1,Dim2))-sum4q(subset(wQtr.Oper_Cost,QtrDim1,Dim2)))/sum4q(subset(wQtr.Oper_Rev,QtrDim1,Dim2));
    DSalesMargins = SalesMargins-tshift(SalesMargins,-4);
    TolAssetsTurn = sum4q(subset(wQtr.Oper_Rev,QtrDim1,Dim2))/subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    DTolAssetsTurn= TolAssetsTurn-tshift(TolAssetsTurn,-4);
    mv             = subset(wPrc_Stocks.Close,Dim1,Dim2)*subset(wPrc_Stocks.Float_A_Shares,Dim1,Dim2);
    Dilu           = log(subset(wPrc_Stocks.Close,Dim1,Dim2)/tshift(subset(wPrc_Stocks.Close,Dim1,Dim2),-21) * tshift(mv,-21) /mv);
    m = (0.5)^(1/126);                                            % 衰减系数
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchange  = iff(Volume>0,1,NaN);
    attenuation = ((1/m).^(0:length(FAClose.Dim1)-1))';           % 衰减序列
    AttenuationTdT = FAClose;
    AttenuationTdT.Data = repmat(attenuation,1,length(FAClose.Dim2));
    Dilu        = trsum(Dilu*AttenuationTdT,{-251,-0})/trsum(iff(ifexchange==1,AttenuationTdT,NaN),{-251,-0});
    PIO = iff(DROA>0,1,0) + iff(Net_Profit_Is>0,1,0) + iff(OpProfit>0,1,0) + iff(CFO>0,1,0) + iff(CFOMPROFIT>0,1,0) + iff(DCurrentRatio>0,1,0) + iff(DD2Aratio>0,0,1) + iff(DSalesMargins>0,0,1) + iff(DTolAssetsTurn>0,0,1);
    if adjustTime==1
        PIO.Dim1   = qtr2trd(PIO.Dim1);
        PIO = ttlast(PIO,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        PIO = ttlast(latestTdT(wQtr.Stm_PublishDate,PIO),{-BackwardDays,-0},Dim1,Dim2);
    end    
    PIO     = PIO + iff(Dilu>0.001,1,0);
    %PIO     = iff(PIO>5,PIO,NaN);
    PIO.Name = 'PIO';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_PIO' '.mat'],'PIO');
    clear ROA DROA Net_Profit_Is OpProfit CFO CFOMPROFIT DCurrentRatio DD2Aratio SalesMargins DSalesMargins TolAssetsTurn DTolAssetsTurn mv Dilu PIO FAClose Volume ifexchange attenuation m AttenuationTdT
%RNOA Done
    Net_Profit_Is  = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2));
    Tot_Cur_AssetsMTot_Cur_Liab = iff((subset(wQtr.Tot_Cur_Assets,QtrDim1,Dim2)-subset(wQtr.Tot_Cur_Liab,QtrDim1,Dim2)<=0),1,(subset(wQtr.Tot_Cur_Assets,QtrDim1,Dim2)-subset(wQtr.Tot_Cur_Liab,QtrDim1,Dim2)));
    RNOA           = Net_Profit_Is/Tot_Cur_AssetsMTot_Cur_Liab;
    if adjustTime==1
        RNOA.Dim1   = qtr2trd(RNOA.Dim1);
        RNOA = ttlast(RNOA,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        RNOA = ttlast(latestTdT(wQtr.Stm_PublishDate,RNOA),{-BackwardDays,-0},Dim1,Dim2);
    end    
    RNOA.Name = 'RNOA';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_RNOA' '.mat'],'RNOA');
    clear Net_Profit_Is Tot_Cur_AssetsMTot_Cur_Liab RNOA
%SMARG Done
    Oper_Rev  = iff(monthTdT(wQtr.Oper_Rev)==3,wQtr.Oper_Rev,wQtr.Oper_Rev-tshift(wQtr.Oper_Rev,-1));
    Acct_Rcv  = subset(wQtr.Acct_Rcv,QtrDim1,Dim2)-tshift(subset(wQtr.Acct_Rcv,QtrDim1,Dim2),-1);
    Temp      = (Oper_Rev-Acct_Rcv)-tshift(Oper_Rev-Acct_Rcv,-4);
    TempMean    = trmean(Temp,{-15,-0});
    Tempstd     = trstd(Temp,{-15,-0});
    SMARG       = (Temp-TempMean)/Tempstd;
    if adjustTime==1
        SMARG.Dim1   = qtr2trd(SMARG.Dim1);
        SMARG = ttlast(SMARG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        SMARG = ttlast(latestTdT(wQtr.Stm_PublishDate,SMARG),{-BackwardDays,-0},Dim1,Dim2);
    end        
    SMARG.Name = 'SMARG';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_SMARG' '.mat'],'SMARG');
    clear Temp Oper_Rev Acct_Rcv empMean Tempstd SMARG
%SUGM Done
    Oper_Rev  = iff(monthTdT(wQtr.Oper_Rev)==3,wQtr.Oper_Rev,wQtr.Oper_Rev-tshift(wQtr.Oper_Rev,-1));
    Oper_Cost = iff(monthTdT(wQtr.Oper_Cost)==3,wQtr.Oper_Cost,wQtr.Oper_Cost-tshift(wQtr.Oper_Cost,-1));
    SalesMargins  = (Oper_Rev-Oper_Cost)/Oper_Rev;                          % 当季度毛利率
    DSalesMargins = SalesMargins-tshift(SalesMargins,-4);
    SUGM       = (DSalesMargins-trmean(DSalesMargins,{-15,0}))/trstd(DSalesMargins,{-15,0});
    if adjustTime==1
        SUGM.Dim1   = qtr2trd(SUGM.Dim1);
        SUGM = ttlast(SUGM,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        SUGM = ttlast(latestTdT(wQtr.Stm_PublishDate,SUGM),{-BackwardDays,-0},Dim1,Dim2);
    end        
    SUGM.Name = 'SUGM';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_SUGM' '.mat'],'SUGM');
    clear Oper_Rev Oper_Cost SalesMargins DSalesMargins SUGM
%SUPAD Done
    ACCT_PAYABLE  = subset(wQtr.ACCT_PAYABLE,QtrDim1,Dim2);
    Tot_Assets    = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    Sig           = (ACCT_PAYABLE - tshift(ACCT_PAYABLE,-4))/(Tot_Assets+tshift(Tot_Assets,-4))/2;
    SUPAD         = (Sig-trmean(Sig,{-16,-1}))/iff(trstd(Sig,{-16,-1})==0,NaN,trstd(Sig,{-16,-1}));
    if adjustTime==1
        SUPAD.Dim1   = qtr2trd(SUPAD.Dim1);
        SUPAD = ttlast(SUPAD,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        SUPAD = ttlast(latestTdT(wQtr.Stm_PublishDate,SUPAD),{-BackwardDays,-0},Dim1,Dim2);
    end        
    SUPAD.Name = 'SUPAD';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_SUPAD' '.mat'],'SUPAD');
    clear ACCT_PAYABLE Tot_Assets Sig SUPAD
%TA2Lia Done
    Tot_Assets    = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    Lia = iff(isnan(wQtr.ST_BORROW)==1,0,wQtr.ST_BORROW) + iff(isnan(wQtr.LT_BORROW)==1,0,wQtr.LT_BORROW);
    if adjustTime==1
        Tot_Assets.Dim1   = qtr2trd(Tot_Assets.Dim1);
        Tot_Assets = ttlast(Tot_Assets,{-BackwardDays,-0},Dim1,Dim2);
        Lia.Dim1   = qtr2trd(Lia.Dim1);
        Lia = ttlast(Lia,{-BackwardDays,-0},Dim1,Dim2);
        Lia = iff(Lia==0, NaN, Lia);
    elseif adjustTime==2
        Tot_Assets = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Assets),{-BackwardDays,-0},Dim1,Dim2);
        Lia = ttlast(latestTdT(wQtr.Stm_PublishDate,Lia),{-BackwardDays,-0},Dim1,Dim2);
        Lia = iff(Lia==0, NaN, Lia);
    end    
    TA2Lia   = Tot_Assets/(Lia);
    TA2Lia.Name = 'TA2Lia';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_TA2Lia' '.mat'],'TA2Lia');
    clear Lia Tot_Assets TA2Lia
%EF Done
    Bsitems = subset(wQtr.eqy_belongto_parcomsh,QtrDim1,Dim2) + iff(isnan(subset(wQtr.LT_BORROW,QtrDim1,Dim2))==1,0,subset(wQtr.LT_BORROW,QtrDim1,Dim2)) ...
                                                              + iff(isnan(subset(wQtr.ST_BORROW,QtrDim1,Dim2))==1,0,subset(wQtr.ST_BORROW,QtrDim1,Dim2)) ...
                                                              - iff(isnan(subset(wQtr.Monetary_Cap,QtrDim1,Dim2))==1,0,subset(wQtr.Monetary_Cap,QtrDim1,Dim2)); 
    Bsitems = Bsitems - tshift(Bsitems,-4);
    Tot_Assets    = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    DIV     = trsum(subset(wQtr.DIV_CASHBEFORETAX,QtrDim1,Dim2)*ttlast(wPrc_Stocks.Total_Shares, {-180,0},QtrDim1,Dim2),{-3,0});  %红利 年度
    EF      = -1*(Bsitems - sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2)) + DIV)/(Tot_Assets+tshift(Tot_Assets,-4))/2;
    if adjustTime==1
        EF.Dim1   = qtr2trd(EF.Dim1);
        EF = ttlast(EF,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        EF = ttlast(latestTdT(wQtr.Stm_PublishDate,EF),{-BackwardDays,-0},Dim1,Dim2);
    end    
    EF.Name = 'EF';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_EF' '.mat'],'EF');
    clear Bsitems Tot_Assets DIV EF     
%QDROA Done
    OpProfit        = iff(monthTdT(wQtr.OpProfit)==3,wQtr.OpProfit,wQtr.OpProfit-tshift(wQtr.OpProfit,-1)) + iff(isnan(iff(monthTdT(wQtr.FIN_EXP_CS)==3,wQtr.FIN_EXP_CS,wQtr.FIN_EXP_CS-tshift(wQtr.FIN_EXP_CS,-1)))==1,0,iff(monthTdT(wQtr.FIN_EXP_CS)==3,wQtr.FIN_EXP_CS,wQtr.FIN_EXP_CS-tshift(wQtr.FIN_EXP_CS,-1)));
    Tot_Assets      = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    QDROA           = OpProfit/trmean(Tot_Assets,{-1,0});
    QDROA           = QDROA - tshift(QDROA,-4);
    if adjustTime==1
        QDROA.Dim1   = qtr2trd(QDROA.Dim1);
        QDROA = ttlast(QDROA,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        QDROA = ttlast(latestTdT(wQtr.Stm_PublishDate,QDROA),{-BackwardDays,-0},Dim1,Dim2);
    end    
    QDROA.Name = 'QDROA';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_QDROA' '.mat'],'QDROA');
    clear Net_Profit_Is Tot_Assets QDROA
%DROA Done
    Net_Profit_Is   = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2));
    Tot_Assets      = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    DROA            = Net_Profit_Is/((Tot_Assets+tshift(Tot_Assets,-4))/2);
    DROA            = DROA - tshift(DROA,-4);
    if adjustTime==1
        DROA.Dim1   = qtr2trd(DROA.Dim1);
        DROA = ttlast(DROA,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        DROA = ttlast(latestTdT(wQtr.Stm_PublishDate,DROA),{-BackwardDays,-0},Dim1,Dim2);
    end    
    DROA.Name = 'DROA';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_DROA' '.mat'],'DROA');
    clear Net_Profit_Is Tot_Assets DROA
%ROA Done
    Net_Profit_Is   = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2));
    Tot_Assets      = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    ROA            = Net_Profit_Is/((Tot_Assets+tshift(Tot_Assets,-4))/2);
    if adjustTime==1
        ROA.Dim1   = qtr2trd(ROA.Dim1);
        ROA = ttlast(ROA,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        ROA = ttlast(latestTdT(wQtr.Stm_PublishDate,ROA),{-BackwardDays,-0},Dim1,Dim2);
    end    
    ROA.Name = 'ROA';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_ROA' '.mat'],'ROA');
    clear Net_Profit_Is Tot_Assets ROA   
%QDROE Done    
    NP_BELONGTO_PARCOMSH   = iff(monthTdT(wQtr.NP_BELONGTO_PARCOMSH)==3,wQtr.NP_BELONGTO_PARCOMSH,wQtr.NP_BELONGTO_PARCOMSH-tshift(wQtr.NP_BELONGTO_PARCOMSH,-1));
    eqy_belongto_parcomsh  = subset(wQtr.eqy_belongto_parcomsh,QtrDim1,Dim2);
    QDROE                  = NP_BELONGTO_PARCOMSH/trmean(eqy_belongto_parcomsh,{-1,0});
    QDROE                  = QDROE-tshift(QDROE,-4);
    if adjustTime==1
        QDROE.Dim1   = qtr2trd(QDROE.Dim1);
        QDROE = ttlast(QDROE,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        QDROE = ttlast(latestTdT(wQtr.Stm_PublishDate,QDROE),{-BackwardDays,-0},Dim1,Dim2);
    end    
    QDROE.Name = 'QDROE';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_QDROE' '.mat'],'QDROE');
    clear NP_BELONGTO_PARCOMSH eqy_belongto_parcomsh QDROE    
%DROE Done
    NP_BELONGTO_PARCOMSH   = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
    eqy_belongto_parcomsh  = subset(wQtr.eqy_belongto_parcomsh,QtrDim1,Dim2);
    DROE                   = NP_BELONGTO_PARCOMSH/((eqy_belongto_parcomsh+tshift(eqy_belongto_parcomsh,-4))/2);
    DROE                   = DROE-tshift(DROE,-4);
    if adjustTime==1
        DROE.Dim1   = qtr2trd(DROE.Dim1);
        DROE = ttlast(DROE,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        DROE = ttlast(latestTdT(wQtr.Stm_PublishDate,DROE),{-BackwardDays,-0},Dim1,Dim2);
    end    
    DROE.Name = 'DROE';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_DROE' '.mat'],'DROE');
    clear Net_Profit_Is Tot_Assets DROE eqy_belongto_parcomsh NP_BELONGTO_PARCOMSH  
%DROE2
    DROE2  = iff(monthTdT(wQtr.NP_BELONGTO_PARCOMSH)==3,wQtr.NP_BELONGTO_PARCOMSH,wQtr.NP_BELONGTO_PARCOMSH-tshift(wQtr.NP_BELONGTO_PARCOMSH,-1));  
    DROE2  = DROE2-tshift(DROE2,-4);
    eqy_belongto_parcomsh  = subset(wQtr.eqy_belongto_parcomsh,QtrDim1,Dim2);
    if adjustTime==1
        DROE2.Dim1   = qtr2trd(DROE2.Dim1);
        DROE2 = ttlast(DROE2,{-BackwardDays,-0},Dim1,Dim2);  
    elseif adjustTime==2
        DROE2 = ttlast(latestTdT(wQtr.Stm_PublishDate,DROE2),{-BackwardDays,0},Dim1,Dim2) / ttlast(latestTdT(wQtr.Stm_PublishDate,eqy_belongto_parcomsh),{-BackwardDays,0},Dim1,Dim2); 
    end
    DROE2.Name = 'DROE2';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_DROE2' '.mat'],'DROE2');
    clear DROE2
%RROE2
    NP_BELONGTO_PARCOMSH = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
    eqy_belongto_parcomsh  = subset(wQtr.eqy_belongto_parcomsh,QtrDim1,Dim2);
    if adjustTime==1
        NP_BELONGTO_PARCOMSH.Dim1   = qtr2trd(NP_BELONGTO_PARCOMSH.Dim1);
        NP_BELONGTO_PARCOMSH = ttlast(NP_BELONGTO_PARCOMSH,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        NP_BELONGTO_PARCOMSH = ttlast(latestTdT(wQtr.Stm_PublishDate,NP_BELONGTO_PARCOMSH),{-BackwardDays,-0},Dim1,Dim2);
    end       
    RROE2 = NP_BELONGTO_PARCOMSH / ttlast(latestTdT(wQtr.Stm_PublishDate,eqy_belongto_parcomsh),{-BackwardDays,0},Dim1,Dim2);
    RROE2 = (RROE2 - ttmean(RROE2,{-364,0})) / ttstd(RROE2,{-364,0});
    RROE2.Name = 'RROE2'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_RROE2' '.mat'],'RROE2');
    clear NP_BELONGTO_PARCOMSH RROE2
%ROE Done
    NP_BELONGTO_PARCOMSH   = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
    eqy_belongto_parcomsh  = subset(wQtr.eqy_belongto_parcomsh,QtrDim1,Dim2);
    ROE                    = NP_BELONGTO_PARCOMSH/((eqy_belongto_parcomsh+tshift(eqy_belongto_parcomsh,-4))/2);
    if adjustTime==1
        ROE.Dim1   = qtr2trd(ROE.Dim1);
        ROE = ttlast(ROE,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        ROE = ttlast(latestTdT(wQtr.Stm_PublishDate,ROE),{-BackwardDays,-0},Dim1,Dim2);
    end    
    ROE.Name = 'ROE';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_ROE' '.mat'],'ROE');
    clear Net_Profit_Is Tot_Assets ROE eqy_belongto_parcomsh NP_BELONGTO_PARCOMSH    
%CFOR
    Oper_Rev  = iff(monthTdT(wQtr.Oper_Rev)==3,wQtr.Oper_Rev,wQtr.Oper_Rev-tshift(wQtr.Oper_Rev,-1));  
    Net_Cash_Flows_Oper_Act  = iff(monthTdT(wQtr.Net_Cash_Flows_Oper_Act)==3,wQtr.Net_Cash_Flows_Oper_Act,wQtr.Net_Cash_Flows_Oper_Act-tshift(wQtr.Net_Cash_Flows_Oper_Act,-1));  
    CFOR   = subset(trsum(Net_Cash_Flows_Oper_Act,{-3,0})/trsum(Oper_Rev,{-3,0}),QtrDim1,Dim2);
    CFOR   = iff(abs(CFOR)>10,NaN,CFOR);
    if adjustTime==1
        CFOR.Dim1   = qtr2trd(CFOR.Dim1);
        CFOR = ttlast(CFOR,{-BackwardDays,-0},Dim1,Dim2) ;   
    elseif adjustTime==2
        CFOR = ttlast(latestTdT(wQtr.Stm_PublishDate,CFOR),{-BackwardDays,-0},Dim1,Dim2);
    end
    CFOR.Name = 'CFOR';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Quality_CFOR' '.mat'],'CFOR');
    clear Oper_Rev Net_Cash_Flows_Oper_Act CFOR
%% Financial_momentum
%FES1 Done 环比
    FES1 = sum4q(subset(wQtr.Net_Profit_Is,QtrDim1,Dim2)) / ttlast(wPrc_Stocks.Total_Shares,{-inf,0},QtrDim1,Dim2);
    FES1 = ( FES1-tshift(FES1,-1) ) / tshift(iff(subset(wQtr.Tot_Assets,QtrDim1,Dim2)==0,1,subset(wQtr.Tot_Assets,QtrDim1,Dim2))*ttlast(wPrc_Stocks.Total_Shares,{-inf,0},QtrDim1,Dim2),-1);
    if adjustTime==1
        FES1.Dim1   = qtr2trd(FES1.Dim1);
        FES1 = ttlast(FES1,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        FES1 = ttlast(latestTdT(wQtr.Stm_PublishDate,FES1),{-BackwardDays,-0},Dim1,Dim2);
    end    
    FES1.Name = 'FES1';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum1_FES1' '.mat'],'FES1');
    clear FES1
%FES2 Done 环比
    FES2 = sum4q(subset(wQtr.pay_all_typ_tax,QtrDim1,Dim2)) / ttlast(wPrc_Stocks.Total_Shares,{-inf,0},QtrDim1,Dim2);
    FES2 = ( FES2-tshift(FES2,-1) ) / tshift(iff(subset(wQtr.Tot_Assets,QtrDim1,Dim2)==0,1,subset(wQtr.Tot_Assets,QtrDim1,Dim2))*ttlast(wPrc_Stocks.Total_Shares,{-inf,0},QtrDim1,Dim2),-1);
    if adjustTime==1
        FES2.Dim1   = qtr2trd(FES2.Dim1);
        FES2 = ttlast(FES2,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        FES2 = ttlast(latestTdT(wQtr.Stm_PublishDate,FES2),{-BackwardDays,-0},Dim1,Dim2);
    end    
    FES2.Name = 'FES2';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum1_FES2' '.mat'],'FES2');
    clear FES2
%SUE Done 当季净利润同比
    Net_Profit_Is  = iff(monthTdT(wQtr.NP_BELONGTO_PARCOMSH)==3,wQtr.NP_BELONGTO_PARCOMSH,wQtr.NP_BELONGTO_PARCOMSH-tshift(wQtr.NP_BELONGTO_PARCOMSH,-1));
    Net_Profit_IsE = Net_Profit_Is - tshift(Net_Profit_Is,-4);
    SUE            =(Net_Profit_IsE - trsum(Net_Profit_IsE,{-7,-0})/trcount(Net_Profit_IsE,{-7,0}))/trstd(Net_Profit_IsE,{-7,-0});
    SUE            = iff(trcount(Net_Profit_Is,{-7,-0})>6,SUE,NaN);
    if adjustTime==1
        SUE.Dim1   = qtr2trd(SUE.Dim1);
        SUE = ttlast(SUE,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        SUE = ttlast(latestTdT(wQtr.Stm_PublishDate,SUE),{-BackwardDays,-0},Dim1,Dim2);
    end    
    SUE.Name = 'SUE';  
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum1_SUE' '.mat'],'SUE');
    clear SUE Net_Profit_Is Net_Profit_IsE    
%SUOI Done 当季营业利润同比
    Oper_RevMOper_Cost  = iff(monthTdT(wQtr.OpProfit)==3,wQtr.OpProfit,wQtr.OpProfit-tshift(wQtr.OpProfit,-1));
    Oper_RevMOper_CostE = Oper_RevMOper_Cost-tshift(Oper_RevMOper_Cost,-4);
    SUOI                = (Oper_RevMOper_CostE - trsum(Oper_RevMOper_CostE,{-7,0})/trcount(Oper_RevMOper_CostE,{-7,0}))/trstd(Oper_RevMOper_CostE,{-7,0});
    SUOI                = iff(trcount(Oper_RevMOper_Cost,{-7,-0})>6,SUOI,NaN);
    if adjustTime==1
        SUOI.Dim1   = qtr2trd(SUOI.Dim1);
        SUOI = ttlast(SUOI,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        SUOI = ttlast(latestTdT(wQtr.Stm_PublishDate,SUOI),{-BackwardDays,-0},Dim1,Dim2);
    end    
    SUOI.Name = 'SUOI'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum1_SUOI' '.mat'],'SUOI');
    clear SUOI Oper_RevMOper_Cost Oper_RevMOper_CostE
%SURI Done 当季营业利润同比
    Oper_rev  = iff(monthTdT(wQtr.Tot_Oper_Rev)==3,wQtr.Tot_Oper_Rev,wQtr.Tot_Oper_Rev-tshift(wQtr.Tot_Oper_Rev,-1));
    Oper_revE = Oper_rev-tshift(Oper_rev,-4);
    SURI                = (Oper_revE - trsum(Oper_revE,{-7,0})/trcount(Oper_revE,{-7,0}))/trstd(Oper_revE,{-7,0});
    SURI                = iff(trcount(Oper_rev,{-7,-0})>6,SURI,NaN);
    if adjustTime==1
        SURI.Dim1   = qtr2trd(SURI.Dim1);
        SURI = ttlast(SURI,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        SURI = ttlast(latestTdT(wQtr.Stm_PublishDate,SURI),{-BackwardDays,-0},Dim1,Dim2);
    end    
    SURI.Name = 'SURI'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum1_SURI' '.mat'],'SURI');
    clear SURI Oper_rev Oper_revE
%SUA Done 当季营业利润同比
    Oper_Acct  = iff(monthTdT(wQtr.Acct_Rcv)==3,wQtr.Acct_Rcv,wQtr.Acct_Rcv-tshift(wQtr.Acct_Rcv,-1));
    Oper_AcctE = Oper_Acct-tshift(Oper_Acct,-4);
    SUA                = (Oper_AcctE - trsum(Oper_AcctE,{-7,0})/trcount(Oper_AcctE,{-7,0}))/trstd(Oper_AcctE,{-7,0});
    SUA                = iff(trcount(Oper_AcctE,{-7,-0})>6,SUA,NaN);
    if adjustTime==1
        SUA.Dim1   = qtr2trd(SUA.Dim1);
        SUA = ttlast(SUA,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        SUA = ttlast(latestTdT(wQtr.Stm_PublishDate,SUA),{-BackwardDays,-0},Dim1,Dim2);
    end    
    SUA.Name = 'SUA'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum1_SUA' '.mat'],'SUA');
    clear SUA Oper_Acct Oper_AcctE
%% Price_momentum
%InduMStkR5D 行业涨的多的+个股涨的少的
    n = 5;
    wPrc_Stocks.Industry_Citic = subset(wPrc_Stocks.Industry_Citic,Dim1,Dim2);
    Ret                        = wPrc_Stocks.Close/wPrc_Stocks.Pre_Close-1;
    IndustryRet                = xgpmean(Ret,wPrc_Stocks.Industry_Citic);
    IndustryRetSum             = trsum(IndustryRet,{-n+1,0});                              % 行业n日累积收益率
    IndustryRetSum4S           = xgpmap(wPrc_Stocks.Industry_Citic,IndustryRetSum);
    IndustryRetScore           = xrank(IndustryRetSum)/xmax(xrank(IndustryRetSum));
    IndustryRetScore           = xgpmap(wPrc_Stocks.Industry_Citic,IndustryRetScore);
    Retsum                     = iff(wPrc_Stocks.Volume>0,trsum(Ret,{-n+1,0}),NaN); % 个股累积收益率
    RetsumDiff                 = Retsum-IndustryRetSum4S;
    rank                       = xrank(-RetsumDiff*iff(abs(Ret)>=0.098,NaN,1),wPrc_Stocks.Industry_Citic);
    rankmax                    = xgpmax(rank,wPrc_Stocks.Industry_Citic);
    rankmax                    = xgpmap(wPrc_Stocks.Industry_Citic,rankmax);
    StockRetScore              = rank/rankmax;
    InduMStkR5D      = StockRetScore+IndustryRetScore;
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_InduMStkR5D' '.mat'],'InduMStkR5D');
    clear n Ret IndustryRet IndustryRetSum IndustryRetSum4S IndustryRetScore Retsum RetsumDiff rank rankmax StockRetScore
%InduMStkR1M
    n = 22;
    wPrc_Stocks.Industry_Citic = subset(wPrc_Stocks.Industry_Citic,Dim1,Dim2);
    Ret                        = wPrc_Stocks.Close/wPrc_Stocks.Pre_Close-1;
    IndustryRet                = xgpmean(Ret,wPrc_Stocks.Industry_Citic);
    IndustryRetSum             = trsum(IndustryRet,{-n+1,0});                              % 行业n日累积收益率
    IndustryRetSum4S           = xgpmap(wPrc_Stocks.Industry_Citic,IndustryRetSum);
    IndustryRetScore           = xrank(IndustryRetSum)/xmax(xrank(IndustryRetSum));
    IndustryRetScore           = xgpmap(wPrc_Stocks.Industry_Citic,IndustryRetScore);
    Retsum                     = iff(wPrc_Stocks.Volume>0,trsum(Ret,{-n+1,0}),NaN); % 个股累积收益率
    RetsumDiff                 = Retsum-IndustryRetSum4S;
    rank                       = xrank(-RetsumDiff*iff(abs(Ret)>=0.098,NaN,1),wPrc_Stocks.Industry_Citic);
    rankmax                    = xgpmax(rank,wPrc_Stocks.Industry_Citic);
    rankmax                    = xgpmap(wPrc_Stocks.Industry_Citic,rankmax);
    StockRetScore              = rank/rankmax;
    InduMStkR1M      = StockRetScore+IndustryRetScore;
    InduMStkR1M.Name = 'InduMStkR1M';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_InduMStkR1M' '.mat'],'InduMStkR1M');
    clear n Ret IndustryRet IndustryRetSum IndustryRetSum4S IndustryRetScore Retsum RetsumDiff rank rankmax StockRetScore
%DEMOM10 Done
    month = 10;
    Mday  = 21;
    for i = 1:month
        Ret.(['R' num2str(i)]) = tshift(ttlast(wPrc_Stocks.FAClose,{-inf,0}),-(i-1)*Mday)/tshift(ttlast(wPrc_Stocks.FAClose,{-inf,0}),-i*Mday);
    end
    for i = 2:month
        if i == 2
            result = 0.5* log(Ret.(['R' num2str(i)]));
        elseif i==month
            result = result + 0.5* log(Ret.(['R' num2str(i)]));
        else
            result = result + log(Ret.(['R' num2str(i)]));
        end
    end
    DEMOM10 = subset(result,Dim1,Dim2);          
    DEMOM10.Name = 'DEMOM10'; 
    DEMOM10 = -DEMOM10;
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_DEMOM10' '.mat'],'DEMOM10');
    clear DEMOM10 month Mday result
%DEMOM7 Done
    month = 7;
    Mday  = 21;
    for i = 1:month
        Ret.(['R' num2str(i)]) = tshift(ttlast(wPrc_Stocks.FAClose,{-inf,0}),-(i-1)*Mday)/tshift(ttlast(wPrc_Stocks.FAClose,{-inf,0}),-i*Mday);
    end
    for i = 2:month
        if i == 2
            result = 0.5* log(Ret.(['R' num2str(i)]));
        elseif i==month
            result = result + 0.5* log(Ret.(['R' num2str(i)]));
        else
            result = result + log(Ret.(['R' num2str(i)]));
        end
    end
    DEMOM7 = subset(result,Dim1,Dim2);          
    DEMOM7.Name = 'DEMOM7';  
    DEMOM7 = -DEMOM7;
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_DEMOM7' '.mat'],'DEMOM7');
    clear DEMOM7 month Mday result
%DEMOM8 Done
    month = 8;
    Mday  = 21;
    for i = 1:month
        Ret.(['R' num2str(i)]) = tshift(ttlast(wPrc_Stocks.FAClose,{-inf,0}),-(i-1)*Mday)/tshift(ttlast(wPrc_Stocks.FAClose,{-inf,0}),-i*Mday);
    end
    for i = 2:month
        if i == 2
            result = 0.5* log(Ret.(['R' num2str(i)]));
        elseif i==month
            result = result + 0.5* log(Ret.(['R' num2str(i)]));
        else
            result = result + log(Ret.(['R' num2str(i)]));
        end
    end 
    DEMOM8 = subset(result,Dim1,Dim2);        
    DEMOM8.Name = 'DEMOM8';   
    DEMOM8 = -DEMOM8;
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_DEMOM8' '.mat'],'DEMOM8');
    clear DEMOM8 month Mday result
%DEMOM9 Done
    month = 9;
    Mday  = 21;
    for i = 1:month
        Ret.(['R' num2str(i)]) = tshift(ttlast(wPrc_Stocks.FAClose,{-inf,0}),-(i-1)*Mday)/tshift(ttlast(wPrc_Stocks.FAClose,{-inf,0}),-i*Mday);
    end
    for i = 2:month
        if i == 2
            result = 0.5* log(Ret.(['R' num2str(i)]));
        elseif i==month
            result = result + 0.5* log(Ret.(['R' num2str(i)]));
        else
            result = result + log(Ret.(['R' num2str(i)]));
        end
    end
    DEMOM9 = subset(result,Dim1,Dim2);         
    DEMOM9.Name = 'DEMOM9';  
    DEMOM9 = -DEMOM9;
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_DEMOM9' '.mat'],'DEMOM9');
    clear DEMOM9 month Mday result
%MOMENTUM Done
    m = (0.5)^(1/126);                                          % 衰减系数
    Close       = subset(wPrc_Stocks.Close,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchage   = iff(Volume>0,1,NaN);
    attenuation = ((1/m).^(0:length(Close.Dim1)-1))';           % 衰减序列
    AttenuationTdT = Close;
    AttenuationTdT.Data = repmat(attenuation,1,length(Close.Dim2));
    lnRet       = log(ttlast(subset(wPrc_Stocks.FAClose,Dim1,Dim2),{-inf,0})/tshift(ttlast(subset(wPrc_Stocks.FAClose,Dim1,Dim2),{-inf,0}),-1));
    MOMENTUM    = trsum(lnRet*AttenuationTdT,{-504,-21})/trsum(iff(ifexchage==1,AttenuationTdT,NaN),{-504,-21});
    MOMENTUM    = iff(trcount(ifexchage,{-504,-21})>504*0.75,MOMENTUM,NaN);
    MOMENTUM    = subset(MOMENTUM,Dim1,Dim2);         
    MOMENTUM.Name = 'MOMENTUM';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_MOMENTUM' '.mat'],'MOMENTUM');
    clear MOMENTUM m attenuation AttenuationTdT lnRet Close Volume ifexchage
%BIAS Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    FACloseAVG  = trmean(FAClose, {-39,0});
    BIAS = -(FAClose-FACloseAVG)/FACloseAVG;
    BIAS.Name = 'BIAS';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_BIAS' '.mat'],'BIAS');
    clear FAClose FACloseAVG BIAS;
%MAR Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchange  = iff(Volume>0,1,NaN);
    MAR = iff(trcount(ifexchange,{-4,0})<5, NaN, trmean(FAClose,{-4,0})/trmean(FAClose,{-39,0})-1);
    MAR = -MAR;
    MAR.Name = 'mar';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_MAR' '.mat'],'MAR');
    clear FAClose Volume ifexchange MAR
%MAX1d Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    Ret         = FAClose/tshift(FAClose,-1)-1;
    MAX1d       = -trmax(Ret, {-20,0});
    MAX1d.Name = 'MAX1d';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_MAX1d' '.mat'],'MAX1d');
    clear FAClose Ret MAX1d; 
%momt1m Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    momt1m      = FAClose/tshift(FAClose,-21) - 1;
    momt1m      = -momt1m;
    momt1m.Name = 'momt1m';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_momt1m' '.mat'],'momt1m');
    clear FAClose momt1m;
%momt3m Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    momt3m      = FAClose/tshift(FAClose,-63) - 1;
    momt3m      = -momt3m;
    momt3m.Name = 'momt3m';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_momt3m' '.mat'],'momt3m');
    clear FAClose momt3m;
%pricetoavg3m Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    Volume      = subset(wPrc_Stocks.Volume,Dim1,Dim2);
    ifexchange  = iff(Volume>0,1,NaN);
    close_cnt = trcount(ifexchange, {-63,0});
    close_ma  = trmean(FAClose, {-63,0});
    pricetoavg3m = iff(close_cnt<60, NaN, FAClose/close_ma-1);
    pricetoavg3m = -pricetoavg3m;
    pricetoavg3m.Name = 'pricetoavg3m';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_pricetoavg3m' '.mat'],'pricetoavg3m');
    clear FAClose Volume ifexchange close_cnt close_ma pricetoavg3m;
%momt6m Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    momt6m      = FAClose/tshift(FAClose,-126) - 1;
    momt6m      = -momt6m;
    momt6m.Name = 'momt6m';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_momt6m' '.mat'],'momt6m');
    clear FAClose momt6m;
%momt9m Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    momt9m      = FAClose/tshift(FAClose,-189) - 1;
    momt9m      = -momt9m;
    momt9m.Name = 'momt9m';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_momt9m' '.mat'],'momt9m');
    clear FAClose momt9m;
%momt12m Done
    FAClose     = subset(wPrc_Stocks.FAClose,Dim1,Dim2);
    momt12m      = FAClose/tshift(FAClose,-252) - 1;
    momt12m      = -momt12m;
    momt12m.Name = 'momt12m';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_momt12m' '.mat'],'momt12m');
    clear FAClose momt12m;
%sumHO
    HOtemp   = log(subset(wPrc_Stocks.High,Dim1,Dim2)/subset(wPrc_Stocks.Open,Dim1,Dim2));
    TradeNum = trcount(iff(subset(wPrc_Stocks.Volume,Dim1,Dim2)>0,1,NaN),{-21,-0});
    sumHO = iff(TradeNum>=22*0.75,-trsum(HOtemp,{-21,0})/TradeNum,NaN);
    sumHO.Name = 'sumHO';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_sumHO' '.mat'],'sumHO');
    clear HOtemp TradeNum
%sumCL
    CLtemp = log(subset(wPrc_Stocks.Close,Dim1,Dim2)/subset(wPrc_Stocks.Low,Dim1,Dim2));
    TradeNum = trcount(iff(subset(wPrc_Stocks.Volume,Dim1,Dim2)>0,1,NaN),{-21,-0});
    sumCL = iff(TradeNum>=22*0.75,-trsum(CLtemp,{-21,0})/TradeNum,NaN);
    sumCL.Name = 'sumCL';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_sumCL' '.mat'],'sumCL');
    clear CLtemp TradeNum
%sumCV
    CVtemp = log(subset(wPrc_Stocks.Close,Dim1,Dim2)/iff(subset(wPrc_Stocks.Volume,Dim1,Dim2)==0,NaN,subset(wPrc_Stocks.Amt,Dim1,Dim2)/subset(wPrc_Stocks.Volume,Dim1,Dim2)));
    TradeNum = trcount(iff(subset(wPrc_Stocks.Volume,Dim1,Dim2)>0,1,NaN),{-21,-0});
    sumCV = iff(TradeNum>=22*0.75,-trsum(CVtemp,{-21,0})/TradeNum,NaN);
    sumCV.Name = 'sumCV';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Momentum2_sumCV' '.mat'],'sumCV');
    clear CVtemp TradeNum    
%% Growth Done
%QCSG Done
    Oper_Rev   = iff(monthTdT(wQtr.Oper_Rev)==3,wQtr.Oper_Rev,wQtr.Oper_Rev-tshift(wQtr.Oper_Rev,-1)); 
    QCSG       = Oper_Rev/iff(tshift(Oper_Rev,-4)==0,1,tshift(Oper_Rev,-4))-1;
    QCSG       = iff(QCSG>7.5|QCSG<-7.5,NaN,QCSG);
    if adjustTime==1
        QCSG.Dim1   = qtr2trd(QCSG.Dim1);
        QCSG = ttlast(QCSG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        QCSG = ttlast(latestTdT(wQtr.Stm_PublishDate,QCSG),{-BackwardDays,-0},Dim1,Dim2);
    end    
    QCSG.Name = 'QCSG'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Growth_QCSG' '.mat'],'QCSG');
    clear Oper_Rev QCSG 
%QCS3YG Done
    Oper_Rev   = sum4q(subset(wQtr.Oper_Rev,QtrDim1,Dim2));
    QCS3YG     = iff(tshift(Oper_Rev,-12)~=0,(Oper_Rev/tshift(Oper_Rev,-12)-1)/3,NaN);
    QCS3YG     = iff(QCS3YG>5|QCS3YG<-5,NaN,QCS3YG);
    if adjustTime==1
        QCS3YG.Dim1   = qtr2trd(QCS3YG.Dim1);
        QCS3YG = ttlast(QCS3YG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        QCS3YG = ttlast(latestTdT(wQtr.Stm_PublishDate,QCS3YG),{-BackwardDays,-0},Dim1,Dim2);
    end        
    QCS3YG.Name = 'QCS3YG'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Growth_QCS3YG' '.mat'],'QCS3YG');
    clear Oper_Rev QCS3YG       
%NPG Done   
    NP_BELONGTO_PARCOMSH   = iff(monthTdT(wQtr.NP_BELONGTO_PARCOMSH)==3,wQtr.NP_BELONGTO_PARCOMSH,wQtr.NP_BELONGTO_PARCOMSH-tshift(wQtr.NP_BELONGTO_PARCOMSH,-1)); 
%     NPG       = NP_BELONGTO_PARCOMSH/iff(tshift(NP_BELONGTO_PARCOMSH,-4)==0,1,tshift(NP_BELONGTO_PARCOMSH,-4))-1;
    NPG       = (NP_BELONGTO_PARCOMSH-iff(tshift(NP_BELONGTO_PARCOMSH,-4)==0,1,tshift(NP_BELONGTO_PARCOMSH,-4)))/abs(iff(tshift(NP_BELONGTO_PARCOMSH,-4)==0,1,tshift(NP_BELONGTO_PARCOMSH,-4)));
    NPG       = iff(NPG>7.5|NPG<-7.5,NaN,NPG);
    if adjustTime==1
        NPG.Dim1   = qtr2trd(NPG.Dim1);
        NPG = ttlast(NPG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        NPG = ttlast(latestTdT(wQtr.Stm_PublishDate,NPG),{-BackwardDays,-0},Dim1,Dim2);
    end    
    NPG.Name = 'NPG';  
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Growth_NPG' '.mat'],'NPG');
    clear NP_BELONGTO_PARCOMSH NPG  
    
%NP3YG Done
    NP_BELONGTO_PARCOMSH   = sum4q(subset(wQtr.NP_BELONGTO_PARCOMSH,QtrDim1,Dim2));
%     NP3YG       = iff(tshift(NP_BELONGTO_PARCOMSH,-12)~=0,(NP_BELONGTO_PARCOMSH/tshift(NP_BELONGTO_PARCOMSH,-12)-1)/3,NaN);
    NP3YG       = (NP_BELONGTO_PARCOMSH-iff(tshift(NP_BELONGTO_PARCOMSH,-12)==0,1,tshift(NP_BELONGTO_PARCOMSH,-12)))/abs(iff(tshift(NP_BELONGTO_PARCOMSH,-12)==0,1,tshift(NP_BELONGTO_PARCOMSH,-12)))/3;
    NP3YG       = iff(NP3YG>5|NP3YG<-5,NaN,NP3YG);
    if adjustTime==1
        NP3YG.Dim1   = qtr2trd(NP3YG.Dim1);
        NP3YG = ttlast(NP3YG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        NP3YG = ttlast(latestTdT(wQtr.Stm_PublishDate,NP3YG),{-BackwardDays,-0},Dim1,Dim2);
    end        
    NP3YG.Name = 'NP3YG';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Growth_NP3YG' '.mat'],'NP3YG');
    clear NP_BELONGTO_PARCOMSH NP3YG    
%OPCG Done
    Net_Cash_Flows_Oper_Act   = iff(monthTdT(wQtr.Net_Cash_Flows_Oper_Act)==3,wQtr.Net_Cash_Flows_Oper_Act,wQtr.Net_Cash_Flows_Oper_Act-tshift(wQtr.Net_Cash_Flows_Oper_Act,-1)); 
    OPCG       = Net_Cash_Flows_Oper_Act/iff(tshift(Net_Cash_Flows_Oper_Act,-4)==0,1,tshift(Net_Cash_Flows_Oper_Act,-4))-1;
    OPCG       = iff(OPCG>7.5|OPCG<-7.5,NaN,OPCG);
    if adjustTime==1
        OPCG.Dim1   = qtr2trd(OPCG.Dim1);
        OPCG = ttlast(OPCG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        OPCG = ttlast(latestTdT(wQtr.Stm_PublishDate,OPCG),{-BackwardDays,-0},Dim1,Dim2);
    end    
    OPCG.Name = 'OPCG'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Growth_OPCG' '.mat'],'OPCG');
    clear Net_Cash_Flows_Oper_Act OPCG 
    
%OPC3YG Done
    Net_Cash_Flows_Oper_Act   = sum4q(subset(wQtr.Net_Cash_Flows_Oper_Act,QtrDim1,Dim2));
    OPC3YG       = iff(tshift(Net_Cash_Flows_Oper_Act,-12)~=0,(Net_Cash_Flows_Oper_Act/tshift(Net_Cash_Flows_Oper_Act,-12)-1)/3,NaN);
    OPC3YG       = iff(OPC3YG>5|OPC3YG<-5,NaN,OPC3YG);
    if adjustTime==1
        OPC3YG.Dim1   = qtr2trd(OPC3YG.Dim1);
        OPC3YG = ttlast(OPC3YG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        OPC3YG = ttlast(latestTdT(wQtr.Stm_PublishDate,OPC3YG),{-BackwardDays,-0},Dim1,Dim2);
    end        
    OPC3YG.Name = 'OPC3YG'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Growth_OPC3YG' '.mat'],'OPC3YG');
    clear Net_Cash_Flows_Oper_Act OPC3YG  
%ROAG Done
    Net_Profit_Is   = iff(monthTdT(wQtr.Net_Profit_Is)==3,wQtr.OpProfit,wQtr.OpProfit-tshift(wQtr.OpProfit,-1)); %与描述不同 直接使用净利润 未使用间接算法
    Tot_Assets      = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    ROAG            = Net_Profit_Is/iff(trmean(Tot_Assets,{-1,0})~=0,trmean(Tot_Assets,{-1,0}),1);
    ROAG            = ROAG-tshift(ROAG,-4);
    if adjustTime==1
        ROAG.Dim1   = qtr2trd(ROAG.Dim1);
        ROAG = ttlast(ROAG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        ROAG = ttlast(latestTdT(wQtr.Stm_PublishDate,ROAG),{-BackwardDays,-0},Dim1,Dim2);
    end    
    ROAG.Name = 'ROAG';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Growth_ROAG' '.mat'],'ROAG');
    clear Net_Profit_Is Tot_Assets ROAG
%ROEG Done   
    NP_BELONGTO_PARCOMSH   = iff(monthTdT(wQtr.NP_BELONGTO_PARCOMSH)==3,wQtr.NP_BELONGTO_PARCOMSH,wQtr.OpProfit-tshift(wQtr.NP_BELONGTO_PARCOMSH,-1)); %与描述不同 直接使用净利润 未使用间接算法
    eqy_belongto_parcomsh  = subset(wQtr.eqy_belongto_parcomsh,QtrDim1,Dim2);
    ROEG           = NP_BELONGTO_PARCOMSH/iff(trmean(eqy_belongto_parcomsh,{-1,0})~=0,trmean(eqy_belongto_parcomsh,{-1,0}),1);
    ROEG           = ROEG-tshift(ROEG,-4);    
    if adjustTime==1
        ROEG.Dim1   = qtr2trd(ROEG.Dim1);
        ROEG = ttlast(ROEG,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        ROEG = ttlast(latestTdT(wQtr.Stm_PublishDate,ROEG),{-BackwardDays,-0},Dim1,Dim2);
    end    
    ROEG.Name = 'ROEG';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Growth_ROEG' '.mat'],'ROEG');
    clear NP_BELONGTO_PARCOMSH eqy_belongto_parcomsh ROEG  

%% Size
%Size CNE5 Done
    Size = -log(subset(wPrc_Stocks.Float_A_Shares,Dim1,Dim2)*subset(wPrc_Stocks.Close,Dim1,Dim2));
    Size.Name = 'Size';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Size_Size' '.mat'],'Size');
    clear Size
%lasst Done
    Tot_Assets      = subset(wQtr.Tot_Assets,QtrDim1,Dim2);
    if adjustTime==1
        Tot_Assets.Dim1   = qtr2trd(Tot_Assets.Dim1);
        Tot_Assets = ttlast(Tot_Assets,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Tot_Assets = ttlast(latestTdT(wQtr.Stm_PublishDate,Tot_Assets),{-BackwardDays,-0},Dim1,Dim2);
    end  
    lasst = -log(iff(Tot_Assets==0,1,Tot_Assets));
    lasst.Name = 'lasst';
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Size_lasst' '.mat'],'lasst');
    clear Tot_Assets lasst
%shareHolders Done
    shareHolders   = subset(wQtr.Holder_Num,QtrDim1,Dim2);
    if adjustTime==1
        shareHolders.Dim1   = qtr2trd(shareHolders.Dim1);
        Holder_Num = ttlast(shareHolders,{-BackwardDays,-0},Dim1,Dim2);
    elseif adjustTime==2
        Holder_Num = ttlast(latestTdT(wQtr.Stm_PublishDate,shareHolders),{-BackwardDays,-0},Dim1,Dim2);
    end  
    shareHolders = log(Holder_Num);
    shareHolders.Name = 'shareHolders'; 
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Size_shareHolders' '.mat'],'shareHolders');
    clear shareHolders Holder_Num
end
%NLSize
    Size = log(subset(wPrc_Stocks.Total_Shares,Dim1,Dim2)*subset(wPrc_Stocks.Close,Dim1,Dim2));
%   cd('D:\Production\Data');
    [beta, alpha, resi] = Get_REGRESI(Size, Size^3);
    NLSize = resi;
    save([dirRoot '\FactorLab\AdT' num2str(adjustTime) '_' 'Size_NLSize' '.mat'],'NLSize');
    clear Size beta alpha resi NLSize
    
end   
    






