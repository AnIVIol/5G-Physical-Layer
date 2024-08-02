clc;
clearvars;
close all;

%  ** Creating the SRS DUT object
srsDesigned = srsGenerator();

srsDesigned.numAntPorts = 2;
srsDesigned.configIndex = 63;
srsDesigned.combSize = 0;
srsDesigned.cyclicShift = 7;

[srs_configs, srs_sequence] = srsDesigned.getSRSSequenceTest(29, 0);
srs_configs_tlast = zeros(size(srs_configs));
srs_configs_tlast(end) = 1;

write_mode = "overwrite";
writematrix(srs_configs, "../simulation_codes/test_files/srs_configs.txt", "WriteMode", write_mode);
writematrix(srs_configs_tlast, "../simulation_codes/test_files/srs_configs_tlast.txt", "WriteMode", write_mode);
writematrix(srs_sequence, "../simulation_codes/test_files/srs_sequence.txt", "WriteMode", write_mode);


srsDesigned.numAntPorts = 0;
srsDesigned.configIndex = 63;
srsDesigned.combSize = 1;
srsDesigned.cyclicShift = 5;

[srs_configs, srs_sequence] = srsDesigned.getSRSSequenceTest(29, 0);
srs_configs_tlast = zeros(size(srs_configs));
srs_configs_tlast(end) = 1;

write_mode = "append";
writematrix(srs_configs, "../simulation_codes/test_files/srs_configs.txt", "WriteMode", write_mode);
writematrix(srs_configs_tlast, "../simulation_codes/test_files/srs_configs_tlast.txt", "WriteMode", write_mode);
writematrix(srs_sequence, "../simulation_codes/test_files/srs_sequence.txt", "WriteMode", write_mode);

srsDesigned.numAntPorts = 2;
srsDesigned.configIndex = 0;
srsDesigned.combSize = 1;
srsDesigned.cyclicShift = 5;

[srs_configs, srs_sequence] = srsDesigned.getSRSSequenceTest(29, 0);
srs_configs_tlast = zeros(size(srs_configs));
srs_configs_tlast(end) = 1;

write_mode = "append";
writematrix(srs_configs, "../simulation_codes/test_files/srs_configs.txt", "WriteMode", write_mode);
writematrix(srs_configs_tlast, "../simulation_codes/test_files/srs_configs_tlast.txt", "WriteMode", write_mode);
writematrix(srs_sequence, "../simulation_codes/test_files/srs_sequence.txt", "WriteMode", write_mode);