% CCA TPC �����Ż�����������
% 1. ��ҪΪ�����������
% 2. �û���Ϊ���飬ÿ���û��ɾ��в�ͬ��ϵͳ���������ʿ��ƣ�CCA�ȣ�
% Author:   Pengfei XIA
% Date:     2015.07.31

%% ������
function cstat  = dynamic_ccatpc(varargin)

switch nargin 
    case 5
        frFactor            =   varargin{1};
        ccaScheme           =   varargin{2};
        ccaLevelOld         =   varargin{3};
        ccaLevelNew         =   varargin{3};
        txpScheme           =   varargin{4};
        txpLevelOld         =   varargin{5};
        txpLevelNew         =   varargin{5};
        
        switch ccaScheme 
            case 1
                ccaString   =   strcat('CCA dynamic ', num2str(ccaLevelOld));
            case 0
                ccaString   =   strcat('CCA  static ', num2str(ccaLevelOld));
        end
        switch txpScheme 
            case 1
                txpString   =   strcat('TxP dynamic ', num2str(txpLevelOld));
            case 0
                txpString   =   strcat('TxP  static ', num2str(txpLevelOld));
        end
        frString            =   strcat('Freq Reuse ', num2str(frFactor));
        fname               =   strcat(frString, ccaString, txpString, '.mat');
        
    case 7
        frFactor            =   varargin{1};
        ccaScheme           =   varargin{2};
        ccaLevelOld         =   varargin{3};
        ccaLevelNew         =   varargin{4};
        txpScheme           =   varargin{5};
        txpLevelOld         =   varargin{6};
        txpLevelNew         =   varargin{7};
        switch ccaScheme
            case 1
                ccaString   =   strcat('CCA dynamic ', num2str(ccaLevelOld), '/', num2str(ccaLevelNew));
            case 0
                ccaString   =   strcat('CCA  static ', num2str(ccaLevelOld), '/', num2str(ccaLevelNew));
        end
        switch txpScheme
            case 1
                txpString   =   strcat('TxP dynamic ', num2str(txpLevelOld), '/', num2str(txpLevelNew));
            case 0
                txpString   =   strcat('TxP  static ', num2str(txpLevelOld), '/', num2str(txpLevelNew));
        end
        frString            =   strcat('Freq Reuse ', num2str(frFactor));
        fname               =   strcat(frString, ccaString, txpString, '.mat');
end

%     frFactor,  ...
%     ccaScheme, ...                                                          % CCA����
%     ccaLevel, ...                                                           % CCA�������ã�����Ǿ�̬CCA����ΪCCA����(dBm)������Ƕ�̬CCA������Ϊ CCA margin (dB)��
%     txpScheme, ...                                                          % ���书�ʷ���
%     txpLevel ...                                                            % ���书�ʲ���������Ǿ�̬TXP����ΪTXP����dBm������Ƕ�̬TXP������ΪTXP margin (dB)��
%     )                                                                       % Ƶ�ʸ������ӣ����Ϊ1�����з��䣨��С��������ͬһƵ�㣬��˲�ͬ����֮�以����ţ�
%                                                                             % ���Ϊ3�����з��乫��������ͬ��Ƶ�㡣���ò�ͬƵ��ķ���֮�以�����š�
rng(1);
%% 1. ��������

nets.frFactor                   =   frFactor;
nets.ccaScheme                  =   ccaScheme;
nets.ccaLevelOld                =   ccaLevelOld;
nets.ccaLevelNew                =   ccaLevelNew;
nets.txpScheme                  =   txpScheme;
nets.txpLevelOld                =   txpLevelOld;
nets.txpLevelNew                =   txpLevelNew;

nets.mcstable                   =   1;                                      % MCS��������
nets.fixAPTxpLevel              =   20;                                     % 20 dBm Tx power for all serving APs (by default); used for uplink transmissions
nets.fixCCALevel                =   -80;                                    % -80 dBm CCA level by default
nets.numDrops                   =   50;                                     % ������Number of drops
nets.numEvents                  =   20;                                     % ÿ����������¼���
nets.roomSize                   =   10;                                     % ���䳤��=���
nets.roomHeight                 =   3;                                      % ����߶�
nets.floorLoss                  =   17;                                     % all in dB
nets.wallLoss                   =   12;                                     % reference IEEE 802.11-14/0082  
nets.combLoss                   =   14.5;                                   % combined floor/wall loss

ccaLevelAP                      =   nets.fixCCALevel;                       % not used for uplink
ccaLevelOldSTA                  =   nets.ccaLevelOld;                       % to be configured
ccaLevelNewSTA                  =   nets.ccaLevelNew;                       % to be configured

txpLevelAP                      =   nets.fixAPTxpLevel;                     % AP Txp ��������ȷ�� STA �Ķ�̬ CCA ����
txpLevelOldSTA                  =   nets.txpLevelOld;                       % to be configured
txpLevelNewSTA                  =   nets.txpLevelNew;                       % to be configured

