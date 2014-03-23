%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SCRIPTING EXAMPLE FOR THE SOURCE INFORMATION FLOW TOOLBOX (SIFT)    %%%
%%% SIFT Version: 1.0-beta                                              %%%
%%%                                                                     %%%
%%% THIS DOES NOT WORK WITH VERSION 0.97-alpha OR EARLIER               %%%
%%%                                                                     %%%
%%% This example demonstrates how to use SIFT from the command-line or  %%%
%%% in a script. This example applies to SIFT 1.0-beta.                 %%%
%%% For additional information on the below steps, please consult the   %%%
%%% SIFT manual located at http://sccn.ucsd.edu/wiki/SIFT               %%%
%%% Author: Tim Mullen (C) 2013, SCCN, INC, UCSD                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% STEP 1: Load Data

% We will begin by loading up the 'RespWrong.set' (and optionally 'RespCorr.set') datasets located in the 
% /Data/ folder within the Sample Data package
% (you can download this package from the SIFT website or at 
% ftp://sccn.ucsd.edu/pub/tim/SIFT/SIFT_SampleData.zip)

EEG = pop_loadset;

%% STEP 2: Define key Processing Parameters

Components          = [8 11 13 19 20 23 38 39];     % these are the components/channels to which we'll fit our multivariate model
WindowLengthSec     = 0.35;                         % sliding window length in seconds
WindowStepSizeSec   = 0.03;                         % sliding window step size in seconds
NewSamplingRate     = [];                           % new sampling rate (if downsampling)
EpochTimeRange      = [-1 1.25];                    % this is the time range (in seconds) to analyze (relative to event at t=0)
GUI_MODE            = 'nogui';                      % whether or not to show the Graphical User Interfaces. Can be 'nogui' or anything else (to show the gui)
VERBOSITY_LEVEL     = 2;                            % Verbosity Level (0=no/minimal output, 2=graphical output)

%% STEP 3: Pre-process the data

disp('===================================')
disp('PRE-PROCESSING DATA');

% select time range
EEG = pop_select( EEG,'time',EpochTimeRange );
% select components
EEG = pop_subcomp( EEG, setdiff_bc(1:EEG.nbchan,Components), 0);
% resample data
if ~isempty(NewSamplingRate)
    EEG = pop_resample( EEG, NewSamplingRate);
end
% convert list of components to cell array of strings
ComponentNames = strtrim(cellstr(num2str(Components'))); 

% apply the command to pre-process the data
[EEG] = pop_pre_prepData(EEG,GUI_MODE, ...
        'VerbosityLevel',VERBOSITY_LEVEL,   ...
        'SignalType',{'Components'},  ...
        'VariableNames',ComponentNames,   ...
        'Detrend',  ...
            {'verb' VERBOSITY_LEVEL ...
            'method' {'linear'} ...
            'piecewise' ...
                {'seglength' 0.33   ...
                 'stepsize' 0.0825} ...
            'plot' true},  ...
        'NormalizeData',    ...
            {'verb' 0       ...
             'method' {'time' 'ensemble'}},   ...
        'resetConfigs',true,    ...
        'badsegments',[],       ...
        'newtrials',[],         ...
        'equalizetrials',false);

disp('===================================')

%% STEP 4: Identify the optimal model order

disp('===================================')
disp('MODEL ORDER IDENTIFICATION');

% Here we compute various model order selection criteria for varying model
% orders (e.g. 1 to 30) and visualize the results

% compute model order selection criteria...
EEG = pop_est_selModelOrder(EEG,GUI_MODE, ...
        'modelingApproach',         ...
            {'Segmentation VAR'     ...
                'algorithm' {'Vieira-Morf'} ...
                'winStartIdx' []    ...
                'winlen'  WindowLengthSec    ...
                'winstep' WindowStepSizeSec  ...
                'taperfcn' 'rectwin'    ...
                'epochTimeLims' []      ...
                'prctWinToSample' 100   ...
                'normalize' []          ...
                'detrend' {'method' 'constant'} ...
                'verb' VERBOSITY_LEVEL},      ...
        'morderRange',[1 30] ,  ...
        'downdate',true,        ...
        'runPll',[],            ...
        'icselector',{'sbc' 'aic' 'fpe' 'hq'},  ...
        'winStartIdx',[],       ...
        'epochTimeLims',[],     ...
        'prctWinToSample',80,   ...
        'plot', [], ...
        'verb',VERBOSITY_LEVEL);

% To plot the results, use this:
handles = vis_plotOrderCriteria(EEG.CAT.IC,{'conditions' []    ...
                                            'icselector' {'sbc','aic','fpe','hq'}  ...
                                            'minimizer' {'min'} ...
                                            'prclim' 90});

% If you want to save this figure you can uncomment the following lines:
%
% for i=1:length(handles)
%     saveas(handles(i),sprintf('orderResults%d.fig',i));
% end
% close(handles);

% Finally, we can automatically select the model order which minimizes one
% of the criteria (or you can set this manually based on above figure)
ModelOrder = ceil(mean(EEG(1).CAT.IC.hq.popt));

% As an alternative to using the minimum of the selection criteria over 
% model order, you can find the "elbow" in the plot of model order versus
% selection criterion value. This is useful in cases where the selection
% criterion does not have a clear minimum. For example, the lines below
% plot and select the elbow location (averaged across windows) for the AIC 
% criterion
%
% vis_plotOrderCriteria(EEG(1).CAT.IC,{},{},'elbow');
% ModelOrder = ceil(mean(EEG(1).CAT.IC.aic.pelbow));

disp('===================================')

%% STEP 5: Fit the VAR model

disp('===================================')
disp('MODEL FITTING');

% Here we can check that our selected parameters make sense
fprintf('===================================================\n');
fprintf('MVAR PARAMETER SUMMARY FOR CONDITION: %s\n',EEG.condition);
fprintf('===================================================\n');
est_dispMVARParamCheck(EEG,struct('morder',ModelOrder','winlen',WindowLengthSec,'winstep',WindowStepSizeSec,'verb',VERBOSITY_LEVEL));

% Once we have identified our optimal model order, we can fit our VAR model.

% Fit a model using the options specifed for model order selection (STEP 4)
[EEG] = pop_est_fitMVAR(EEG,GUI_MODE, ...
            EEG.CAT.configs.est_selModelOrder.modelingApproach, ...
            'ModelOrder',ModelOrder);

% Note that EEG.CAT.MODEL now contains the model structure with
% coefficients (in MODEL.AR), prediction errors (MODEL.PE) and other
% self-evident information

% Alternately, we can fit the VAR parameters using a Kalman filter (see
% doc est_fitMVARKalman for more info on arguments)
%
% EEG.CAT.MODEL = est_fitMVARKalman(EEG,0,'updatecoeff',0.0005,'updatemode',2,'morder',ModelOrder,'verb',2,'downsampleFactor',50);

disp('===================================')

%% STEP 6: Validate the fitted model

disp('===================================')
disp('MODEL VALIDATION');

% Here we assess the quality of the fit of our model w.r.t. the data. This
% step can be slow.

% We can obtain statistics for residual whiteness, percent consistency, and
% model stability ...
[EEG] = pop_est_validateMVAR(EEG,GUI_MODE,...
                            'checkWhiteness', ...
                                {'alpha' 0.05 ...
                                 'statcorrection' 'none' ...
                                 'numAcfLags' 50         ...
                                 'whitenessCriteria' {'Ljung-Box' 'ACF' 'Box-Pierce' 'Li-McLeod'} ...
                                 'winStartIdx' [] ...
                                 'prctWinToSample' 100  ...
                                 'verb' 0}, ...
                             'checkResidualVariance',...
                                {'alpha' 0.05 ...
                                 'statcorrection' 'none' ...
                                 'numAcfLags' 50    ...
                                 'whitenessCriteria' {}  ...
                                 'winStartIdx' []        ...
                                 'prctWinToSample' 100   ...
                                 'verb' 0}, ...
                             'checkConsistency',    ...
                                {'winStartIdx' []   ...
                                 'prctWinToSample' 100 ...
                                 'Nr' []                ...
                                 'donorm' 0         ...
                                 'nlags' []         ...
                                 'verb' 0}, ...
                             'checkStability',  ...
                                {'winStartIdx' []   ...
                                 'prctWinToSample' 100 ...
                                 'verb' 0},     ...
                             'prctWinToSample',70,  ...
                             'winStartIdx',[],      ...
                             'verb',VERBOSITY_LEVEL,...
                             'plot',false);

% ... and then plot the results
handles = [];
for k=1:length(EEG)
    handles(k) = vis_plotModelValidation(EEG(k).CAT.VALIDATION.whitestats, ...
                                         EEG(k).CAT.VALIDATION.PC,         ...
                                         EEG(k).CAT.VALIDATION.stability);
end

% If you want to save this figure you can uncomment the following lines:
%
% for i=1:length(handles)
%     saveas(handles(i),sprintf('validationResults%d.fig',i));
% end
% close(handles);


% To automatically determine whether our model accurately fits the data you
% can write a few lines as follows (replace 'acf' with desired statistic):
%
% if ~all(EEG(1).CAT.VALIDATION.whitestats.acf.w)
%     msgbox('Residuals are not completely white!');
% end

disp('===================================')


%% STEP 7: Compute Connectivity

disp('===================================')
disp('CONNECTIVITY ESTIMATION');

% Next we will compute various dynamical quantities, including connectivity,
% from the fitted VAR model. We can compute these for a range of
% frequencies (here 1-40 Hz). See 'doc est_mvarConnectivity' for a complete
% list of available connectivity and spectral estimators.

EEG = pop_est_mvarConnectivity(EEG,GUI_MODE, ...
            'connmethods',{'nDTF' 'dDTF08' 'nPDC' 'S'}, ...
            'absvalsq',true,           ...
            'spectraldecibels',true,   ...
            'freqs',[1:40] ,        ...
            'verb',VERBOSITY_LEVEL);


%% OPTIONAL STEP 8: Compute Statistics (This step is slow)

% number of bootstrap samples to draw
NumSamples = 200;

% obtain the bootstrap distributions for each condition
for cnd=1:length(EEG)
    EEG(cnd) = pop_stat_surrogateGen(EEG(k),GUI_MODE, ...
        'modelingApproach', EEG(k).CAT.configs.est_fitMVAR, ...
        'connectivityModeling',EEG(k).CAT.configs.est_mvarConnectivity, ...
        'mode',{'Bootstrap' 'nperms' NumSamples 'saveTrialIdx' true}, ...
        'autosave',[], ...
        'verb',VERBOSITY_LEVEL);
end

% Bootstrap distributions are now stored in EEG.CAT.PConn
% This is a structure containing bootstrap estimates of the connectivity,
% etc., stored in matrices of size:
% [num_vars x num_vars x num_freqs x num_times x num_samples]


% we can also replace connectivity estimate with bootstrap estimate
% for cnd=1:length(EEG)
%     EEG(cnd).CAT.Conn = stat_getDistribMean(EEG(cnd).CAT.PConn);
% end

disp('===================================')

%% NOTE: alternately, we can also obtain the phase-randomized null distributions for each condition

% number of null distribution samples to draw
NumSamples = 200;

for cnd=1:length(EEG)
    EEG(cnd) = pop_stat_surrogateGen(EEG(cnd),GUI_MODE, ...
        'modelingApproach', EEG(cnd).CAT.configs.est_fitMVAR, ...
        'connectivityModeling',EEG(cnd).CAT.configs.est_mvarConnectivity, ...
        'mode',{'PhaseRand' 'nperms' NumSamples}, ...
        'autosave',[], ...
        'verb',VERBOSITY_LEVEL);
end

% Phase randomized distributions are now stored in EEG.CAT.PConn
% This is a structure containing estimates of the connectivity etc., under 
% the null hypothesis of no connectivity (random phase).
% The distributions are stored in matrices of size:
% [num_vars x num_vars x num_freqs x num_times x num_samples]

%% next we compute p-values and confidence intervals
% (CHOOSE ONE OF THE FOLLOWING)

%% 1) Between-condition test:
%     For conditions A and B, the null hypothesis is either
%     A(i,j)<=B(i,j), for a one-sided test, or
%     A(i,j)=B(i,j), for a two-sided test
%     A p-value for rejection of the null hypothesis can be
%     obtained by taking the difference of the distributions
%     computing the probability
%     that a sample from the difference distribution is non-zero
if length(EEG)<2
    error('You need two datasets to compute between-condition statistics')
end
% Note this function will return a new EEG dataset with the condition
% differences (Set A - Set B) in the order specified in datasetOrder
EEG(end+1) = pop_stat_surrogateStats(EEG,GUI_MODE, ...
                    'statTest', ...
                        {'Hab'  ...
                         'datasetOrder' sprintf('%s-%s',EEG(1).setname,EEG(2).setname) ...
                         'testMethod' 'quantile' ...
                         'tail' 'both'           ...
                         'computeci' true        ...
                         'alpha' 0.05            ...
                         'mcorrection' 'fdr'     ...
                         'statcondargs' {}},     ...
                     'connmethods',{},           ...
                     'verb',VERBOSITY_LEVEL);


% Statistics for each dynamical measure are now stored in EEG.CAT.Stats.
% The dimensionality is [num_vars x num_vars x num_freqs x num_times]


%% 2) Devation from baseline test
%     For conditions A, the null hypothesis is
%     C(i,j)=baseline_mean(C). This is a two-sided test.
%     A p-value for rejection of the null hypothesis can be
%     obtained by obtaining the distribution of the difference from
%     baseline mean and computing the probability
%     that a sample from this distribution is non-zero

BASELINE = [-1 -0.25];
for cnd=1:length(EEG)
    EEG(cnd) = pop_stat_surrogateStats(EEG(cnd),GUI_MODE, ...
                        'statTest', ...
                            {'Hbase' ...
                            'baseline' BASELINE       ...
                            'testMeans' true    ...
                            'testMethod' 'quantile' ...
                            'tail' 'both'       ...
                            'computeci' true    ...
                            'alpha' 0.05        ...
                            'mcorrection' 'fdr' ...
                            'statcondargs' {}}, ...
                        'connmethods',{},       ...
                        'verb',VERBOSITY_LEVEL);
end

% Statistics for each dynamical measure are now stored in EEG.CAT.Stats.
% The dimensionality is [num_vars x num_vars x num_freqs x num_times]


%% 3) Test for non-zero connectivity
%     We are testing with respect to a phase-randomized null
%     distribution. A p-value for rejection of the null hypothesis
%     can be obtained by computing the probability that the
%     observed connectivity is a random sample from the null distribution
for cnd=1:length(EEG)
    EEG(cnd) = pop_stat_surrogateStats(EEG(cnd),GUI_MODE, ...
                        'statTest', ...
                            {'Hnull' ...
                             'testMethod' 'quantile'    ...
                             'tail' 'right'             ...
                             'alpha' 0.05               ...
                             'mcorrection' 'fdr'        ...
                             'statcondargs' {}},        ...
                         'connmethods',{}, ...
                         'verb',VERBOSITY_LEVEL);
end

% Statistics for each dynamical measure are now stored in EEG.CAT.Stats.
% The dimensionality is [num_vars x num_vars x num_freqs x num_times]

%% OPTIONAL STEP 8b: Compute analytic statistics
% This computes analytic alpha-significance thresholds, p-values, and confidence
% intervals for select connectivity estimators (RPDC, nPDC).
% These are asymptotic estimators and may not be accurate for small sample
% sizes. However, they are very fast and usually a reasonable estimate.
for cnd=1:length(EEG)
    EEG(cnd) = pop_stat_analyticStats(EEG(cnd),GUI_MODE,    ...
                        'estimator',hlp_getConnMethodNames(EEG(cnd).CAT.Conn),   ...
                        'statistic',{'P-value' 'Threshold' 'ConfidenceInterval'},   ...
                        'alpha', 0.01,  ...
                        'genpdf',[],    ...
                        'verb',true);
end

% Statistics for each dynamical measure are now stored in EEG.CAT.Stats.
% The dimensionality is [num_vars x num_vars x num_freqs x num_times]

%% STEP 9: Visualize the Connectivity estimates in a Time-Frequency Grid

% This example plots a Time-Frequency Grid using "simple" percentile
% statistics (this doesn't use the rigorous stats returned by
% stat_surrogateStats).

% For a single condition, we call pop_vis_TimeFreqGrid(EEG(cnd),...)
% If we want to compare two conditions we can either use the dataset
% returned by pop_stat_surrogateStat() with the 'Hab' statistics mode 
% OR we can compare set1-set2 by calling 
% pop_vis_TimeFreqGrid(EEG([set1 set2]), ... ) where set1,set2 are the 
% indices of the datasets we want to compare.
EEG(end) = pop_vis_TimeFreqGrid(EEG(end),GUI_MODE, ...
                        'plotCondDiff',false,   ...
                        'vismode','TimeXFrequency', ...
                        'MatrixLayout', ...
                            {'Partial' ...
                             'triu' 'dDTF08' 'ut_clim' 100 ...
                             'tril' 'dDTF08' 'lt_clim' 100 ...
                             'diag' 'S' 'd_clim' 100   ...
                             'clim' 99.7},  ...
                         'clim',100,        ...
                         'timeRange',[],    ...
                         'freqValues',[1:40],   ...
                         'windows',[],      ...
                         'pcontour',[],     ...
                         'thresholding',    ...
                            {'Simple'       ...
                            'prcthresh' [97.5 3]  ...
                            'absthresh' []},    ...
                        'baseline',[-1 -0.25] , ...
                        'fighandles',[],        ...
                        'smooth',false,         ...
                        'xord',[],'yord',[],    ...
                        'plotorder',[],         ...
                        'topoplot','dipole',    ...
                        'topoplot_opts',{},     ...
                        'customTopoMatrix',[],  ...
                        'dipplot',  ...
                            {'mri' '' 'coordformat' 'mni' 'dipplotopt' {}}, ...
                        'nodelabels',ComponentNames,        ...
                        'foilines',[3 7 15],    ...
                        'foilinecolor',[0.7 0.7 0.7] ,  ...
                        'events',{{0 'r' ':' 2}},       ...
                        'freqscale','linear',           ...
                        'transform','linear',           ...
                        'yTickLoc','right',             ...
                        'titleString','',               ...
                        'titleFontSize',12,             ...
                        'axesFontSize',11,              ...
                        'textColor',[1 1 1] ,           ...
                        'linecolor',[1 1 1] ,           ...
                        'patchcolor',[1 1 1] ,          ...
                        'colormap',jet(64),             ...
                        'backgroundColor',[0 0 0]);



%% ... Or if stats are present we can use those 
EEG(end) = pop_vis_TimeFreqGrid(EEG(end), GUI_MODE, ...
                        'MatrixLayout', ...
                            {'Partial', ...
                             'UpperTriangle', 'dDTF08', ...
                             'LowerTriangle','dDTF08','Diagonal','S'},  ...
                        'ColorLimits',99.9,        ...
                        'FrequencyScale','linear', ...
                        'Baseline',[],             ...
                        'Smooth2D',false,          ...
                        'Thresholding',        ...
                            {'Statistics',      ...
                            'ThresholdingMethod','pval',    ...
                            'PlotConfidenceIntervals',true},...
                        'BackgroundColor',[0 0 0],  ...
                        'TextColor',[1 1 1],    ...
                        'LineColor',[1 1 1]);


%% STEP 10: Visualize the Connectivity estimates in a 3D Brain-Movie
pop_vis_causalBrainMovie3D(EEG(end),GUI_MODE,'stats',[],'connmethod','dDTF08','timeRange',[] ,'freqsToCollapse',[1:40] ,'collapsefun','max','resample',0,'subtractconds',false,'showNodeLabels',{'nodelabels' ComponentNames'},'nodesToExclude',{},'edgeColorMapping','PeakFreq','edgeSizeMapping','Connectivity','nodeColorMapping','Outflow','nodeSizeMapping','Power','baseline',[],'normalize',true,'useStats',[],'prcthresh',0.05,'absthresh',[],'footerPanelSpec',{'ICA_ERPenvelope' 'plottingmode' {'all' 'envelope'} 'envColor' [1 0 0] },'BMopts',{'size' [800 800]  'visible' 'on' 'latency' [] 'frames' [] 'figurehandle' [] 'cameraMenu' false 'rotationpath3d' {'AngleFactor' 1 'PhaseFactor' 0.75 'FramesPerCycle' []} 'view' [122 36]  'makeCompass' true 'project3d' 'off' 'theme' {'theme' 'classic'} 'Layers' {'scalp' {'scalpres' 'high' 'volumefile' [] 'scalptrans' 0.9 'scalpcolor' [1 0.75 0.65] } 'skull' [] 'csf' [] 'cortex' {'cortexres' 'mid' 'volumefile' [] 'cortextrans' 0.9 'cortexcolor' {'LONI_Atlas' 'colormapping' {'jet'}}} 'custom' []} 'facelighting' 'phong' 'opengl' 'on' 'events' {{0 'r' ':' 2}} 'flashEvents' false 'square' 'on' 'caption' true 'displayLegendLimitText' true 'showLatency' true 'dispRT' false 'backcolor' [0 0 0]  'graphColorAndScaling' {'nodeSizeLimits' [0.1 1]  'nodeColorLimits' [0 1]  'edgeSizeLimits' [0.1 0.8]  'edgeColorLimits' [0 1]  'nodeSizeDataRange' [] 'nodeColorDataRange' [] 'edgeSizeDataRange' [] 'edgeColorDataRange' [] 'centerDataRange' false 'edgeColormap' jet(64) 'diskscale' 0.2 'magnify' 1} 'outputFormat' {'framefolder' '' 'framesout' 'jpg' 'moviename' '' 'movieopts' {'videoname' ''} 'size' []} 'mri' 'standard_BEM_mri.mat' 'plotimgs' false 'coordformat' 'spherical' 'dipplotopt' {} 'bmopts_suppl' {} 'renderBrainMovie' true 'speedy' false 'mode' 'init_and_render' 'vars' []});


