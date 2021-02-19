tble0 = readtable('C:\Users\pinfuLG\Documents\MATLAB\Production\wind vs sun_time1.xlsx','Sheet','Sheet3');

brokerName2NoMap = brokerName2No(tble0);
brokerNo2NameMap = brokerNo2Name(tble0);

function result = brokerName2No(tble0)
   idx   = find(~strcmpi(tble0.AShareEarningEST,''));
   tble1 = tble0(idx,[2 8]);
   tble1.Properties.VariableNames(1) = {'BrokerName'};
   
   idx   = find(~strcmpi(tble0.Sun_Time,''));
   tble2 = tble0(idx,[5 8]);
   tble2.Properties.VariableNames(1) = {'BrokerName'};
   
   result = [tble1; tble2];
   result = sortrows(result,{'BrokerID','BrokerName'});
   result = containers.Map(result.BrokerName, result.BrokerID);
end


function result = brokerNo2Name(tble0)
   idx    = find(~isnan(tble0.BrokerID));
   result = tble0(idx,[8 9]);
   result.Properties.VariableNames(2) = {'BrokerName'};
   result = sortrows(result,{'BrokerID','BrokerName'});
   result = containers.Map(result.BrokerID, result.BrokerName);
end