uldlProb            =   1;



%% 2. �������ã�ÿ������һ��AP�� ÿ�������ĸ��û�����Ŀ������)��2 old STA and 2 new STA

show3D                          =   0;                                      % ��ʾ 1��disabled by default
numFloors                       =   1;                                      % number of floors for the entire network
numRows                         =   5;                                      % number of rows
numCells                        =   5;                                      % number of cells per row
numOldSTAperAP                  =   2;                                      % number of legacy/old stas per ap/room
numNewSTAperAP                  =   2;                                      % number of new stas per ap/room
numRooms                        =   numFloors * numRows * numCells;         % �ܷ����� number of ttl rooms in the building network
numAP                           =   numRooms;                               % ÿ������һ��AP
numSTAsperAP                    =   numOldSTAperAP + numNewSTAperAP;        % ÿ�����û��� number of stas in total per room/ap
nodesperAP                      =   numSTAsperAP + 1;                       % ÿ�����豸�����û���+1 AP) number of nodes (stas + 1 ap) per room/ap
numSTAs                         =   numSTAsperAP * numAP;                   % ���������û��� ��STA only��number of stas in the network
numOldSTAs                      =   numOldSTAperAP * numAP;                 % ����������û���
numNewSTAs                      =   numNewSTAperAP * numAP;                 % �����������û���
numNodes                        =   numAP + numSTAs;                        % ���������豸�� ��STA +��AP)number of nodes in the network

nets.show3D                     =   show3D;
nets.floors                     =   numFloors;
nets.rows                       =   numRows;
nets.cells                      =   numCells;
nets.numOldSTAperAP             =   numOldSTAperAP;
nets.numNewSTAperAP             =   numNewSTAperAP;
nets.numRooms                   =   numRooms;
nets.numAP                      =   numAP;
nets.numSTAsperAP               =   numSTAsperAP;
nets.nodesperAP                 =   nodesperAP;
nets.numSTAs                    =   numSTAs;
nets.numOldSTAs                 =   numOldSTAs;
nets.numNewSTAs                 =   numNewSTAs;
nets.numNodes                   =   numNodes;
nets.freqIndex                  =   1;
nets.nodeIndex                  =   1:nets.numNodes;
nets.APIndex                    =   1:nets.nodesperAP:nets.numNodes;               %AP���豸��ţ�1,6,11,16.......
nets.STAIndex                   =   setdiff(nets.nodeIndex, nets.APIndex);         %�����û����豸��ţ�2,3,4,5��7,8,9,10.....
nets.oldSTAIndex                =   sort([2:nets.nodesperAP:nets.numNodes, 3:nets.nodesperAP:nets.numNodes]);%���û����豸��ţ�2,3,7,8,....
nets.newSTAIndex                =   sort([4:nets.nodesperAP:nets.numNodes, 5:nets.nodesperAP:nets.numNodes]);%���û����豸��ţ�4,5,9,10....
nets.uldlProb                   =   uldlProb;

%% 3. ��������
roomID = 0;
for x=1:1:numFloors
    for y=1:numRows
        for z=1:numCells
            roomID              = roomID+1;                                 % �����
            roomArray(roomID)   = rooms(roomID,x,y,z,nets);                 % �ڵ�X���Y�е�Z�м�һ������
        end;
    end;
end

