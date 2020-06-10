wQtrVars = {
%    FactorLab_zyd
    'wQtr.Stm_IssuingDate'                                  'AShareIncome.ANN_DT';                    % num2date();
    'wQtr.employee'                                         'AShareStaff.S_INFO_TOTALEMPLOYEES';
    'wQtr.Holder_Num'                                       'AShareHolderNumber.S_HOLDER_TOTAL_NUM';
    'wQtr.fcfeps'                                           'AShareFinancialIndicator.S_FA_FCFEPS';
    'wQtr.fcffps'                                           'AShareFinancialIndicator.S_FA_FCFFPS';
    'wQtr.DIV_CASHBEFORETAX'                                'AShareDividend.CASH_DVD_PER_SH_PRE_TAX';
    'wQtr.Net_Profit_Is'                                    'AShareIncome.NET_PROFIT_INCL_MIN_INT_INC';
    'wQtr.NP_BELONGTO_PARCOMSH'                             'AShareIncome.NET_PROFIT_EXCL_MIN_INT_INC';
    'wQtr.Oper_Rev'                                         'AShareIncome.OPER_REV';
    'wQtr.OpProfit'                                         'AShareIncome.OPER_PROFIT';
    'wQtr.Oper_Cost'                                        'AShareIncome.LESS_OPER_COST';
    'wQtr.Tot_Oper_Rev'                                     'AShareIncome.LESS_OPER_REV';
    'wQtr.Net_Cash_Flows_Oper_Act'                          'AShareCashFlow.NET_CASH_FLOWS_OPER_ACT';
    'wQtr.NET_CASH_PAY_AQUIS_SOBU'                          'AShareCashFlow.NET_CASH_PAY_AQUIS_SOBU';
    'wQtr.NET_CASH_RECP_DISP_SOBU'                          'AShareCashFlow.NET_CASH_RECP_DISP_SOBU';
    'wQtr.NET_CASH_RECP_DISP_FIOLTA'                        'AShareCashFlow.NET_CASH_RECP_DISP_FIOLTA';
    'wQtr.CASH_PAY_ACQ_CONST_FIOLTA'                        'AShareCashFlow.CASH_PAY_ACQ_CONST_FIOLTA';
    'wQtr.FIN_EXP_CS'                                       'AShareCashFlow.FIN_EXP';
    'wQtr.pay_all_typ_tax'                                  'AShareCashFlow.PAY_ALL_TYP_TAX';
    'wQtr.recp_tax_rends'                                   'AShareCashFlow.RECP_TAX_RENDS';
    'wQtr.ACCT_PAYABLE'                                     'AShareBalanceSheet.ACCT_PAYABLE';
    'wQtr.Acct_Rcv'                                         'AShareBalanceSheet.ACCT_RCV';
    'wQtr.eqy_belongto_parcomsh'                            'AShareBalanceSheet.TOT_SHRHLDR_EQY_EXCL_MIN_INT';
    'wQtr.Monetary_Cap'                                     'AShareBalanceSheet.MONEYTARY_CAP';
    'wQtr.ST_BORROW'                                        'AShareBalanceSheet.ST_BORROW';
    'wQtr.LT_BORROW'                                        'AShareBalanceSheet.LT_BORROW';
    'wQtr.Tot_Assets'                                       'AShareBalanceSheet.TOT_ASSETS';
    'wQtr.Tot_Cur_Assets'                                   'AShareBalanceSheet.TOT_CUR_ASSETS';
    'wQtr.Tot_Cur_Liab'                                     'AShareBalanceSheet.TOT_CUR_LIAB';
    'wQtr.Tot_Equity'                                       'AShareBalanceSheet.TOT_SHRHLDR_EQY_INCL_MIN_INT';
    'wQtr.Tot_Liab'                                         'AShareBalanceSheet.TOT_LIAB';
%    FactorLab_lqy
    'wQtr.Tot_Profit'                                       'AShareIncome.Tot_Profit';
    'wQtr.DeductedProfit'                                   'AShareFinancialIndicator.S_FA_DeductedProfit';
    'wQtr.minority_int'                                     'AShareBalanceSheet.MINORITY_INT';
    'wQtr.PerformanceExpress_Date'                          'AShareProfitExpress.ANN_DT';              % num2date();
    'wQtr.PerformanceExpress_PerfexIncome'                  'AShareProfitExpress.OPER_REV'
    'wQtr.PerformanceExpress_PerfexNetProfitToShareholder'  'AShareProfitExpress.TOT_PROFIT'
    'wQtr.PerformanceExpress_PerfexTotalProfit'             'AShareProfitExpress.NET_PROFIT_EXCL_MIN_INT_INC'
    'wQtr.ProfitNotice_Date'                                'AShareProfitNotice.S_PROFITNOTICE_DATE';  % num2date();
    'wQtr.ProfitNotice_NetProfitMin'                        'AShareProfitNotice.S_PROFITNOTICE_NETPROFITMIN';
    'wQtr.ProfitNotice_NetProfitMax'                        'AShareProfitNotice.S_PROFITNOTICE_NETPROFITMAX';
};

