classdef srsEstimator
    properties
        snrdB (1, 1) double
        srs_config (1, 1) nrSRSConfig
        carrier_config (1, 1) nrCarrierConfig
        channel_config (1, 1) nrTDLChannel
        simulation_outputs (1, 1) struct
    end

    properties (SetAccess=protected, GetAccess=public)
        simulation_struct (1, 1) struct
    end

    properties (Dependent)
        carrier_info
    end

    methods
        function carrier_info = get.carrier_info(obj)
            carrier_info = nrOFDMInfo(obj.carrier_config);
        end
    end

    methods
        function obj = run_simulation(obj)
            obj = calculate_max_tx_channel_delay(obj);

            obj = init_ul_chain(obj);

            obj.simulation_struct.tx_grid = nrResourceGrid(obj.carrier_config, obj.channel_config.NumTransmitAntennas);

            [obj.simulation_struct.ref_srs, obj.simulation_outputs.srs_info] = nrSRS(obj.carrier_config, obj.srs_config);
            obj.simulation_outputs.srs_info.num_ports = obj.srs_config.NumSRSPorts;

            [obj.simulation_struct.srs_indices, ~] = nrSRSIndices(obj.carrier_config, obj.srs_config);
            [~, obj.simulation_struct.srs_ant_indices] = nrExtractResources(obj.simulation_struct.srs_indices, obj.simulation_struct.tx_grid);

            obj.simulation_struct.tx_grid(obj.simulation_struct.srs_ant_indices) = obj.simulation_struct.ref_srs;
            obj.simulation_struct.tx_ofdm_signal = nrOFDMModulate(obj.carrier_config, obj.simulation_struct.tx_grid);
            obj.simulation_struct.pad_zeros = zeros(obj.simulation_struct.max_tx_channel_delay, size(obj.simulation_struct.tx_ofdm_signal, 2));
            obj.simulation_struct.tx_waveform = [obj.simulation_struct.tx_ofdm_signal; obj.simulation_struct.pad_zeros];

            [obj.simulation_struct.rx_waveform, ~, ~] = obj.channel_config(obj.simulation_struct.tx_waveform);
            obj.simulation_struct.snr = 10^(0.1 * obj.snrdB);

            obj.simulation_struct.noise_norm_factor = obj.channel_config.NumReceiveAntennas * double(obj.carrier_info.Nfft) * obj.simulation_struct.snr;
            obj.simulation_struct.N0 = 1/sqrt(2 * obj.simulation_struct.noise_norm_factor);
            obj.simulation_struct.noise_samples = complex(randn(size(obj.simulation_struct.rx_waveform)), randn(size(obj.simulation_struct.rx_waveform)));
            obj.simulation_struct.noise = obj.simulation_struct.N0 * obj.simulation_struct.noise_samples;

            obj.simulation_struct.rx_waveform = obj.simulation_struct.rx_waveform + obj.simulation_struct.noise;

            [obj.simulation_struct.timing_est, obj.simulation_struct.corr_mag] ...
                = nrTimingEstimate(obj.carrier_config, obj.simulation_struct.rx_waveform, obj.simulation_struct.srs_indices, obj.simulation_struct.ref_srs);

            obj.simulation_struct.sync_offset = hSkipWeakTimingOffset(obj.simulation_struct.sync_offset, obj.simulation_struct.timing_est, obj.simulation_struct.corr_mag);
            if(obj.simulation_struct.sync_offset > obj.simulation_struct.max_tx_channel_delay)
                warning(['Estimated timing offset (%d) is greater than the maximum channel delay (%d). This will result in a decoding '...
                'failure. This may be caused by low SNR, or not enough SRS symbols to synchronize successfully.']           , ...
                obj.simulation_struct.sync_offset, obj.simulation_struct.max_tx_channel_delay);
            end

            obj.simulation_struct.rx_ofdm_signal = obj.simulation_struct.rx_waveform(1 + obj.simulation_struct.sync_offset:end, :);
            obj.simulation_struct.rx_grid = nrOFDMDemodulate(obj.carrier_config, obj.simulation_struct.rx_ofdm_signal);

            obj.simulation_struct.rx_srs = zeros(size(obj.simulation_struct.srs_indices, 1), obj.channel_config.NumReceiveAntennas);

            for each_rx_ant = 1:obj.channel_config.NumReceiveAntennas
                obj.simulation_struct.each_rx_grid = obj.simulation_struct.rx_grid(:, :, each_rx_ant);
                obj.simulation_struct.rx_srs(:, each_rx_ant) = obj.simulation_struct.each_rx_grid(obj.simulation_struct.srs_indices(:, 1));
            end

            obj.simulation_outputs.recvd_srs = obj.simulation_struct.rx_srs;
            obj.simulation_struct.rx_srs = obj.simulation_struct.rx_srs.';
            obj.simulation_struct.rx_srs = reshape(obj.simulation_struct.rx_srs, obj.channel_config.NumReceiveAntennas, 12, []);

            obj.simulation_struct.ref_srs = pagetranspose(reshape(obj.simulation_struct.ref_srs.', obj.srs_config.NumSRSPorts, 12, []));
            obj.simulation_struct.srs_estimates_temp = pagemtimes(obj.simulation_struct.rx_srs, conj(obj.simulation_struct.ref_srs)) / 12;

            obj.simulation_outputs.srs_estimates = reshape(obj.simulation_struct.srs_estimates_temp, obj.channel_config.NumReceiveAntennas, []);
            obj.simulation_outputs.srs_estimates = obj.simulation_outputs.srs_estimates.';
        end

        function obj = calculate_max_tx_channel_delay(obj)
            tx_channel_info = info(obj.channel_config);
            obj.simulation_struct.max_tx_channel_delay = ceil(max(tx_channel_info.PathDelays * obj.channel_config.SampleRate)) + tx_channel_info.ChannelFilterDelay;
        end

        function obj = init_ul_chain(obj)
            rng('default');
            reset(obj.channel_config);
            obj.simulation_struct.sync_offset = 0;
        end
    end
end
