%Robust Embedding
function [AudioStego,messageBCHLen] = AudioRobustEmb_Matrix_FixER22(AudioCover,Embmessage,qStep,blocksize,Init_ramdom,dwtlevel,UseBCH,Originalbit,Transmittedbit)
frameWidth = length(AudioCover);
audio_y = AudioCover;
blockCounts = floor(frameWidth/blocksize);
%% 利用BCH对嵌入消息进行冗余编码
cwl=Transmittedbit;  %panjang codeword 7 加密后的bit数  Transmittedbit  
k = Originalbit;   %segmentasi pesan  4 原始bit数     Originalbit
fprintf('If not use BCH encode the maixmum Embedded rate is: %f, else the the maixmum Embedded rate is: %f\n',1/blocksize,k/(cwl*blocksize)); 
switch UseBCH
    case 0
        emim=Embmessage;
    case 1
        padd= ceil(length(Embmessage)/k)*k-length(Embmessage);
        strimm=[Embmessage zeros(1,padd)];
        enc=comm.BCHEncoder(cwl,k);  % creates a BCH encoder object, enc, with the CodewordLength property set to N and the MessageLength property set to K.
        emim=step(enc,strimm.').';
    otherwise
        msg = 'input UseBCH must be 0 or 1, where 0 means not using BCH coding and 1 means using BCH coding';
        error(msg);
end
%% 对BCH加密后的消息进行置乱，以方便产生随机错误，而不是连续性错误，方便纠错
Init_ramdom=10;
rand('seed', Init_ramdom);
perm  = randperm(length(emim));
messageBCH=emim;%(perm)

%%
messageBCHLen=length(messageBCH);
fprintf('BCH Encodded Message With Matrix Encodeded legnth: %d.\n', messageBCHLen);

if messageBCHLen <(blockCounts-1)
    rand('seed', Init_ramdom);
%     randmat = randperm(blockCounts, messageBCHMatrixLen);
 randmat = 1:messageBCHLen;
else
    fprintf('The maximum capacity bits is %d, and the maximum bitrate is: %f\n',blockCounts,1/blocksize*(k/cwl));
    msg = 'BCH Encodded Message is to long,  Reducing the embrate values';
    error(msg);
end

%% 嵌入
blockdata = zeros(1,blocksize);

for i = 1: length(messageBCH)
    messageBit = messageBCH(i);
    col_index = int32(mod(randmat(i),blockCounts));
    if col_index == 0
        col_index = blockCounts;
    end
    blockdata = audio_y((col_index-1)*blocksize+1:col_index*blocksize);
    
    temp=blockdata;
    for jj=1:dwtlevel
        [cA{jj},cD{jj}]=dwt(temp,'haar');
        temp=cA{jj};
    end
    clear temp
    % converting into vectorform
%     temp=cD{1};
%     for jj=1:dwtlevel-1
%         temp=cat(1,temp,cD{jj+1});
%     end
%     vectorform=[cA{dwtlevel}' flipud(temp)'];  %合CA CD为波形向量
%     clear temp
    
    % making matrix D as shown in Ref paper in figure 6
    D=cA{1}';
%     for jj=1:dwtlevel-1
%         %         temp=(cat(1,cD{jj+1},cD{jj+1}))';
%         temp=repmat(cA{jj+1}',[1,2^jj]);
%         D=cat(1,D,temp(1:size(D,2)));
%     end
    
    [U,S,V] = svd(D);
%       fprintf('S_Value:%d\t',S(1)); disp(blockdata');
    OriSVDS1(i)=S(1);
%     fid=fopen('OriSVD.txt','a');
%     fprintf(fid,'%f\n',S(1));
%     fclose(fid);
    if messageBit == 0
        S(1) = floor(S(1)/qStep) * qStep + mod(floor(S(1)/qStep + 0),2) * qStep;
    else
        S(1) = floor(S(1)/qStep) * qStep + mod(floor(S(1)/qStep + 1),2) * qStep;
    end
%     fprintf('S_Value:%d\n',S(1));
    NewSVDS1(i)=S(1);
%     fid=fopen('OriChangedSVD.txt','a');
%     fprintf(fid,'%f\n',S(1));
%     fclose(fid);
    % inverse of SVD
    Dww=U*S*V';
    
    
    % inverse of DWT
    colms=size(Dww,2);
    for kk=1:dwtlevel
        if kk==1|| kk==2
            Dww_cA{kk}=Dww(kk,1:colms/kk);
        else
            Dww_cA{kk}=Dww(kk,1:colms/(2^(kk-1)));
        end
    end
    temp=Dww_cA{dwtlevel};
    for jj=dwtlevel:-1:1
        if numel(cD{jj})>numel(temp)
            dim=numel(cD{jj})-numel(temp);
            temp=padarray(temp,[0,dim],'post');% padding of zeros at last to make both cA and new cD of same size
        elseif (cD{jj})<numel(temp)
            dim=numel(temp)-numel(cD{jj});
            temp=temp(1:numel(cD{jj}));
        else
            fim=numel(temp);
        end
        
        temp=idwt(temp,cD{jj}','haar');
%          disp(temp);
        watermrkedframe{jj}=temp;
        
    end    
    audio_y((col_index-1)*blocksize+1:col_index*blocksize) = watermrkedframe{1};
end
%     fid=fopen('OriSVD.txt','w');
%     fprintf(fid,'%f\n',OriSVDS1);
%     fclose(fid);
%     fid=fopen('OriChangedSVD.txt','w');
%     fprintf(fid,'%f\n',NewSVDS1);
%     fclose(fid);
AudioStego = audio_y;
end