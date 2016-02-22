function [] = podem()
    clc;
    clear all;
    global FL
    global FV
    global l
    global netlist
    global no_devices
    global ins
    global outs
    global node_map
    global no_nodes
	global node_values
    global device_map
    global stack_G
    global stack_V
    
    FaultValue= 1;           % Change value to 0/1 for s-a-1/s-a-0 
    FaultLocation='n6';      % Type in various fault location values
    main_podem(FaultLocation,int8(FaultValue));
    disp(' ');
    str1=['Fault Location', ' ', FaultLocation];
    disp(str1);
    str1 =  ['Fault Value', ' ', num2str(FaultValue)];
    disp(str1);

   
end

function [] = main_podem(nG_C,nV)
    
    global FL
    global FV
    global l
    global netlist
    global no_devices
    global ins
    global outs
    global node_map
    global no_nodes
	global node_values
    global device_map
    global stack_G
    global stack_V
    
    f = fopen ('netlist.txt', 'r');
    l = textscan(f,'%s','delimiter','\n','whitespace','');
    NCV = [1,0,1,0,1,-5,-5,1]; % matrix for non controlling value for each gate type
    l=l{1};
    netlist =cell(0);
    ins =cell(0);
    outs =cell(0);
    node_map=cell(0);
    read_netlist();
    convert_netlist();
	node_values = zeros(no_nodes,1,'int8');
    device_map = cell(0);
    create_devicemap()
    values_initial()
    match_in=0;
    for i =1:no_nodes             % Check existence of FaultLocation in netlist
        if(strcmpi(nG_C, node_map{i,1}))
            nG = i;
            FL = i;
            match_in=1;
            break;
        
        else
            match_in=0;
        end
    end
   
    if(match_in==0)
        disp('Error: Undefined Fault Location. Input another location');
        return 
    end
    stack_G=java.util.Stack();       % Defining 2 stack for storing values of backtrace each time its called
    stack_V=java.util.Stack();

    [PI, PI_V] = objective(nG, nV);    
    imply(PI, PI_V);
    
     while(node_values(FL) == -5)
        if(size(stack_G)>0)
            nG = stack_G.pop();     % Keeps poping latest value from stack till the fault node value is unassigned
            nV = stack_V.pop();
            
        else
            disp('Error')
            return
        end
        [PI, PI_V] = objective(nG, nV);
        imply(PI, PI_V);
     end
    
    
    index_arr =  cnctd_devices(FL);           % Checks if fault at primary output i.e no connected devices to it
    [size_index_arr,~] = size(index_arr);     % displays if primary output is fault location
    if(size_index_arr==0)
        %fault at primary output
        if (FV==node_values(FL) )
            disp('Fault is at primary output')
            
        end
    end
    
    for j =1:size_index_arr                  % Checking for fault propogation 
        count = 0 ;                          % Checks all gates where fault location is connected. 
        nc_value = 1; 
        [~,size_t] = size(netlist{index_arr{j,1},1});
        connected_in = netlist{index_arr{j,1},1}(4:size_t);
        [~, size_connected_in] = size(connected_in);
        for p =1:size_connected_in
            if(connected_in{1,p} ~= FL)                     % For other unassigned inputs at these gates, set this to non controlling value by calling objective
                if(node_values(connected_in{1,p}) == -5)            
                    [PI, PI_V] = objective(connected_in{1,p}, nc_value);
                    imply(PI, PI_V)
                    if(node_values(connected_in{1,p}) == nc_value)
                        count = count + 1;
                    end
                elseif(node_values(connected_in{1,p}) == nc_value)
                    count = count +1;
                elseif(node_values(connected_in{1,p}) == (1-nc_value))
                    disp('Test not detected because not all of the input to primary output gate were non controlling')
                    break
                end
            end
        end
        [~, size_connected_in] = size(connected_in);      % if for rest of the inputs, ncv can be set, fault can be propogated. so disp- fault is detectable
        if(count == (size_connected_in-1))
            disp('Fault is detectable')
            disp (' ')
            disp('Primary Input values are:')             % if fault is detectable, display primary inputs by running through ins array, which contains all PI

            for i=1:size((ins),1)
                if(node_values(ins{i,1})==-5)
                    str1 = ['Input',' ',num2str(node_map{ins{i,1},1}),' ','x'];
                    disp(str1);
                else
                    str1 = ['Input',' ',node_map{ins{i,1},1},' ',num2str(node_values(ins{i,1}))];
                    disp (str1);

                end
            end
        else
            disp('Fault is not detectable')
        end
    end
end

