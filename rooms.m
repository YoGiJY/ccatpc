% ÿ�����䳤�ȵ��ڿ�ȣ������ã���
% ÿ������һ��AP��λ�ڷ������У�λ�ù̶���
% ÿ�������ĸ��û�����Ŀ�����ã������λ�ڷ����в�ͬλ�á�

classdef rooms
    
    properties
        roomid;             % �����
        x_start;            % X��������ʼֵ
        x_length;           % X�����곤��
        x_end;              % X���������ֵ
        x_middle;           % X�������м�ֵ
        y_start;
        y_length;
        y_end;
        y_middle;
        z_start;
        z_length;
        z_end;
        z_middle;
        numSTAs;            % ÿ�������û���
        numAPs;             % ÿ������AP������1
        floorno;            % ���
        rowno;              % �к�
        cellno;             % �к�
        freq;               % Ƶ��
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
            % roomArray     ���з����б�
            % roomid        �����
            % txpLevel      ���书�ʿ���
            % ccaLevel      CCA����
            % show3d        ��ʾ����
            % oldsta        ����
            % freqindex     Ƶ��
            % nets.nodesperAP    ÿ�������豸������AP)
            % nodeid        AP֮nodeid
                        
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
            % roomArray     �����б�
            % roomid        �����
            % txpLevel      ���书�ʿ���
            % ccaLevel      CCA����
            % show3d        ��ʾ
            % oldsta        old STA or new STA
            % freqindex     Ƶ��
            % nets.nodesperAP    ÿ�������豸������AP)
            % nets.roomSize      �����С
            % nodeid        STA֮nodeid
            
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
