function [ BER_post,P] = FEC_LDPC_data(D, P, r, N)

numBlock = 2000;
H = dvbs2ldpc(r);
hEnc = comm.LDPCEncoder(H);
hDec = comm.LDPCDecoder(H);
% hgpuDec   = comm.gpu.LDPCDecoder(H);
hError = comm.ErrorRate;

frameErrorCount=0;

for counter = 1:numBlock
    P.Nt=N/log2(P.M);
    data1 = logical(randi([0 1],N*r,1));  % Generate binary data
    encodedData1    = step(hEnc, data1);

    P.CodeBits=reshape(encodedData1(:),log2(P.N),N/log2(P.N) );

    [~,llr,P] = exdatademapping(D,P,encodedData1);

    if gpuDeviceCount==1
        % CPU
        receivedBits   = step(hDec, llr);
        errorStats     = step(hError, data1, receivedBits);
    else
        % GPU
        receivedBits   = step(hgpuDec, llr); 
        errorStats     = step(hError, data1, receivedBits); 
    end
    frameErrorCount=frameErrorCount+((sum(data1~=receivedBits))>0);

    if frameErrorCount>50
        break
    end
end

fprintf('mode is %1d,    power is %.4f, SNR is %.4f,   BER_post Error     = %1.9f\n ',D.mode,D.power,D.SNR, errorStats(1))
BER_post = errorStats(1);

