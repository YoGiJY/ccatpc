% CCA TPC 参数优化及方案仿真
% 1. 主要为上行网络设计
% 2. 用户分为两组，每组用户可具有不同的系统参数（功率控制，CCA等）
% Author:   Pengfei XIA
% Date:     2015.07.31

%% 主程序
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
%     ccaScheme, ...                                                          % CCA方案
%     ccaLevel, ...                                                           % CCA参数设置；如果是静态CCA，则为CCA参数(dBm)；如果是动态CCA，则设为 CCA margin (dB)。
%     txpScheme, ...                                                          % 发射功率方案
%     txpLevel ...                                                            % 发射功率参数；如果是静态TXP，则为TXP参数dBm；如果是动态TXP，则设为TXP margin (dB)。
%     )                                                                       % 频率复用因子；如果为1，所有房间（或小区）公用同一频点，因此不同房间之间互相干扰；
%                                                                             % 如果为3，所有房间公用三个不同的频点。采用不同频点的房间之间互不干扰。
rng(1);
%% 1. 参数设置

nets.frFactor                   =   frFactor;
nets.ccaScheme                  =   ccaScheme;
nets.ccaLevelOld                =   ccaLevelOld;
nets.ccaLevelNew                =   ccaLevelNew;
nets.txpScheme                  =   txpScheme;
nets.txpLevelOld                =   txpLevelOld;
nets.txpLevelNew                =   txpLevelNew;

nets.mcstable                   =   1;                                      % MCS参数设置
nets.fixAPTxpLevel              =   20;                                     % 20 dBm Tx power for all serving APs (by default); used for uplink transmissions
nets.fixCCALevel                =   -80;                                    % -80 dBm CCA level by default
nets.numDrops                   =   50;                                     % 场景数Number of drops
nets.numEvents                  =   20;                                     % 每场景下随机事件数
nets.roomSize                   =   10;                                     % 房间长度=宽度
nets.roomHeight                 =   3;                                      % 房间高度
nets.floorLoss                  =   17;                                     % all in dB
nets.wallLoss                   =   12;                                     % reference IEEE 802.11-14/0082  
nets.combLoss                   =   14.5;                                   % combined floor/wall loss

ccaLevelAP                      =   nets.fixCCALevel;                       % not used for uplink
ccaLevelOldSTA                  =   nets.ccaLevelOld;                       % to be configured
ccaLevelNewSTA                  =   nets.ccaLevelNew;                       % to be configured

txpLevelAP                      =   nets.fixAPTxpLevel;                     % AP Txp 参数用来确定 STA 的动态 CCA 参数
txpLevelOldSTA                  =   nets.txpLevelOld;                       % to be configured
txpLevelNewSTA                  =   nets.txpLevelNew;                       % to be configured

uldlProb            =   1;



%% 2. 网络设置；每个房间一个AP； 每个房间四个用户（数目可设置)；2 old STA and 2 new STA

show3D                          =   0;                                      % 显示 1；disabled by default
numFloors                       =   1;                                      % number of floors for the entire network
numRows                         =   5;                                      % number of rows
numCells                        =   5;                                      % number of cells per row
numOldSTAperAP                  =   2;                                      % number of legacy/old stas per ap/room
numNewSTAperAP                  =   2;                                      % number of new stas per ap/room
numRooms                        =   numFloors * numRows * numCells;         % 总房间数 number of ttl rooms in the building network
numAP                           =   numRooms;                               % 每个房间一个AP
numSTAsperAP                    =   numOldSTAperAP + numNewSTAperAP;        % 每房间用户数 number of stas in total per room/ap
nodesperAP                      =   numSTAsperAP + 1;                       % 每房间设备数（用户数+1 AP) number of nodes (stas + 1 ap) per room/ap
numSTAs                         =   numSTAsperAP * numAP;                   % 整个网络用户数 （STA only）number of stas in the network
numOldSTAs                      =   numOldSTAperAP * numAP;                 % 整个网络旧用户数
numNewSTAs                      =   numNewSTAperAP * numAP;                 % 整个网络新用户数
numNodes                        =   numAP + numSTAs;                        % 整个网络设备数 （STA +　AP)number of nodes in the network

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
nets.APIndex                    =   1:nets.nodesperAP:nets.numNodes;               %AP的设备编号：1,6,11,16.......
nets.STAIndex                   =   setdiff(nets.nodeIndex, nets.APIndex);         %所有用户的设备编号：2,3,4,5，7,8,9,10.....
nets.oldSTAIndex                =   sort([2:nets.nodesperAP:nets.numNodes, 3:nets.nodesperAP:nets.numNodes]);%旧用户的设备编号：2,3,7,8,....
nets.newSTAIndex                =   sort([4:nets.nodesperAP:nets.numNodes, 5:nets.nodesperAP:nets.numNodes]);%新用户的设备编号：4,5,9,10....
nets.uldlProb                   =   uldlProb;

