%% Auditory hMT localizer using translational motion in four directions
%  (up- down- left and right-ward)

% by Mohamed Rezk 2018
% adapted by MarcoB and RemiG 2020

%%

getOnlyPress = 1;

more off;

% Clear all the previous stuff
% clc; clear;
if ~ismac
    close all;
    clear Screen;
end

% make sure we got access to all the required functions and inputs
initEnv();

% set and load all the parameters to run the experiment
cfg = setParameters;
cfg = userInputs(cfg);
cfg = createFilename(cfg);

%%  Experiment

% Safety loop: close the screen if code crashes
try

    %% Init the experiment
    [cfg] = initPTB(cfg);

    % % % REFACTOR THIS FUNCTION % % %

    [cfg] = loadAudioFiles(cfg);

    % % % REFACTOR THIS FUNCTION % % %

    [el] = eyeTracker('Calibration', cfg);

    % % % REFACTOR THIS FUNCTION % % %

    [cfg] = expDesign(cfg);

    % % % REFACTOR THIS FUNCTION % % %

    % Prepare for the output logfiles with all
    logFile.extraColumns = cfg.extraColumns;
    logFile = saveEventsFile('open', cfg, logFile);

    disp(cfg);

    % Show experiment instruction
    standByScreen(cfg);

    % prepare the KbQueue to collect responses
    getResponse('init', cfg.keyboard.responseBox, cfg);

    % Wait for Trigger from Scanner
    waitForTrigger(cfg);

    %% Experiment Start
    cfg = getExperimentStart(cfg);

    getResponse('start', cfg.keyboard.responseBox);

    WaitSecs(cfg.timing.onsetDelay);

    %% For Each Block

    for iBlock = 1:cfg.numBlocks

        fprintf('\n - Running Block %.0f \n', iBlock);

        eyeTracker('StartRecording', cfg);

        % For each event in the block
        for iEvent = 1:cfg.numEventsPerBlock

            % Check for experiment abortion from operator
            checkAbort(cfg, cfg.keyboard.keyboard);

            % set direction, speed of that event and if it is a target
            thisEvent.trial_type = cfg.design.blockNames{iBlock};
            thisEvent.direction = cfg.design.directions(iBlock, iEvent);
            % thisEvent.speed = cfg.design.speeds(iBlock, iEvent);
            thisEvent.target = cfg.design.fixationTargets(iBlock, iEvent);

            % % % REFACTOR THIS FUNCTION % % %

            % play the sounds and collect onset and duration of the event
            [onset, duration] = doAudMot(cfg, thisEvent);

            % % % REFACTOR THIS FUNCTION % % %

            thisEvent.event = iEvent;
            thisEvent.block = iBlock;
            thisEvent.keyName = 'n/a';
            thisEvent.duration = duration;
            thisEvent.onset = onset - cfg.experimentStart;

            % Save the events txt logfile
            % we save event by event so we clear this variable every loop
            thisEvent.fileID = logFile.fileID;
            thisEvent.extraColumns = logFile.extraColumns;

            saveEventsFile('save', cfg, thisEvent);

            clear thisEvent;

            % collect the responses and appends to the event structure for
            % saving in the tsv file
            responseEvents = getResponse('check', cfg.keyboard.responseBox, cfg, ...
                getOnlyPress);

            triggerString = ['trigger_' cfg.design.blockNames{iBlock}];
            saveResponsesAndTriggers(responseEvents, cfg, logFile, triggerString);

            % wait for the inter-stimulus interval
            WaitSecs(cfg.timing.ISI);

        end

        eyeTracker('StopRecordings', cfg);

        WaitSecs(cfg.timing.IBI);

        % trigger monitoring
        triggerEvents = getResponse('check', cfg.keyboard.responseBox, cfg, ...
            getOnlyPress);

        triggerString = 'trigger_baseline';
        saveResponsesAndTriggers(triggerEvents, cfg, logFile, triggerString);

    end

    % End of the run for the BOLD to go down
    WaitSecs(cfg.timing.endDelay);

    cfg = getExperimentEnd(cfg);

    % Close the logfiles
    saveEventsFile('close', cfg, logFile);

    getResponse('stop', cfg.keyboard.responseBox);
    getResponse('release', cfg.keyboard.responseBox);

    eyeTracker('Shutdown', cfg);

    createBoldJson(cfg, cfg);

    farewellScreen(cfg);

    cleanUp();

catch

    cleanUp();
    psychrethrow(psychlasterror);

end