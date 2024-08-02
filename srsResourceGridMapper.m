classdef srsResourceGridMapper < srsGenerator
    properties (Access = protected)
        nSRS
        transmitSRS
        Nb
        Fb_nSRS
        nb
        srsIndices
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
                                  "mSRS_bandwidthIndex", ...
                                  "sequenceLength", ...
                                  "sequenceNumber", ...
                                  "groupNumber"];

            simParametersTitle2 = "Non-Configurable Parameters";

            simParametersGroup2 = matlab.mixin.util.PropertyGroup(simParametersList2, simParametersTitle2);

            displayOrder = [simParametersGroup1, simParametersGroup2];
        end
    end

    methods (Access = protected)
        function obj = getTransmitSRS(obj, slotNumber, frameNumber)
            switch obj.resourceType
                case 0
                    obj.transmitSRS = 1;

                otherwise
                    nSRSTemp = 20*frameNumber + slotNumber - obj.Toffset;
                    if(mod(nSRSTemp, obj.Tsrs) == 0)
                        obj.transmitSRS = 1;
                    else
                        obj.transmitSRS = 0;
                    end
            end
        end

        function obj = getnSRS(obj, srsSymbolNumber, slotNumber, frameNumber)
            switch obj.resourceType
                case 0
                    obj.nSRS = floor(srsSymbolNumber * 2^(-obj.numRepetitions));

                otherwise
                    nSRSTemp = 20*frameNumber + slotNumber - obj.Toffset;
                    obj.nSRS = (nSRSTemp/obj.Tsrs) * 2^(obj.numSymbols-obj.numRepetitions) + floor((srsSymbolNumber-1) * 2^(-obj.numRepetitions));
            end
        end

        function obj = getNb(obj)
            obj.Nb = zeros(obj.bandwidthIndex+1, 1);

            for each_bValue = 0:obj.bandwidthIndex
                switch each_bValue
                    case 0
                        obj.Nb(each_bValue+1) = obj.N0SRS_array(obj.configIndex+1);

                    case 1
                        obj.Nb(each_bValue+1) = obj.N1SRS_array(obj.configIndex+1);

                    case 2
                        obj.Nb(each_bValue+1) = obj.N2SRS_array(obj.configIndex+1);

                    case 3
                        obj.Nb(each_bValue+1) = obj.N3SRS_array(obj.configIndex+1);
                end
            end
        end

        function Fb_nSRS = getFb_nSRS_value(obj, bValue)
            NbProductTemp1 = 1;
            NbProductTemp2 = 1;

            for each_bValue = obj.frequencyHopping+1:bValue
                if(each_bValue < bValue)
                    NbProductTemp2 = NbProductTemp2 * obj.Nb(each_bValue+1);
                end

                NbProductTemp1 = NbProductTemp1 * obj.Nb(each_bValue+1);
            end

            if(mod(obj.Nb(bValue+1), 2) == 0)
                Fb_nSRS = obj.Nb(bValue+1)/2 * floor(mod(obj.nSRS, NbProductTemp1)/NbProductTemp2) + floor(mod(obj.nSRS, NbProductTemp1)/2/NbProductTemp2);
            else
                Fb_nSRS = floor(obj.Nb(bValue+1)/2) * floor(obj.nSRS/NbProductTemp2);
            end
        end

        function mSRSbValue = get_mSRSbValue(obj, bValue)
            switch bValue
                case 0
                    mSRSbValue = obj.mSRS0_array(obj.configIndex+1);

                case 1
                    mSRSbValue = obj.mSRS1_array(obj.configIndex+1);

                case 2
                    mSRSbValue = obj.mSRS2_array(obj.configIndex+1);

                case 3
                    mSRSbValue = obj.mSRS3_array(obj.configIndex+1);
            end
        end

        function obj = nbValue(obj)
            obj.nb = zeros(numel(0:obj.bandwidthIndex), 1);

            for each_nbValue = 0:obj.bandwidthIndex
                if (obj.frequencyHopping >= obj.bandwidthIndex) 
                    obj.nb(each_nbValue+1) = mod(floor(4*obj.frequencyPosition/get_mSRSbValue(obj, obj.bandwidthIndex)), obj.Nb(each_nbValue+1));
                else
                    try
                        if(each_nbValue <= obj.frequencyHopping)
                            obj.nb(each_nbValue+1) = mod(floor(4*obj.frequencyPosition/get_mSRSbValue(obj, each_nbValue)), obj.Nb(each_nbValue+1));
                        else
                            obj.nb(each_nbValue+1) =   mod(getFb_nSRS_value(obj, each_nbValue) ...
                                                     + floor(4*obj.frequencyPosition/get_mSRSbValue(obj, each_nbValue)), obj.Nb(each_nbValue+1));
                        end
                    catch
                        disp("error");
                    end
                end
            end
        end

        function Msc_bValues = getMsc_bValues(obj)
            Msc_bValues = zeros(numel(0:obj.bandwidthIndex), 1);

            for each_bValue = 1:numel(Msc_bValues)
                switch each_bValue
                    case 1
                        Msc_bValues(each_bValue) = obj.mSRS0_array(obj.configIndex+1) * 12/2^(obj.combSize+1);

                    case 2
                        Msc_bValues(each_bValue) = obj.mSRS1_array(obj.configIndex+1) * 12/2^(obj.combSize+1);

                    case 3
                        Msc_bValues(each_bValue) = obj.mSRS2_array(obj.configIndex+1) * 12/2^(obj.combSize+1);

                    case 4
                        Msc_bValues(each_bValue) = obj.mSRS3_array(obj.configIndex+1) * 12/2^(obj.combSize+1);
                end
            end
        end

        function startingPosition = getSRSIndicesStartPos(obj)
            obj = nbValue(obj);
            Msc_bValues = getMsc_bValues(obj);

            combOffsetPerPort = zeros(2^(obj.numAntPorts), 1);

            for eachSRSPort = 1:numel(combOffsetPerPort)
                switch eachSRSPort
                    case 1
                        if(2^(obj.numAntPorts) == 4 && obj.cyclicShift >= 6)
                            combOffsetPerPort(eachSRSPort) = mod(obj.combOffset + 2^(obj.combSize+1)/2, 2^(obj.combSize+1));
                        else
                            combOffsetPerPort(eachSRSPort) = obj.combOffset;
                        end

                    case 2
                        combOffsetPerPort(eachSRSPort) = obj.combOffset;

                    case 3
                        if(2^(obj.numAntPorts) == 4 && obj.cyclicShift >= 6)
                            combOffsetPerPort(eachSRSPort) = mod(obj.combOffset + 2^(obj.combSize+1)/2, 2^(obj.combSize+1));
                        else
                            combOffsetPerPort(eachSRSPort) = obj.combOffset;
                        end

                    case 4
                        combOffsetPerPort(eachSRSPort) = obj.combOffset;
                end
            end

            startingPositionTemp = 12*obj.frequencyShift + combOffsetPerPort;

            startingPosition = startingPositionTemp + 2^(obj.combSize+1) * (Msc_bValues' * obj.nb);
        end
    end

    methods
        function srsIndices = getSRSIndices(obj, slotNumber, frameNumber)
            srsIndices = zeros(obj.sequenceLength, 2^(obj.numAntPorts), 2^obj.numSymbols);
            obj = getTransmitSRS(obj, slotNumber, frameNumber);

            if(obj.transmitSRS == 1)
                for eachSymbol = 1:2^obj.numSymbols
                    obj = getnSRS(obj, eachSymbol, slotNumber, frameNumber);
                    obj = getNb(obj);
                    startingPosition = getSRSIndicesStartPos(obj);
                    srsIndices(:, :, eachSymbol) = (startingPosition + 2^(obj.combSize+1)*(0:obj.sequenceLength-1)).';
                end
            end
        end
    end
end