%% 3. 房间设置
roomID = 0;
for x=1:1:numFloors
    for y=1:numRows
        for z=1:numCells
            roomID              = roomID+1;                                 % 房间号
            roomArray(roomID)   = rooms(roomID,x,y,z,nets);                 % 在第X层第Y行第Z列加一个房间
        end;
    end;
end

%% 4. 场景循环；每个场景内，用户的位置（以及信道衰减、信道阴影等）保持不变。不同场景之间，用户的位置（以及信道衰减、信道阴影等）随机变化。
for xDrops = 1:nets.numDrops
    
    freqArray                   =   randi([1 frFactor],1,numRooms);         % 给每个房间随机分配一个频点
    
    nodeID   = 0;
    
    for roomID=1:numRooms                                                   % 4.1 对每个房间进行设备安装
        
        nodeID                  =   nodeID+1;                               % nodeID    当前设备（AP或STA)之nodeid
        APID                    =   nodeID;                                 % APID      AP之nodeid
        % AP安装：房间号，设备号，发射功率，CCA参数，频点，nets系统参数
        nodes(nodeID)    =   roomArray.addAP(roomID, nodeID, txpLevelAP, ccaLevelAP,freqArray(roomID), nets); %#ok<*AGROW>
        
        % 用户安装：old STA for this loop and new STA for the next loop
        for j=1:nets.numOldSTAperAP
            
            nodeID       =   nodeID+1;                                      % 当前用户设备号nodeID，当前用户的AP之设备号APID
            
            % 房间号，设备号，发射功率，CCA，频点，nets，old STA
            nodes(nodeID)=   roomArray.addSTA(roomID,nodeID,txpLevelOldSTA, ccaLevelOldSTA, freqArray(roomID), nets, 1); %#ok<AGROW> 1:旧用户
            
            ccaLevel     =      nets.ccaLevelOld;
            txpLevel     =      nets.txpLevelOld;
            if ccaScheme == 1                                                   % 如果动态CCA且上行，需要调整每个用户的CCA参数。
                [pathLoss, ~, dist] = calcPL(nodes(APID), nodes(nodeID),nets);  % 根据用户当前位置和AP的位置，计算信道衰减；信道阴影忽略
                ttcca = nets.fixAPTxpLevel - pathLoss - ccaLevel;               % 动态CCA = AP 发射功率 - 信道衰减 - CCA margin 参数
                if ttcca > -50                                                  % 单位dBm;
                    ttcca = -50;
                end
                nodes(nodeID).ccaLevel   = ttcca;
            end
            if txpScheme==1                                                     % 如果动态功率控制且上行，需调整发射功率
                [pathLoss, ~, dist] = calcPL(nodes(APID), nodes(nodeID),nets);  %#ok<*NASGU>
                targetrxpwr = 30 + (-96);                                       % 期望接收功率；期望SNR 设为 30 dB。(-96)= (-174)+73(20MHz)+5(noise figure)。
                targettxpwr = targetrxpwr + pathLoss + txpLevel;                % 期望发射功率；txpLevel is the margin here.
                if targettxpwr < 0                                              % 单位dBm
                    targettxpwr = 0;
                end
                nodes(nodeID).txpLevel =   targettxpwr;
            end
        end
        
        % 重复上面过程 for new STA
        for j=1:numNewSTAperAP
            nodeID       =   nodeID+1;
            %房间号，设备号，发射功率，CCA，频点，nets，new STA
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
                if targettxpwr < 0                                          % 单位dBm
                    targettxpwr = 0;
                end
                nodes(nodeID).txpLevel =   targettxpwr;
            end
        end
    end
    
    
    nodes_f1 = [];
    nodes_f2 = [];
    nodes_f3 = [];
    nodes_tt = [];            %列表1-125
    
    for nodeID=1:nets.numNodes
        nodes_tt        =   [nodes_tt nodes(nodeID)];                       % 所有频点上的网络以及设备列表
        switch nodes(nodeID).freq
            case 1
                nodes_f1 = [nodes_f1 nodes(nodeID)];                        % 第一频点上的网络以及设备列表
            case 2
                nodes_f2 = [nodes_f2 nodes(nodeID)];                        % 第二频点上的网络以及设备列表
            case 3
                nodes_f3 = [nodes_f3 nodes(nodeID)];                        % 第三频点上的网络以及设备列表
        end
    end
    
    %% 仿真
    switch frFactor
        case 1
            cout{1}{xDrops}                 = sim_one_freq(nodes_f1, nodes_tt, nets);
            for m=1:length(cout{1}{xDrops})
                dout{xDrops}(m).ulRoomThru  = cout{1}{xDrops}(m).ulRoomThru; %1：频点  xDrops：场景的索引    m：事件的索引index of event
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