%% 4. ����ѭ����ÿ�������ڣ��û���λ�ã��Լ��ŵ�˥�����ŵ���Ӱ�ȣ����ֲ��䡣��ͬ����֮�䣬�û���λ�ã��Լ��ŵ�˥�����ŵ���Ӱ�ȣ�����仯��
for xDrops = 1:nets.numDrops
    
    freqArray                   =   randi([1 frFactor],1,numRooms);         % ��ÿ�������������һ��Ƶ��
    
    nodeID   = 0;
    
    for roomID=1:numRooms                                                   % 4.1 ��ÿ����������豸��װ
        
        nodeID                  =   nodeID+1;                               % nodeID    ��ǰ�豸��AP��STA)֮nodeid
        APID                    =   nodeID;                                 % APID      AP֮nodeid
        % AP��װ������ţ��豸�ţ����书�ʣ�CCA������Ƶ�㣬netsϵͳ����
        nodes(nodeID)    =   roomArray.addAP(roomID, nodeID, txpLevelAP, ccaLevelAP,freqArray(roomID), nets); %#ok<*AGROW>
        
        % �û���װ��old STA for this loop and new STA for the next loop
        for j=1:nets.numOldSTAperAP
            
            nodeID       =   nodeID+1;                                      % ��ǰ�û��豸��nodeID����ǰ�û���AP֮�豸��APID
            
            % ����ţ��豸�ţ����书�ʣ�CCA��Ƶ�㣬nets��old STA
            nodes(nodeID)=   roomArray.addSTA(roomID,nodeID,txpLevelOldSTA, ccaLevelOldSTA, freqArray(roomID), nets, 1); %#ok<AGROW> 1:���û�
            
            ccaLevel     =      nets.ccaLevelOld;
            txpLevel     =      nets.txpLevelOld;
            if ccaScheme == 1                                                   % �����̬CCA�����У���Ҫ����ÿ���û���CCA������
                [pathLoss, ~, dist] = calcPL(nodes(APID), nodes(nodeID),nets);  % �����û���ǰλ�ú�AP��λ�ã������ŵ�˥�����ŵ���Ӱ����
                ttcca = nets.fixAPTxpLevel - pathLoss - ccaLevel;               % ��̬CCA = AP ���书�� - �ŵ�˥�� - CCA margin ����
                if ttcca > -50                                                  % ��λdBm;
                    ttcca = -50;
                end
                nodes(nodeID).ccaLevel   = ttcca;
            end
            if txpScheme==1                                                     % �����̬���ʿ��������У���������书��
                [pathLoss, ~, dist] = calcPL(nodes(APID), nodes(nodeID),nets);  %#ok<*NASGU>
                targetrxpwr = 30 + (-96);                                       % �������չ��ʣ�����SNR ��Ϊ 30 dB��(-96)= (-174)+73(20MHz)+5(noise figure)��
                targettxpwr = targetrxpwr + pathLoss + txpLevel;                % �������书�ʣ�txpLevel is the margin here.
                if targettxpwr < 0                                              % ��λdBm
                    targettxpwr = 0;
                end
                nodes(nodeID).txpLevel =   targettxpwr;
            end
        end
        
        % �ظ�������� for new STA
        for j=1:numNewSTAperAP
            nodeID       =   nodeID+1;
            %����ţ��豸�ţ����书�ʣ�CCA��Ƶ�㣬nets��new STA
            nodes(nodeID)=   roomArray.addSTA(roomID,nodeID,txpLevelNewSTA, ccaLevelNewSTA, freqArray(roomID), nets, 0);
            
            
            ccaLevel     =      nets.ccaLevelNew;
            txpLevel     =      nets.txpLevelNew;
            if ccaScheme == 1
                [pathLoss, ~, dist] = calcPL(nodes(APID), nodes(nodeID),nets);
                ttcca = nets.fixAPTxpLevel - pathLoss - ccaLevel;
                if ttcca > -50
                    ttcca = -50;
                end
                nodes(nodeID).ccaLevel   = ttcca;
            end
            if txpScheme==1
                [pathLoss, ~, dist] = calcPL(nodes(APID), nodes(nodeID),nets);
                targetrxpwr = 30 + (-96);                                   % (-96)= (-174)+73(20MHz)+5(noise figure);
                targettxpwr = targetrxpwr + pathLoss + txpLevel;            % txpLevel is the margin here.
                if targettxpwr < 0                                          % ��λdBm
                    targettxpwr = 0;
                end
                nodes(nodeID).txpLevel =   targettxpwr;
            end
        end
    end
    
    
    nodes_f1 = [];
    nodes_f2 = [];
    nodes_f3 = [];
    nodes_tt = [];            %�б�1-125
    
    for nodeID=1:nets.numNodes
        nodes_tt        =   [nodes_tt nodes(nodeID)];                       % ����Ƶ���ϵ������Լ��豸�б�
        switch nodes(nodeID).freq
            case 1
                nodes_f1 = [nodes_f1 nodes(nodeID)];                        % ��һƵ���ϵ������Լ��豸�б�
            case 2
                nodes_f2 = [nodes_f2 nodes(nodeID)];                        % �ڶ�Ƶ���ϵ������Լ��豸�б�
            case 3
                nodes_f3 = [nodes_f3 nodes(nodeID)];                        % ����Ƶ���ϵ������Լ��豸�б�
        end
    end
    
    %% ����
    switch frFactor
        case 1
            cout{1}{xDrops}                 = sim_one_freq(nodes_f1, nodes_tt, nets);
            for m=1:length(cout{1}{xDrops})
                dout{xDrops}(m).ulRoomThru  = cout{1}{xDrops}(m).ulRoomThru; %1��Ƶ��  xDrops������������    m���¼�������index of event
                dout{xDrops}(m).ulUserThru  = cout{1}{xDrops}(m).ulUserThru;
            end
        case 3
            cout{1}{xDrops}                 = sim_one_freq(nodes_f1, nodes_tt, nets);
            cout{2}{xDrops}                 = sim_one_freq(nodes_f2, nodes_tt, nets);
            cout{3}{xDrops}                 = sim_one_freq(nodes_f3, nodes_tt, nets);
            for m=1:length(cout{1}{xDrops})
                dout{xDrops}(m).ulRoomThru  =   cout{1}{xDrops}(m).ulRoomThru + ...
                    cout{2}{xDrops}(m).ulRoomThru + ...
                    cout{3}{xDrops}(m).ulRoomThru;
                dout{xDrops}(m).ulUserThru  =   cout{1}{xDrops}(m).ulUserThru + ...
                    cout{2}{xDrops}(m).ulUserThru + ...
                    cout{3}{xDrops}(m).ulUserThru;
            end
    end
