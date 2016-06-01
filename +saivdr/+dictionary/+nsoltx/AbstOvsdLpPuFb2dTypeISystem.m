classdef AbstOvsdLpPuFb2dTypeISystem < ...
        saivdr.dictionary.nsoltx.AbstOvsdLpPuFb2dSystem %#codegen
    %ABSTOVSDLPPUFB2DTYPEISYSTEM Abstract class 2-D Type-I OLPPUFB
    %
    % SVN identifier:
    % $Id: AbstOvsdLpPuFb2dTypeISystem.m 690 2015-06-09 09:37:49Z sho $
    %
    % Requirements: MATLAB R2013b
    %
    % Copyright (c) 2014-2015, Shogo MURAMATSU
    %
    % All rights reserved.
    %
    % Contact address: Shogo MURAMATSU,
    %                Faculty of Engineering, Niigata University,
    %                8050 2-no-cho Ikarashi, Nishi-ku,
    %                Niigata, 950-2181, JAPAN
    %
    % LinedIn: http://www.linkedin.com/pub/shogo-muramatsu/4b/b08/627
    %

    properties (Access = protected)
        matrixE0
        mexFcn
    end

    properties (Access = protected,PositiveInteger)
        nStages
    end

    methods (Access = protected, Static = true, Abstract = true)
        value = getDefaultPolyPhaseOrder_()
    end

    methods
        function obj = AbstOvsdLpPuFb2dTypeISystem(varargin)
            obj = obj@saivdr.dictionary.nsoltx.AbstOvsdLpPuFb2dSystem(...
                varargin{:});
            updateProperties_(obj);
            updateAngles_(obj);
            updateMus_(obj);
        end
    end

    methods (Access = protected)

        function s = saveObjectImpl(obj)
            s = saveObjectImpl@saivdr.dictionary.nsoltx.AbstOvsdLpPuFb2dSystem(obj);
            s.nStages = obj.nStages;
            s.matrixE0 = obj.matrixE0;
            s.mexFcn   = obj.mexFcn;
        end

        function loadObjectImpl(obj,s,wasLocked)
            obj.mexFcn   = s.mexFcn;
            obj.nStages = s.nStages;
            obj.matrixE0 = s.matrixE0;
            loadObjectImpl@saivdr.dictionary.nsoltx.AbstOvsdLpPuFb2dSystem(obj,s,wasLocked);
        end

        function resetImpl(obj)
            resetImpl@saivdr.dictionary.nsoltx.AbstOvsdLpPuFb2dSystem(obj);
            % Prepare MEX function
            import saivdr.dictionary.nsoltx.mexsrcs.fcn_autobuild_bb_type1
            [obj.mexFcn, obj.mexFlag] = fcn_autobuild_bb_type1(obj.NumberOfChannels(1));
        end

        function setupImpl(obj,varargin)
            % Prepare MEX function
            import saivdr.dictionary.nsoltx.mexsrcs.fcn_autobuild_bb_type1
            [obj.mexFcn, obj.mexFlag] = fcn_autobuild_bb_type1(obj.NumberOfChannels(1));
        end

        function updateProperties_(obj)
            import saivdr.dictionary.nsoltx.ChannelGroup
            import saivdr.dictionary.utility.Direction
            import saivdr.dictionary.utility.ParameterMatrixSet
           % import saivdr.dictionary.nsoltx.AbstOvsdLpPuFb2dTypeISystem

            % Check DecimationFactor
            if length(obj.DecimationFactor) > 2
                error('Dimension of DecimationFactor must be less than or equal to two.');
            end
            nHalfDecs = prod(obj.DecimationFactor)/2;

            % Check PolyPhaseOrder
            if isempty(obj.PolyPhaseOrder)
                obj.PolyPhaseOrder = obj.getDefaultPolyPhaseOrder_();
            end
            if length(obj.PolyPhaseOrder) > 2
                error('Dimension of PolyPhaseOrder must be less than or equal to two.');
            end
            ordX = obj.PolyPhaseOrder(Direction.HORIZONTAL);
            ordY = obj.PolyPhaseOrder(Direction.VERTICAL);
            obj.nStages = uint32(1+ordX+ordY);
            obj.matrixE0 = getMatrixE0_(obj);

            % Check NumberOfChannels
            if length(obj.NumberOfChannels) > 2
                error('Dimension of NumberOfChannels must be less than or equal to two.');
            end
            id = 'SaivDr:IllegalArgumentException';
            if isempty(obj.NumberOfChannels)
                obj.NumberOfChannels = nHalfDecs * [ 1 1 ];
            elseif isscalar(obj.NumberOfChannels)
                if mod(obj.NumberOfChannels,2) ~= 0
                    msg = '#Channels must be even.';
                    me = MException(id, msg);
                    throw(me);
                else
                    obj.NumberOfChannels = ...
                        obj.NumberOfChannels * [ 1 1 ]/2;
                end
            elseif obj.NumberOfChannels(ChannelGroup.UPPER) ~= ...
                    obj.NumberOfChannels(ChannelGroup.LOWER)
                msg = 'ps and pa must be the same as each other.';
                me = MException(id, msg);
                throw(me);
            end

            % Prepare ParameterMatrixSet
            initParamMtxSizeTab = sum(obj.NumberOfChannels)*ones(1,2);
            propParamMtxSizeTab = [...
                obj.NumberOfChannels(ChannelGroup.UPPER)*ones(1,2);
                obj.NumberOfChannels(ChannelGroup.LOWER)*ones(1,2);
                floor(sum(obj.NumberOfChannels)/4),1 ];
            paramMtxSizeTab = [...
                initParamMtxSizeTab;
                repmat(propParamMtxSizeTab,obj.nStages-1,1)];
            obj.ParameterMatrixSet = ParameterMatrixSet(...
                'MatrixSizeTable',paramMtxSizeTab);

        end

        function updateAngles_(obj)
            import saivdr.dictionary.nsoltx.ChannelGroup
            import saivdr.dictionary.utility.Direction
            nCh = sum(obj.NumberOfChannels);
            nInitAngs = nCh*(nCh-1)/2;
            nAngsPerStg = nCh*(nCh-2)/4+floor(nCh/4);
            sizeOfAngles = nInitAngs + (obj.nStages-1)*nAngsPerStg;
            if isscalar(obj.Angles) && obj.Angles==0
                obj.Angles = zeros(sizeOfAngles,1);
            end