%% 5. 数据采集
cstat   =   collect(dout, nets);

% save(fname, 'cstat');
% fprintf('%7d   ', txpLevel);
% fprintf('%7d   ', ccaLevel);
% fprintf('%14.0f ', cstat.ttl_thru_all);
% fprintf('%20.1f ', cstat.pctl5thru);
% fprintf('%20.0f ', cstat.num_link_all);


end

%% 单独一个频点仿真
function tout = sim_one_freq(nodes_f0, nodes_tt, nets)

% nodes_f0      本频点网络设备列表
% nodes_tt      所有网络设备列表
% nets          系统参数

if isempty(nodes_f0) % 如果本频点没有设备，直接清零退出
    for xEvent = 1:nets.numEvents
        tout(xEvent).ulRoomThru     =   zeros(1, nets.numRooms);
        tout(xEvent).ulUserThru     =   zeros(1, nets.numNodes);
    end
else
    
    numRoomsTtl         =   nets.rows * nets.cells * nets.floors;           % 总共房间数（此频点以及其他频点）
    numRoomsThisFreq    =   length(nodes_f0)/nets.nodesperAP;               % 此频点房间数
    
    numNodesTtl         =   numRoomsTtl * nets.nodesperAP;                  % 总共设备数
    numNodesThisFreq    =   length(nodes_f0);                               % 此频点设备数
    
    numStasTtl          =   numRoomsTtl * (nets.nodesperAP - 1);            % 总共用户数
    numStasThisFreq     =   numRoomsThisFreq * (nets.nodesperAP - 1);       % 此频点用户数
    
    roomIdThisFreq      =   [];
    nodeIdThisFreq      =   [];
    
    for i = 1:length(nodes_f0)
        roomIdThisFreq  =   [roomIdThisFreq, nodes_f0(i).roomid];
        nodeIdThisFreq  =   [nodeIdThisFreq, nodes_f0(i).nodeid];           % 此频点上的设备号列表
    end
        roomIdThisFreq      =   unique(roomIdThisFreq);                     % 此频点上的房间号列表，为何会出现相同的roomId in this Freq
    
    
    % 对此场景下，由于用户位置已固定，AP位置已固定，信道衰减因此确定。信道阴影也假设为确定并作为信道衰减的一部分。
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
    
    %roomThru        =   zeros(nets.numEvents, numRoomsTtl);                 % 每个房间throughput列表
    userThru        =   zeros(nets.numEvents, numStasTtl);                  % 每个用户throughput列表
    
    % 事件循环；不同事件中，不同的房间中的不同用户得到不同的throughput；
    for xEvent = 1:nets.numEvents
        
        oldlinks        =   [];                                             % 已确认连接（满足CCA准则）
        newlink         =   [];                                             % 待确认连接（根据CCA准则进行确认）
        pendingset      =   roomIdThisFreq;                                 % 本频点上待确认房间列表
        pendingaps      =   length(pendingset);                             % 本频点上待确认房间数
        
        while ~isempty(pendingset)
            
            ftt         =   randi(pendingaps, 1, 1);                        % 从待确认房间中随机选取
            roomx       =   pendingset(ftt);                                % 被选中房间的全局房间号(所有频点)
            
            roomap      =   (roomx-1) * nets.nodesperAP + 1;                % 被选中房间AP之设备号
            roomsta     =   roomap + randi(nets.nodesperAP-1,1,1);          % 在被选中房间中随机选取一个用户之设备号
            
            pendingset  =   pendingset([1:ftt-1 ftt+1:end]);                % 更新 把当前房间从待确认房间中删除
            pendingaps  =   length(pendingset);                             % 更新本频点上待确认房间数
            
            % 上行
            txNodeID        =   roomsta;                                   % 发射机设备号
            rxNodeID        =   roomap;                                    % 接收机设备号
            uldl            =   1;
            newlink.txid        =   txNodeID;                               % 新连接发射机设备号
            newlink.rxid        =   rxNodeID;                               % 新连接接收机设备号
            newlink.uldl        =   uldl;
            oldlinks   =   check_link(oldlinks, newlink, pathlossdb, chpwrdb, nodes_tt);        % 确认该连接是否满足CCA准则    左侧为已经确认成功的新links
            
        end
        
        all_active_links        =   oldlinks;                               % 本场景本事件下，所有active的连接。
        tout(xEvent) = runbss(all_active_links, pathlossdb, chpwrdb, nodes_tt, nets);
        
    end
    