end

%% 5. ���ݲɼ�
cstat   =   collect(dout, nets);

% save(fname, 'cstat');
% fprintf('%7d   ', txpLevel);
% fprintf('%7d   ', ccaLevel);
% fprintf('%14.0f ', cstat.ttl_thru_all);
% fprintf('%20.1f ', cstat.pctl5thru);
% fprintf('%20.0f ', cstat.num_link_all);


end

%% ����һ��Ƶ�����
function tout = sim_one_freq(nodes_f0, nodes_tt, nets)

% nodes_f0      ��Ƶ�������豸�б�
% nodes_tt      ���������豸�б�
% nets          ϵͳ����

if isempty(nodes_f0) % �����Ƶ��û���豸��ֱ�������˳�
    for xEvent = 1:nets.numEvents
        tout(xEvent).ulRoomThru     =   zeros(1, nets.numRooms);
        tout(xEvent).ulUserThru     =   zeros(1, nets.numNodes);
    end
else
    
    numRoomsTtl         =   nets.rows * nets.cells * nets.floors;           % �ܹ�����������Ƶ���Լ�����Ƶ�㣩
    numRoomsThisFreq    =   length(nodes_f0)/nets.nodesperAP;               % ��Ƶ�㷿����
    
    numNodesTtl         =   numRoomsTtl * nets.nodesperAP;                  % �ܹ��豸��
    numNodesThisFreq    =   length(nodes_f0);                               % ��Ƶ���豸��
    
    numStasTtl          =   numRoomsTtl * (nets.nodesperAP - 1);            % �ܹ��û���
    numStasThisFreq     =   numRoomsThisFreq * (nets.nodesperAP - 1);       % ��Ƶ���û���
    
    roomIdThisFreq      =   [];
    nodeIdThisFreq      =   [];
    
    for i = 1:length(nodes_f0)
        roomIdThisFreq  =   [roomIdThisFreq, nodes_f0(i).roomid];
        nodeIdThisFreq  =   [nodeIdThisFreq, nodes_f0(i).nodeid];           % ��Ƶ���ϵ��豸���б�
    end
        roomIdThisFreq      =   unique(roomIdThisFreq);                     % ��Ƶ���ϵķ�����б�Ϊ�λ������ͬ��roomId in this Freq
    
    
    % �Դ˳����£������û�λ���ѹ̶���APλ���ѹ̶����ŵ�˥�����ȷ�����ŵ���ӰҲ����Ϊȷ������Ϊ�ŵ�˥����һ���֡�
    for i= 1:numNodesTtl
        for j=i:numNodesTtl
            [pathlossdb(i,j), shadowingdb(i,j), chpwrdb(:,i,j)] = calcPL(nodes_tt(i), nodes_tt(j), nets);
            pathlossdb(i,j)     =   pathlossdb(i,j) + shadowingdb(i,j);
        end
    end
    for i=1:numNodesTtl
        for j=1:i
            pathlossdb(i,j) = pathlossdb(j,i);
            chpwrdb(:,i,j)  = chpwrdb(:,j,i);
        end
    end
    
    %roomThru        =   zeros(nets.numEvents, numRoomsTtl);                 % ÿ������throughput�б�
    userThru        =   zeros(nets.numEvents, numStasTtl);                  % ÿ���û�throughput�б�
    
    % �¼�ѭ������ͬ�¼��У���ͬ�ķ����еĲ�ͬ�û��õ���ͬ��throughput��
    for xEvent = 1:nets.numEvents
        
        oldlinks        =   [];                                             % ��ȷ�����ӣ�����CCA׼��
        newlink         =   [];                                             % ��ȷ�����ӣ�����CCA׼�����ȷ�ϣ�
        pendingset      =   roomIdThisFreq;                                 % ��Ƶ���ϴ�ȷ�Ϸ����б�
        pendingaps      =   length(pendingset);                             % ��Ƶ���ϴ�ȷ�Ϸ�����
        
        while ~isempty(pendingset)
            
            ftt         =   randi(pendingaps, 1, 1);                        % �Ӵ�ȷ�Ϸ��������ѡȡ
            roomx       =   pendingset(ftt);                                % ��ѡ�з����ȫ�ַ����(����Ƶ��)
            
            roomap      =   (roomx-1) * nets.nodesperAP + 1;                % ��ѡ�з���AP֮�豸��
            roomsta     =   roomap + randi(nets.nodesperAP-1,1,1);          % �ڱ�ѡ�з��������ѡȡһ���û�֮�豸��
            
            pendingset  =   pendingset([1:ftt-1 ftt+1:end]);                % ���� �ѵ�ǰ����Ӵ�ȷ�Ϸ�����ɾ��
            pendingaps  =   length(pendingset);                             % ���±�Ƶ���ϴ�ȷ�Ϸ�����
            
            % ����
            txNodeID        =   roomsta;                                   % ������豸��
            rxNodeID        =   roomap;                                    % ���ջ��豸��
            uldl            =   1;
            newlink.txid        =   txNodeID;                               % �����ӷ�����豸��
            newlink.rxid        =   rxNodeID;                               % �����ӽ��ջ��豸��
            newlink.uldl        =   uldl;
            oldlinks   =   check_link(oldlinks, newlink, pathlossdb, chpwrdb, nodes_tt);        % ȷ�ϸ������Ƿ�����CCA׼��    ���Ϊ�Ѿ�ȷ�ϳɹ�����links
            
        end
        
        all_active_links        =   oldlinks;                               % ���������¼��£�����active�����ӡ�
        tout(xEvent) = runbss(all_active_links, pathlossdb, chpwrdb, nodes_tt, nets);
        
    end
    
