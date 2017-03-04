
%% This script tests the static CCA and static TxP

function runtask_static_cca_static_txp

ccaScheme   =   0;                                                          % static CCA    “1”：动态
txpScheme   =   0;                                                          % static TxP
frReuse     =   1;                                                          % freq reuse     频率复用因子

fprintf('  CCA_Old    CCA_New  TxP_Old  TxP_New    每房间平均    每用户平均    旧用户平均    新用户平均   总用户数目    旧用户数目    新用户数目   此循环时间\n');
fprintf('  (dBm)      (dBm)    (dBm)    (dBm)       (Mbps)       (Mbps)        (Mbps)       (Mbps)     (Number)     (Number)     (Number)     (second)\n');

for cca=-90:5:-30                                                           % CCA level 从 -90 dBm 到 -30 dBm
    for txp=10:5:20;                                                        % TxP level 从 10  dBm 到  20 dBm
        
        %% 案例1.  新用户 CCA = 旧用户 CCA； 新用户 TxP = 旧用户 TxP
        cca0        =   cca;
        txp0        =   txp;    tic; 
        cstat       =   dynamic_ccatpc(frReuse,ccaScheme,cca,txpScheme,txp);      % 0： static CCA and static txp
        fprintf('%6d %9d %8d %8d ', cca, cca0, txp, txp0);
        fprintf('%12.1f %12.1f %12.1f %12.1f %12.1f %12.1f %12.1f ',cstat.ulRoomMean, cstat.ulUserMean, cstat.ulOldUserMean, cstat.ulNewUserMean, cstat.ulUserActv, cstat.ulOldUserActv, cstat.ulNewUserActv); b           =   toc;
        fprintf('%12.0f \n', b);
        
        %% 案例2.  新用户 CCA = 旧用户 CCA + 5 dB； 新用户 TxP = 旧用户 TxP
        cca0        =   cca+5;
        txp0        =   txp;    tic;
        cstat       =   dynamic_ccatpc(frReuse,ccaScheme,cca,cca+5,txpScheme,txp, txp);%cca旧    cca+5新
        fprintf('%6d %9d %8d %8d ', cca, cca0, txp, txp0);
        fprintf('%12.1f %12.1f %12.1f %12.1f %12.1f %12.1f %12.1f ',cstat.ulRoomMean, cstat.ulUserMean, cstat.ulOldUserMean, cstat.ulNewUserMean, cstat.ulUserActv, cstat.ulOldUserActv, cstat.ulNewUserActv); b           =   toc;
        fprintf('%12.0f \n', b);
        
        %% 案例3.  新用户 CCA = 旧用户 CCA； 新用户 TxP = 旧用户 TxP + 5 dB
        cca0        =   cca;
        txp0        =   txp+5; tic;
        cstat       =   dynamic_ccatpc(frReuse,ccaScheme,cca,cca,txpScheme,txp, txp+5);
        fprintf('%6d %9d %8d %8d ', cca, cca0, txp, txp0);
        fprintf('%12.1f %12.1f %12.1f %12.1f %12.1f %12.1f %12.1f ',cstat.ulRoomMean, cstat.ulUserMean, cstat.ulOldUserMean, cstat.ulNewUserMean, cstat.ulUserActv, cstat.ulOldUserActv, cstat.ulNewUserActv); b           =   toc;
        fprintf('%12.0f \n', b);

        %% 案例4.  新用户 CCA = 旧用户 CCA + 5 dB； 新用户 TxP = 旧用户 TxP + 5 dB
        cca0        =   cca+5;
        txp0        =   txp+5;  tic;
        cstat       =   dynamic_ccatpc(frReuse,ccaScheme,cca,cca+5,txpScheme,txp, txp+5);
        fprintf('%6d %9d %8d %8d ', cca, cca0, txp, txp0);
        fprintf('%12.1f %12.1f %12.1f %12.1f %12.1f %12.1f %12.1f ',cstat.ulRoomMean, cstat.ulUserMean, cstat.ulOldUserMean, cstat.ulNewUserMean, cstat.ulUserActv, cstat.ulOldUserActv, cstat.ulNewUserActv); b           =   toc;
        fprintf('%12.0f\n\n', b);

    end;
end
end