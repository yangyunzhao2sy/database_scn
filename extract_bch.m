clc; clear all;
mdct=load('G:\1AYYZ\Project\rubust\soundcloud\compress\re-compress\embed\lame-3.99.5\output\Debug\mdct.txt');
mdct_square=mdct.*mdct;
mdct=abs(mdct);
for i=1:1536
    sub_energy(i,1)=sum(mdct_square(i,1:4))/4;
    sub_energy(i,2)=sum(mdct_square(i,5:8))/4;
    sub_energy(i,3)=sum(mdct_square(i,9:12))/4;
    sub_energy(i,4)=sum(mdct_square(i,13:16))/4;
    sub_energy(i,5)=sum(mdct_square(i,17:20))/4;
    sub_energy(i,6)=sum(mdct_square(i,21:24))/4;
    sub_energy(i,7)=sum(mdct_square(i,25:30))/6;
    sub_energy(i,8)=sum(mdct_square(i,31:36))/6;
    sub_energy(i,9)=sum(mdct_square(i,37:44))/8;
    sub_energy(i,10)=sum(mdct_square(i,45:52))/8;
    sub_energy(i,11)=sum(mdct_square(i,53:62))/10;
    sub_energy(i,12)=sum(mdct_square(i,63:74))/12;
    sub_energy(i,13)=sum(mdct_square(i,75:90))/16;
    sub_energy(i,14)=sum(mdct_square(i,91:110))/20;
    sub_energy(i,15)=sum(mdct_square(i,111:134))/24;
    sub_energy(i,16)=sum(mdct_square(i,135:162))/28;
    sub_energy(i,17)=sum(mdct_square(i,163:196))/34;
    sub_energy(i,18)=sum(mdct_square(i,197:238))/42;
    sub_energy(i,19)=sum(mdct_square(i,239:288))/50;
    sub_energy(i,20)=sum(mdct_square(i,289:342))/54;
    sub_energy(i,21)=sum(mdct_square(i,343:418))/76;
end

for i=1:1536
    temp=unique(sub_energy(i,:));
    [row1,col1]=find(sub_energy(i,:)== temp(end));
    sub_index(i,1)=col1(1,1);
    [row2,col2]=find(sub_energy(i,:)== temp(end-1));
    if(length(col1)>=2)
        sub_index(i,2)=col1(1,2);
    else
        sub_index(i,2)=col2(1,1);
    end
    [row3,col3]=find(sub_energy(i,:)== temp(end-2));
    if(length(col1)>=3)
        sub_index(i,3)=col1(1,3);
    elseif(length(col1)>=2)
        sub_index(i,3)=col2(1,1);
    elseif(length(col2)>=2)
        sub_index(i,3)=col2(1,2);
    else
        sub_index(i,3)=col3(1,1);
    end
end

for i=1:1536
    sub_index(i,:)=sort(sub_index(i,:));
end


sub_begin=[1 5 9 13 17 21 25 31 37 45 53 63 75 91 111 135 163 197 239 289 343];
sub_len=[4 4 4 4 4 4 6 6 8 8 10 12 16 20 24 28 34 42 50 54 76];

msg_num=1;

for i=1:1536
    index1=sub_index(i,1);
    index2=sub_index(i,2);
    index3=sub_index(i,3);
    
    %第一个比例因子带%
    begin=sub_begin(index1);
    len=sub_len(index1);
    sub_max=max(mdct(i,begin:begin+len-1));
    max_index=find(mdct(i,begin:begin+len-1)== sub_max);
    max1(i,1)=sub_max;
    stego_index(i,1)=max_index(1,1)+begin-1;
    extract_msg(1,msg_num)=mod(max_index(1,1),2);
    msg_num=msg_num+1;
    
    %第二个比例因子带%
    begin=sub_begin(index2);
    len=sub_len(index2);
    sub_max=max(mdct(i,begin:begin+len-1));
    max_index=find(mdct(i,begin:begin+len-1)== sub_max);
    max1(i,2)=sub_max;
    stego_index(i,2)=max_index(1,1)+begin-1;
    extract_msg(1,msg_num)=mod(max_index(1,1),2);
    msg_num=msg_num+1;
    
    %第三个比例因子带%
    begin=sub_begin(index3);
    len=sub_len(index3);
    sub_max=max(mdct(i,begin:begin+len-1));
    max_index=find(mdct(i,begin:begin+len-1)== sub_max);
    max1(i,3)=sub_max;
    stego_index(i,3)=max_index(1,1)+begin-1;
    extract_msg(1,msg_num)=mod(max_index(1,1),2);
    msg_num=msg_num+1;
end
Init_ramdom=10;
rand('seed', Init_ramdom);
perm  = randperm(length(extract_msg)); 
extract_msg1(perm)=extract_msg;
cwl=7;  %panjang codeword 7 加密后的bit数  Transmittedbit  
k = 4;   %segmentasi pesan  4 原始bit数     Originalbit
extract_msg2=extract_msg1(1,1:4606);
dec=comm.BCHDecoder(cwl,k);
DecMess=step(dec,extract_msg2.').';

