
  [data, name] = Gutfreund_KCa_PRC_model(0, 2000, 0, 'I_app', 1,... 0.87,...
      'STPstim', [0 -1], 'STPwidth', 12, 'STPshift', 0:12:180,... 'STPstim', 0:-.25:-2.5, 'STPwidth', 24, 'STPshift', 0:6:180,...
      'gKDR', 0, 'gNa', 0, 'gCa', 0, 'gKCa', 0,...
      'STPkernelType', 25, 'STPonset', 750);
  
  results = Gutfreund_KCa_PRC_plot(data, [], name);