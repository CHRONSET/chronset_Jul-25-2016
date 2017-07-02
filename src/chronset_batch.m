%Usage after compile:
% % ./run_chronset_batch.sh <MCRDEPLOY_ROOT> <dir with input wavs> <outfile> 
%
% e.g.,
% ./run_chronset_batch.sh /opt/matlab/MATLAB_Compiler_Runtime/v80/ ~/barmstrong/Chronset_input/ chronOut_test.txt



function chronset_batch(input_folder,output_file)

%write any errors to output_file rather than dying quietly


nWorkers = 1; % number of parallel workers


%% Load Optimized Thresholds %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load(['.',filesep,'thresholds',filesep,'greedy_optim_thresholds_BCN_final.mat']);
%%
[thresh] = chronset_extract_thresholds(optim_data);



%% Process Individual Wavs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
    fileList = dir(input_folder);
    nf = length(fileList);
    rts = cell(nf,1);

    %matlabpool(nWorkers);

    %start at ind = 3 to avoid . and .. on the search path
    %parfor i = 3:nf
    for i = 3:nf
        disp(['File name being processed: ' fileList(i).name]);

        in = struct;
        try
            [in.wav,in.FS] = wavread2([input_folder '/' fileList(i).name]);
        catch ME
            [in.wav,in.Fs] = audioread([input_folder '/' fileList(i).name]);
        end
    
            
        %[in.wav,in.FS] = wavread2([input_folder '/' fileList(i).name]);
        in.wav = in.wav(:,1);
        [feat_data] = compute_feat_data([],in);
        [on] = detect_speech_on_and_offset(feat_data,[thresh' {0.035} {4} {0.25}]);

        rts(i) = {[fileList(i).name, '	', num2str(round(on))]};

    end;

    %matlabpool close;
catch ME
    
    msgString = getReport(ME);
    rts = cell(3,1);
    rts(3) = {msgString};
    
end;

%% Saving Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Writing results to file:');

disp(output_file);


fid = fopen(output_file,'w+');

nrows = size(rts);
formatSpec = '%s\n';

%b/c ind = 3 used in processing individual wavs
for row = 3:nrows
	fprintf(fid,formatSpec,rts{row,:});
end

fclose(fid);