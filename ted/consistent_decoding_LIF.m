%CONSISTENT_DECODING_LIF Decode a signal encoded with a leaky IAF neuron.
%   U_REC = CONSISTENT_DECODING_LIF(TK,T,B,D,R,C) decodes a
%   finite-energy signal encoded as spike times TK over the times T
%   using a leaky IAF neuron with bias B, threshold D, resistance R,
%   and capacitance C.
%
%   The calculation is described in further detail in Section 2.2 of
%   the Consistent Recovery paper mentioned in the toolbox references.

%   Author: Eftychios A. Pnevmatikakis
%   Copyright 2009-2015 Eftychios A. Pnevmatikakis
function u_rec = consistent_decoding_LIF(tk,t,b,d,R,C)

ln = length(tk)-1;

RC=R*C;

q = C*(d-b*R)+ b*RC*exp(-(tk(2:end)-tk(1:end-1))/RC)';

G = G_IF(tk,RC);
p = p_IF(tk',RC);
r = r_IF(tk',RC);

V = [G p r; p' 0 0; r' 0 0];

cv = pinv(V)*[q;0;0];
d0 = cv(end-1);
d1 = cv(end);
c  = cv(1:end-2);

u_rec = d0+d1*t;

for i = 1:ln
    u_rec = u_rec + c(i)*psi(tk(i),tk(i+1),t,RC);
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% auxiliary functions to generate G, p, r, ans psi

function G = G_IF(tk,varargin)
%G_IF Compute the reconstruction matrix G for a single IAF time decoder.
%   G = G_IF(TK,RC) computes the reconstruction matrix G with entries
%   G[i,j] = <phi_i,psi_j> used to decode a signal in L2 space that
%   was encoded by a leaky IAF neuron as the spike times TK with time
%   constant RC; if no time constant is specified, the neuron is
%   assumed to be ideal.
%   
%   The calculation is described in further detail in Equations
%   17 and 19 of the Consistent Recover paper mentioned in the
%   toolbox references.



ln = length(tk)-1;
G = zeros(ln,ln);

if nargin > 1
    RC = varargin{1};
else
    RC = Inf;
end

if isinf(RC)
    for i=1:ln
        for j=1:ln
            tmz=tk(min(i,j));
            tmp=tk(min(i,j)+1);
            tpz=tk(max(i,j));
            tpp=tk(max(i,j)+1);
            G(i,j)=((tpp-tmz)^5-(tpp-tmp)^5+(tpz-tmp)^5-(tpz-tmz)^5)/20;
        end
    end    
else
    etk  = exp(-diff(tk)/RC);  % exp(-(t_{k+1}-t_k)/RC)
    TkTl = (ones(ln+1,1)*tk-tk'*ones(1,ln+1))/RC; % tk - tl

    g=@(x)(-x.^3-6*x);
    gtk = g(TkTl');

    for k = 1:ln
        for l = 1:ln
            if k<l
                G(k,l) = (-gtk(l+1,k+1)+gtk(l+1,k)*etk(k)+(gtk(l,k+1)-gtk(l,k)*etk(k))*etk(l))*(RC^5);
            elseif k>l
                G(k,l) = -(-gtk(l+1,k+1)+gtk(l+1,k)*etk(k)+(gtk(l,k+1)-gtk(l,k)*etk(k))*etk(l))*(RC^5);
            else
                G(k,l) = (gtk(k+1,k)*2*etk(k)+6*(1-exp(-2*(tk(k+1)-tk(k))/RC)))*(RC^5);
            end
        end
    end
end




function p = p_IF(TK,RC,varargin)
%P_IF Compute the inner product <1,\phi_k>.
%   P = P_IF(TK,RC) computes the inner product <1,\phi_k> for
%   a leaky IAF neuron with time constant RC (an ideal neuron may
%   be simulated by setting RC to Inf). The spike times generated
%   by the neuron are specified in TK.
%
%   P = P_IF(TK,RC,LN,W) computes the inner product for a population
%   of IAF neurons; LN contains the number of spikes from each
%   neuron, and W contains the values by which each neuron weights
%   the input. If W is not specified, the input is not weighted.


if nargin > 2
    ln = varargin{1};
else
    ln = length(TK)-1;
    w = 1;
    N = 1;
end
if nargin > 3
    w = varargin{2};
    N = length(ln);
else
    w = ones(1,length(ln));
    N = length(ln);
end
if nargin > 4
    error('Too many input arguments.');
end

ln2 = cumsum([0,ln]);
p = zeros(sum(ln),1);

if isinf(RC)
    for i = 1:N
        p(ln2(i)+1:ln2(i+1)) = w(i)*diff(TK(1:ln(i)+1,i));
    end
else
    for i = 1:N
        p(ln2(i)+1:ln2(i+1)) = w(i)*RC(i)*(1-exp(-diff(TK(1:ln(i)+1,i))/RC(i)));
    end
end




function r = r_IF(TK,RC,varargin)

%R_IF Compute the inner product <t,\phi_k>.
%   R = R_IF(TK,RC) computes the inner product <t,\phi_k> for a
%   leaky IAF neuron with time constant RC (an ideal neuron may be
%   simulated by setting RC to Inf). The spike times generated by
%   the neuron are specified in TK.
%
%   R = R_IF(TK,RC,LN,W) computes the inner product for a
%   population of IAF neurons; LN contains the number of spikes
%   from each neuron, and W contains the values by which each
%   neuron weights the input. If W is not specified, the input is
%   not weighted.

if nargin > 2
    ln = varargin{1};
else
    ln = length(TK)-1;
    w = 1;
    N = 1;
end
if nargin > 3
    w = varargin{2};
    N = length(ln);
else
    w = ones(1,length(ln));
    N = length(ln);
end
if nargin > 4
    error('Too many input arguments.');
end

ln2 = cumsum([0,ln]);
r = zeros(sum(ln),1);

if isinf(RC)
    for i = 1:N
        r(ln2(i)+1:ln2(i+1)) = w(i)*diff(TK(1:ln(i)+1,i).^2)/2;
    end
else
    for i = 1:N
        r(ln2(i)+1:ln2(i+1)) = w(i)*(RC(i)^2)*(TK(2:ln(i)+1,i)/RC(i)-1-(TK(1:ln(i),i)/RC(i)-1).*exp(-diff(TK(1:ln(i)+1,i))/RC(i)));
    end
end



function psi = psi(tk1,tk2,t,varargin)

%PSI Create the signal reconstruction function psi.
%   P = PSI(TK1,TK2,T,RC) computes the matrix reconstruction function
%   psi for an IAF neuron for the interspike interval [TK1,TK2] over
%   the times T. If the neuron's time constant RC is not specified, it
%   is assumed to be infinite.
%   
%   The calculation is described in further detail in Equation 19 of
%   the Consistent Recovery paper mentioned in the toolbox references.

psi = zeros(1,length(t));

if nargin > 3
    RC = varargin{1};
elseif nargin == 3
    RC = Inf;
else
    error('Wrong number of input arguments.');
end


if isinf(RC)
    t1 = (tk1 - t).^4;
    t2 = (tk2 - t).^4; 

    fp = find(t>tk2,1);
    fm = find(t>tk1,1);

    sp = ones(1,length(t));
    sm = ones(1,length(t));
    sp(fp:end)=-1;
    sm(1:fm-1)=-1;
    psi = 0.25*(sp.*t2 + sm.*t1);

else    
    
    t1 = (tk1 - t)/RC;
    t2 = (tk2 - t)/RC;

    f=@(x)(x.^3-3*x.^2+6*x-6);

    ft  = (RC^4)*f([t1;t2]);
    etk = exp(-(tk2-tk1)/RC);
    ett = 12*(RC^4)*exp(-[t1;t2]);

    fp = find(t>tk2,1);
    fm = find(t>tk1,1);

    psi(1:fm-1)  = ft(2,1:fm-1)-ft(1,1:fm-1)*etk;
    psi(fm:fp-1) = ett(2,fm:fp-1)+ft(2,fm:fp-1)+ft(1,fm:fp-1)*etk;
    psi(fp:end)  = ft(1,fp:end)*etk-ft(2,fp:end);
end


