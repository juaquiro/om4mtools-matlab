%> @file DemodulatorProps.m
%> @brief enumeration of Demodulator properties, typed and unit-tagged
%> @details NA
%> @copyright 2026 IOT
%> @author AQ


% ======================================================================
%> @brief enumeration of demodulator props, each carrying its own type
%> validator and physical unit
%> @details replaces the untyped enumeration this class used to be. Each
%> member's ValidationFcn is applied by DemodulatorPropStore.Set before a
%> value is accepted; Unit is documentation metadata only (never enforced).
%> A prop with no meaningful type constraint uses ValidationFcn=[]
% ======================================================================
classdef DemodulatorProps

    %% props
    properties (SetAccess = immutable)
        %> function handle called as ValidationFcn(value); throws if value is invalid. [] means no check
        ValidationFcn;
        %> physical unit of the prop value, e.g. 'px', 'rad'. '' if dimensionless or not applicable
        Unit;
    end

    %% public methods
    methods
        function this = DemodulatorProps(validationFcn, unit)
            this.ValidationFcn = validationFcn;
            this.Unit = unit;
        end

        % ======================================================================
        %> @brief typechecks value against this prop's ValidationFcn
        %> @param this instance of the enum member (e.g. DemodulatorProps.Tx)
        %> @param value candidate value to store under this prop
        %> @details throws the ValidationFcn's own error (e.g. a mustBeXxx
        %> error) if value is invalid; does nothing if ValidationFcn is []
        % ======================================================================
        function CheckValue(this, value)
            if not(isempty(this.ValidationFcn))
                this.ValidationFcn(value);
            end
        end
    end

    %% static methods
    methods (Static)
        % ======================================================================
        %> @brief looks up the enum member whose name matches a char, e.g. 'Tx'
        %> @param name char name of a DemodulatorProps member
        %> @retval member the matching DemodulatorProps enum member
        % ======================================================================
        function member = FromName(name)
            allMembers = enumeration('DemodulatorProps');
            allNames = arrayfun(@char, allMembers, 'UniformOutput', false);
            member = allMembers(strcmp(allNames, name));
            if isempty(member)
                error('DemodulatorProps:FromName:UnknownProp', ['unknown DemodulatorProps name: <<' name '>>']);
            end
        end
    end

    %% enumeration
    enumeration
        M                       (@(v) validateattributes(v, {'numeric','logical'}, {}), '')       % logical array which defines the ROI
        zList                   (@(v) mustBeA(v, 'cell'), '')                                      % phasor cell array demodulated from the input cell array of Process()
        NL                      (@(v) mustBeMember(v, [2 4]), '')                                  % number of Lobes
        Tx                      (@mustBeNumeric, 'px')                                             % period in px of the Fringe patterns generated for display
        Ty                      (@mustBeNumeric, 'px')                                             % period in px of the Fringe patterns generated for display
        PSType                  (@(v) mustBeA(v, 'PSFilterTypes'), '')                             % for PS demodulators the type of PS filter used, see appendix A of FPA
        PSDir                   (@mustBeNumeric, '')                                                % 1==X vertical patterns, 2==Y horizontal patterns
        StepsTwoPwiRange        (@mustBeNumeric, 'rad|V')                                          % two pi range in voltage or angles necessary for the generation of the phase steps
        z2alpha                 (@mustBeNumeric, '')                                                % isoclinic phasor for retardation demodulation
        NIgrams                 (@mustBeNumeric, 'count')                                          % number of igrams in temporal analysis methods
        TempAnalysisType        ([], '')                                                            % type of temporal analysis method
        TempRange               (@mustBeNumeric, 'V|deg|s')                                        % maximum range [0 TempRange] of the temporal variation
        TempVals                (@(v) mustBeA(v, 'cell'), 'V|deg|s')                               % cell array with the temporal values at which the series was acquired
        FFCut                   (@mustBeNumeric, 'FF')                                             % high pass cut to eliminate in FT based temporal analysis, in FF
        NFilt                   (@mustBeNumeric, 'px')                                             % filter size for phasor and mask filtering
        ROINormTH               (@mustBeNumeric, 'norm')                                           % normalized threshold [0 1] for ROI calculation
        deltaList               (@(v) validateattributes(v, {'numeric','struct'}, {}), 'rad')       % phase steps list for the LS phase demodulator; a struct('X',...,'Y',...) for the XY-multiplexed variant
        w0                      (@mustBeNumeric, 'rad/sample')                                     % temporal/spatial carrier freq
        AbsolutePhasePSADemType (@(v) mustBeA(v, 'DemodulatorTypes'), '')                          % PSA type used for absolute GCPSA demodulators
    end
end
