function [D, P] = data_analysis(mode, filename, M)
addpath(genpath('./functions/'));

load('.\data\sent_data_kksdm.mat','data_origs')
if M == 8
    tx=data_origs.mod8QAM;
elseif M == 64
    tx=data_origs.mod4D64;
end
rx = h5read(filename,'/samples');

data_mod = tx([1 3],:).'+1i*tx([2 4],:).';  % send repeat  
data_sample = rx(:,[4*mode-3 4*mode-1])+1i*rx(:,[4*mode-2 4*mode]);


%% alignment

[acor,lag] = xcorr(data_sample(:,1)',data_mod(:,1)');         %  cross-correlation
diff=find(abs(acor)>max(abs(acor))*0.8);                    %  find max cross-correlation

pos_begin = lag(diff(1)); 
pos_end  = lag(diff(end));

if pos_begin<0             
    diff = diff(1,2:end);
end
if pos_end>size(data_sample,1)-size(data_mod,1) 
    diff = diff(1,1:end-1);
end
beginning = lag(diff(1,1))+1;
data_send = data_mod(end-beginning+2:end,:);  

for i = 1:length(diff) 
    data_send = [data_send;data_mod];
end
data_sample = data_sample.';
len_sub = length(data_sample) - length(data_send); 
data_send = [data_send;data_mod(1:len_sub,:)];      %   send symbol
data_rec = data_sample.';                             %   received symbol

% %% blind constellation
% trainsymbols = 65536;
% 
% if pos_begin < 0
%     pos_begin = pos_begin + trainsymbols;
% end
% data_send_cov = data_send(pos_begin : pos_begin+trainsymbols-1, :);
% data_rec_cov = data_rec(pos_begin : pos_begin+trainsymbols-1, :);     

%%   mapping constellation,        P  = Parameters(Constellation);   % Load Simulation Parameters
if M == 32
     load('D:\fwk\LLR_4D\constellations\32QAM_normalized.mat','Labeling','X');
     Lbin = Labeling;
     [X, Lbin] = PMD_XY(X,Lbin,X,Lbin);
elseif M == 8
    load('.\data\constellation\X_L_8QAM_Experiment.mat','L','X');
    Lbin = L;
elseif M == 64
    load('.\data\constellation\X_4D_64_optimized_for_8dB.mat','L','X')
    Lbin = L;
else
    [X,~,Lbin]=get_constellations('QAM',M); 
    [X, Lbin] = PMD_XY(X,Lbin,X,Lbin);
end

P.Lbin = Lbin;
P.Constellation=[(X(:,1)+1i*X(:,2)), (X(:,3)+1i*X(:,4))].';  
[P.M, P.N] = size(X);    
P.m = log2(M);

P.Channels=1;
P.X      = X;                          % Constellation
P.Lbin   = Lbin;                          % Constellation
P.L      = bin2dec(num2str(P.Lbin));           
P.CustomSymbolMapping = bin2dec(num2str(P.Lbin)); % Convert to decimal
[P.M, P.N] = size(P.X);                             % Number of constellation points
P.m      = log2(P.M);                             % Bits/symb

% Synchronously permute constellation and labeling (useful for mapper)
[~,idx_sort]=sort(P.CustomSymbolMapping);
P.CustomSymbolMapping=sort(P.CustomSymbolMapping);
P.X=P.X(idx_sort,:);
% Binary labeling
P.Lbin= dec2bin(P.CustomSymbolMapping)-48;

% Unit energy constellation
Es=1/P.M*sum(sum((P.X).^2))*2/P.N;                          % Energy: 1 unit/ polarization 
P.X=P.X/sqrt(Es);
if P.N==2
    P.Constellation=(P.X(:,1)+1i*P.X(:,2)).';               % 2D Complex-valued constellation
elseif P.N==4
    P.Constellation=(P.X(:,[1 3])+1i*P.X(:,[2 4])).';       % 4D Complex-valued constellation
end
% Find Subconstellations defined by the labeling
P.Ik0 = zeros(P.M/2,P.m);
P.Ik1 = zeros(P.M/2,P.m);
for kk=1:P.m
    pntr0=1;
    pntr1=1;
    for i=1:P.M
        if P.Lbin(i,kk)==0
            P.Ik0(pntr0,kk)=i;
            pntr0=pntr0+1;
        else
            P.Ik1(pntr1,kk)=i;
            pntr1=pntr1+1;
        end
    end
end

%% blind constellation
norm_send = [real(data_send(:,1)),imag(data_send(:,1))];
norms = sqrt(sum(sum(norm_send.^2))/length(norm_send));        %   normlization
norm_rec = [real(data_rec(:,1)),imag(data_rec(:,1))];
normr = sqrt(sum(sum(norm_rec.^2))/length(norm_rec));        %   normlization

data_send = data_send/norms;
data_rec = data_rec/normr;      

varX = data_send(1:2^14, :);
varY = data_rec(1:2^14, :);
% varX = data_send;
% varY = data_rec;
for i = 1:3
    varX = [varX; data_send(i*65536+1:i*65536+2^14, :)];
    varY = [varY; data_rec(i*65536+1:i*65536+2^14, :)];
end
D.var = mean(var(varY-varX));
% 
SNR_add = 19.7;
data_rec = awgn(data_rec, SNR_add);
norm_rec = [real(data_rec(:,1)),imag(data_rec(:,1))];
normr = sqrt(sum(sum(norm_rec.^2))/length(norm_rec)); 
data_rec = data_rec/normr;
SNR = 10*log10(var(data_send)/var(data_rec - data_send));
D.SNR = SNR;

% D.constellation = constellation;
D.data_send = data_send;
D.data_rec = data_rec;



