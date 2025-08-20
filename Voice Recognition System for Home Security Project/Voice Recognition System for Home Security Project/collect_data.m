function [dataTable, meta] = collect_data(cfg)
% Record or load voice samples for each user, command, condition.
% For demo, this uses audiorecorder to capture small dataset.
% Replace with dataset loading as needed.

fs = cfg.fs;
dur = cfg.sampleDurationSec;
N = cfg.samplesPerUserPerCommand;

userId = [];
commandId = [];
condition = strings(0);
audio = {};
fsCol = [];

fprintf('Starting data collection...\n');
for u = cfg.userIds
    for c = 1:cfg.numCommands
        for cond = cfg.conditions
            for n = 1:(N/numel(cfg.conditions))
                prompt = sprintf('User %d | Command "%s" | Condition %s -> press Enter to record...', ...
                    u, cfg.commands(c), cond);
                input(prompt,'s');

                recObj = audiorecorder(fs, 16, 1);
                disp('Recording...');
                recordblocking(recObj, dur);
                disp('Done.');
                x = getaudiodata(recObj);

                % simulate noise for "noisy" condition if actual environment is quiet
                if cond == "noisy"
                    x = x + 0.01*randn(size(x));
                end

                userId(end+1,1) = u;
                commandId(end+1,1) = c;
                condition(end+1,1) = cond;
                audio{end+1,1} = x;
                fsCol(end+1,1) = fs;
            end
        end
    end
end

dataTable = table(userId, commandId, condition, fsCol, audio, ...
    'VariableNames', {'userId','commandId','condition','fs','audio'});

meta.timestamp = datetime();
meta.fs = fs;
meta.users = cfg.userIds;
meta.commands = cfg.commands;

end
