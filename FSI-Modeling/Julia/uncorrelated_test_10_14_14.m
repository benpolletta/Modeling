%check for whether cells are connected in 10 cell version
%try 100% connection in 10 cell version
%remind ben about gamma paper

clear;
T0 = 10000;  %3000 millisecond long trial
dt = .005;
T = floor(T0/dt);
t = (1:T)*dt;
no_cells = 2;
p_gj = 1; %probability of gap junction between any pair of cells. should be 1 if you're using 2 cells

no_e_inputs = 127*no_cells; %127 = number of AMPA input synapses per cell in Hjorth et al, times 10 cells
e_rate = 2; % presynaptic firing rate (Hz) in Hjorth et al
e_size = 0.0053; %changes magnitude of input. 0.0053 gets you between 5 and 2 Hz firing rate.
%you stop getting firing rate decreases as conductance increases for 10 cells around 0.015. 
%at around 0.5 you can get increased spike pairs with increased conductance in 10 cell networks, but firing rate is deeply weird

gj_strength = (8*e_size/no_cells); %magnitude of steps of strength of gap junction

no_i_inputs = 93*no_cells; % = 93 times 10
i_rate = 2;
i_size = 0.0053;

tau_i1 = 1; tau_ir = 0.5; tau_id = 5; tau_i = 10; tau_r = 1;
tau_e1 = 1; tau_er = 0.5; tau_ed = 2;
delta_t = 5; %number of milliseconds between two spikes to consider them "synchronous"
CE_e = repmat(eye(no_cells), 1, no_e_inputs/no_cells);
CE_i = repmat(eye(no_cells), 1, no_i_inputs/no_cells);    %Define connectivity from inputs to cells.

max_j = 10; %number of trials to run
max_k = 11; %number of conductance values to use

% EPSP for spikes at time t = 0.
epsp = tau_i*(exp(-max(t - tau_e1,0)/tau_ed) - exp(-max(t - tau_e1,0)/tau_er))/(tau_ed - tau_er);
epsp = epsp(epsp > eps);    %?
epsp = [zeros(1,length(epsp)) epsp]; %?

% IPSP for spikes at time t = 0.
ipsp = tau_i*(exp(-max(t - tau_i1,0)/tau_id) - exp(-max(t - tau_i1,0)/tau_ir))/(tau_id - tau_ir);
ipsp = ipsp(ipsp > eps);
ipsp = [zeros(1,length(ipsp)) ipsp];

%rectangle for convolutions
rect = [zeros(1,200), 3*ones(1,1000), zeros(1, 2000)];
rect = rect(rect > eps);
rect = [zeros(1,length(rect)) rect];

firing_rate = zeros(max_k,max_j);
spike_pairs = zeros(max_k, max_j);
firing_avg = zeros(max_k,1);
pair_avg = zeros(max_k, max_j);
spike_indicator = zeros(no_cells,(T0/dt)-1);
synch_indicator = zeros(no_cells, no_cells, (T0/dt)-2);

for j = 1:max_j

    e_spikes = rand(no_e_inputs,length(t));
    e_spikes = e_spikes < e_rate*dt/1000;
    
    e_spike_arrivals = CE_e*e_spikes; % Calculating presynaptic spikes for each cell.

    epsps = nan(size(e_spike_arrivals)); % Calculating EPSP experienced by each cell.
    for c = 1:no_cells
      epsps(c,:) = e_size*conv(e_spike_arrivals(c,:),epsp,'same');
    end
    
    i_spikes = rand(no_i_inputs,length(t));
    i_spikes = i_spikes < i_rate*dt/1000;
   
    i_spike_arrivals = CE_i*i_spikes; % Calculating presynaptic spikes for each cell.

    ipsps = nan(size(i_spike_arrivals)); % Calculating IPSP experienced by each cell.

    for c = 1:no_cells
        ipsps(c,:) = i_size*conv(i_spike_arrivals(c,:),ipsp,'same');
    end
	
	CG = gj_strength*(rand(no_cells) < p_gj);
	CG(logical(eye(size(CG)))) = 0; %No gap junctions between cells and themselves.
    
    for k = 1:max_k	
		
        [Vs,Vd,s,m,h,n,t] = ing_w_dendritic_gap_jxn(no_cells, epsps-ipsps, T0, [], zeros(no_cells), (k-1)*CG);
		% firing_rate(k,j) = 0;
		
        wide_spikes = zeros(no_cells,length(t)-1);
		
        for a = 1:no_cells
			
            Vs_pos = Vs > 0;
			
            Vs_sign_change = diff(Vs_pos(a,:), [], 2);
			
            spike_indicator(a,:) = Vs_sign_change == 1;
			
            firing_rate(k,j) = firing_rate(k,j) + sum(spike_indicator(a,:));
			
            wide_spikes(c,:) = conv(spike_indicator(c,:),rect,'same'); 
        
        end
        
        % firing_rate(k,j) = (firing_rate(k,j)/no_cells)*(1000/T0);
			
		% spike_pairs(k,j) = 0;
        
        for b = 1:no_cells
			
            for c = 1:no_cells
				
                if b ~= c
					
                    wide_sum = wide_spikes(b,:) + wide_spikes(c,:);
                    
					foo = wide_sum > 5;
					
                    wide_synch = diff(foo, [], 2);
					
                    synch_indicator(b,c,:) = wide_synch == 1;
					
                    spike_pairs(k,j) = spike_pairs(k,j) + sum(synch_indicator(b,c,:));
				
                end
                
            end
            
        end
        
    end
    
    %firing_avg = sum(firing_rate,2)/max_j;

end

firing_rate = (firing_rate/no_cells)*(1000/T0);

firing_avg = mean(firing_rate, 2);

spike_pairs = spike_pairs./firing_rate;
pair_avg = sum(spike_pairs,2)/max_j;