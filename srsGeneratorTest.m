clc;
clearvars;
close all;

%  ** Creating a nr carrier object
carrierConfig = getCarrierConfig();

%  ** Creating the SRS DUT object
srsDesigned = srsGenerator();

%  ** Creating a reference SRS object
srsReferenceConfig = nrSRSConfig();

%  ** SRS parameters
srsTestStruct.carrierSlots = 0:19;
srsTestStruct.srsAntennaPorts = 0:2;
srsTestStruct.srsSymbols = 0:2;
srsTestStruct.srsConfigIndex = 0:1;
srsTestStruct.srsBandwidthIndex = 0:3;
srsTestStruct.srsCombSize = 0:1;
srsTestStruct.srsGroupOrSequenceHopping = 0:2;

%  ** SRS testing
fprintf("SRS testing started\n");
for eachCarrierSlot = srsTestStruct.carrierSlots
    carrierConfig.NSlot = eachCarrierSlot;
    srsTestStruct.srsSequenceID = randi([0, 65535], 1, 10);

    for eachSequenceID = srsTestStruct.srsSequenceID
        fprintf("\t|-> Testing for sequence ID = %d\n", eachSequenceID);

        srsDesigned.sequenceID = eachSequenceID;
        srsReferenceConfig.NSRSID = eachSequenceID;

        for eachAntennaPorts = srsTestStruct.srsAntennaPorts
            srsDesigned.numAntPorts = eachAntennaPorts;
            srsReferenceConfig.NumSRSPorts = 2^eachAntennaPorts;

            for eachSRSSymbols = srsTestStruct.srsSymbols
                carrierConfigBdcast = carrierConfig;
                srsDesignedBdcast = srsDesigned;
                srsReferenceConfigBdcast = srsReferencw
                srsTestStructBdcast = srsTestStruct;
                srsEachSymbol(srsDesignedBdcast, srsReferenceConfigBdcast, eachSRSSymbols, srsTestStructBdcast, carrierConfigBdcast);
            end
        end
    end
    fprintf("\t\t|-> Finished for carrier slot = %d\n", eachCarrierSlot);
end

%  ** Carrier config function
function carrierConfig = getCarrierConfig()
    carrierConfig = nrCarrierConfig();
    carrierConfig.NSizeGrid = 273;
    carrierConfig.SubcarrierSpacing = 30;
    carrierConfig.CyclicPrefix = "Normal";
    carrierConfig.NCellID = 0;
end

%  ** srs testing
function srsEachSymbol(srsDesigned, srsReferenceConfig, eachSRSSymbols, srsTestStruct, carrierConfig)
    srsDesigned.numSymbols = eachSRSSymbols;
    srsReferenceConfig.NumSRSSymbols = 2^eachSRSSymbols;

    srsStartingPosition = 8:14-2^(eachSRSSymbols);

    for eachStartingPosition = srsStartingPosition
        srsDesigned.timeStartPosition = eachStartingPosition;
        srsReferenceConfig.SymbolStart = eachStartingPosition;

        for eachBandwidthIndex = srsTestStruct.srsBandwidthIndex
            srsDesigned.bandwidthIndex = eachBandwidthIndex;
            srsReferenceConfig.BSRS = eachBandwidthIndex;

            for eachCombSize = srsTestStruct.srsCombSize
                srsDesigned.combSize = eachCombSize;
                srsReferenceConfig.KTC = 2^(eachCombSize+1);

                switch(eachCombSize)
                    case 0
                        srsCyclicShift = 0:7;

                    case 1
                        srsCyclicShift = 0:11;
                end

                for eachCyclicShift = srsCyclicShift
                    srsDesigned.cyclicShift = eachCyclicShift;
                    srsReferenceConfig.CyclicShift = eachCyclicShift;

                    for eachConfigIndex = srsTestStruct.srsConfigIndex
                        srsDesigned.configIndex = eachConfigIndex;
                        srsReferenceConfig.CSRS = eachConfigIndex;

                        for eachHoppingCfg = srsTestStruct.srsGroupOrSequenceHopping
                            srsDesigned.groupOrSequenceHopping = eachHoppingCfg;

                            switch(eachHoppingCfg)
                                case 0
                                    srsReferenceConfig.GroupSeqHopping = 'neither';
                                case 1
                                    srsReferenceConfig.GroupSeqHopping = 'groupHopping';
                                case 2
                                    srsReferenceConfig.GroupSeqHopping = 'sequenceHopping';
                            end

                            srsRefSymbolsTemp = nrSRS(carrierConfig, srsReferenceConfig);
                            srsSequence = getSRSSequence(srsDesigned, carrierConfig.NSlot);

                            srsRefSymbols = complex(zeros(size(srsSequence)));

                            for eachAntPort = 1:srsReferenceConfig.NumSRSPorts
                                srsRefSymbols(:, :, eachAntPort) = reshape(srsRefSymbolsTemp(:, eachAntPort), [], size(srsSequence, 2));
                            end

                            if(srsSequence ~= srsRefSymbols)
                                error("TestCase Failed\n");
                            end
                        end
                    end
                end
            end
        end
    end
end
