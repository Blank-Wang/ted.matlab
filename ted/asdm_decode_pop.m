%ASDM_DECODE_POP Decode a signal encoded by an ensemble of ASD modulators. 
%   U_REC = ASDM_DECODE_POP(S_LIST,DUR,DT,BW,B_LIST,D_LIST,K_LIST)
%   decodes the signal with duration DUR s and bandwidth BW rad/s
%   encoded as a cell array S_LIST of spike interval arrays using
%   several asynchronous sigma-delta modulators with biases, Schmitt
%   trigger thresholds, and integration constants respectively
%   specified in the cell arrays B_LIST, D_LIST, and K_LIST. The
%   recovered signal is assumed to be sampled at sampling rate 1/DT
%   Hz.
%
%   Note that the number of spikes contributed by each neuron may
%   differ from the number contributed by other neurons.

%   Author: Lev Givon
%   Copyright 2009-2010 Trustees of Columbia University

function u_rec = asdm_decode_pop(s_list,dur,dt,bw,b_list,d_list, ...
                                 k_list)

M = length(s_list);
if M == 0,
    error('no spike data given');
end

bwpi = bw/pi;

% Compute the midpoints between spikes:
ts_list = cellfun(@cumsum,s_list,'UniformOutput',false);
tsh_list = cellfun(@(ts) (ts(1:end-1)+ts(2:end))/2, ...
                   ts_list,'UniformOutput',false);

% Compute number of spikes in each spike list:
Ns_list = cellfun(@length,ts_list);
Nsh_list = cellfun(@length,tsh_list);

% Compute the values of the matrix that must be inverted to obtain
% the reconstruction coefficients:
Nsh_sum = sum(Nsh_list);
G = zeros(Nsh_sum,Nsh_sum);
q = zeros(Nsh_sum,1);
for l=1:M,
    for m=1:M,
        G_block = zeros(Nsh_list(l),Nsh_list(m));

        % Compute the values for all of the sincs so that they do
        % not need to each be recomputed when determining the
        % integrals between spike times:
        for k=1:Nsh_list(m),
            temp = si(bw*(ts_list{l}-tsh_list{m}(k)))/pi;
            for n=1:Nsh_list(l),
                G_block(n,k) = temp(n+1)-temp(n);
            end
        end
        G(sum(Nsh_list(1:l-1))+1:sum(Nsh_list(1:l)), ...
          sum(Nsh_list(1:m-1))+1:sum(Nsh_list(1:m))) = G_block;
    end
    
    % Compute the quanta:
    q(sum(Nsh_list(1:l-1))+1:sum(Nsh_list(1:l)),1) = ...
        (-1).^[1:Nsh_list(l)].*(2*k_list{l}*d_list{l}-b_list{l}* ...
                               s_list{l}(2:end));

end

% Compute the reconstruction coefficients:
c = pinv(G)*q;

% Reconstruct the signal using the coefficients:
t = [0:dt:dur];
u_rec = zeros(1,length(t));
for m=1:M,
    for k=1:Nsh_list(m),
        u_rec = u_rec + sinc(bwpi*(t-tsh_list{m}(k)))*bwpi* ...
                c(sum(Nsh_list(1:m-1))+k,1);
    end
end    
