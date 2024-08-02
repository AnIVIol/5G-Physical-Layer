clc;
clearvars;
close all;

srs_estimator = srsEstimator;

srs_estimator.snrdB = 5;

srs_estimator.srs_config.NumSRSPorts = 4;
srs_estimator.srs_config.NumSRSSymbols = 1;
srs_estimator.srs_config.SymbolStart = 13;
srs_estimator.srs_config.KTC = 2;
srs_estimator.srs_config.KBarTC = 0;
srs_estimator.srs_config.CyclicShift = 0;
srs_estimator.srs_config.FrequencyStart = 0;
srs_estimator.srs_config.NRRC = 0;
srs_estimator.srs_config.CSRS = 63;
srs_estimator.srs_config.BSRS = 0;
srs_estimator.srs_config.BHop = 0;
srs_estimator.srs_config.Repetition = 1;
srs_estimator.srs_config.SRSPeriod = 'on';
srs_estimator.srs_config.ResourceType = 'periodic';
srs_estimator.srs_config.GroupSeqHopping = "neither";
srs_estimator.srs_config.NSRSID = 0;

srs_estimator.carrier_config.NSizeGrid = 273;
srs_estimator.carrier_config.SubcarrierSpacing = 30;
srs_estimator.carrier_config.CyclicPrefix = "normal";
srs_estimator.carrier_config.NCellID = 0;
srs_estimator.carrier_config.NSlot = 5;

srs_estimator.channel_config = nrTDLChannel;
srs_estimator.channel_config.DelayProfile = "TDL-C";
srs_estimator.channel_config.TransmissionDirection = "Uplink";
srs_estimator.channel_config.NumTransmitAntennas = srs_estimator.srs_config.NumSRSPorts;
srs_estimator.channel_config.NumReceiveAntennas = 16;
srs_estimator.channel_config.DelaySpread = 300e-9;
srs_estimator.channel_config.MaximumDopplerShift = 0;

srs_estimator = srs_estimator.run_simulation();

srs_recvd_values = string(zeros(size(srs_estimator.simulation_outputs.recvd_srs)));

for each_index = 1:size(srs_recvd_values, 2)
    imag_values = string(dec2hex(floor(imag(srs_estimator.simulation_outputs.recvd_srs(:, each_index)) * 2^13)));
    real_values = string(dec2hex(floor(real(srs_estimator.simulation_outputs.recvd_srs(:, each_index)) * 2^13)));
    srs_recvd_values(:, each_index) = "0x" + imag_values + real_values;
end

srs_estimate_values = string(zeros(size(srs_estimator.simulation_outputs.srs_estimates)));

for each_index = 1:size(srs_estimate_values, 2)
    imag_values = string(dec2hex(floor(imag(srs_estimator.simulation_outputs.srs_estimates(:, each_index)) * 2^13)));
    real_values = string(dec2hex(floor(real(srs_estimator.simulation_outputs.srs_estimates(:, each_index)) * 2^13)));
    srs_estimate_values(:, each_index) = "0x" + imag_values + real_values;
end

srs_designed = srsGenerator();

srs_designed.numAntPorts = log2(srs_estimator.srs_config.NumSRSPorts);
srs_designed.configIndex = srs_estimator.srs_config.CSRS;
srs_designed.combSize = log2(srs_estimator.srs_config.KTC);
srs_designed.cyclicShift = srs_estimator.srs_config.CyclicShift;

[srs_configs, ~] = srs_designed.getSRSSequenceTest(srs_estimator.simulation_outputs.srs_info.SeqGroup, srs_estimator.simulation_outputs.srs_info.NSeq);

writematrix(srs_recvd_values, "../simulation_codes/test_files/srs_recvd_values.txt", "WriteMode", "overwrite");
writematrix(srs_estimate_values, "../simulation_codes/test_files/srs_estimates.txt", "WriteMode", "overwrite");
writematrix(srs_configs, "../simulation_codes/test_files/srs_configs.txt", "WriteMode", "overwrite");