end
end


%% 采集数据
function cstat = collect(dout, nets)

tmp0            =   zeros(nets.numDrops, nets.numEvents, nets.numRooms);
tmp1            =   zeros(nets.numDrops, nets.numEvents);
for xDrops = 1:length(dout)
    for xEvent = 1:length(dout{1})
        tmp0(xDrops, xEvent, :)     =   dout{xDrops}(xEvent).ulRoomThru;
        tmp1(xDrops, xEvent)        =   length(find(dout{xDrops}(xEvent).ulRoomThru));
    end
end
cstat.ulRoomThru                    =   squeeze(mean(mean(tmp0,1),2))';     % 每个房间throughput列表
cstat.ulRoomActv                    =   mean(mean(tmp1));                   % Active的房间数
cstat.ulRoomMean                    =   mean(cstat.ulRoomThru);             % 每个房间平均throughput

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
cstat.ulUserThru                    =   squeeze(mean(mean(tmp00,1),2))';    % 每个用户throughput列表
cstat.ulOldUserThru                 =   squeeze(mean(mean(tmp10,1),2))';    % 每个旧用户throughput列表
cstat.ulNewUserThru                 =   squeeze(mean(mean(tmp20,1),2))';    % 每个新用户throughput列表

cstat.ulUserActv                    =   mean(mean(tmp01));                  % Active的用户数
cstat.ulOldUserActv                 =   mean(mean(tmp11));                  % Active的旧用户数
cstat.ulNewUserActv                 =   mean(mean(tmp21));                  % Active的新用户数

cstat.ulUserMean                    =   mean(cstat.ulUserThru);             % 每个用户平均throughput
cstat.ulOldUserMean                 =   mean(cstat.ulOldUserThru);          % 每个旧用户平均throughput
cstat.ulNewUserMean                 =   mean(cstat.ulNewUserThru);          % 每个新用户平均throughput

end

%% 仿真当前网络的throughput
function out = runbss(links, pathlossdb, chpwrdb, nodes_tt, nets)

% links         所有active连接
% pathlossdb    信道衰减矩阵
% chpwrdb       信道系数矩阵
% nodes_tt      所有设备节点列表
% nets          系统参数

numRooms        =   nets.floors * nets.rows * nets.cells;

ulRoomThru      =   zeros(1, numRooms);                                     % 上行每个房间throughput

ulUserThru      =   zeros(1, numRooms * (nets.numSTAsperAP+1));             % 上行每个用户throughput

numlinks        =   length(links);

if numlinks     == 1
    txid        = links(1).txid;
    rxid        = links(1).rxid;
    signal_pwr  = chpwrdb(:,txid, rxid) - pathlossdb(txid,rxid) + nodes_tt(txid).txpLevel;%接受到信号的强度
    
    interf_pwr  = -96;                                                      % -174+73(20MHz)+5(noise figure)接收机的噪声功率
    sinrdb      = signal_pwr - interf_pwr;                                  %接收机的信干噪比SINR
    thruputs    = phy_abs(sinrdb, nets);                                    % in units of Mbps
    % 上行
    staid   = txid;
    apid    = rxid;
    
    roomid      = (apid-1)/(nets.numSTAsperAP+1)+1;                         % 从apid获取roomid
    
    ulRoomThru(roomid)          =   thruputs;
    ulUserThru(staid)           =   thruputs;