end
end


%% �ɼ�����
function cstat = collect(dout, nets)

tmp0            =   zeros(nets.numDrops, nets.numEvents, nets.numRooms);
tmp1            =   zeros(nets.numDrops, nets.numEvents);
for xDrops = 1:length(dout)
    for xEvent = 1:length(dout{1})
        tmp0(xDrops, xEvent, :)     =   dout{xDrops}(xEvent).ulRoomThru;
        tmp1(xDrops, xEvent)        =   length(find(dout{xDrops}(xEvent).ulRoomThru));
    end
end
cstat.ulRoomThru                    =   squeeze(mean(mean(tmp0,1),2))';     % ÿ������throughput�б�
cstat.ulRoomActv                    =   mean(mean(tmp1));                   % Active�ķ�����
cstat.ulRoomMean                    =   mean(cstat.ulRoomThru);             % ÿ������ƽ��throughput

tmp00           =   zeros(nets.numDrops, nets.numEvents, nets.numSTAs);
tmp10           =   zeros(nets.numDrops, nets.numEvents, nets.numOldSTAs);
tmp20           =   zeros(nets.numDrops, nets.numEvents, nets.numNewSTAs);
tmp11           =   zeros(nets.numDrops, nets.numEvents);
tmp21           =   zeros(nets.numDrops, nets.numEvents);

for xDrops = 1:length(dout)
    for xEvent = 1:length(dout{1})
        tmp00(xDrops, xEvent, :)    =   dout{xDrops}(xEvent).ulUserThru(nets.STAIndex);
        tmp10(xDrops, xEvent, :)    =   dout{xDrops}(xEvent).ulUserThru(nets.oldSTAIndex);
        tmp20(xDrops, xEvent, :)    =   dout{xDrops}(xEvent).ulUserThru(nets.newSTAIndex);
        
        tmp01(xDrops, xEvent)       =   length(find(dout{xDrops}(xEvent).ulUserThru(nets.STAIndex)));
        tmp11(xDrops, xEvent)       =   length(find(dout{xDrops}(xEvent).ulUserThru(nets.oldSTAIndex)));
        tmp21(xDrops, xEvent)       =   length(find(dout{xDrops}(xEvent).ulUserThru(nets.newSTAIndex)));
    end
end
cstat.ulUserThru                    =   squeeze(mean(mean(tmp00,1),2))';    % ÿ���û�throughput�б�
cstat.ulOldUserThru                 =   squeeze(mean(mean(tmp10,1),2))';    % ÿ�����û�throughput�б�
cstat.ulNewUserThru                 =   squeeze(mean(mean(tmp20,1),2))';    % ÿ�����û�throughput�б�

cstat.ulUserActv                    =   mean(mean(tmp01));                  % Active���û���
cstat.ulOldUserActv                 =   mean(mean(tmp11));                  % Active�ľ��û���
cstat.ulNewUserActv                 =   mean(mean(tmp21));                  % Active�����û���

cstat.ulUserMean                    =   mean(cstat.ulUserThru);             % ÿ���û�ƽ��throughput
cstat.ulOldUserMean                 =   mean(cstat.ulOldUserThru);          % ÿ�����û�ƽ��throughput
cstat.ulNewUserMean                 =   mean(cstat.ulNewUserThru);          % ÿ�����û�ƽ��throughput

end

%% ���浱ǰ�����throughput
function out = runbss(links, pathlossdb, chpwrdb, nodes_tt, nets)

