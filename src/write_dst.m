function ierr = write_dst(DST,fitfun,fnamedat)
%function ierr = write_dst(DST,fitfun,fnamedat)
% write all the data needed for a model to flat file called fnamedat
% see read_dst for definitions of fields
% 2010-OCT-11: Updated with additional fields and columns
% 2010-DEC-06: 2 header lines
% 2013-MAY-13: add 4 lines for quadtree

% open file for data
%fname = 'simman1.dat'
fid = fopen(fnamedat,'w');
if fid <= 0
    error(sprintf('Cannot open DST file called %s\n',fnamedat));
    return
end

% number of columns
%ncols = 20;
varnames = fieldnames(DST);
ncols = numel(varnames)
fprintf(fid,'%d %s\n',ncols,fitfun);
for i=1:ncols
    fprintf(fid,' %s',varnames{i});
end
fprintf(fid,'\n');

% number of rows
ndata = numel(DST.i);
%DST

% write a format statement
%fmt = '%5d %5d %5d %5d %5d'; % first 5 columns are integers
fmt = ' ';
% must match number of real variables in fprintf statement below
for i=1:ncols-5-4
fmt = sprintf('%s %s',fmt,'%12.6e');
end
%fmt = sprintf('%s \\n',fmt)

% reserve space for the model
phamod = 0.;
% loop over rows
kount = 0;
for k=1:ndata
    kount = kount+1;
    %DST.qii1(k)
    %fprintf(fid,'%5d %5d %5d %5d %5d'...
    fprintf(fid, '%5d '...        
        ,DST.i(k)            ...
        ,DST.idatatype(k)    ...
        ,DST.k(k)            ...
        ,DST.kmast(k)        ...
        ,DST.kslav(k));
    
    fprintf(fid,'%12.6e' ...
        ,DST.phaobs(k)       ...
        ,DST.phamod(k)       ...
        ,DST.tmast(k)        ...
        ,DST.tslav(k)        ...
        ,DST.x(k)            ...
        ,DST.y(k)            ...
        ,DST.z(k)            ...
        ,DST.uvx(k)          ...
        ,DST.uvy(k)          ...
        ,DST.uvz(k)          ...
        ,DST.mpercy(k)       ...
        ,DST.bmast(k)        ...
        ,DST.bslav(k)        ...
        ,DST.dmast(k)        ...
        ,DST.dslav(k)        ...
        ,DST.x0(k)           ...
        ,DST.y0(k)           ...
        ,DST.z0(k)           ...
        ,DST.dx(k)           ...
        ,DST.dy(k)           ...
        ,DST.dz(k)           ...
        ,DST.alond(k)        ...
        ,DST.alatd(k)        ...
        ,DST.orbm1(k)           ...
        ,DST.orbm2(k)           ...
        ,DST.orbm3(k)           ...
        ,DST.orbm4(k)           ...
        ,DST.orbm5(k)           ...
        ,DST.orbm6(k)           ...
        ,DST.orbs1(k)           ...
        ,DST.orbs2(k)           ...
        ,DST.orbs3(k)           ...
        ,DST.orbs4(k)           ...
        ,DST.orbs5(k)           ...
        ,DST.orbs6(k));
    
    fprintf(fid,'%5d '...
        ,DST.qii1(k)       ...
        ,DST.qii2(k)    ...
        ,DST.qjj1(k)      ...
        ,DST.qjj2(k) ...
        );
    fprintf(fid,'%5d '...
        ,DST.phasig(k) ...
        );
    % end the line with a carriage return
    fprintf(fid,'\n');
end

% check count
if kount == ndata
    fprintf(1,'Wrote meta data for %d pixels to file %s\n',kount,fnamedat);
    fclose(fid);
    ierr = 0;
else
    error(sprintf('kount (%d) not equal to ndata (%d)\n',kount,ndata));
    ierr = 1;
end

return

