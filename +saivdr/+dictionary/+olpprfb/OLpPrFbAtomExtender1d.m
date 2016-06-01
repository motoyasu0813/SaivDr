classdef OLpPrFbAtomExtender1d <  ...
        saivdr.dictionary.olpprfb.AbstOLpPrFbCoefManipulator1d %#codegen
    %OLPPRFBATOMEXTENDER1D 1-D Atom Extender for OLPPRFB
    %
    % SVN identifier:
    % $Id: OLpPrFbAtomExtender1d.m 657 2015-03-17 00:45:15Z sho $
    %
    % Requirements: MATLAB R2013b
    %
    % Copyright (c) 2014, Shogo MURAMATSU
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
    
    methods
        
        % Constructor
        function obj = OLpPrFbAtomExtender1d(varargin)
            obj = obj@saivdr.dictionary.olpprfb.AbstOLpPrFbCoefManipulator1d(varargin{:});
        end
        
    end
    
    methods (Access = protected)
        
        function s = saveObjectImpl(obj)
            % Call the base class method
            s = saveObjectImpl@saivdr.dictionary.olpprfb.AbstOLpPrFbCoefManipulator1d(obj);
        end
        
        function loadObjectImpl(obj,s,wasLocked)
            % Call base class method to load public properties
            loadObjectImpl@saivdr.dictionary.olpprfb.AbstOLpPrFbCoefManipulator1d(obj,s,wasLocked);
        end
        
        function arrayCoefs = stepImpl(obj, arrayCoefs, subScale, pmCoefs)
            stepImpl@saivdr.dictionary.olpprfb.AbstOLpPrFbCoefManipulator1d(obj,arrayCoefs,subScale,pmCoefs);        
            %
            arrayCoefs = initialStep_(obj,arrayCoefs);
            %
            if strcmp(obj.OLpPrFbType,'Type I')
                arrayCoefs = fullAtomExtTypeI_(obj,arrayCoefs);
            else
                arrayCoefs = fullAtomExtTypeII_(obj,arrayCoefs);
            end
            
        end
        
    end
    
    methods ( Access = private )
        
        function arrayCoefs = initialStep_(obj,arrayCoefs)
            
            %hLenU = obj.NumberOfSymmetricChannels;            
            %
            if ~isempty(obj.paramMtxCoefs)
                %W0 = getParamMtx_(obj,uint32(1));
                %U0 = getParamMtx_(obj,uint32(2));
                V0 = getParamMtx_(obj,uint32(1));
                %arrayCoefs(1:hLenU,:)     = W0*arrayCoefs(1:hLenU,:);
                %arrayCoefs(hLenU+1:end,:) = U0*arrayCoefs(hLenU+1:end,:);
                arrayCoefs = V0*arrayCoefs;
            end

        end
        
        function arrayCoefs = fullAtomExtTypeI_(obj,arrayCoefs)
            %
            isPeriodicExt = obj.IsPeriodicExt; % BoundaryOperation = 'Circular'
            %
            ord = obj.PolyPhaseOrder;
    
            % Order extension
            hOrd = uint32(ord/2);
            if hOrd > 0
                for iOrd = uint32(1):hOrd
                    paramMtxW1 = getParamMtx_(obj,6*iOrd-4);
                    paramMtxU1 = getParamMtx_(obj,6*iOrd-3);
                    paramAngB1 = getParamMtx_(obj,6*iOrd-2);
                    paramMtxW2 = getParamMtx_(obj,6*iOrd-1);
                    paramMtxU2 = getParamMtx_(obj,6*iOrd+0);
                    paramAngB2 = getParamMtx_(obj,6*iOrd+1);
                    %
                    arrayCoefs = supportExtTypeI_(obj,arrayCoefs,...
                        paramMtxW1,paramMtxU1,paramAngB1,...
                        paramMtxW2,paramMtxU2,paramAngB2,...
                        isPeriodicExt);
                end
            end
            
        end
        
        function arrayCoefs = fullAtomExtTypeII_(obj,arrayCoefs)
            %
            isPeriodicExt = obj.IsPeriodicExt; % BoundaryOperation = 'Circular'
            isPsGtPa      = obj.IsPsGreaterThanPa;            
            %
            ord = obj.PolyPhaseOrder;
            
            % Order extension
            for iOrd = uint32(1):uint32(ord/2)
                paramMtx1 = getParamMtx_(obj,6*iOrd-4); % W
                paramMtx2 = getParamMtx_(obj,6*iOrd-3); % U
                paramMtx3 = getParamMtx_(obj,6*iOrd-2); % angB1
                paramMtx4 = getParamMtx_(obj,6*iOrd-1); % HW
                paramMtx5 = getParamMtx_(obj,6*iOrd+0); % HU
                paramMtx6 = getParamMtx_(obj,6*iOrd+1); % angB2
                %
                %if isPsGtPa
                    arrayCoefs = supportExtTypeIIPsGtPa_(obj,arrayCoefs,...
                        paramMtx1,paramMtx2,paramMtx3,paramMtx4,paramMtx5,paramMtx6,...
                        isPeriodicExt);
                %else
                %    arrayCoefs = supportExtTypeIIPsLtPa_(obj,arrayCoefs,paramMtx1,paramMtx2,[],isPeriodicExt);
                %end
            end

        end
        
        function arrayCoefs = supportExtTypeI_(obj,arrayCoefs,paramMtx1,paramMtx2,paramMtx3,paramMtx4,paramMtx5,paramMtx6,isPeriodicExt)
            hLen = obj.NumberOfSymmetricChannels;

            % Phase 1
            Wx = paramMtx1;
            Ux = paramMtx2;
            B = butterflyMtx_(obj,paramMtx3);
            %B = eye(obj.NumberOfSymmetricChannels+obj.NumberOfAntisymmetricChannels);
            %TODO:
            %arrayCoefs = blockButterflyTypeI_(obj,arrayCoefs,angB1);
            arrayCoefs = B'*arrayCoefs;
            arrayCoefs = rightShiftLowerCoefs_(obj,arrayCoefs);
            arrayCoefs = B*arrayCoefs;
            %arrayCoefs = blockButterflyTypeI_(obj,arrayCoefs,angB1);
            %arrayCoefs = arrayCoefs/2.0;
            % Lower channel rotation
            if isPeriodicExt
                arrayCoefs(1:hLen,:) = Wx*arrayCoefs(1:hLen,:);
                arrayCoefs(hLen+1:end,:) = Ux*arrayCoefs(hLen+1:end,:);
            else % TODO:周期拡張でない場合の変換方法の定義