% links         ����active����
% pathlossdb    �ŵ�˥������
% chpwrdb       �ŵ�ϵ������
% nodes_tt      �����豸�ڵ��б�
% nets          ϵͳ����

numRooms        =   nets.floors * nets.rows * nets.cells;

ulRoomThru      =   zeros(1, numRooms);                                     % ����ÿ������throughput

ulUserThru      =   zeros(1, numRooms * (nets.numSTAsperAP+1));             % ����ÿ���û�throughput

numlinks        =   length(links);

if numlinks     == 1
    txid        = links(1).txid;
    rxid        = links(1).rxid;
    signal_pwr  = chpwrdb(:,txid, rxid) - pathlossdb(txid,rxid) + nodes_tt(txid).txpLevel;%���ܵ��źŵ�ǿ��
    
    interf_pwr  = -96;                                                      % -174+73(20MHz)+5(noise figure)���ջ�����������
    sinrdb      = signal_pwr - interf_pwr;                                  %���ջ����Ÿ����SINR
    thruputs    = phy_abs(sinrdb, nets);                                    % in units of Mbps
    % ����
    staid   = txid;
    apid    = rxid;
    
    roomid      = (apid-1)/(nets.numSTAsperAP+1)+1;                         % ��apid��ȡroomid
    
    ulRoomThru(roomid)          =   thruputs;
    ulUserThru(staid)           =   thruputs;
else
    for i=1:numlinks
        rxid = links(i).rxid;
        nilink  = 0;                                                        % ����������
        for j=1:numlinks
            txid = links(j).txid;
            if j==i
                sgpwr = chpwrdb(:, txid, rxid);
                sgpls = pathlossdb(txid,rxid);
                sgpwr = sgpwr - sgpls + nodes_tt(txid).txpLevel;
            else
                nilink = nilink + 1;
                inpwr(:, nilink) = chpwrdb(:, txid, rxid);
                inpls(nilink)    = pathlossdb(txid, rxid);
                inpwr(:, nilink) = inpwr(:, nilink) - inpls(nilink) + nodes_tt(txid).txpLevel;
            end
        end
        inpwr = [inpwr -96*ones(size(inpwr,1), 1)];                         % add noise power of -96dbm;
        signal_pwr = sgpwr;
        interf_pwr = 10*log10(sum(10.^(inpwr/10),2));
        sinrdb = signal_pwr - interf_pwr;
        thruputs(i) = phy_abs(sinrdb, nets);
        % ����
        staid = links(i).txid;
        apid  = links(i).rxid;
        
        roomid = (apid-1)/(nets.numSTAsperAP+1)+1;
        % ����
        ulRoomThru(roomid)          =   thruputs(i);
        ulUserThru(staid)           =   thruputs(i);
        
    end
end

out.ulRoomThru      =   ulRoomThru;                                         % ���У�ÿ������throughput
out.ulUserThru      =   ulUserThru;                                         % ���У�ÿ���û�throughput
end


%% ȷ���µ������Ƿ�����CCA׼��
function oldlinks       =       check_link(oldlinks, newlink, pathlossdb, chpwrdb, nodes_tt)
% oldlinks              �Ѿ�ȷ��active������
% newlink               ��ȷ������
% pathlossdb            �ŵ�˥������
% chpwrdb               �ŵ�ϵ������
% nodes_tt              �����豸�б�

if isempty(oldlinks)                                                        % ���֮ǰ��Ƶ����û���κ����ӣ����µ�����һ�����Ա����롣
    linkid = 1;
    oldlinks(linkid).txid = newlink.txid;
    oldlinks(linkid).rxid = newlink.rxid;
    oldlinks(linkid).uldl = newlink.uldl;                                   % �˳�
else
    
    % ȷ�Ϸ��������ÿ����ȷ�����ӵķ�������������������ӷ�������Ľ��չ��ʡ�����ܽ��չ��ʳ���CCA���ޣ���������Ӳ��ɽ��롣
    % ����ܽ��չ��ʵ���CCA���ޣ���������ӿ��Խ��롣
    
    NumLinks = length(oldlinks);                                            % ��ȷ��������
    rxttl = -inf;                                                           % �ܽ��չ���
    for i=1:NumLinks
        txid = oldlinks(i).txid;                                            % ��ȷ�����ӷ�������豸��
        rxid = newlink.txid;                                                % �����ӷ�������豸�ţ�ע��˴��������ӽ��ջ���
        txpLevel(i) = nodes_tt(txid).txpLevel;                              % ���书��
        totalloss(i)  = pathlossdb(txid, rxid) +...                         % ��˥�����ŵ�˥��+�ŵ�ϵ����
            10*log10(sum(10.^(chpwrdb(:,txid,rxid)/10)));
        rxpwr(i) = txpLevel(i) - totalloss(i);                              % �ˣ����ӷ���������׵Ľ��չ���
        rxttl    = 10*log10(10^(rxttl/10) + 10^(rxpwr(i)/10));              % �ܽ��չ���
    end
    
    if rxttl < nodes_tt(rxid).ccaLevel                                      % ���Խ���;����
        oldlinks(NumLinks+1).txid = newlink.txid;
        oldlinks(NumLinks+1).rxid = newlink.rxid;
        oldlinks(NumLinks+1).uldl = newlink.uldl;
    else                                                                    % ���ɽ��룻�������
    end