wQtrVars = {
    'wPrc_Stocks.AdjFactor'                                 'AShareEODPrices.S_DQ_ADJFACTOR';
    'wPrc_Stocks.FAClose'                                   'AShareEODPrices.S_DQ_ADJCLOSE';
    'wPrc_Stocks.Amt'                                       'AShareEODPrices.S_DQ_AMOUNT';
    'wPrc_Stocks.Volume'                                    'AShareEODPrices.S_DQ_VOLUME';
    'wPrc_Stocks.Pre_Close'                                 'AShareEODPrices.S_DQ_PRECLOSE';
    'wPrc_Stocks.Open'                                      'AShareEODPrices.S_DQ_OPEN';
    'wPrc_Stocks.Low'                                       'AShareEODPrices.S_DQ_LOW';
    'wPrc_Stocks.High'                                      'AShareEODPrices.S_DQ_HIGH';
    'wPrc_Stocks.Close'                                     'AShareEODPrices.S_DQ_CLOSE';
    'wPrc_Stocks.Total_Shares'                              'AShareCapitalization.TOT_SHR';
    'wPrc_Stocks.Float_A_Shares'                            'AShareCapitalization.TOT_A_SHR';
    'wPrc_Stocks.Free_Float_Shares'                         'AShareFreeFloat.S_SHARE_FREESHARES';   % ANN_DT
    'wPrc_Stocks.Industry_Citic'                            'AShareEODPrices.AIndexMembersCITICS';  % S_CON_INDATE
    'wPrc_Indices.Close'                                    'AIndexEODPrices.S_DQ_CLOSE';
    'wPrc_Indices.Close'                                    'AIndexIndustriesEODCITICS.S_DQ_CLOSE';
    'wIdx.CSI800'                                           ''
};

VN = {'Pre_Close';'Open';'High';'Low';'Close';'Volume';'Amt';'AdjFactor';'Total_Shares';'Float_A_Shares';'Free_Float_Shares';'Industry_SW';'Industry_Citic';'Industry_Citic2';'Dealnum'};
for v = fieldnames(wPrc_Stocks)'
    vn = v{:};
    disp(['wPrc_' vn ' = wPrc_Stocks.' vn ';']);
    eval(['wPrc_' vn ' = wPrc_Stocks.' vn ';']);
    switch vn
    case 'Volume';  wPrc_Volume = modify(wPrc_Volume, 'type',{'date','cell','single'});  wPrc_Volume = 10000*floor(wPrc_Volume/10000);
    case 'Amt';     wPrc_Amt    = modify(wPrc_Amt,    'type',{'date','cell','single'});  wPrc_Amt  =  100000*floor(wPrc_Amt/100000);
    end
    save(['wPrc_' vn '.mat'], ['wPrc_' vn]);
end
    