function []= read_netlist()
    global l
    global netlist
    global ins
    global outs
    global node_map
    i_netlist=1;
    device_id=1;
    [y_l,~] = size(l);
    for i =1:y_l
        temp=l{i};
        
        temp_str='';
        i_tmpstr=1;
        device=cell(0);
        i_dev = 1;
        if(strcmp(temp(1),'\n'))
            continue;
        else                           % storing device ID for each gate
            device{1,i_dev}=(device_id);
            i_dev = i_dev +1;
			device_id=device_id+1;
        end

        [~,x]=size(temp);
        for j =1:x
            if (j==size(temp)-1)
                if (~strcmp(temp(j) ,' ' )|| strcmp(temp(j) ,'\n'))
                    if(temp_str)
                        device{1,i_dev}=temp_str;
                        i_dev=i_dev+1;
                        temp_str='';
                        i_tmpstr =1;
                    end
                else
                    if(temp_str)
                        device{1,i_dev}=temp_str;
                        i_dev=i_dev+1;
                        k=k+1;
                        temp_str='';
					end
				end
            elseif (~strcmp(temp(j),' '))
                
                temp_str (i_tmpstr)= temp(1,j);
                i_tmpstr = i_tmpstr +1;
            else
                if(size(temp_str)~=0)
                    device{1,i_dev}=temp_str;
					i_dev=i_dev+1;
                    temp_str='';
                    i_tmpstr =1;
				end
			end
        
        end
        
        
        netlist{i_netlist,1}=device;
        i_netlist = i_netlist +1;
    end
end

function [temp_return] = convert_netlist()
    global no_devices
    global netlist
    global ins
    global outs
    global node_map
    global no_nodes
    temp=1;
    i_ins=1;
    i_outs=1;
    i_node=1;
    node_old =cell(0);
    i_node_old =1;
    node_new =cell(0);
    i_node_new =1;
    [no_devices,~] = size(netlist);                % checking gate and assigning a gate type as tabulated in document
    for i = 1:	no_devices 
       
        if (strncmpi(netlist{i,1}{2},'and2_',5))
            netlist{i,1}{2} = 3;
        elseif (strncmpi(netlist{i,1}{2},'not',2))
            netlist{i,1}{2} = 1;
        elseif (strncmpi(netlist{i,1}{2},'nand4_',6))
            netlist{i,1}{2} = 8;
        elseif (strncmpi(netlist{i,1}{2},'nand2_',6))
            netlist{i,1}{2} = 5;
		end
		[~,ins_size] =  size(netlist{i,1});
        for j =3:ins_size 
            if (strncmpi(netlist{i,1}{j},'in',2))
                match=0;
                for k =1:size(node_old)
                    if (strcmpi(netlist{i,1}{j},node_old{k,1}));
                        match=1;
                        break
                    end
                end
                
                if (match)
                    netlist{i,1}{j}=node_new{k,1};
                else                   
                    ins{i_ins,1}=temp;  % ins array storing all the primary input
                    node_old{i_node_old,1}=netlist{i,1}{j};
                    node_new{i_node_new,1}=temp;
                    i_ins = i_ins +1;
                    i_node_old = i_node_old +1;
                    i_node_new = i_node_new +1;
                    
                    netlist{i,1}{j}=temp;
                    temp=temp+1;
				end
            elseif (strncmpi(netlist{i,1}{j},'out',3))
                match=0;
                for k =1:size(node_old)
                    if (strcmpi(netlist{i,1}{j},node_old{k,1}));
                        match=1;
                        break
                    end
                end
                if (match)        
                    netlist{i,1}{j}=node_new{k,1};
                else                    
                    outs{i_outs,1}=temp; % outs array storing all the primary outputs
                    node_old{i_node_old,1}=netlist{i,1}{j};
                    node_new{i_node_new,1}=temp;
                    i_outs = i_outs +1;
                    i_node_old = i_node_old +1;
                    i_node_new = i_node_new +1;
                    netlist{i,1}{j}=temp;
                    temp=temp+1;
				end
            else
                match=0;
                for k =1:size(node_old)
                    if (strcmpi(netlist{i,1}{j},node_old{k,1}));
                        match=1;
                        break
                    end
                end
                if (match)        
                    netlist{i,1}{j}=node_new{k,1};
                else
                    node_old{i_node_old,1}=netlist{i,1}{j};
                    node_new{i_node_new,1}=temp;
                    i_node_old = i_node_old +1;
                    i_node_new = i_node_new +1;
                    netlist{i,1}{j}=temp;
                    temp=temp+1;
				end
			end
        end
    end                  
    
    node_map = node_old;  % node_map stores device_ID and corresponding nodes 
  	
    no_nodes = temp -1;   % no_nodes is the number of nodes in netlist
end

