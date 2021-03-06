function [data, name] = Gutfreund_original(I_const, I_app, varargin)

% Set tau_fast = 7, look at I_app = 2.5, ..., 3.5 to see transition from
% subthreshold oscillations to intermittent spiking to continuous spiking.

vary_label = ''; vary_cell = cell(length(varargin)/2, 3);

if ~isempty(varargin)
    
    no_params = length(varargin)/2;
    
    for a = 1:no_params
        
        if isscalar(varargin{2*a})
            
            vary_label = [vary_label, sprintf('_%s_%g', varargin{2*a - 1}, varargin{2*a})];
            
        else
        
            vary_label = [vary_label, sprintf('_%s_%gto%g', varargin{2*a - 1}, varargin{2*a}(1), varargin{2*a}(end))];
        
        end
            
        vary_cell(a, :) = {'pop1', varargin{2*a - 1}, varargin{2*a}};
        
    end
    
end

name = ['gutfreund_original', vary_label];

if size(vary_cell, 1) > 2

    no_figures = prod(cellfun(@length, vary_cell(3:end, 3)));

else
    
    no_figures = 1;
    
end

tspan = 6000;

model_eqns = ['dv/dt=(I_const+I(t)+@current)/Cm; Cm=.25; v(0)=-65;',...
    sprintf('{iNaP,iKs,iKDRG,iNaG,gleak,iPulse}; gKs=0.084; gNaP=0.025; gl=0.025; I_const=%f;', I_const),...    %  halfKs=-60; halfNaP=-60; gNaP=0.0125; % 'tau_fast=5; tau_h=tau_fast; tau_m=tau_fast;',...
    'offset=0; Koffset=offset; Noffset=offset;',...     % gKDR=5/3; gNa=12.5/3; gl=0; 
    'tau_fast=7; tau_h=tau_fast; tau_m=tau_fast;',...
    sprintf('I(t)=I_app*((t/ton)*(t<=ton)+(ton<t&t<toff))*(1+rand*.25); ton=500; toff=%f; I_app=%f;', tspan, I_app),...
    'PPstim = 0; PPon = 2000; PPwidth = 250; kernel_type = 7;',... % in ms
    'monitor functions'];

if ~isempty(varargin)
    
    if strcmp(version('-release'), '2012a')
    
        data = SimulateModel(model_eqns, 'tspan', [0 tspan], 'vary', vary_cell);
    
    else
        
        data = SimulateModel(model_eqns, 'tspan', [0 tspan], 'vary', vary_cell, 'compile_flag', 1);
    
    end
    
else
    
    if strcmp(version('-release'), '2012a')
    
        data = SimulateModel(model_eqns, 'tspan', [0 tspan]);
    
    else
    
        data=SimulateModel(model_eqns, 'tspan', [0 tspan], 'compile_flag', 1);
        
    end
     
end
    
try 
    
    PlotData(data)

    if no_figures > 1
        
        for f = 1:no_figures
            
            save_as_pdf(f, ['Figures/', name, sprintf('_%g', f)])
            
        end
        
    else
    
        save_as_pdf(gcf, ['Figures/', name])

    end
    
catch error
    
    display('PlotData failed:')
    
    display(error)

end