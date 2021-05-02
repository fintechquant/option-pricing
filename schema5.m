tic
dirData = getDir('Data');

sizeRMB = 4 * 10000000;
load([dirData '\DF-2.mat']);

Multiple = iff(DF.Size<=800, 1, iff(DF.Size<=1600, 1, 1)) + iff(DF.AmtMean>=100000000, 1, iff(DF.AmtMean >= 50000000, 1, 1));
Multiple = tshift(Multiple, -1) / 100;

iftrade0 = iff(DF.Amt>0, 1, 0);
iftrade1 = iff(abs(DF.Open/DF.Pre_Close-1)<0.095, 1, 0);

iftrade0 = iftrade0.modify('Data', [iftrade0.Data(1:end-1,:); iftrade0.Data(end-1:end-1,:)]);
iftrade1 = iftrade1.modify('Data', [iftrade1.Data(1:end-1,:); ones(1, numel(iftrade1.Dim2))]);

load([dirData '\mEst_Factors_NIs_f1.mat']);
load([dirData '\mEst_Factors_NIs_f2.mat']);

factor1 = iff(isnan(mEstFactors_NIs_f1.FY2),0,mEstFactors_NIs_f1.FY2)*1.3 + ...
          iff(isnan(mEstFactors_NIs_f1.FY3),0,mEstFactors_NIs_f1.FY3)*1.2 + ...
          iff(isnan(mEstFactors_NIs_f1.FY1),0,mEstFactors_NIs_f1.FY1)*1.1 + ...
          iff(isnan(mEstFactors_NIs_f1.FY0),0,mEstFactors_NIs_f1.FY0)*1.0 ;   

factor1 = iff(isnan(mEstFactors_NIs_f1.FY2)&isnan(mEstFactors_NIs_f1.FY3)&...
             isnan(mEstFactors_NIs_f1.FY1)&isnan(mEstFactors_NIs_f1.FY0), NaN, factor1);      

Dim1 = DF.Close.Dim1;
Dim2 = DF.Close.Dim2;

factor1 = ttsum(factor1, {[0;Dim1(1:end-1)]+9.01/24, Dim1+9.01/24}, Dim1, Dim2);
factor1 = iff(factor1>0.2, factor1, NaN);

factor2 = merge(mEstFactors_NIs_f2.FY2, mEstFactors_NIs_f2.FY1);
factor2 = iff(abs(factor2-1)<0.00001, 1, factor2);
factor2 = ttmean(factor2, {[0;Dim1(1:end-1)]+9.01/24, Dim1+9.01/24}, Dim1, Dim2);
factor2 = iff(factor2>1, factor2, NaN);

restforb = iff(iftrade0 ==0 | iftrade1 == 0, 1, 0);
restforb = subset(restforb, Dim1, Dim2); restforb = iff(isnan(restforb), 0, restforb); restforb = restforb.Data;
amt = trmean(DF.Amt, {-21, -1}); amt = amt.subset(Dim1, Dim2);  amt = iff(isnan(amt), 0, amt); amt = amt.Data;
multiple = subset(Multiple, Dim1, Dim2); multiple = iff(isnan(multiple), 0, multiple); multiple = multiple.Data;
Pre2Close = subset(DF.Close/DF.Pre_Close, Dim1, Dim2); Pre2Close = iff(isnan(Pre2Close), 1, Pre2Close); Pre2Close = Pre2Close.Data;
[~,i500] = ismember('000905.SH', Dim2);

config = 33;
switch config
case 33
    ftr1 = subset(factor1, Dim1, Dim2); ftr1 = xrankII(ftr1) / xmax(xrankII(ftr1)); 
    ftr2 = subset(factor2, Dim1, Dim2); ftr2 = xrankII(ftr2) / xmax(xrankII(ftr2));
    factor = iff(isnan(ftr1), 0, ftr1) * 2 + iff(isnan(ftr2), 0, ftr2);
    factor = iff(factor == 0, nan, factor);
    factor = xrankII(-factor);  factor = factor.Data;
    window_days = 20; schema = 5; numPort = 50; ranknum = 12;