end
end


%% ���������豸�ڵ㣬�����������ڵ�֮����ŵ�˥�����ŵ�ϵ��
function [PathLoss_dB, Shadowing_dB, chpwrdb] = calcPL(node1, node2, nets)

floor1              =   node1.floorno;
floor2              =   node2.floorno;
row1                =   node1.rowno;
row2                =   node2.rowno;
cell1               =   node1.cellno;
cell2               =   node2.cellno;
floors              =   sort([floor1 floor2]);
rows                =   sort([row1 row2]);
cells               =   sort([cell1 cell2]);
floordiff           =   abs(floors(2)-floors(1));                           % �������
rowdiff             =   abs(rows(2)-rows(1));                               % �������
celldiff            =   abs(cells(2)-cells(1));                             % �������

walldiff            =   rowdiff + celldiff;                                 % ���ǽ����Ŀ
floordiff           =   floordiff^((floordiff+2)/(floordiff+1)-0.46);
walldiff            =   walldiff^((walldiff+2)/(walldiff+1)-0.46);
combdiff            =   (floordiff+walldiff)^( (floordiff+walldiff+2)/(floordiff+walldiff+1) - 0.46);
penetrationloss     =   nets.floorLoss * floordiff + walldiff * nets.wallLoss;

distance            =   sqrt((node1.x-node2.x)^2+(node1.y-node2.y)^2+(node1.z-node2.z)^2);
chtype              =   'B';
CarrierFrequency_Hz =   5.2e9;

[PDP_dB, d_BP_m, K_factor_dB, ShadowFading_std_dB] = readChanProfile(chtype, distance);

if (distance > d_BP_m)
    PathLoss_dB     =   20*log10(4*pi*CarrierFrequency_Hz/3e8) + 20*log10(d_BP_m) + (35*log10(distance/d_BP_m));
else
    PathLoss_dB     =   20*log10(4*pi*CarrierFrequency_Hz/3e8) + 20*log10(distance);
end;
Shadowing_dB        =   randn * ShadowFading_std_dB;                        % �ŵ���Ӱ

PathLoss_dB         =   PathLoss_dB  + penetrationloss;                     % �ŵ�˥������͸ЧӦ

K                   =   10.^(K_factor_dB/10);
L                   =   size(PDP_dB,2);
PDP                 =   10.^(PDP_dB(1,:)/10);
PDPsum              =   sum(PDP);
PDP                 =   sqrt(PDP/PDPsum);
h                   =   (randn(1,L) + 1j*randn(1,L))/sqrt(2);
th                  =   sqrt(K./(K+1)) + sqrt(1./(K+1)) .* h .*PDP;         % ʱ����
fh                  =   fft(th, 64)/sqrt(64);
fh                  =   fh';
chpwrdb             =   10*log10(abs(fh).^2);                               % �ŵ�ϵ��������ֵƽ�� dB)
end


%% ��ȡ�ŵ������Լ��ŵ����Ͳ���
function [PDP_dB, d_BP_m, K_factor_dB, ShadowFading_std_dB] = readChanProfile(chtype, distance_Tx_Rx_m)