else
    for i=1:numlinks
        rxid = links(i).rxid;
        nilink  = 0;                                                        % 干扰连接数
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
        % 上行
        staid = links(i).txid;
        apid  = links(i).rxid;
        
        roomid = (apid-1)/(nets.numSTAsperAP+1)+1;
        % 上行
        ulRoomThru(roomid)          =   thruputs(i);
        ulUserThru(staid)           =   thruputs(i);
        
    end
end

out.ulRoomThru      =   ulRoomThru;                                         % 上行，每个房间throughput
out.ulUserThru      =   ulUserThru;                                         % 上行，每个用户throughput
end


%% 确认新的连接是否满足CCA准则
function oldlinks       =       check_link(oldlinks, newlink, pathlossdb, chpwrdb, nodes_tt)
% oldlinks              已经确认active的连接
% newlink               待确认连接
% pathlossdb            信道衰减矩阵
% chpwrdb               信道系数矩阵
% nodes_tt              所有设备列表

if isempty(oldlinks)                                                        % 如果之前此频点上没有任何连接，则新的连接一定可以被加入。
    linkid = 1;
    oldlinks(linkid).txid = newlink.txid;
    oldlinks(linkid).rxid = newlink.rxid;
    oldlinks(linkid).uldl = newlink.uldl;                                   % 退出
else
    
    % 确认方法：针对每个已确认连接的发射机，计算其在新连接发射机处的接收功率。如果总接收功率超过CCA门限，则此新连接不可接入。
    % 如果总接收功率低于CCA门限，则此新连接可以接入。
    
    NumLinks = length(oldlinks);                                            % 已确认连接数
    rxttl = -inf;                                                           % 总接收功率
    for i=1:NumLinks
        txid = oldlinks(i).txid;                                            % 已确认连接发射机的设备号
        rxid = newlink.txid;                                                % 新连接发射机的设备号（注意此处非新连接接收机）
        txpLevel(i) = nodes_tt(txid).txpLevel;                              % 发射功率
        totalloss(i)  = pathlossdb(txid, rxid) +...                         % 总衰减（信道衰减+信道系数）
            10*log10(sum(10.^(chpwrdb(:,txid,rxid)/10)));
        rxpwr(i) = txpLevel(i) - totalloss(i);                              % 此（连接发射机）贡献的接收功率
        rxttl    = 10*log10(10^(rxttl/10) + 10^(rxpwr(i)/10));              % 总接收功率
    end
    
    if rxttl < nodes_tt(rxid).ccaLevel                                      % 可以接入;更新
        oldlinks(NumLinks+1).txid = newlink.txid;
        oldlinks(NumLinks+1).rxid = newlink.rxid;
        oldlinks(NumLinks+1).uldl = newlink.uldl;
    else                                                                    % 不可接入；不需更新
    end
end
end


%% 给定两个设备节点，计算这两个节点之间的信道衰减和信道系数
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
floordiff           =   abs(floors(2)-floors(1));                           % 层数差别
rowdiff             =   abs(rows(2)-rows(1));                               % 行数差别
celldiff            =   abs(cells(2)-cells(1));                             % 列数差别

walldiff            =   rowdiff + celldiff;                                 % 间隔墙的数目
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
Shadowing_dB        =   randn * ShadowFading_std_dB;                        % 信道阴影

PathLoss_dB         =   PathLoss_dB  + penetrationloss;                     % 信道衰减含穿透效应

K                   =   10.^(K_factor_dB/10);
L                   =   size(PDP_dB,2);
PDP                 =   10.^(PDP_dB(1,:)/10);
PDPsum              =   sum(PDP);
PDP                 =   sqrt(PDP/PDPsum);
h                   =   (randn(1,L) + 1j*randn(1,L))/sqrt(2);
th                  =   sqrt(K./(K+1)) + sqrt(1./(K+1)) .* h .*PDP;         % 时间域
fh                  =   fft(th, 64)/sqrt(64);
fh                  =   fh';
chpwrdb             =   10*log10(abs(fh).^2);                               % 信道系数（绝对值平方 dB)
end


%% 读取信道类型以及信道类型参数
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



%% 从信干噪比查询可以达到的throughput
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


%% 注释

% AI: if uplink + dynamic cca; change cca level per drop
% AI: if uplink + dynamic txp; change txp level per drop
% AI: need to update the AP power for each event if static cca + dynamic txp + dnlink