function []=create_devicemap()     % 
    global device_map
    global no_devices 
    global netlist
    for i=1:no_devices
        device_map{i,1}= (cnctd_devices (netlist{i,1}{3}));   % device_map stores the gates every node is connected to 
    end
end

function [device_index]= cnctd_devices (c_Node)   % cnctd_devices is a function which outputs device_ID s to which input node "c_Node" is connected
    global no_devices
    global netlist
    global node_map
    device_index = cell(0);
    i_device_index = 1;
    for i = 1: no_devices 
        [~, size1] = size(netlist{i,1} );
        for j =4 : size1
            if(c_Node == netlist{i,1}{j})
                device_index{i_device_index,1}=i;
                i_device_index = i_device_index +1;
            end
        end
    end
end

function [] = values_initial()      % node_values array stores values of each node                  
	global node_values              % function initializes node_values array to -5 (unassigned)
	global no_nodes
	for i=1:no_nodes
		node_values(i)=-5;
	end
end

function[o,i1,i2,i3,i4] = nand_4input(o,i1,i2,i3,i4,g)
    if(g==0)                      % g=0 for backtracing
        if(o==-5)                 % for given output value, evaluates input values
            i1 = -5;
            i2 = -5;
            i3 = -5;
            i4 = -5;
        elseif(o == 0)
            i1 = 1;
            i2 = 1;
            i3 = 1;
            i4 = 1;
        elseif (o==1)
            i1 = 0;
        end
    elseif(g==1)                 % g=1 for implying
        o1 = (i1*i2*i3*i4) ;     % given the value of inputs, output is evaluated
        if(abs(o1)>1)
            o = -5;
        else
            o = (not(o1));
        end
    end
end

function[o,i1,i2] = nand_out(o,i1,i2,g)
    if (g==0)
        if(o == -5)
            i1= i1 ;
            i2= i2;
            o=o;
        elseif(o == 0)
            i1 = 1; i2 = 1;
        elseif(o == 1)
            if (i1 == 1)
                i2= 0;
            elseif(i2 == 1)
                i1= 0;
            elseif (i1== 0)
                i2= i2;
            elseif (i2== 0)
                i1= i1;
            else
                i1=0;
                i2=0;
            end
        end
    elseif(g==1)
        if(i1 == -5 && i2 == -5)
            o =-5;
        else
            o1 = (i1*i2) ;
            if(abs(o1)>1)
                o = -5;
            else
                o = (not(o1));
            end
        end
    end
end

function[o,i1]= not_out(o,i1,g)
    if(g==0)
        if(o==-5)
            i1 = -5;
        else
            i1 = (not(o));
        end
    else
        if(i1==-5)
            o = -5;
        else
            o = (not(i1));
        end
    end
end

function[o,i1,i2] = and_out(o,i1,i2,g)
    if (g==0)
        if(o == -5)
            i1= i1 ;
            i2= i2;
            o=o;
        elseif(o == 1)
            i1 = 1; i2 = 1;
        elseif(o == 0)
            if (i1 == 1)
                i2= 0;
            elseif(i2 == 1)
                i1= 0;
            elseif(i1== 0)
                i2= i2;
            elseif(i2== 0)
                i1= i1;
            else
                i1=0;
                i2=0;
            end
        end
    else
        if(i1 == -5 && i2 == -5)
            o =-5;
        else
            o1 = (i1*i2) ;
            if(abs(o1)>1)
                o = -5;
            else
                o = o1;
            end
        end
    end
end

function [nG, nV]=objective(nG, nV)
    global ins
    global stack_G
    global stack_V
    
    global netlist
    global no_devices 
    isPI=0;
    while(nV ~=-5 && isPI == 0)
        
        [ins_size,~] = size(ins);
        for i = 1:ins_size
            if (nG == ins{i,1})
                isPI=1;               % if input in backtrace(nG) is a PI, then flag isPI is asserted
                break
            end
        end
        if (isPI==1)                  % chekcs for isPI
            return;
        else
            backtrace(nG,nV)
            
            if(size(stack_G)>0)
                nG=  stack_G.pop();
                nV=  stack_V.pop();
               
            end
        end
    end
end
        
function []= backtrace(nG, nV)
    global no_devices
    global netlist
    global stack_G
    global stack_V
    fprintf('New Objective set for backtracing is (%d,%d) \n',nG,nV)
    for i = 1: no_devices
        if ( netlist{i,1}{3} == nG)
            row_values = update_rowvalues(i);
            row_v = Type(nV,row_values);
            [~,row_v_size] = size(row_v);
            for j=1:(row_v_size-3)

                g = (netlist{i,1}{3+j}) ;
                v = row_v(3+j);
                
                stack_G.push(g);            % each time fills in the stack with backtraced values
                stack_V.push(v);
            end
        end
    end
