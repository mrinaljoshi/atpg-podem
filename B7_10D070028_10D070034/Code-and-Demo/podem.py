import copy
f=open("netlist.txt","r")
l=f.readlines();

def read_netlist():
    device_id=0;
    for i in range (0, len(l)):
        temp=l[i]
        temp_str=''
        device=[]
        if(temp=='\n'):
            continue
        else:
            device.append(device_id) #id
            device_id=device_id+1
            
        flag=0;
        z=len(temp)
        w=temp[len(temp)-1]
        for j in range (0, len(temp)):
            ewc=temp[j]
            if (j==len(temp)-1):
                if (temp[j] != ' ' or temp[j] == '\n'):
                    if(temp_str):
                        device.append(temp_str)
                        temp_str=''
                else:
                    if(temp_str):
                        device.append(temp_str)
                        temp_str=''
            elif (temp[j] !=' '):
                temp_str = temp_str + temp[j]
                
            else:
                if(temp_str):
                    device.append(temp_str)
                temp_str=''
        netlist.append(device)    
    
def convert_netlist():
    
    temp=1
    
    node_old =[]
    node_new =[]
    for i in range (0, len(netlist)):
        if (netlist[i][1][:5] == 'and2_'):
            netlist[i][1] = 3;
        elif (netlist[i][1][:3] == 'not'):
            netlist[i][1] = 1;
        elif (netlist[i][1][:6] == 'nand4_'):
            netlist[i][1] = 8;
        elif (netlist[i][1][:6] == 'nand2_'):
            netlist[i][1] = 5;
            
        for j in range (2,len(netlist[i])):
            if (netlist[i][j][:2] == 'in'):
                match=0
                for k in range (0, len(node_old)):
                    if (netlist[i][j] == node_old[k]):
                        match=1
                        break
                        
                if (match):        
                    netlist[i][j]=node_new[k]
                else:                    
                    ins.append(temp)
                    node_old.append(netlist[i][j])
                    node_new.append(temp)
                    netlist[i][j]=temp
                    temp=temp+1
                    
            elif (netlist[i][j][:3] == 'out'):
                match=0
                for k in range (0, len(node_old)):
                    if (netlist[i][j] == node_old[k]):
                        match=1
                        break
                        
                if (match):        
                    netlist[i][j]=node_new[k]
                else:                    
                    outs.append(temp)
                    node_old.append(netlist[i][j])
                    node_new.append(temp)
                    netlist[i][j]=temp
                    temp=temp+1
            else:
                match=0
                for k in range (0, len(node_old)):
                    if (netlist[i][j] == node_old[k]):
                        match=1
                        break
                        
                if (match):        
                    netlist[i][j]=node_new[k]
                else:
                    node_old.append(netlist[i][j])
                    node_new.append(temp)
                    netlist[i][j]=temp
                    temp=temp+1
    for i in range(0, len(node_old)):
        temp2 = []
        temp2.append(node_old[i])
        temp2.append(node_new[i])
        node_map.append(temp2)
    return (temp -1)

def values_initial (no_nodes):
 
    for i in range (0, no_nodes+1):
        node_values.append(-5) 


def nand_out(o,i1,i2,g):

    if (g==0):          
        if(o == -5):
            i1= i1 ; 
            i2= i2;
            o=o;      
        elif(o == 0):
            i1 = 1; i2 = 1;
        elif(o == 1):
            if (i1 == 1):  
                i2= 0;
            elif(i2 == 1): 
                    i1= 0;
            elif (i1== 0):
                i2= i2;
            elif (i2== 0):
                i1= i1;
            else:
                i1=0;
                i2=0;


    else:
        if(i1 == -5 and i2 == -5):
            o =-5;
        else:
            o1 = (i1*i2) ;
            if(abs(o1)>1): 
                o = -5;
            else:
                o = int(not(o1));
    return[o,i1,i2] 

def not_out(o,i1,g):
    if(g==0):
        if(o==-5):
            i1 = -5;
        else:    
            i1 = int(not(o))
    else:
        if(i1==-5):
            o = -5;
        else:    
            o = int(not(i1));
    return[o,i1]

