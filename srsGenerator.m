classdef srsGenerator <  matlab.mixin.CustomDisplay
    properties
        %  ** SRS PDU parameters according to FAPI

        %  ** Number of SRS ports:
        %   ** 0: 1 port
        %   ** 1: 2 ports
        %   ** 2: 4 ports
        numAntPorts (1, 1) double {mustBeMember(numAntPorts, 0:2)} = 0

        %  ** Number of SRS symbols
        %   ** 0: 1 symbol
        %   ** 1: 2 symbols
        %   ** 2: 4 symbols
        numSymbols  (1, 1) double {mustBeMember(numSymbols, 0:2)} = 0

        %  ** Repetition factor
        %   ** 0: 1
        %   ** 1: 2
        %   ** 2: 4
        numRepetitions (1, 1) double {mustBeMember(numRepetitions, 0:2)} = 0

        %  ** Starting position in time domain 8 -> 13
        timeStartPosition (1, 1) double {mustBeMember(timeStartPosition, 8:13)} = 13

        %  ** SRS bandwidth config index 0 -> 63
        configIndex (1, 1) double {mustBeMember(configIndex, 0:63)} = 0

        %  ** SRS sequence ID 0 -> 65535
        sequenceID (1, 1) double {mustBeMember(sequenceID, 0:65535)} = 0

        %  ** SRS bandwidth index 0 -> 3
        bandwidthIndex (1, 1) double {mustBeMember(bandwidthIndex, 0:3)} = 0

        %  ** Transmission comb size
        %   ** 0: comb size 2
        %   ** 1: comb size 4
        combSize (1, 1) double {mustBeMember(combSize, 0:1)} = 0

        %  ** Transmission comb offset
        %   ** 0 -> 1 (combSize = 0)
        %   ** 0 -> 3 (combSize = 1)
        combOffset (1, 1) double {mustBeMember(combOffset, 0:3)} = 0

        %  ** Cyclic shift
        %   ** 0 -> 7 (combSize = 0)
        %   ** 0 -> 11 (combSize = 1)
        cyclicShift (1, 1) double {mustBeMember(cyclicShift, 0:11)} = 0

        %  ** Frequency domain position 0 -> 67
        frequencyPosition (1, 1) double {mustBeMember(frequencyPosition, 0:67)} = 0

        %  ** Frequency domain shift 0 -> 268
        frequencyShift (1, 1) double {mustBeMember(frequencyShift, 0:268)} = 0

        %  ** Frequency hopping 0 -> 3
        frequencyHopping (1, 1) double {mustBeMember(frequencyHopping, 0:3)} = 0

        %  ** Group or sequence hopping configuration
        %   ** 0: No hopping
        %   ** 1: Group hopping
        %   ** 2: Sequence hopping
        groupOrSequenceHopping (1, 1) double {mustBeMember(groupOrSequenceHopping, 0:2)} = 0

        %  ** Type of SRS resource allocation
        %   ** 0: aperiodic
        %   ** 1: semi-persistent
        %   ** 2: periodic
        resourceType (1, 1) double {mustBeMember(resourceType, 0:2)} = 0

        %  ** SRS-Periodicity in slots (1, 2, 3, 4, 5, 8, 10, 16, 20, 32, 40, 64, 80, 160, 320, 640, 1280, 2560)
        Tsrs (1, 1) double {mustBeMember(Tsrs, [1, 2, 3, 4, 5, 8, 10, 16, 20, 32, 40, 64, 80, 160, 320, 640, 1280, 2560])} = 1

        %  ** Slot offset value 0 -> 2559
        Toffset (1, 1) double {mustBeMember(Toffset, 0:2559)} = 0
    end

    properties(SetAccess = protected, GetAccess = public)
        sequenceNumber (1, 1) double {mustBeMember(sequenceNumber, 0:1)} = 0
        groupNumber (1, 1) double {mustBeMember(groupNumber, 0:29)} = 0
    end 

    properties (Dependent)
        srsAntPortNum
        alphaValues
        mSRS
        sequenceLength
    end

    properties (Access = protected, Constant)
        mSRS0_array = nrSRSConfig.BandwidthConfigurationTable.m_SRS_0
        mSRS1_array = nrSRSConfig.BandwidthConfigurationTable.m_SRS_1
        mSRS2_array = nrSRSConfig.BandwidthConfigurationTable.m_SRS_2
        mSRS3_array = nrSRSConfig.BandwidthConfigurationTable.m_SRS_3
        N0SRS_array = nrSRSConfig.BandwidthConfigurationTable.N_0
        N1SRS_array = nrSRSConfig.BandwidthConfigurationTable.N_1
        N2SRS_array = nrSRSConfig.BandwidthConfigurationTable.N_2
        N3SRS_array = nrSRSConfig.BandwidthConfigurationTable.N_3
    end

    properties (Access = protected, Constant)
        phiTableForLen6 = [-3  -1   3   3  -1  -3; ...
                           -3   3  -1  -1   3  -3; ...
                           -3  -3  -3   3   1  -3; ...
                            1   1   1   3  -1  -3; ...
                            1   1   1  -3  -1   3; ...
                           -3   1  -1  -3  -3  -3; ...
                           -3   1   3  -3  -3  -3; ...
                           -3  -1   1  -3   1  -1; ...
                           -3  -1  -3   1  -3  -3; ...
                           -3  -3   1  -3   3  -3; ...
                           -3   1   3   1  -3  -3; ...
                           -3  -1  -3   1   1  -3; ...
                            1   1   3  -1  -3   3; ...
                            1   1   3   3  -1   3; ...
                            1   1   1  -3   3  -1; ...
                            1   1   1  -1   3  -3; ...
                           -3  -1  -1  -1   3  -1; ...
                           -3  -3  -1   1  -1  -3; ...
                           -3  -3  -3   1  -3  -1; ...
                           -3   1   1  -3  -1  -3; ...
                           -3   3  -3   1   1  -3; ...
                           -3   1  -3  -3  -3  -1; ...
                            1   1  -3   3   1   3; ...
                            1   1  -3  -3   1  -3; ...
                            1   1   3  -1   3   3; ...
                            1   1  -3   1   3   3; ...
                            1   1  -1  -1   3  -1; ...
                            1   1  -1   3  -1  -1; ...
                            1   1  -1   3  -3  -1; ...
                            1   1  -3   1  -1  -1];

        phiTableForLen12 = [-3   1  -3  -3  -3   3  -3  -1   1   1   1  -3; ...
                            -3   3   1  -3   1   3  -1  -1   1   3   3   3; ...
                            -3   3   3   1  -3   3  -1   1   3  -3   3  -3; ...
                            -3  -3  -1   3   3   3  -3   3  -3   1  -1  -3; ...
                            -3  -1  -1   1   3   1   1  -1   1  -1  -3   1; ...
                            -3  -3   3   1  -3  -3  -3  -1   3  -1   1   3; ...
                             1  -1   3  -1  -1  -1  -3  -1   1   1   1  -3; ...
                            -1  -3   3  -1  -3  -3  -3  -1   1  -1   1  -3; ...
                            -3  -1   3   1  -3  -1  -3   3   1   3   3   1; ...
                            -3  -1  -1  -3  -3  -1  -3   3   1   3  -1  -3; ...
                            -3   3  -3   3   3  -3  -1  -1   3   3   1  -3; ...
                            -3  -1  -3  -1  -1  -3   3   3  -1  -1   1  -3; ...
                            -3  -1   3  -3  -3  -1  -3   1  -1  -3   3   3; ...
                            -3   1  -1  -1   3   3  -3  -1  -1  -3  -1  -3; ...
                             1   3  -3   1   3   3   3   1  -1   1  -1   3; ...
                            -3   1   3  -1  -1  -3  -3  -1  -1   3   1  -3; ...
                            -1  -1  -1  -1   1  -3  -1   3   3  -1  -3   1; ...
                            -1   1   1  -1   1   3   3  -1  -1  -3   1  -3; ...
                            -3   1   3   3  -1  -1  -3   3   3  -3   3  -3; ...
                            -3  -3   3  -3  -1   3   3   3  -1  -3   1  -3; ...
                             3   1   3   1   3  -3  -1   1   3   1  -1  -3; ...
                            -3   3   1   3  -3   1   1   1   1   3  -3   3; ...
                            -3   3   3   3  -1  -3  -3  -1  -3   1   3  -3; ...
                             3  -1  -3   3  -3  -1   3   3   3  -3  -1  -3; ...
                            -3  -1   1  -3   1   3   3   3  -1  -3   3   3; ...
                            -3   3   1  -1   3   3  -3   1  -1   1  -1   1; ...
                            -1   1   3  -3   1  -1   1  -1  -1  -3   1  -1; ...
                            -3  -3   3   3   3  -3  -1   1  -3   3   1  -3; ...
                             1  -1   3   1   1  -1  -1  -1   1   3  -3   1; ...
                            -3   3  -3   3  -3  -3   3  -1  -1   1   3  -3];

        phiTableForLen18 = [-1   3  -1  -3   3   1  -3  -1   3  -3  -1  -1   1   1   1  -1  -1  -1; ...
                             3  -3   3  -1   1   3  -3  -1  -3  -3  -1  -3   3   1  -1   3  -3   3; ...
                            -3   3   1  -1  -1   3  -3  -1   1   1   1   1   1  -1   3  -1  -3  -1; ...
                            -3  -3   3   3   3   1  -3   1   3   3   1  -3  -3   3  -1  -3  -1   1; ...
                             1   1  -1  -1  -3  -1   1  -3  -3  -3   1  -3  -1  -1   1  -1   3   1; ...
                             3  -3   1   1   3  -1   1  -1  -1  -3   1   1  -1   3   3  -3   3  -1; ...
                            -3   3  -1   1   3   1  -3  -1   1   1  -3   1   3   3  -1  -3  -3  -3; ...
                             1   1  -3   3   3   1   3  -3   3  -1   1   1  -1   1  -3  -3  -1   3; ...
                            -3   1  -3  -3   1  -3  -3   3   1  -3  -1  -3  -3  -3  -1   1   1   3; ...
                             3  -1   3   1  -3  -3  -1   1  -3  -3   3   3   3   1   3  -3   3  -3; ...
                            -3  -3  -3   1  -3   3   1   1   3  -3  -3   1   3  -1   3  -3  -3   3; ...
                            -3  -3   3   3   3  -1  -1  -3  -1  -1  -1   3   1  -3  -3  -1   3  -1; ...
                            -3  -1  -3  -3   1   1  -1  -3  -1  -3  -1  -1   3   3  -1   3   1   3; ...
                             1   1  -3  -3  -3  -3   1   3  -3   3   3   1  -3  -1   3  -1  -3   1; ...
                            -3   3  -1  -3  -1  -3   1   1  -3  -3  -1  -1   3  -3   1   3   1   1; ...
                             3   1  -3   1  -3   3   3  -1  -3  -3  -1  -3  -3   3  -3  -1   1   3; ...
                            -3  -1  -3  -1  -3   1   3  -3  -1   3   3   3   1  -1  -3   3  -1  -3; ...
                            -3  -1   3   3  -1   3  -1  -3  -1   1  -1  -3  -1  -1  -1   3   3   1; ...
                            -3   1  -3  -1  -1   3   1  -3  -3  -3  -1  -3  -3   1   1   1  -1  -1; ...
                             3   3   3  -3  -1  -3  -1   3  -1   1  -1  -3   1  -3  -3  -1   3   3; ...
                            -3   1   1  -3   1   1   3  -3  -1  -3  -1   3  -3   3  -1  -1  -1  -3; ...
                             1  -3  -1  -3   3   3  -1  -3   1  -3  -3  -1  -3  -1   1   3   3   3; ...
                            -3  -3   1  -1  -1   1   1  -3  -1   3   3   3   3  -1   3   1   3   1; ...
                             3  -1  -3   1  -3  -3  -3   3   3  -1   1  -3  -1   3   1   1   3   3; ...
                             3  -1  -1   1  -3  -1  -3  -1  -3  -3  -1  -3   1   1   1  -3  -3   3; ...
                            -3  -3   1  -3   3   3   3  -1   3   1   1  -3  -3  -3   3  -3  -1  -1; ...
                            -3  -1  -1  -3   1  -3   3  -1  -1  -3   3   3  -3  -1   3  -1  -1  -1; ...
                            -3  -3   3   3  -3   1   3  -1  -3   1  -1  -3   3  -3  -1  -1  -1   3; ...
                            -1  -3   1  -3  -3  -3   1   1   3   3  -3   3   3  -3  -1   3  -3   1; ...
                            -3   3   1  -1  -1  -1  -1   1  -1   3   3  -3  -1   1   3  -1   3  -1];

        phiTableForLen24 = [-1  -3   3  -1   3   1   3  -1   1  -3  -1  -3  -1   1   3  -3  -1  -3   3   3   3  -3  -3  -3; ...
                            -1  -3   3   1   1  -3   1  -3  -3   1  -3  -1  -1   3  -3   3   3   3  -3   1   3   3  -3  -3; ...
                            -1  -3  -3   1  -1  -1  -3   1   3  -1  -3  -1  -1  -3   1   1   3   1  -3  -1  -1   3  -3  -3; ...
                             1  -3   3  -1  -3  -1   3   3   1  -1   1   1   3  -3  -1  -3  -3  -3  -1   3  -3  -1  -3  -3; ...
                            -1   3  -3  -3  -1   3  -1  -1   1   3   1   3  -1  -1  -3   1   3   1  -1  -3   1  -1  -3  -3; ...
                            -3  -1   1  -3  -3   1   1  -3   3  -1  -1  -3   1   3   1  -1  -3  -1  -3   1  -3  -3  -3  -3; ...
                            -3   3   1   3  -1   1  -3   1  -3   1  -1  -3  -1  -3  -3  -3  -3  -1  -1  -1   1   1  -3  -3; ...
                            -3   1   3  -1   1  -1   3  -3   3  -1  -3  -1  -3   3  -1  -1  -1  -3  -1  -1  -3   3   3  -3; ...
                            -3   1  -3   3  -1  -1  -1  -3   3   1  -1  -3  -1   1   3  -1   1  -1   1  -3  -3  -3  -3  -3; ...
                             1   1  -1  -3  -1   1   1  -3   1  -1   1  -3   3  -3  -3   3  -1  -3   1   3  -3   1  -3  -3; ...
                            -3  -3  -3  -1   3  -3   3   1   3   1  -3  -1  -1  -3   1   1   3   1  -1  -3   3   1   3  -3; ...
                            -3   3  -1   3   1  -1  -1  -1   3   3   1   1   1   3   3   1  -3  -3  -1   1  -3   1   3  -3; ...
                             3  -3   3  -1  -3   1   3   1  -1  -1  -3  -1   3  -3   3  -1  -1   3   3  -3  -3   3  -3  -3; ...
                            -3   3  -1   3  -1   3   3   1   1  -3   1   3  -3   3  -3  -3  -1   1   3  -3  -1  -1  -3  -3; ...
                            -3   1  -3  -1  -1   3   1   3  -3   1  -1   3   3  -1  -3   3  -3  -1  -1  -3  -3  -3   3  -3; ...
                            -3  -1  -1  -3   1  -3  -3  -1  -1   3  -1   1  -1   3   1  -3  -1   3   1   1  -1  -1  -3  -3; ...
                            -3  -3   1  -1   3   3  -3  -1   1  -1  -1   1   1  -1  -1   3  -3   1  -3   1  -1  -1  -1  -3; ...
                             3  -1   3  -1   1  -3   1   1  -3  -3   3  -3  -1  -1  -1  -1  -1  -3  -3  -1   1   1  -3  -3; ...
                            -3   1  -3   1  -3  -3   1  -3   1  -3  -3  -3  -3  -3   1  -3  -3   1   1  -3   1   1  -3  -3; ...
                            -3  -3   3   3   1  -1  -1  -1   1  -3  -1   1  -1   3  -3  -1  -3  -1  -1   1  -3   3  -1  -3; ...
                            -3  -3  -1  -1  -1  -3   1  -1  -3  -1   3  -3   1  -3   3  -3   3   3   1  -1  -1   1  -3  -3; ...
                             3  -1   1  -1   3  -3   1   1   3  -1  -3   3   1  -3   3  -1  -1  -1  -1   1  -3  -3  -3  -3; ...
                            -3   1  -3   3  -3   1  -3   3   1  -1  -3  -1  -3  -3  -3  -3   1   3  -1   1   3   3   3  -3; ...
                            -3  -1   1  -3  -1  -1   1   1   1   3   3  -1   1  -1   1  -1  -1  -3  -3  -3   3   1  -1  -3; ...
                            -3   3  -1  -3  -1  -1  -1   3  -1  -1   3  -3  -1   3  -3   3  -3  -1   3   1   1  -1  -3  -3; ...
                            -3   1  -1  -3  -3  -1   1  -3  -1  -3   1   1  -1   1   1   3   3   3  -1   1  -1   1  -1  -3; ...
                            -1   3  -1  -1   3   3  -1  -1  -1   3  -1  -3   1   3   1   1  -3  -3  -3  -1  -3  -1  -3  -3; ...
                             3  -3  -3  -1   3   3  -3  -1   3   1   1   1   3  -1   3  -3  -1   3  -1   3   1  -1  -3  -3; ...
                            -3   1  -3   1  -3   1   1   3   1  -3  -3  -1   1   3  -1  -3   3   1  -1  -3  -3  -3  -3  -3; ...
                             3  -3  -1   1   3  -1  -1  -3  -1   3  -1  -3  -1  -3   3  -1   3   1   1  -3   3  -3  -3  -3];
    end

    methods (Access = protected)
        function displayOrder = getPropertyGroups(~)
            simParametersList1 = ["numAntPorts", ...
                                  "numSymbols", ...
                                  "numRepetitions", ...
                                  "timeStartPosition", ...
                                  "configIndex", ...
                                  "sequenceID", ...
                                  "bandwidthIndex", ...
                                  "combSize", ...
                                  "combOffset", ...
                                  "cyclicShift", ...
                                  "frequencyPosition", ...
                                  "frequencyShift", ...
                                  "frequencyHopping", ...
                                  "groupOrSequenceHopping", ...
                                  "resourceType", ...
                                  "Tsrs", ...
                                  "Toffset"];

            simParametersTitle1 = "Configurable Parameters";

            simParametersGroup1 = matlab.mixin.util.PropertyGroup(simParametersList1, simParametersTitle1);

            simParametersList2 = ["srsAntPortNum", ...
                                  "alphaValues", ...
                                  "mSRS", ...
                                  "sequenceLength", ...
                                  "sequenceNumber", ...
                                  "groupNumber"];

            simParametersTitle2 = "Non-Configurable Parameters";

            simParametersGroup2 = matlab.mixin.util.PropertyGroup(simParametersList2, simParametersTitle2);

            displayOrder = [simParametersGroup1, simParametersGroup2];
        end
    end

    methods
        function srsAntPortNum = get.srsAntPortNum(obj)
            srsAntPortNum = 1000 + (0:2^obj.numAntPorts-1);
        end

        function alphaValues = get.alphaValues(obj)
            switch obj.combSize
                case 0
                    cyclicShiftMax = 8;

                case 1
                    cyclicShiftMax = 12;
            end

            phaseOffsetTemp = obj.cyclicShift + cyclicShiftMax*(obj.srsAntPortNum-1000)/2^obj.numAntPorts;
            phaseOffset = mod(phaseOffsetTemp, cyclicShiftMax);

            alphaValues = 2 * pi * phaseOffset / cyclicShiftMax;
        end

        function mSRS = get.mSRS(obj)
            switch obj.bandwidthIndex
                case 0
                    mSRS = obj.mSRS0_array(obj.configIndex+1);

                case 1
                    mSRS = obj.mSRS1_array(obj.configIndex+1);

                case 2
                    mSRS = obj.mSRS2_array(obj.configIndex+1);

                case 3
                    mSRS = obj.mSRS3_array(obj.configIndex+1);
            end
        end

        function sequenceLength = get.sequenceLength(obj)
            sequenceLength = obj.mSRS * 12 / 2^(obj.combSize+1);
        end
    end

    methods
        function obj = getSequenceNumber(obj, srsSymbolNumber, slotNumber)
            if(obj.groupOrSequenceHopping ~= 2)
                obj.sequenceNumber = 0;
            else
                if(obj.mSRS/2^(obj.combSize+1) >= 6)
                    seqStartIndex = slotNumber * 14 + obj.timeStartPosition + srsSymbolNumber - 1;
                    obj.sequenceNumber = nrPRBS(obj.sequenceID, [seqStartIndex 1]);
                else
                    obj.sequenceNumber = 0;
                end
            end
        end

        function obj = getGroupNumber(obj, srsSymbolNumber, slotNumber)
            if(obj.groupOrSequenceHopping ~= 1)
                obj.groupNumber = mod(obj.sequenceID, 30);
            else
                seqStartIndex = 8 * (slotNumber * 14 + obj.timeStartPosition + srsSymbolNumber - 1);
                groupHopVal = 2.^(0:7) * nrPRBS(obj.sequenceID, [seqStartIndex 8]);
                obj.groupNumber = mod(groupHopVal + obj.sequenceID, 30);
            end
        end

        function srsSequence = getSRSSequence(obj, slotNumber)
            srsSequence = complex(zeros(obj.sequenceLength, 2^obj.numSymbols, 2^obj.numAntPorts));
            baseSRSSequence = complex(zeros(obj.sequenceLength, 2^obj.numSymbols));

            for eachSymbol = 1:2^obj.numSymbols
                obj = getSequenceNumber(obj, eachSymbol, slotNumber);
                obj = getGroupNumber(obj, eachSymbol, slotNumber);

                switch obj.sequenceLength
                    case 6
                        phaseValues = obj.phiTableForLen6(obj.groupNumber+1, :);
                        baseSRSSequence(:, eachSymbol) = exp(1i * pi * phaseValues / 4);

                    case 12
                        phaseValues = obj.phiTableForLen12(obj.groupNumber+1, :);
                        baseSRSSequence(:, eachSymbol) = exp(1i * pi * phaseValues / 4);

                    case 18
                        phaseValues = obj.phiTableForLen18(obj.groupNumber+1, :);
                        baseSRSSequence(:, eachSymbol) = exp(1i * pi * phaseValues / 4);

                    case 24
                        phaseValues = obj.phiTableForLen24(obj.groupNumber+1, :);
                        baseSRSSequence(:, eachSymbol) = exp(1i * pi * phaseValues / 4);

                    case 30
                        nValues = 0:obj.sequenceLength-1;
                        baseSRSSequence(:, eachSymbol) = exp(-1i * pi * (obj.groupNumber+1) * (nValues+1) .* (nValues+2) / 31);

                    otherwise
                        NzcValue = max(primes(obj.sequenceLength));

                        qBarValue = NzcValue * (obj.groupNumber+1) / 31;
                        qValue = floor(qBarValue + 0.5) + obj.sequenceNumber * (-1)^(floor(2*qBarValue));

                        mValues = 0:NzcValue-1;
                        zadOffChuSequence = exp(-1i * pi * qValue * mValues .* (mValues+1) / NzcValue);

                        nValues = 0:obj.sequenceLength-1;
                        baseSRSSequence(:, eachSymbol) = zadOffChuSequence(mod(nValues, NzcValue) + 1);
                end
            end

            for eachAntPort = 1:2^obj.numAntPorts
                nValues = 0:obj.sequenceLength-1;
                srsSequence(:, :, eachAntPort) = exp(1i * obj.alphaValues(eachAntPort) * nValues.') .* baseSRSSequence;
            end
        end

        function [srsConfigs, srsSequence] = getSRSSequenceTest(obj, groupNumber, sequenceNumber)
            if(obj.sequenceLength < 30)
                srsConfigs(1) = (0 * 2^8) + obj.numAntPorts;
            elseif(obj.sequenceLength == 30)
                srsConfigs(1) = (1 * 2^8) + obj.numAntPorts;
            else
                srsConfigs(1) = (2 * 2^8) + obj.numAntPorts;
            end

            if(obj.numAntPorts == 0)
                srsConfigs(2) = floor(obj.alphaValues(1)/pi * 2^30);
                srsConfigs(3) = 0;
                srsConfigs(4) = 0;
                srsConfigs(5) = 0;
            elseif(obj.numAntPorts == 1)
                srsConfigs(2) = floor(obj.alphaValues(1)/pi * 2^30);
                srsConfigs(3) = floor(obj.alphaValues(2)/pi * 2^30);
                srsConfigs(4) = 0;
                srsConfigs(5) = 0;
            else
                srsConfigs(2) = floor(obj.alphaValues(1)/pi * 2^30);
                srsConfigs(3) = floor(obj.alphaValues(2)/pi * 2^30);
                srsConfigs(4) = floor(obj.alphaValues(3)/pi * 2^30);
                srsConfigs(5) = floor(obj.alphaValues(4)/pi * 2^30);
            end

            srsConfigs(6) = obj.sequenceLength;

            switch obj.sequenceLength
                case 6
                    phaseValues = obj.phiTableForLen6(groupNumber+1, :);
                    baseSRSSequence = exp(1i * pi * phaseValues / 4);

                case 12
                    phaseValues = obj.phiTableForLen12(groupNumber+1, :);
                    baseSRSSequence = exp(1i * pi * phaseValues / 4);

                case 18
                    phaseValues = obj.phiTableForLen18(groupNumber+1, :);
                    baseSRSSequence = exp(1i * pi * phaseValues / 4);

                case 24
                    phaseValues = obj.phiTableForLen24(groupNumber+1, :);
                    baseSRSSequence = exp(1i * pi * phaseValues / 4);

                case 30
                    nValues = 0:obj.sequenceLength-1;
                    baseSRSSequence = exp(-1i * pi * (groupNumber+1) * (nValues+1) .* (nValues+2) / 31);
                    srsConfigs(7) = floor((groupNumber+1) / 31 * 2^30);

                otherwise
                    NzcValue = max(primes(obj.sequenceLength));

                    qBarValue = NzcValue * (groupNumber+1) / 31;
                    qValue = floor(qBarValue + 0.5) + sequenceNumber * (-1)^(floor(2*qBarValue));

                    srsConfigs(7) = NzcValue;
                    srsConfigs(8) = floor(qValue / NzcValue * 2^(30));

                    mValues = 0:NzcValue-1;
                    zadOffChuSequence = exp(-1i * pi * qValue * mValues .* (mValues+1) / NzcValue);

                    nValues = 0:obj.sequenceLength-1;
                    baseSRSSequence = zadOffChuSequence(mod(nValues, NzcValue) + 1);
            end

            if(any([6, 12, 18, 24]==obj.sequenceLength))
                configPhaseValues = phaseValues;
                configPhaseValues(configPhaseValues == 3) = 5;
                configPhaseValues(configPhaseValues == 1) = 7;
                configPhaseValues(configPhaseValues == -3) = 3;
                configPhaseValues(configPhaseValues == -1) = 1;
                temp_var1 = numel(srsConfigs) + 1;
                temp_var2 = temp_var1 + numel(configPhaseValues) - 1;
                srsConfigs(temp_var1:temp_var2) = floor(configPhaseValues * 2^28);
            end

            baseSRSSequence = reshape(baseSRSSequence, [], 1);
            srsSequence = zeros(numel(baseSRSSequence), 2^obj.numAntPorts);
            for eachAntPort = 1:2^obj.numAntPorts
                nValues = 0:obj.sequenceLength-1;
                srsSequence(:, eachAntPort) = exp(1i * obj.alphaValues(eachAntPort) * nValues.') .* baseSRSSequence;
            end

            srsConfigs = reshape(srsConfigs, [], 1);
            srsConfigs = string(dec2hex(srsConfigs, 8));

            srsSequence = reshape(srsSequence.', [], 1);
            srsSequence = floor(srsSequence * 2^14);
            srsSequence = string(dec2hex(imag(srsSequence), 4)) + string(dec2hex(real(srsSequence), 4));
        end
    end
end