case 0 
    ftr1 = subset(factor1, Dim1, Dim2); ftr1 = xrankII(-ftr1);
    ftr2 = subset(factor2, Dim1, Dim2); ftr2 = xrankII(-ftr2);
    factor = iff(~isnan(ftr1), ftr1, ftr2+50);
    factor = iff(isnan(factor), 9999, factor).Data;
    window_days = 1; schema = 2; base = 0.22; numPort = 2;
case 31
    ftr1 = subset(factor1, Dim1, Dim2); ftr1 = xrankII(-ftr1);
    ftr2 = subset(factor2, Dim1, Dim2); ftr2 = xrankII(-ftr2);
    factor = iff(~isnan(ftr1), ftr1, iff(~isnan(ftr2), ftr2+50, 9999)).Data;
    window_days = 1; schema = 2; base = 0.22; numPort = 2;
case 32
    ftr1 = subset(factor1, Dim1, Dim2); ftr1 = xrankII(ftr1);
    ftr2 = subset(factor2, Dim1, Dim2); ftr2 = xrankII(ftr2);
    factor = iff(~isnan(ftr1), ftr1, 0) + iff(~isnan(ftr2), ftr2, 0)/100;
    factor = xrankII(-factor);
    factor = iff(isnan(factor), 9999, factor).Data;
    window_days = 1; schema = 2; base = 0.22; numPort = 2;
case 12
    ftr1 = subset(factor1, Dim1, Dim2); ftr1 = xrankII(-ftr1);
    factor = iff(~isnan(ftr1), ftr1, 9999); factor = factor.Data;
    window_days = 1; schema = 2; base = 0.22; numPort = 2;
case 14
    ftr1 = subset(factor1, Dim1, Dim2); ftr1 = xrankII(-ftr1);
    factor = iff(~isnan(ftr1), ftr1, 9999).Data;
    window_days = 1; schema = 4; base = 12; numPort = 2;
case 22
    ftr2 = subset(factor2, Dim1, Dim2); ftr2 = xrankII(-ftr2);
    factor = iff(~isnan(ftr2), ftr2, 9999); factor = factor.Data;
    window_days = 1; schema = 2; base = 0.2; numPort = 2;
case 24
    ftr2 = subset(factor2, Dim1, Dim2); ftr2 = xrankII(-ftr2);
    factor = iff(~isnan(ftr2), ftr2, 9999).Data;
    window_days = 1; schema = 4; base = 30; numPort = 2;
end

vIndex = 0;
KEEP = zeros(window_days, numel(Dim2));
KEEPTdT = zeros(size(factor));

for t0 = 2:size(KEEPTdT,1)
    
    rankStk = factor(t0,:);
    portRank = rankStk;
    
    multBuy = double(restforb(t0,:) == 0);
    multBuy = 1 * multBuy .* multiple(t0,:);
    multBuy_1 = repmat(multBuy, [window_days-1,1]);
    multBuy_2 = repmat(multBuy, [window_days,1]);
    portRank_1 = repmat(portRank, [window_days-1, 1]);
    
    if sum(portRank <= numPort & restforb(t0,:) == 0)>=1
        if vIndex == 0; vIndex = 1*sizeRMB; end
        if vIndex > 1.05*sizeRMB; vIndex = 1.05 * sizeRMB; end
        if vIndex < 0.95*sizeRMB; vIndex = 0.95 * sizeRMB; end
        
        if sum(KEEP(KEEP>=0)) == 0
%             ≥ı ºªØ
            KEEP(:, (portRank<=numPort) & (restforb(t0,:)==0)) = multBuy_2(:,(portRank<=numPort) & (restforb(t0,:)==0))*vIndex/window_days;
        else
            
            KEEP(:, sum(KEEP,1)>0 & sum(KEEP,1)<0.0005*sizeRMB & restforb(t0,:)==0) = 0;
            KEEP_1 = KEEP(2:end,:);
            KEEP_2 = zeros([1, size(KEEP,2)]);
            KEEP_2((portRank<=numPort) & (restforb(t0,:)==0)) = multBuy((portRank<=numPort) & (restforb(t0,:)==0))*vIndex/window_days;
            
            KEEP_1(:,restforb(t0,:)==0 & portRank<=ranknum) = multBuy_1(:,restforb(t0,:)==0 & portRank<=ranknum) * vIndex/window_days;
            KEEP_1(:, restforb(t0,:) == 0 & isnan(portRank)) = 0;
            
            vKEEP = vIndex - sum(KEEP_1(:)) - sum(KEEP_2(:));
            
            rankmin = ranknum + 1;
            while (vKEEP > 1000 && rankmin < 999)
                rankInidx = find(double(restforb(t0,:) ==0 & portRank == rankmin));
                tempbuy = sum(sum(multBuy_1(:,rankInidx)* vIndex/window_days)) - sum(sum(KEEP_1(:,rankInidx)));
                if tempbuy > 0