def and_out(o,i1,i2,g):
    if (g==0):          
        if(o == -5):
            i1= i1 ; 
            i2= i2;
            o=o;      
        elif(o == 1):
            i1 = 1; i2 = 1;
        elif(o == 0):
            if (i1 == 1):  
                i2= 0;
            elif(i2 == 1): 
                    i1= 0;
            elif(i1== 0):
                i2= i2;
            elif(i2== 0):
                i1= i1;
            else:
                i1=0;
                i2=0;
    else:
        if(i1 == -5 and i2 == -5):
            o =-5;
        else:
            o1 = (i1*i2) ;
            if(abs(o1)>1): 
                o = -5;
            else:
                o = o1;
    return[o,i1,i2] 

def nand_4input(o,i1,i2,i3,i4,g):
    if(g==0):
        if(o==-5):
            i1 = i2 = i3 = i4 = -5;
        if(o == 0):
            i1 = i2 = i3 = i4 = 1;
        elif (o==1): 
            i1 = 0;
    elif(g==1):
        o1 = (i1*i2*i3*i4) ;
        if(abs(o1)>1): 
            o = -5;
        else:
            o = int(not(o1));
    return(o,i1,i2,i3,i4);
         
def Type(V,row):
    g=0; 
    row_update = copy.deepcopy(row);
    if(V == -5): 
        row_update = copy.deepcopy(row)
        print('Value of V is not allowed')
    else:
        if(int(row[1])==1):
            row_update[2:5] =  not_out(V,row[3],g);
        elif(int(row[1])==3):
            row_update[2:5] =  and_out( V, row[3], row[4], g);
        elif(int(row[1])==5):
            row_update[2:5] =  nand_out( V, row[3], row[4], g); 
        elif(int(row[1])==8):
            row_update[2:7] =  nand_4input( V, row[3], row[4],row[5],row[6],g);
    return row_update

def update_rowvalues(device_id):
    rowvector=[]
    rowvector.append(device_id)
    rowvector.append(netlist[device_id][1])
    
    for i in range (2, len(netlist[device_id])):
        rowvector.append(node_values[netlist[device_id][i]])

    return rowvector

def backtrace(nG, nV):
    for i in range (0,len(netlist)): 
        if ( int(netlist[i][2]) == nG):
            row_values = update_rowvalues(i)
            row_v = Type(nV,row_values)

            for j in range (0, len(row_v)-3):

                g = int(netlist[i][3+j]) ;
                v = row_v[3+j];
                m =  [g,v]
                stack_G.append(m)
              
def objective(nG, nV):
    isPI=0
    while(nV !=-5 and isPI == 0):
        
        
        for i in range (0, len(ins)):
            if (nG == ins[i]):
                isPI=1
                break
        if (isPI==1):
            return (nG, nV)
        else:
            backtrace(nG,nV)
            
            if(stack_G):
                (nG,nV) = stack_G.pop()
            #isPI=0
        
    return (nG, nV)

def type_imply(row_imply):
    g=1;
    row_update = copy.deepcopy(row_imply);
    temp =int(row_imply[1]);
    if(temp==1):
        [row_update[2],row_update[3] ]= not_out(row_update[2], row_imply[3],g);
    elif(temp==3):
        [row_update[2],row_update[3],row_update[4] ] = and_out( row_update[2], row_imply[3], row_imply[4],g) ;
    elif(temp==5):
        [row_update[2],row_update[3],row_update[4] ] = nand_out(row_update[2],row_imply[3], row_imply[4], g); 
    elif(temp==8):
        [row_update[2],row_update[3],row_update[4],row_update[5],row_update[6]] = nand_4input( row_update[2], row_imply[3], row_imply[4], row_imply[5], row_imply[6],g);
    return row_update



def cnctd_devices (c_Node):
    device_index = []
    for i in range (0,len(netlist)):
        for j in range(3,len(netlist[i])):
            if(c_Node == netlist[i][j]):
                device_index.append(i);
                
    return device_index

# find device connected to each node once 
# one time job


def create_devicemap():
    
    for i in range (0, len(netlist)):
        
        device_map.append (cnctd_devices (netlist[i][2]));


def imply_device(device_id):
    
    row_imply = update_rowvalues(device_id)
    row_update = type_imply(row_imply)
    node_values [netlist[device_id][2]] = row_update[2]

       
