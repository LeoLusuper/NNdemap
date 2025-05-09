% Discription:
% 
% 
% Inputs:
% r             : code rate of LDPC(number of input codewords/total number of codewords)
% blocklength   : block length of LDPC
% 
% Outputs:
% BER_post      : 
% 
% Leo Lu
% May 2025
function [ BER_post ] = ModLDPC_data(r,blocklength)

dataModulation = '4D64';            % 4D64
demapMethod = 'CG4D';               % iddG4D   CG4D  CG4D_oneCov  iidG4D   NN   NNMixCG4D  NNMixCG4D6mode
power = 7.5;                        % 5:0.5:8;
isnet = 0;                          % 0: no nueral network;  1: use nueral network  0.5: half

powerlength = length(power);
BER_post = zeros(1,powerlength);
SNR = zeros(1,powerlength);

for mode = 3                        % 1:6
    for index = 1:powerlength
       file_name = ['D:\fwk\data\SDM_expriment_data\',dataModulation,'\R_190412_+',...
           sprintf('%0.1f',power(index)),'dBm_',dataModulation,'_00000.h5'];
       [D, P] = data_analysis(mode, file_name, 64);
       % D: send and received symbols of experiment data
       D.power = power(index);
       D.mode = mode;
       % P: information about demap
       P.insnet = isnet;
       P.demapMethod = demapMethod;
       
       [BER_post_one] = FEC_LDPC_data(D, P, r, blocklength);
       BER_post(index) = BER_post_one;
       SNR(index) = D.SNR; 
       if BER_post(index)==0
           break
       end
    end
    save_path = ['./results/mode3/4D64PRS/',demapMethod,'/mode',num2str(mode),'/'];
    save_name = [save_path,'R_',num2str(r),'_sample_',num2str(D.sample),'_mode',num2str(mode),modulation,demapMethod,'_BER_post.'];
    % the 'txt' file is used for paper drawing
    dlmwrite([save_name,'txt'],[power',SNR', BER_post'],'delimiter','\t','precision','%.9f')
    % the 'mat' file is used for later data inspection
    save([save_name,'mat'],'power','SNR','BER_post')
end