%                 arrayCoefs(1:hLen,1) = -arrayCoefs(1:hLen,1);
%                 arrayCoefs(1:hLen,2:end) = Wx*arrayCoefs(1:hLen,2:end);
%                 
%                 arrayCoefs(hLen+1:end,1) = -arrayCoefs(hLen+1:end,1);
%                 arrayCoefs(hLen+1:end,2:end) = Ux*arrayCoefs(hLen+1:end,2:end);
                arrayCoefs(1:hLen,:) = Wx*arrayCoefs(1:hLen,:);
                arrayCoefs(hLen+1:end,:) = Ux*arrayCoefs(hLen+1:end,:);
            end
            
            % Phase 2
            Wx = paramMtx4;
            Ux = paramMtx5;
            B = butterflyMtx_(obj,paramMtx6);
            %B = eye(obj.NumberOfSymmetricChannels+obj.NumberOfAntisymmetricChannels);
            %TODO:
            %arrayCoefs = blockButterflyTypeI_(obj,arrayCoefs,angB2);
            arrayCoefs = B'*arrayCoefs;
            arrayCoefs = leftShiftUpperCoefs_(obj,arrayCoefs);
            arrayCoefs = B*arrayCoefs;
            %arrayCoefs = blockButterflyTypeI_(obj,arrayCoefs,angB2);
            %arrayCoefs = arrayCoefs/2.0;
            % Lower channel rotation
            arrayCoefs(1:hLen,:) = Wx*arrayCoefs(1:hLen,:);
            arrayCoefs(hLen+1:end,:) = Ux*arrayCoefs(hLen+1:end,:);
            %arrayCoefs = conj(arrayCoefs);
        end
        
        function arrayCoefs = supportExtTypeIIPsGtPa_(obj,arrayCoefs,paramMtx1,paramMtx2,paramMtx3,paramMtx4,paramMtx5,paramMtx6,isPeriodicExt)
            hLen = obj.NumberOfAntisymmetricChannels;
            
            % Phase 1
            Wx = paramMtx1;
            Ux = paramMtx2;
            B = butterflyMtx_(obj,paramMtx3);
            %arrayCoefs = blockButterflyTypeII_(obj,arrayCoefs,[]);
            arrayCoefs(1:end-1,:) = B'*arrayCoefs(1:end-1,:);
            arrayCoefs(1:end-1,:) = rightShiftLowerCoefs_(obj,arrayCoefs(1:end-1,:));
            arrayCoefs(1:end-1,:) = B*arrayCoefs(1:end-1,:);
            %arrayCoefs = blockButterflyTypeII_(obj,arrayCoefs,[]);
            %arrayCoefs = arrayCoefs/2.0;
            % Lower channel rotation
            if isPeriodicExt
                arrayCoefs(1:hLen,:) = Wx*arrayCoefs(1:hLen,:);
                arrayCoefs(hLen+1:end-1,:) = Ux*arrayCoefs(hLen+1:end-1,:);
            else
                % TODO: 周期拡張でない場合の変換方法の定義
                arrayCoefs(1:hLen,1) = -arrayCoefs(1:hLen,1);
                arrayCoefs(1:hLen,2:end) = Wx*arrayCoefs(1:hLen,2:end);
                
                arrayCoefs(hLen+1:end-1,1) = -arrayCoefs(hLen+1:end-1,1);
                arrayCoefs(hLen+1:end-1,2:end) = Ux*arrayCoefs(hLen+1:end-1,2:end);