%             if size(obj.Angles,1) ~= sizeOfAngles(1) || ...
%                     size(obj.Angles,2) ~= sizeOfAngles(2)
            if size(obj.Angles) ~= sizeOfAngles
                id = 'SaivDr:IllegalArgumentException';
                %TODO: エラーメッセージの設定
                msg = sprintf(...
                    'Size of angles must be [ %d %d ]',...
                    sizeOfAngles(1), sizeOfAngles(2));
                me = MException(id, msg);
                throw(me);
            end
        end

        %TODO:　修正する
        function updateMus_(obj)
            import saivdr.dictionary.nsoltx.ChannelGroup
            import saivdr.dictionary.utility.Direction
            %nChL = obj.NumberOfChannels(ChannelGroup.LOWER);
            nCh = sum(obj.NumberOfChannels);
            sizeOfMus = [ nCh obj.nStages];
            if isscalar(obj.Mus) && obj.Mus==1
%                 obj.Mus = -ones(sizeOfMus);
%                 obj.Mus(:,1:2) = ones(size(obj.Mus,1),2);
                obj.Mus = ones(sizeOfMus);
            end
            if size(obj.Mus,1) ~= sizeOfMus(1) || ...
                    size(obj.Mus,2) ~= sizeOfMus(2)
                id = 'SaivDr:IllegalArgumentException';
                msg = sprintf(...
                    'Size of mus must be [ %d %d ]',...
                    sizeOfMus(1), sizeOfMus(2));
                me = MException(id, msg);
                throw(me);
            end

        end

        function value = getAnalysisFilterBank_(obj)
            import saivdr.dictionary.nsoltx.ChannelGroup
            import saivdr.dictionary.utility.Direction
            import saivdr.dictionary.nsoltx.AbstOvsdLpPuFb2dTypeISystem
            %import saivdr.dictionary.nsoltx.mexsrcs.*
            %
            nChs = sum(obj.NumberOfChannels);
            dec  = obj.DecimationFactor;
            decX = dec(Direction.HORIZONTAL);
            decY = dec(Direction.VERTICAL);
            nHalfDecs = prod(dec)/2;
            ordX = obj.PolyPhaseOrder(Direction.HORIZONTAL);
            ordY = obj.PolyPhaseOrder(Direction.VERTICAL);
            pmMtxSet_  = obj.ParameterMatrixSet;
            mexFcn_ = obj.mexFcn;
            mexFlag_ = obj.mexFlag;
            %
            E0 = obj.matrixE0;
            %
            %TODO: begin
