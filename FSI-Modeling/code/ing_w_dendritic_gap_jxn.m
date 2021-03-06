%Implement a model of Interneuron Network Gamma (ING).
%Use the Hodgkin-Huxley equation for the individual neuron.
%Use Borgers et al, PNAS, 2008 to model the synapses
%  (see http://www.pnas.org/content/105/46/18023.abstract).

%INPUTS:
%  no_cells = number of simulated FSIs.
%  I0  = Injected current to cell.
%  tauI= decay time of inhibitory synapse.
%  T0  = total time of simulation [s].
%  CS = inhibitory synapse connectivity matrix, including conductance (strength) for each synapse.
%  CG = gap junction connectivity matrix, including conductance (strength) for each gap junction.

%OUTPUTS:
%  V = voltage of I-cell.
%  s = inhibitory synapse.
%  t = time axis vector (useful for plotting).

function [Vs,Vd,s,m,h,n,t] = ing_w_dendritic_gap_jxn(no_cells,I0,T0,g_sd,CS,CG)

  dt = 0.005;                       %The time step.
  T  = ceil(T0/dt);
  tauI = 12;                        %Decay time of inhibition.
  gNa = 120;  ENa=115;              %Sodium max conductance and reversal.    
  gK = 36;  EK=-12;                 %Potassium max conductance and reversal.
  gL = 0.3;  ERest=10.6;            %Leak max conductance and reversal.
  if isempty(g_sd)
    g_sd = gL/2;                    %Conductance from dendrite to soma (half of leak conductance, as in Lewis & Rinzel 2003).
  end
    
  t = (1:T)*dt;                     %Define time axis vector (useful for plotting).
  
  Vs = zeros(no_cells,T);                %Make empty variables to hold I-cell results.
  Vd = zeros(no_cells,T);
  m = zeros(no_cells,T);
  h = zeros(no_cells,T);
  n = zeros(no_cells,T);

  s = zeros(no_cells,T);                %Make empty variables to hold the synapse results.
  
  Vs(:,1)=-70+70*rand(no_cells,1);  	%Set the initial conditions for P-cells, I-cells, and synapses.
  Vd(:,1)=Vs(:,1);
  m(:,1)=rand(no_cells,1);
  h(:,1)=0.5*rand(no_cells,1);
  n(:,1)=0.35 + .4*rand(no_cells,1);
  s(:,1)=0.0 + 0.1*rand(no_cells,1);
  I_on=7*rand(no_cells,1);
  
  for i=1:T-1                       %Integrate the equations.
      
      %I-cell dynamics - NOTE the synaptic current!
      Vs(:,i+1) = Vs(:,i) + dt*(gNa*(m(:,i).^3).*h(:,i).*(ENa-(Vs(:,i)+65)) + gK*(n(:,i).^4).*(EK-(Vs(:,i)+65)) + gL*(ERest-(Vs(:,i)+65)) + I0*(t(i)>I_on) ...
          + CS*s(:,i).*(-80-Vs(:,i)) + g_sd*(Vd(:,i)-Vs(:,i)));                                                                                %Update I-cell voltage of soma.
      Vd(:,i+1) = Vd(:,i) + dt*(g_sd*(Vs(:,i)-Vd(:,i)) + (CG*diag(Vd(:,i))-diag(Vd(:,i))*CG)*ones(no_cells,1));                     
      m(:,i+1) = m(:,i) + dt*(alphaM(Vs(:,i)).*(1-m(:,i)) - betaM(Vs(:,i)).*m(:,i));                                    %Update m.
      h(:,i+1) = h(:,i) + dt*(alphaH(Vs(:,i)).*(1-h(:,i)) - betaH(Vs(:,i)).*h(:,i));                                    %Update h.
      n(:,i+1) = n(:,i) + dt*(alphaN(Vs(:,i)).*(1-n(:,i)) - betaN(Vs(:,i)).*n(:,i));                                    %Update n.
      s(:,i+1) = s(:,i) + dt*(((1+tanh(Vs(:,i)/10))/2).*(1-s(:,i))/0.5 - s(:,i)/tauI);                                 %Update s.
      
  end
  
end

%Below, define the auxiliary functions alpha & beta for each gating variable.

function aM = alphaM(V)
aM = (2.5-0.1*(V+65)) ./ (exp(2.5-0.1*(V+65)) -1);
end

function bM = betaM(V)
bM = 4*exp(-(V+65)/18);
end

function aH = alphaH(V)
aH = 0.07*exp(-(V+65)/20);
end

function bH = betaH(V)
bH = 1./(exp(3.0-0.1*(V+65))+1);
end

function aN = alphaN(V)
aN = (0.1-0.01*(V+65)) ./ (exp(1-0.1*(V+65)) -1);
end

function bN = betaN(V)
bN = 0.125*exp(-(V+65)/80);
end