switch chtype
    
    case 'A'
        PDP_dB = [  0;0];                                                   % Average power [dB] and Relative delay (ns)
        d_BP_m = 5;
        if (distance_Tx_Rx_m < d_BP_m)
            K_factor_dB = [0,(-100).*ones(1, size(AoA_Rx_deg, 2)-1)];
            ShadowFading_std_dB = 3;
        else
            K_factor_dB = (-100).*ones(1, size(AoA_Rx_deg, 2));
            ShadowFading_std_dB = 4;
        end;
    case 'B'
        PDP_dB = [  0 -5.4287 -2.5162 -5.8905 -9.1603 -12.5105 -15.6126 -18.7147 -21.8168; ...
            0 10e-9   20e-9   30e-9   40e-9   50e-9    60e-9    70e-9    80e-9   ];
        d_BP_m = 5;
        if (distance_Tx_Rx_m < d_BP_m)
            K_factor_dB = [0,(-100).*ones(1, size(PDP_dB, 2)-1)];
            ShadowFading_std_dB = 3;
        else
            K_factor_dB = (-100).*ones(1, size(PDP_dB, 2));
            ShadowFading_std_dB = 4;
        end;
    case 'C'
        PDP_dB = [  0 -2.1715 -4.3429 -6.5144 -8.6859 -10.8574 -4.3899 -6.5614 -8.7329 -10.9043 -13.7147 -15.8862 -18.0577 -20.2291; ...
            0 10e-9   20e-9   30e-9   40e-9   50e-9    60e-9   70e-9   80e-9   90e-9    110e-9   140e-9   170e-9   200e-9];  % Relative delay (ns)
        d_BP_m = 5;
        if (distance_Tx_Rx_m < d_BP_m)
            K_factor_dB = [0,(-100).*ones(1, size(PDP_dB, 2)-1)];
            ShadowFading_std_dB = 3;
        else
            K_factor_dB = (-100).*ones(1, size(PDP_dB, 2));
            ShadowFading_std_dB = 5;
        end;
    case 'D'
        PDP_dB = [  0 -0.9  -1.7  -2.6  -3.5  -4.3  -5.2  -6.1  -6.9  -7.8  -4.7   -7.3   -9.9   -12.5  -13.7  -18    -22.4  -26.7; ...
            0 10e-9 20e-9 30e-9 40e-9 50e-9 60e-9 70e-9 80e-9 90e-9 110e-9 140e-9 170e-9 200e-9 240e-9 290e-9 340e-9 390e-9]; % Relative delay (ns)
        d_BP_m = 10;
        if (distance_Tx_Rx_m < d_BP_m)
            K_factor_dB = [3,(-100).*ones(1, size(PDP_dB, 2)-1)];
            ShadowFading_std_dB = 3;
        else
            K_factor_dB = (-100).*ones(1, size(PDP_dB, 2));
            ShadowFading_std_dB = 5;
        end;
    case 'E'
        PDP_dB = [  -2.5 -3.0  -3.5  -3.9  0     -1.3  -2.6   -3.9   -3.4   -5.6   -7.7   -9.9   -12.1  -14.3  -15.4  -18.4  -20.7  -24.6;  ...
            0    10e-9 20e-9 30e-9 50e-9 80e-9 110e-9 140e-9 180e-9 230e-9 280e-9 330e-9 380e-9 430e-9 490e-9 560e-9 640e-9 730e-9]; % Relative delay (ns)
        d_BP_m = 20;
        if (distance_Tx_Rx_m < d_BP_m)
            K_factor_dB = [6,(-100).*ones(1, size(PDP_dB, 2)-1)];
            ShadowFading_std_dB = 3;
        else
            K_factor_dB = (-100).*ones(1, size(PDP_dB, 2));
            ShadowFading_std_dB = 6;
        end;
    case 'F'
        PDP_dB = [  -3.3 -3.6  -3.9  -4.2  0     -0.9  -1.7   -2.6   -1.5   -3.0   -4.4   -5.9   -5.3   -7.9   -9.4   -13.2  -16.3  -21.2; ...
            0    10e-9 20e-9 30e-9 50e-9 80e-9 110e-9 140e-9 180e-9 230e-9 280e-9 330e-9 400e-9 490e-9 600e-9 730e-9 880e-9 1050e-9]; % Relative delay (ns)
        d_BP_m = 30;
        if (distance_Tx_Rx_m < d_BP_m)
            K_factor_dB = [6,(-100).*ones(1, size(PDP_dB, 2)-1)];
            ShadowFading_std_dB = 3;
        else
            K_factor_dB = (-100).*ones(1, size(PDP_dB, 2));
            ShadowFading_std_dB = 6;
        end;
end;
end



%% ���Ÿ���Ȳ�ѯ���Դﵽ��throughput
function thruputs = phy_abs(sinrdb, nets)

sinr            = 10.^(sinrdb/10);
thruput         = mean(real(log2(1+sinr)));
sinreff         = 2^thruput - 1;
sinreffdb       = 10*log10(sinreff);
switch nets.mcstable
    case 1
        sinrthr = [-inf 3.2 7.0 9.6 11.8 15.5 18.8 20.4 21.9 25.0 27.0];
        mcsrate = [0 6.5 13.0 19.5 26.0 39.0 52.0 58.5 65.0 78.0 86.7];
    case 2
        sinrthr = [-inf 3.2 7.0 9.6 11.8 15.5 18.8 20.4 21.9 25.0 27.0];
        mcsrate = [0 6.5 13.0 19.5 26.0 39.0 52.0 58.5 65.0 78.0 86.7];
end
x               = find((sinreffdb-sinrthr>0),1,'last');
thruputs        = mcsrate(x);
end


%% ע��

% AI: if uplink + dynamic cca; change cca level per drop
% AI: if uplink + dynamic txp; change txp level per drop
% AI: need to update the AP power for each event if static cca + dynamic txp + dnlink