%                 arrayCoefs(1:hLen,:) = Wx*arrayCoefs(1:hLen,:);
%                 arrayCoefs(hLen+1:end-1,:) = Ux*arrayCoefs(hLen+1:end-1,:);
            end
            
            % Phase 2
            Wx = paramMtx4;
            Ux = paramMtx5;
            B = blkdiag(butterflyMtx_(obj,paramMtx6),1);
            %arrayCoefs = blockButterflyTypeII_(obj,arrayCoefs,[]);
            arrayCoefs = B'*arrayCoefs;
            arrayCoefs = leftShiftUpperCoefs_(obj,arrayCoefs);
            arrayCoefs = B*arrayCoefs;
            %arrayCoefs = blockButterflyTypeII_(obj,arrayCoefs,[]);
            %arrayCoefs = arrayCoefs/2.0;
            % Upper channel rotation
            arrayCoefs(hLen+1:end,:) = Ux*arrayCoefs(hLen+1:end,:);
            arrayCoefs(1:hLen+1,:) = Wx*arrayCoefs(1:hLen+1,:);
        end
        
%         function arrayCoefs = supportExtTypeIIPsLtPa_(obj,arrayCoefs,paramMtx1,paramMtx2,~,isPeriodicExt)
%             hLen = obj.NumberOfSymmetricChannels;
%             
%             % Phase 1
%             Wx = paramMtx1;
%             arrayCoefs = blockButterflyTypeII_(obj,arrayCoefs,[]);
%             arrayCoefs = rightShiftLowerCoefs_(obj,arrayCoefs);
%             arrayCoefs = blockButterflyTypeII_(obj,arrayCoefs,[]);
%             arrayCoefs = arrayCoefs/2.0;
%             % Upper channel rotation
%             if isPeriodicExt
%                 arrayCoefs(1:hLen,:) = Wx*arrayCoefs(1:hLen,:);
%             else
%                 arrayCoefs(1:hLen,1) = -arrayCoefs(1:hLen,1);
%                 arrayCoefs(1:hLen,2:end) = Wx*arrayCoefs(1:hLen,2:end);                
%             end
%             
%             % Phase 2
%             Ux = paramMtx2;
%             arrayCoefs = blockButterflyTypeII_(obj,arrayCoefs,[]);
%             arrayCoefs = leftShiftUpperCoefs_(obj,arrayCoefs);
%             arrayCoefs = blockButterflyTypeII_(obj,arrayCoefs,[]);
%             arrayCoefs = arrayCoefs/2.0;
%             % Lower channel rotation
%             arrayCoefs(hLen+1:end,:) = Ux*arrayCoefs(hLen+1:end,:);
%         end
        
        function arrayCoefs = rightShiftLowerCoefs_(obj,arrayCoefs)
            hLenMn = min([ obj.NumberOfSymmetricChannels
                obj.NumberOfAntisymmetricChannels]);
            %
            lowerCoefsPre = arrayCoefs(hLenMn+1:end,end);
            arrayCoefs(hLenMn+1:end,2:end) = arrayCoefs(hLenMn+1:end,1:end-1);
            arrayCoefs(hLenMn+1:end,1) = lowerCoefsPre;
        end
        
        function arrayCoefs = leftShiftUpperCoefs_(obj,arrayCoefs)
            hLenMn = min([ obj.NumberOfSymmetricChannels
                obj.NumberOfAntisymmetricChannels]);
            %
            upperCoefsPost = arrayCoefs(1:hLenMn,1);
            arrayCoefs(1:hLenMn,1:end-1) = arrayCoefs(1:hLenMn,2:end);
            arrayCoefs(1:hLenMn,end) = upperCoefsPost;            
        end
        
        function hB = butterflyMtx_(obj, angles)%TODO: 同一の関数がAbstBuildingBlock.mで実装されているので一箇所にまとめる．
            hchs = obj.NumberOfAntisymmetricChannels;
            
            hC = complex(eye(hchs));
            hS = complex(eye(hchs));
            for p = 1:floor(hchs/2)
                tp = angles(p);
                
                hC(2*p-1:2*p, 2*p-1:2*p) = [-1i*cos(tp), -1i*sin(tp);
                    cos(tp) , -sin(tp)]; %c^
                hS(2*p-1:2*p, 2*p-1:2*p) = [ -1i*sin(tp), -1i*cos(tp);
                    sin(tp) , -cos(tp)]; %s^
            end
            
            hB = [hC, conj(hC); 1i*hS, -1i*conj(hS)]/sqrt(2);
        end
    end
    
end
