%Robust Extracting
function [DecMess] = AudioRobustExt_Matrix_FixER22(filename,qStep,blocksize,Init_ramdom,EmbedBCHMessLen,dwtlevel,UseBCH,Originalbit,Transmittedbit)
 
[Audio,Fs]=audioread(filename); %haar dwt不能用int16类型数
AudioStego=double(Audio(2769:end,1)); %2710  2769
frameWidth = length(AudioStego);
audio_y = AudioStego;

blockCounts = floor(frameWidth/blocksize);
message_extract = zeros(1,EmbedBCHMessLen);

rand('seed', Init_ramdom);
% randmat = randperm(blockCounts,messageBCHMatrixLen_Ext);
randmat =1:EmbedBCHMessLen;
blockdata = zeros(1,blocksize);

for i = 1: length(message_extract)
    col_index = int32(mod(randmat(i),blockCounts));
    if col_index == 0
        col_index = blockCounts;
    end
    blockdata = audio_y((col_index-1)*blocksize+1:col_index*blocksize);
    temp=blockdata;
    
    for jj=1:dwtlevel
        [cA{jj},cD{jj}]=dwt(temp,'haar');
        temp=cD{jj};
    end
    clear temp
    % converting into vectorform
    temp=cD{1};
    for jj=1:dwtlevel-1
        temp=cat(1,temp,cD{jj+1});
    end
    vectorform=[cA{dwtlevel}' flipud(temp)'];  %合CA CD为波形向量
    clear temp
    
    % making matrix D as shown in Ref paper in figure 6
    D=cD{1}';
    for jj=1:dwtlevel-1
        %       temp=(cat(1,cD{jj+1},cD{jj+1}))';
        temp=repmat(cD{jj+1}',[1,2^jj]);
        D=cat(1,D,temp(1:size(D,2)));
    end
    
    [U,S,V] = svd(D);
    ExtSVDS1(i)=S(1);
    message_extract(i) = mod(floor(S(1)/qStep + 0.5),2) ;
end

%% 对BCH加密后的消息进行反置乱，以方便产生随机错误，而不是连续性错误，方便纠错
Init_ramdom=10;
rand('seed', Init_ramdom);
perm  = randperm(length(message_extract)); 
message_extract2(perm)=message_extract;

%% 是否用BCH解码
cwl=Transmittedbit;  %panjang codeword 7 加密后的bit数  Transmittedbit  
k = Originalbit;   %segmentasi pesan  4 原始bit数     Originalbit
switch UseBCH
    case 0
        DecMess=message_extract2;
    case 1
        dec=comm.BCHDecoder(cwl,k);
        DecMess=step(dec,message_extract2.').';
    otherwise
        msg = 'input UBC hanya boleh 0 atau 1';
        error(msg);
end
end







