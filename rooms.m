% 每个房间长度等于宽度（可设置）。
% 每个房间一个AP，位于房间正中，位置固定。
% 每个房间四个用户（数目可设置），随机位于房间中不同位置。

classdef rooms
    
    properties
        roomid;             % 房间号
        x_start;            % X轴坐标起始值
        x_length;           % X轴坐标长度
        x_end;              % X轴坐标结束值
        x_middle;           % X轴坐标中间值
        y_start;
        y_length;
        y_end;
        y_middle;
        z_start;
        z_length;
        z_end;
        z_middle;
        numSTAs;            % 每个房间用户数
        numAPs;             % 每个房间AP数等于1
        floorno;            % 层号
        rowno;              % 行号
        cellno;             % 列号
        freq;               % 频点
    end
    
    methods
        
        function obj = rooms(roomid, floorno, rowno, cellno, nets)
            
            obj.x_length =      nets.roomSize;                                        
            obj.y_length =      nets.roomSize;
            obj.z_length =      nets.roomHeight;                                             
            obj.x_start  =      (cellno - 1) * obj.x_length;                   
            obj.y_start  =      (rowno - 1) * (obj.y_length + 0);              
            obj.z_start  =      (floorno - 1) * obj.z_length;                  
            obj.x_end    =      obj.x_start + nets.roomSize;
            obj.y_end    =      obj.y_start + nets.roomSize;
            obj.z_end    =      obj.z_start + nets.roomHeight;
            obj.x_middle =      mean([obj.x_start obj.x_end]);
            obj.y_middle =      mean([obj.y_start obj.y_end]);
            obj.z_middle =      mean([obj.z_start obj.z_end]);
            obj.roomid   =      roomid;
            obj.floorno  =      floorno;
            obj.rowno    =      rowno;
            obj.cellno   =      cellno;
            obj.freq     =      nets.freqIndex;
            
            if nets.show3D == 1
                a = [ obj.x_start obj.y_start obj.z_start];
                b = [ obj.x_end   obj.y_start obj.z_start];
                c = [ obj.x_start obj.y_end   obj.z_start];
                d = [ obj.x_start obj.y_start obj.z_end  ];
                e = [ obj.x_start obj.y_end   obj.z_end  ];
                f = [ obj.x_end   obj.y_start obj.z_end  ];
                g = [ obj.x_end   obj.y_end   obj.z_start];
                h = [ obj.x_end   obj.y_end   obj.z_end  ];
                p = [ a;b;f;h;g;c;a;d;e;h;f;d;e;c;g;b];
                switch rowno
                    case 1
                        plot3(p(:,1),p(:,2),p(:,3),'m','linewidth',2)
                    case 2
                        plot3(p(:,1),p(:,2),p(:,3),'b','linewidth',2)
                    case 3
                        plot3(p(:,1),p(:,2),p(:,3),'r','linewidth',2)
                    case 4
                        plot3(p(:,1),p(:,2),p(:,3),'k','linewidth',2)
                end
                axis equal
                hold on;
            end
        end
        
                    

        function ap = addAP(roomArray, roomid, nodeid, txpLevel, ccaLevel, freqindex, nets)
            % roomArray     所有房间列表
            % roomid        房间号
            % txpLevel      发射功率控制
            % ccaLevel      CCA参数
            % show3d        显示控制
            % oldsta        忽略
            % freqindex     频点
            % nets.nodesperAP    每个房间设备数（含AP)
            % nodeid        AP之nodeid
                        
            ap.x            = roomArray(roomid).x_middle;                            
            ap.y            = roomArray(roomid).y_middle;                            
            ap.z            = roomArray(roomid).z_start + 0.5 * roomArray(roomid).z_length;

            ap.floorno      = roomArray(roomid).floorno;                         
            ap.rowno        = roomArray(roomid).rowno;
            ap.cellno       = roomArray(roomid).cellno;
            ap.roomid       = roomid;
            ap.nodeid       = nodeid;
            ap.txpLevel     = txpLevel;
            ap.ccaLevel     = ccaLevel;
            ap.freq         = freqindex;
            ap.old          = 1;   
            if nets.show3D == 1
                plot3(ap.x,ap.y,ap.z,'k o');hold on;
            end
        end
        
        
        
        function sta = addSTA(roomArray, roomid, nodeid, txpLevel, ccaLevel, freqindex, nets, oldsta)
            % roomArray     房间列表
            % roomid        房间号
            % txpLevel      发射功率控制
            % ccaLevel      CCA参数
            % show3d        显示
            % oldsta        old STA or new STA
            % freqindex     频点
            % nets.nodesperAP    每个房间设备数（含AP)
            % nets.roomSize      房间大小
            % nodeid        STA之nodeid
            
            sta.x           = roomArray(roomid).x_start + rand * nets.roomSize;
            sta.y           = roomArray(roomid).y_start + rand * nets.roomSize;
            sta.z           = roomArray(roomid).z_start + rand * 2;
            sta.floorno     = roomArray(roomid).floorno;                      
            sta.rowno       = roomArray(roomid).rowno;
            sta.cellno      = roomArray(roomid).cellno;
            sta.roomid      = roomid;
            sta.nodeid      = nodeid;
            sta.txpLevel    = txpLevel;
            sta.ccaLevel    = ccaLevel;
            sta.freq        = freqindex;
            
            if nets.show3D == 1
                if oldsta == 1
                    plot3(sta.x,sta.y,sta.z,'k .');hold on;
                else
                    plot3(sta.x,sta.y,sta.z,'k .');hold on;
                end
            end
            if oldsta == 1
                sta.old     = 1;
            else
                sta.old     = 0;
            end
        end
        
    end
    
end
