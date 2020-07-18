load('G:\production\data\wQtr.mat');
load('G:\production\data\wPrc_Stocks.mat');

Dim1 = wPrc_Stocks.Close.Dim1;
Dim2 = wPrc_Stocks.Close.Dim2;
wQtrDim1 = wQtr.Stm_IssuingDate.Dim1;

wQtr_Assets                        = subset(wQtr.Tot_Assets,                       wQtrDim1, Dim2);
wQtr_Monetary_Cap                  = subset(wQtr.Monetary_Cap,                     wQtrDim1, Dim2);
wQtr_Tradable_Fin_Assets           = subset(wQtr.Tradable_Fin_Assets,              wQtrDim1, Dim2);
wQtr_ST_BONDS_PAYABLE              = subset(wQtr.ST_BONDS_PAYABLE,                 wQtrDim1, Dim2);
wQtr_ST_BORROW                     = subset(wQtr.ST_BORROW,                        wQtrDim1, Dim2);
wQtr_NON_CUR_LIAB_DUE_WITHIN_1Y    = subset(wQtr.NON_CUR_LIAB_DUE_WITHIN_1Y,       wQtrDim1, Dim2);
wQtr_Net_Cash_Flows_Oper_Act       = subset(wQtr.Net_Cash_Flows_Oper_Act,       wQtrDim1, Dim2);
wQtr_Net_Cash_Flows_Oper_Act_Is    = iff(monthTdT(wQtr_Net_Cash_Flows_Oper_Act)==3, wQtr_Net_Cash_Flows_Oper_Act, wQtr_Net_Cash_Flows_Oper_Act - tshift(wQtr_Net_Cash_Flows_Oper_Act, -1)); 
wQtr_Net_Cash_Flows_Oper_Act_TTM   = trsum(wQtr_Net_Cash_Flows_Oper_Act_Is, {-3 0});

wQtr_Monetary_Cap                = iff(isnan(wQtr_Monetary_Cap),                0, wQtr_Monetary_Cap);
wQtr_Tradable_Fin_Assets         = iff(isnan(wQtr_Tradable_Fin_Assets),         0, wQtr_Tradable_Fin_Assets);
wQtr_ST_BONDS_PAYABLE            = iff(isnan(wQtr_ST_BONDS_PAYABLE),            0, wQtr_ST_BONDS_PAYABLE);
wQtr_ST_BORROW                   = iff(isnan(wQtr_ST_BORROW),                   0, wQtr_ST_BORROW);
wQtr_NON_CUR_LIAB_DUE_WITHIN_1Y  = iff(isnan(wQtr_NON_CUR_LIAB_DUE_WITHIN_1Y),  0, wQtr_NON_CUR_LIAB_DUE_WITHIN_1Y);
wQtr_Net_Cash_Flows_Oper_Act_TTM = iff(isnan(wQtr_Net_Cash_Flows_Oper_Act_TTM), 0, wQtr_Net_Cash_Flows_Oper_Act_TTM);

wQtr_Money   = wQtr_Monetary_Cap + wQtr_Tradable_Fin_Assets;
wQtr_ST_LIAB = wQtr_ST_BORROW + wQtr_ST_BONDS_PAYABLE + wQtr_NON_CUR_LIAB_DUE_WITHIN_1Y;

factor    = (wQtr_Monetary_Cap + wQtr_Tradable_Fin_Assets + wQtr_Net_Cash_Flows_Oper_Act_TTM - wQtr_ST_LIAB) / wQtr_Assets;
factor_td = ttlast(latestTdT(wQtr.Stm_IssuingDate,  factor), {Dim1+1,[Dim1(2:end);9999999]},Dim1,Dim2);
factor_td = ttlast(factor_td, {-inf 0});
factor_td = factor_parse(factor_td);
factor_td = factor_td.wins_norm_sizeNeutrual;
factor_td.Name = 'CFPA';
CFPA = factor_td;
save('G:\production\data\factors\CFPA.mat','CFPA');

clear all;clc;


%% 初始化Data
load([dir '\Data\wPrc_Stocks.mat']); 
load([dir '\Data\wPrc_Events.mat']);
load([dir '\Data\wQtr.mat']);
load([dir '\Data\funclist.mat']);  %这个function list 维护了用来进行计算的函数，第一列是函数名，第二列是第几步才可以被使用，第三列是自带参数，第四列是需要参数的个数

DF = DF1(wPrc_Stocks,wPrc_Events); %初始化Data

Dim1 = wPrc_Stocks.Close.Dim1;
Dim2 = wPrc_Stocks.Close.Dim2;

%% wTD下的各个数据主要用于gen2函数的计算，可以让得出的因子在日频上有变化，比如和MkrCap, Assets,Equity进行交互计算。

wQtrDim1 = unique([wQtr.Stm_IssuingDate.Dim1 ;wQtr.ProfitNotice_Date.Dim1 ;wQtr.PerformanceExpress_Date.Dim1]); 
wQtr_updatetime  = subset(wQtr.Stm_IssuingDate,  wQtrDim1, Dim2); wQtr_updatetime.Name  = '定期报告披露日期'; 
    
TN_ROIC = wDay_TNORM(wDay_TD(wQtr_Is(wQtr.ROIC),wQtr_updatetime,Dim1,Dim2));
TN_ROIC = factor_parse(TN_ROIC);
TN_ROIC = TN_ROIC.wins_norm_sizeNeutrual;
TN_ROIC.Name = 'TN_ROIC';
factor_disp2_b(TN_ROIC);

save('G:\production\data\factors\TN_ROIC.mat', 'TN_ROIC');



TN_Oper_Rev = wDay_TNORM(wDay_TD(wQtr_Is(wQtr.Oper_Rev),wQtr_updatetime,Dim1,Dim2));
TN_Oper_Rev = factor_parse(TN_Oper_Rev);
TN_Oper_Rev = TN_Oper_Rev.wins_norm_sizeNeutrual;
TN_Oper_Rev.Name = 'TN_Oper_Rev';
factor_disp2_b(TN_Oper_Rev);

save('G:\production\data\factors\TN_Oper_Rev.mat', 'TN_Oper_Rev');