%             cM_2 = ceil(nHalfDecs);
%             W = step(pmMtxSet_,[],uint32(1))*[ eye(cM_2) ;
%                 zeros(nChs(ChannelGroup.LOWER)-cM_2,cM_2)];
%             fM_2 = floor(nHalfDecs);
%             U = step(pmMtxSet_,[],uint32(2))*[ eye(fM_2);
%                 zeros(nChs(ChannelGroup.LOWER)-fM_2,fM_2) ];
            R = step(pmMtxSet_,[],uint32(1))*[ eye(prod(dec)); zeros(nChs-prod(dec),prod(dec))];
            %R = blkdiag(W,U);
            %TODO: end
            E = R*E0;
            iParamMtx = uint32(2);
            %TODO: iParamMtx = uint32(2);
            hChs = nChs/2;

            %
            initOrdX = 1;
            lenX = decX;
            initOrdY = 1;
            lenY = decY;

            % Horizontal extention
            nShift = int32(lenY*lenX);
            for iOrdX = initOrdX:ordX
                %TODO:
                W = step(pmMtxSet_,[],iParamMtx);
                %W = eye(hChs);
                U = step(pmMtxSet_,[],iParamMtx+1);
                %U = step(pmMtxSet_,[],iParamMtx);
                angsB = step(pmMtxSet_,[],iParamMtx+2);
                %angles = pi/4*ones(floor(hChs/2),1);
                if mexFlag_
                    %TODO:
                    E = mexFcn_(E, W, U, angsB, hChs, nShift);
                else
                    import saivdr.dictionary.nsoltx.mexsrcs.Order1BuildingBlockTypeI
                    hObb = Order1BuildingBlockTypeI();
                    E = step(hObb, E, W, U, angsB, hChs, nShift);
                end
                %iParamMtx = iParamMtx+1;
                iParamMtx = iParamMtx+3;
            end
            lenX = decX*(ordX+1);

            % Vertical extention
            if ordY > 0
                E = permuteCoefs_(obj,E,lenY);
                nShift = int32(lenX*lenY);
                for iOrdY = initOrdY:ordY
                    W = step(pmMtxSet_,[],iParamMtx);
                    %W = eye(hChs);
                    U = step(pmMtxSet_,[],iParamMtx+1);
                    %U = step(pmMtxSet_,[],iParamMtx);
                    angsB = step(pmMtxSet_,[],iParamMtx+2);
                    %angsB = pi/4*ones(floor(hChs/2),1);
                    if mexFlag_
                        %TODO
                        E = mexFcn_(E, W, U, angsB, hChs, nShift);
                    else
                        import saivdr.dictionary.nsoltx.mexsrcs.Order1BuildingBlockTypeI
                        hObb = Order1BuildingBlockTypeI();
                        E = step(hObb, E, W, U, angsB, hChs, nShift);
                    end
                    %iParamMtx = iParamMtx+1;
                    iParamMtx = iParamMtx+3;
                end
                lenY = decY*(ordY+1);

                E = ipermuteCoefs_(obj,E,lenY);
            end
            %
            nSubbands = size(E,1);
            value = zeros(lenY,lenX,nSubbands);
            for iSubband = 1:nSubbands
                value(:,:,iSubband) = reshape(E(iSubband,:),lenY,lenX);
            end

        end

    end
end
