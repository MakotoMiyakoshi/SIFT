function savemedit(node,face,elem,fname)
%
% savedmedit(node,face,elem,fname)
%
% save a surface or tetrahedral mesh to Medit format
%
% author: Qianqian Fang (fangq<at> nmr.mgh.harvard.edu)
% date: 2010/10/30
%
% input:
%      node: input, surface node list, dimension (nn,3 or 4)
%      face: input, surface face element list, dimension (be,3 or 4)
%      elem: input, tetrahedral element list, dimension (ne,4 or 5)
%      fname: output file name
%
% -- this function is part of iso2mesh toolbox (http://iso2mesh.sf.net)
%

fid=fopen(fname,'wt');
if(fid==-1)
    error('You do not have permission to save mesh files.');
end

fprintf(fid,'# Generated by iso2mesh: http://iso2mesh.sf.net\n');
fprintf(fid,'MeshVersionFormatted\t1\nDimension\t3\n');

if(~isempty(node))
  if(size(node,2)<=3) node(1,4)=0; end
  fprintf(fid,'Vertices\t%d\n',size(node,1));
  fprintf(fid,'%e\t%e\t%e\t%.0f\n',node(:,1:4)');
end

if(~isempty(face))
  if(size(face,2)<=3) face(1,4)=0; end
  fprintf(fid,'Triangles\t%d\n',size(face,1));
  fprintf(fid,'%d\t%d\t%d\t%d\n',face(:,1:3)');
end

if(~isempty(elem))
  if(size(elem,2)<=4) elem(1,5)=0; end
  fprintf(fid,'Tetrahedra\t%d\n',size(elem,1));
  fprintf(fid,'%d\t%d\t%d\t%d\t%d\n',elem(:,1:5)');
end

fprintf(fid,'End');

fclose(fid);