%                     disp(rankmin)
                    if vKEEP - tempbuy > 0
                        KEEP_1(:,rankInidx) = multBuy_1(:,rankInidx)* vIndex/window_days;
                        vKEEP = vKEEP - tempbuy;
%                         disp(['change: -' num2str(tempbuy)])
%                         disp(['vKEEP: ' num2str(vKEEP)])
                    else
                        KEEP_1(:,rankInidx) = vKEEP/(window_days-1) ;
%                         disp(['change: -' num2str(vKEEP)])                       
                        vKEEP = 0;
%                         disp(['vKEEP: ' num2str(vKEEP)]) 
                    end
                end
                rankmin = rankmin + 1;
            end
            
            rankmax = 9999;
%             disp(vKEEP);
            while (vKEEP < -1000 && rankmax > 1)
                rankmax = max(portRank_1(restforb(t0,:) ==0 & KEEP_1>0));
                rankOutidx = find(portRank == rankmax);
%                 disp(rankmax);
%                 disp(rankOutidx);
                tempsell = sum(sum(KEEP_1(:,rankOutidx)));
                if vKEEP + tempsell < 0
                    KEEP_1(:,rankOutidx) = 0;
                    vKEEP = vKEEP + tempsell;
%                     disp(['change: +' num2str(tempsell)])
%                     disp(['vKEEP: ' num2str(vKEEP)])
                else
                    KEEP_1(:,rankOutidx) = KEEP_1(:,rankOutidx) + vKEEP/(window_days-1)/length(rankOutidx) ;
%                     disp(['change: +' num2str(-vKEEP)])                       
                    vKEEP = 0;
%                     disp(['vKEEP: ' num2str(vKEEP)]) 
                end
            end
            
            KEEP = [KEEP_1; KEEP_2];
            
        end
    else
        disp([datestr(Dim1(t0), 'yyyymmdd') '  ' num2str2([t0 sum(portRank<=numPort) sum(sum(KEEP,1)>0) sum(KEEP(KEEP>0)) -vIndex toc], '%13.0f') ' --']);
    end
    
    if abs(sum(KEEP(:)) / vIndex-1) > 0.01
        disp([datestr(Dim1(t0), 'yyyymmdd') '  ' num2str2([t0 sum(portRank<=numPort) sum(sum(KEEP,1)>0) sum(KEEP(KEEP>0)) -vIndex toc], '%13.0f') num2str2(sum(KEEP(:))/vIndex-1, '%8.4f')]);
    end
    if sum(KEEP(:))<vIndex*0.98 || sum(KEEP(:))>vIndex*1.02; vIndex = sum(KEEP(:)); end
    
    KEEP(end, i500) = -vIndex;
    KEEP = KEEP .* Pre2Close(t0,:);
    KEEPTdT(t0,:) = sum(KEEP, 1);
    vIndex = -sum(KEEP(:, i500));
    
    if ismember(t0, [2 floor((1:numel(Dim1))/100.00)*100.00 numel(Dim1)])
        disp([datestr(Dim1(t0), 'yyyymmdd') '  ' num2str2([t0 sum(portRank<=numPort) sum(sum(KEEP,1)>0) sum(KEEP(KEEP>0)) sum(KEEP(KEEP<0)) toc], '%13.0f')]);
    end
    KEEP(:, i500) = 0;
        
end
KEEPTdT = iftrade1.modify('Data', KEEPTdT);
disp(['config: ' num2str(config) '; window_days: ' num2str(window_days) '; schema: ' num2str(schema) '; numPort: ' num2str(numPort) '; ranknum: ' num2str(ranknum)]);

PortWei = KEEPTdT;
save('C:\Users\Admin\Desktop\factor12.mat', 'PortWei');

Nav = Port_NavUSD(DF, 'C:\Users\Admin\Desktop\factor12', 'xls');

