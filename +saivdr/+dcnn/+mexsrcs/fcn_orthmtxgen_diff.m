function [matrix,matrixpst,matrixpre] = fcn_orthmtxgen_diff(...
    angles,mus,pdAng,matrixpst,matrixpre,isGpu) %#codegen
%FCN_ORTHMTXGEN_DIFF
%
% Function realization of
% saivdr.dictionary.utility.OrthonormalMatrixGenerationSystem
% for supporting dlarray (Deep learning array for custom training
% loops)
%
% Requirements: MATLAB R2020a
%
% Copyright (c) 2020-2021, Shogo MURAMATSU
%
% All rights reserved.
%
% Contact address: Shogo MURAMATSU,
%                Faculty of Engineering, Niigata University,
%                8050 2-no-cho Ikarashi, Nishi-ku,
%                Niigata, 950-2181, JAPAN
%
% http://msiplab.eng.niigata-u.ac.jp/

if nargin < 6
    isGpu = isgpuarray(angles);
end
if nargin < 3
    pdAng = 0;
end

nDim_ = (1+sqrt(1+8.*length(angles)))/2.;
matrix = eye(nDim_,'like',angles);
matrixrev = eye(nDim_,'like',angles);
matrixdif = zeros(nDim_,'like',angles);
iAng = uint32(1);
for iTop=1:nDim_-1
    rt = matrixrev(iTop,:);
    dt = zeros(1,nDim_,'like',angles);
    dt(iTop) = 1;
    for iBtm=iTop+1:nDim_
        if iAng == pdAng
            angle = angles(iAng);
            %
            rb = matrixrev(iBtm,:);
            db = zeros(1,nDim_,'like',angles);
            db(iBtm) = 1;
            dangle = angle + pi/2;
            % 
            %[rt,rb] = rot_(rt,rb,-angle);
            %[dt,db] = rot_(dt,db,dangle);
            [vt,vb] = rot_([rt;dt],[rb;db],[-angle;dangle],isGpu);
            %
            matrixrev(iTop,:) = vt(1,:); %rt;
            matrixrev(iBtm,:) = vb(1,:); %rb;
            matrixdif(iTop,:) = vt(2,:); %dt;
            matrixdif(iBtm,:) = vb(2,:); %db;
            %
            matrixpst = matrixpst*matrixrev;
            matrix    = matrixpst*matrixdif*matrixpre;
            matrixpre = matrixrev.'*matrixpre;
        end
        iAng = iAng + 1;
    end
end
if ~all(mus==1)
    if isGpu
        % TODO: Replace BSXFUN only for gpuArray    
        %matrix = bsxfun(@times,mus(:),matrix);
        matrix = arrayfun(@times,mus(:),matrix);        
    else
        % TODO: Use direct operations on CPU    
        matrix = mus(:).*matrix;
    end
end
end

function [vt,vb] = rot_(vt,vb,angle,isGpu)
c = cos(angle);
s = sin(angle);
if isGpu
    % TODO: Replace BSXFUN only for gpuArray
    %u  = bsxfun(@times,s,bsxfun(@plus,vt,vb));
    %vt = bsxfun(@minus,bsxfun(@times,c+s,vt),u);
    %vb = bsxfun(@plus,bsxfun(@times,c-s,vb),u);
    u  = arrayfun(@times,s,arrayfun(@plus,vt,vb));
    vt = arrayfun(@minus,arrayfun(@times,c+s,vt),u);
    vb = arrayfun(@plus,arrayfun(@times,c-s,vb),u);
else
    % TODO: Use direct operations on CPU
    u  = s.*(vt+vb);
    vt = (c+s).*vt-u;
    vb = (c-s).*vb+u;
end
end

