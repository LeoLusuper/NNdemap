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
clc;clear;close;
addpath(genpath('./functions/'));
warning off;

blocklength = 64800;
r=3/4;              % 5/6  1/3  4/5  2/3
% SNRdB = 10;                         

[ BER_post  ] = ModLDPC_data(r, blocklength);