def imply(PI, PI_Value):
    count_OUT = []
    flag=0
    node_values[PI] = PI_Value
    device_connected_next = []
    while (len(count_OUT) != len(outs)):
        #len(count_OUT) != len(outs)):
        #device_connected_next = []
        #device_connected = []
        
        if(flag==0):
            flag = 1
            device_connected = cnctd_devices(PI)
            for i in range (0, len(device_connected)):
                imply_device(device_connected[i])
                       
        else:
            flag = flag +1
            device_connected = device_connected_next
            device_connected_next = []
            
            for i in range(0, len(device_connected)):
                imply_device(device_connected[i])
            
            
           
        next_d = []
        
        for i in range (0, len(device_connected)):
                device_map_copy = copy.deepcopy(device_map)
                next_d = device_map_copy[device_connected[i]]
            
            # check if temp_d is empty
                if (len(next_d)==0):
                    
                    match_out = False
                    
                    for i1 in range (0, len(count_OUT)):
                        if (count_OUT[i1] == device_connected[i]):
                            match_out = True
                            break
                    if (~match_out):
                        count_OUT.append(device_connected[i])
                   
                if(next_d):
                        x = -1
                        while (len(next_d) > 0):
                            x = next_d.pop()
                            match_12 = False
                            for i2 in range(0, len(device_connected_next)):                         
                                
                                if(x==device_connected_next[i2]):
                                    match_12 = True
                                    break
                                    
                            if(~match_12):
                                    device_connected_next.append(x)
        # Values[i][j] = copy.deepcopy(V_temp); # dont where to put :P
        #flag = 5 
        #break     
#****************************************************************************


def main_podem(nG_C, nV):
    read_netlist()
    no_nodes = convert_netlist()
    create_devicemap()
    values_initial(no_nodes)
    for i in range(1, len(node_map)):
        if(nG_C == node_map[i][0]):
            nG = node_map[i][1]
            FL = node_map[i][1]
            
    (PI, PI_V) = objective(nG, nV)
    imply(PI, PI_V)
    
    while(node_values[FL] == -5):
        if(stack_G):
            (nG,nV) = stack_G.pop()
        else:
            print("Error")
            return
        (PI, PI_V) = objective(nG, nV)
        imply(PI, PI_V)
    #

    #NCV = [-5,-5,1,-5,1,-5,-5,1];
    index_arr =  cnctd_devices(FL)
    k = len(index_arr)
    if(k==0):
        #fault at primary output
        if (FV==node_values[FL] ):
            print('Fault is detectable')
        else:
            print('Fault is not detectable')
    
    for j in range (0, len(index_arr)):
        count = 0 ;
        nc_value = 1#NCV[int(netlist[index_arr[j]][1])]
        connected_in = netlist[index_arr[j]][3:len(netlist[index_arr[j]])]
        for p in range(0, len(connected_in)):
            if(connected_in[p] != FL):
                if(node_values[connected_in[p]] == -5):
                    (PI, PI_V) = objective(connected_in[p], nc_value)
                    imply(PI, PI_V)
                    if(node_values[connected_in[p]] == nc_value):
                        count = count + 1;
                elif(node_values[connected_in[p]] == nc_value): 
                    count = count +1
                elif(node_values[connected_in[p]] == (1-nc_value)):
                    print('Test not detected')
                    break
        if(count == (len(connected_in)-1)): 
            print('Fault is detectable')
            print (' ')
            print('Primary Input values are:')
            for i in range (0, len(ins)):
                if(node_values[ins[i]]==-5):
                    print ('Node',node_map[ins[i]][0]," ",'x')
                else:
                    print ('Node',node_map[ins[i]][0]," ",node_values[ins[i]])

        else:
            print('Fault is not detectable')
    
    return (PI, PI_V)

netlist=[]
node_values = []        
ins=[]
outs=[]
device_map = []
stack_G = []
node_map=[[]]

# ------------------------------------------------#
# Define Fault_Location and Fault_Location here   #
# ------------------------------------------------#
Fault_Location = 'n6'
Fault_Value = 1;
# ------------------------------------------------#
# ------------------------------------------------#

FL = 0;
FV = Fault_Value


print ('Fault Location', Fault_Location)
print ('Fault Value', FV)
print (' ')
main_podem(Fault_Location,FV)