end

function [rowvector]= update_rowvalues(device_id)  % creates a row for given "device_id" in the format of [device_ID, gate_type, output node value, input node values]
    global netlist
    global node_values
    rowvector=zeros(0,'int32');

    rowvector(1)=device_id;
    rowvector(2)=(netlist{device_id,1}{2});
    [~,size_t] = size(netlist{device_id,1});
    for i =3:size_t 
        rowvector(i)=(node_values(netlist{device_id,1}{i}));
    end
end

function [row_update] = Type (V,row)
    g=0;                 % used in backtracing
    row_update = (row);

    if(V == -5)   
        row_update = (row);
        print('Value of V is not allowed')
    else                            % checks for gate_type and calls corresponding gate function
        if((row(2))==1)
            [row_update(3),row_update(4)] =  not_out(V,row(4),g);
        elseif((row(2))==3)
            [row_update(3),row_update(4),row_update(5)] =  and_out( V, row(4), row(5), g);
        elseif((row(2))==5)
            [row_update(3),row_update(4),row_update(5)] =  nand_out( V, row(4), row(5), g); 
        elseif((row(2))==8)
            [row_update(3),row_update(4),row_update(5),row_update(6),row_update(7)] =  nand_4input( V, row(4), row(5),row(6),row(7),g);
        end
    end
end

function imply(PI, PI_Value)
    global netlist
    global outs
    global node_values
    global device_map
    count_OUT = zeros(0);
    i_count_OUT=1;
    flag=0;
    node_values(PI) = PI_Value;
    device_connected_next = cell(0);
    [size_outs, ~] = size(outs);
    while (size(count_OUT) ~= size_outs)   % Runs till all primary outputs are implied 
      
          if(flag==0)
            flag = 1;
            
            device_connected =cnctd_devices(PI);  % device_connected is the nodes where PI will be the input
            [size_device_connected, ~] = size(device_connected);
            for i=1:size_device_connected
                imply_device(device_connected{i,1})
            end
        
        else
            flag = flag +1;
            device_connected = device_connected_next;
            device_connected_next = cell(0);
            
            [size_device_connected, ~] = size(device_connected);
            for i=1:size_device_connected
                imply_device(device_connected{i,1})
            end
        end
            
           
        next_d = cell(0);
        
        [size_device_connected, ~] = size(device_connected);
        i_device_connected_next =1;
        for i=1:size_device_connected
                next_d = device_map{device_connected{i,1},1};
            
            % check if temp_d is empty
                [size_next_d,~] = size(next_d);
                if (size_next_d==0)
                    
                    match_out = 0;
                    
                    for i1 = 1: size(count_OUT)
                        if (count_OUT(i1) == device_connected{i,1})
                            match_out = True;
                            break
                        end
                    end
                    if (~match_out)
                        count_OUT(i_count_OUT)= (device_connected{i,1});
                        i_count_OUT = i_count_OUT +1;
                    end
                end
                [size_next_d,~] = size(next_d);
                if(size_next_d>0)
                        x = -1;
                        for j1=1:size_next_d
                            x = next_d{j1,1};
                            match_12 = 0;
                             [size_device_connected_next, ~] = size(device_connected_next);
                            for i2 = 1:size_device_connected_next                          
                                
                                if(x==device_connected_next{i2,1})
                                    match_12 = 1;
                                    break
                                end
                            end
                            if(~match_12)
                                    device_connected_next{i_device_connected_next,1}=(x);
                                    i_device_connected_next = i_device_connected_next +1;
                            end
                        end
                end
        end
    end
end

function []= imply_device(device_id)
    global netlist
    global node_values
    row_imply = update_rowvalues(device_id);
    row_update = type_imply(row_imply);
    node_values (netlist{device_id,1}{3}) = row_update(3);
end

function [row_update] = type_imply(row_imply)
    g=1;                     % used in inply function
    row_update = row_imply;
    temp =(row_imply(2));
    if(temp==1)
        [row_update(3),row_update(4) ]= not_out(row_update(3), row_imply(4),g);
    elseif(temp==3)
        [row_update(3),row_update(4),row_update(5) ] = and_out( row_update(3), row_imply(4), row_imply(5),g);
    elseif(temp==5)
        [row_update(3),row_update(4),row_update(5) ] = nand_out(row_update(3),row_imply(4), row_imply(5), g); 
    elseif(temp==8)
        [row_update(3),row_update(4),row_update(5),row_update(6),row_update(7)] = nand_4input( row_update(3), row_imply(4), row_imply(5), row_imply(6), row_imply(7),g);
    end
end
