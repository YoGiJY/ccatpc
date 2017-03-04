
%% This script tests the static CCA and static TxP

function runtask_static_cca_static_txp

ccaScheme   =   0;                                                          % static CCA    ��1������̬
txpScheme   =   0;                                                          % static TxP
frReuse     =   1;                                                          % freq reuse     Ƶ�ʸ�������

fprintf('  CCA_Old    CCA_New  TxP_Old  TxP_New    ÿ����ƽ��    ÿ�û�ƽ��    ���û�ƽ��    ���û�ƽ��   ���û���Ŀ    ���û���Ŀ    ���û���Ŀ   ��ѭ��ʱ��\n');
fprintf('  (dBm)      (dBm)    (dBm)    (dBm)       (Mbps)       (Mbps)        (Mbps)       (Mbps)     (Number)     (Number)     (Number)     (second)\n');

for cca=-90:5:-30                                                           % CCA level �� -90 dBm �� -30 dBm
    for txp=10:5:20;                                                        % TxP level �� 10  dBm ��  20 dBm
        
        %% ����1.  ���û� CCA = ���û� CCA�� ���û� TxP = ���û� TxP
        cca0        =   cca;
        txp0        =   txp;    tic; 
        cstat       =   dynamic_ccatpc(frReuse,ccaScheme,cca,txpScheme,txp);      % 0�� static CCA and static txp
        fprintf('%6d %9d %8d %8d ', cca, cca0, txp, txp0);
        fprintf('%12.1f %12.1f %12.1f %12.1f %12.1f %12.1f %12.1f ',cstat.ulRoomMean, cstat.ulUserMean, cstat.ulOldUserMean, cstat.ulNewUserMean, cstat.ulUserActv, cstat.ulOldUserActv, cstat.ulNewUserActv); b           =   toc;
        fprintf('%12.0f \n', b);
        
        %% ����2.  ���û� CCA = ���û� CCA + 5 dB�� ���û� TxP = ���û� TxP
        cca0        =   cca+5;
        txp0        =   txp;    tic;
        cstat       =   dynamic_ccatpc(frReuse,ccaScheme,cca,cca+5,txpScheme,txp, txp);%cca��    cca+5��
        fprintf('%6d %9d %8d %8d ', cca, cca0, txp, txp0);
        fprintf('%12.1f %12.1f %12.1f %12.1f %12.1f %12.1f %12.1f ',cstat.ulRoomMean, cstat.ulUserMean, cstat.ulOldUserMean, cstat.ulNewUserMean, cstat.ulUserActv, cstat.ulOldUserActv, cstat.ulNewUserActv); b           =   toc;
        fprintf('%12.0f \n', b);
        
        %% ����3.  ���û� CCA = ���û� CCA�� ���û� TxP = ���û� TxP + 5 dB
        cca0        =   cca;
        txp0        =   txp+5; tic;
        cstat       =   dynamic_ccatpc(frReuse,ccaScheme,cca,cca,txpScheme,txp, txp+5);
        fprintf('%6d %9d %8d %8d ', cca, cca0, txp, txp0);
        fprintf('%12.1f %12.1f %12.1f %12.1f %12.1f %12.1f %12.1f ',cstat.ulRoomMean, cstat.ulUserMean, cstat.ulOldUserMean, cstat.ulNewUserMean, cstat.ulUserActv, cstat.ulOldUserActv, cstat.ulNewUserActv); b           =   toc;
        fprintf('%12.0f \n', b);

        %% ����4.  ���û� CCA = ���û� CCA + 5 dB�� ���û� TxP = ���û� TxP + 5 dB
        cca0        =   cca+5;
        txp0        =   txp+5;  tic;
        cstat       =   dynamic_ccatpc(frReuse,ccaScheme,cca,cca+5,txpScheme,txp, txp+5);
        fprintf('%6d %9d %8d %8d ', cca, cca0, txp, txp0);
        fprintf('%12.1f %12.1f %12.1f %12.1f %12.1f %12.1f %12.1f ',cstat.ulRoomMean, cstat.ulUserMean, cstat.ulOldUserMean, cstat.ulNewUserMean, cstat.ulUserActv, cstat.ulOldUserActv, cstat.ulNewUserActv); b           =   toc;
        fprintf('%12.0f\n\n', b);

    end;
end
end