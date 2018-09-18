function [data, name] = Gutfreund_Cap(I_const, tspan, save_flag, gKs_in, gCa_in, gKCa_in, varargin)

% Set tau_fast = 7, look at I_app = 2.5, ..., 3.5 to see transition from
% subthreshold oscillations to intermittent spiking to continuous spiking.

if isempty(gKs_in)
    gKs_in = 0.134; gKs_flag = ''; 
else
    gKs_flag = sprintf('_gKs_in_%g', gKs_in);
end

if isempty(gCa_in) 
    gCa_in = 0.05; gCa_flag = '';
else
    gCa_flag = sprintf('_gCa_in_%g', gCa_in);

end

if isempty(gKCa_in)
    gKCa_in = 0.014; gKCa_flag = '';
else
    gKCa_flag = sprintf('_gKCa_in_%g', gKCa_in);
end

vary_label = ''; vary_cell = cell(length(varargin)/2, 3);

if ~isempty(varargin)
    
    for a = 1:(length(varargin)/2)
        
        if isscalar(varargin{2*a})
            
            vary_label = [vary_label, sprintf('_%s_%g', varargin{2*a - 1}, varargin{2*a})];
            
        else
        
            vary_label = [vary_label, sprintf('_%s_%gto%g', varargin{2*a - 1}, varargin{2*a}(1), varargin{2*a}(end))];
        
        end
        
        vary_cell(a, :) = {'pop1', varargin{2*a - 1}, varargin{2*a}};
        
    end
    
end

name = ['gutfreund_Cap', gKs_flag, gCa_flag, gKCa_flag, vary_label];

if size(vary_cell, 1) > 2

    no_figures = prod(cellfun(@length, vary_cell(3:end, 3)));

else
    
    no_figures = 1;
    
end

% I_app = 0;

% C_mult = .9/.25;

ton = 500;

model_eqns = ['dv/dt=(I_const+I(t)+@current)/Cm; Cm=.9; v(0)=-65;',... % +I(t)
    '{iNaP,iKs,iKDRG,iNaG,gleak,CaDynT,iCaT,iKCaT};',...
    sprintf('I_const=%g;', I_const),...    %  halfKs=-60; halfNaP=-60; 
    sprintf( 'C_mult=Cm/.25; gKs=C_mult*%g; gCa=C_mult*%g; gKCa=C_mult*%g;', gKs_in, gCa_in, gKCa_in),...
    'gNaP_denom=3.36; gNaP=gKs/gNaP_denom;',...
    'gl=C_mult*0.025; CAF=24/C_mult; bKCa = .002;',... % C_mult*ones(1, 3)),... %%% 'tau_fast=5; tau_h=tau_fast; tau_m=tau_fast;',... %'slow_offset=0; halfKs=slow_offset; halfNaP=slow_offset;',... %%% 'offset=0; Koffset=offset; Noffset=offset;',...     % 
    'fast_denom=1; gKDR=C_mult*5/fast_denom; gNa=C_mult*12.5/fast_denom;',... % C_mult*ones(1, 2)),...
    'tau_fast = 5; tau_m = tau_fast; tau_h = tau_fast; I_app = 0;',...
    sprintf('ton=%g; toff=%g;', ton, tspan),... %  (ton<t&t<toff) %%% 'PPstim = 0; PPfreq = 1.5; PPwidth = floor((1000/PPfreq)/4); PPshift = 0; ap_pulse_num = 0; kernel_type = 7;',... % in ms % 
    'noise=0; I(t)=C_mult*I_app*((t/ton)*(t<=ton)+(ton<t&t<toff))*(1+rand*noise);',... % *((1-pulse/2)+pulse*(mod(t,750)<250&t>2*ton));',...
    'monitor functions'];

if ~isempty(varargin)
    
    % if strcmp(version('-release'), '2012a')
    
    % if prod(cell2mat(cellfun(@(x) length(x), vary_cell(:, 3), 'UniformOutput', 0))) > 12
    % 
    %     data = SimulateModel(model_eqns, 'tspan', [0 tspan], 'vary', vary_cell, 'cluster_flag', 1, 'overwrite_flag', 1,...
    %         'save_data_flag', 1, 'verbose_flag', 1, 'study_dir', name, 'downsample_factor', 25);
    % 
    %     return
    % 
    % else
        
        data = SimulateModel(model_eqns, 'tspan', [0 tspan], 'vary', vary_cell, 'parallel_flag', 1, 'compile_flag', 1, 'downsample_factor', 25);
        
    % end
    
    % else
    % 
    %     data = SimulateModel(model_eqns, 'tspan', [0 tspan], 'vary', vary_cell, 'compile_flag', 1);
    % 
    % end
    
else
    
    % if strcmp(version('-release'), '2012a')
    
        data = SimulateModel(model_eqns, 'tspan', [0 tspan], 'downsample_factor', 25);
    
    % else
    % 
    %     data=SimulateModel(model_eqns, 'tspan', [0 tspan], 'compile_flag', 1);
    % 
    % end
     
end
    
try 
    
    PlotData(data)

    if no_figures > 1
        
        for f = 1:no_figures
            
            save_as_pdf(f, ['Figures/', name, sprintf('_%g', f)], '-v7.3')
            
        end
        
    else
    
        save_as_pdf(gcf, ['Figures/', name], '-v7.3')

    end
    
catch error
    
    display('PlotData failed:')
    
    display(error)

end

if save_flag
    
    save([name, '.mat'], 'data', '-v7.3')
    
end