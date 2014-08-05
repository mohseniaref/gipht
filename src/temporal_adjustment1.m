function [pest, psig, mse, dmod, tfit, pfit, sfitl, sfitu] = temporal_adjustment1(data,data_sigma,tm,ts,tbreaks,tfunc)
%function [pest, psig, mse, dmod, dmodsig, tfit, pfit, sfit] = adjust_steps(data,data_sigma,tm,ts,imast,islav,tbreaks,DD)
% given time tags and data values, perform temporal adjustment
% use step functions
% by epochs in tbreaks
%%dmod = modeled value of differential quantity (from 1st epoch (tm) to 2nd epoch (ts))
%    intmod = modeled value of integrated quantity since beginning of time
%    (minimum of [tm, ts]
% tfunc == time function
%          'step'
%          'pwl'
%          'poly'
% Kurt Feigl University of Wisconsin-Madison
% 2011-OCT-08
% 2014-06-27

fprintf(1,'%s begins ...\n',mfilename);

error(nargchk(6,6,nargin));
error(nargoutchk(8,8,nargout));

iok=which('lscov');
if numel(iok) < 1
    error('Need lscov function')
end

% number of data
ndat = length(data);
if numel(data_sigma) == ndat
    dsig = colvec(data_sigma);
else
    error('data_sigma has wrong dimensions');
end
dmod = nan(size(data));

% make column vectors
tm = colvec(tm); % master epoch
ts = colvec(ts); % slave epoch
tu = colvec(sort(unique([tm; ts]))); % unique set of epochs
me = numel(tu);  % number of epochs

%if  min(tbreaks) - min(tu) > 1.0/365.25
if  min(tbreaks) <  min(tu)
    error('min(tbreaks) before first observation');
    %     warning('Adding break point at begining.');
    %     tbreaks(2:end+1) = tbreaks;
    %     tbreaks(1) = min(tu);
end

if max(tbreaks) > max(tu)
    error('max(tbreaks) after last observation');
    %     warning('Adding break point at end.\n');
    %     tbreaks(end+1) = max(tu);
end


% sort time epochs 
tbreaks = colvec(sort(unique(tbreaks)));
fprintf(1,'i,tbreaks(i)\n');
for i=1:numel(tbreaks)
    fprintf(1,'%d %12.5f\n',i,tbreaks(i));
end

% get number of parameters
fms = time_function4(tfunc,min(tu),max(tu),tbreaks);
disp('number of parameters')
mparam = numel(fms)

% build design matrix
G = zeros(ndat,mparam);
for i=1:ndat   
    fms = time_function4(tfunc,tm(i),ts(i),tbreaks);
    for j=1:numel(fms)
        G(i,j) = fms(j);
    end
end % loop over data


% length of intervals
%dt = diff(tbreaks);

% fprintf(1,'i,j,G(i,j)\n');
% for i=1:ndat
%     for j=1:mparam
%         fprintf (1,'%5d %5d %12.4g\n',i,j,G(i,j));
%     end
% end


fprintf(1,'i,data(i),dsig(i)\n');
for i = 1:ndat
    fprintf (1,'%5d %12.4g %12.4g \n',i,data(i),dsig(i));
end

disp 'Length of data vector, including constraints';ndat = numel((data))
disp 'Dimensons of design matrix, including constraints';nm = size(G)
disp 'Rank of G'; rank(G)
disp 'Rank defiency, including constraints'; rd = mparam - rank(G)
if rd > 0
    figure;spy(G);hold on;
    xlabel('column');ylabel('row');
    title(sprintf('G matrix for %s',strrep(mfilename,'_',' ')));
    error('Rank defiency persists!');
end

disp 'Begin least squares adjustment...'
%    LSCOV assumes that the covariance matrix of B is known only up to a
%     scale factor.  MSE is an estimate of that unknown scale factor, and
%     LSCOV scales the outputs S and STDX appropriately.  However, if V is
%     known to be exactly the covariance matrix of B, then that scaling is
%     unnecessary.  To get the appropriate estimates in this case, you should
%     rescale S and STDX by 1/MSE and sqrt(1/MSE), respectively.

if ndat < 2
    pest(1) = 0;  % arbitrarily make first the origin
    pest(2) = data(1);
    psig(1) = 0;
    psig(2) = dsig(1);
    mse = 1;
else
    A = G;
    B = colvec(data);
    W = colvec(1./dsig.^2);
    %W = eye(ndat); % unweighted least squares
    [pest,psig,mse]=lscov(A,B,W,'orth');
    
    % modeled values for each pair
    dmod = G * pest;
    %dmod = interp1(tbreaks,pest,tm,'linear');
    
    % integrate over time
    tfit = colvec(linspace(nanmin(tu),nanmax(tu),100));
    %tfit = tu;
    pfit = zeros(size(tfit));
    sfitl = zeros(size(tfit));
    sfitu = zeros(size(tfit));
    %     dm = 0;
    %     dsl = 0;
    %     dsu = 0;
    %     for i=2:numel(tfit)
    %         dt = time_function4(tfunc,tfit(i-1),tfit(i),tbreaks);       % time increments
    %         for j=1:numel(dt)
    %             dm  = dm   + dt(j) * pest(j);                % accumulate modeled displacement
    %             dsl = dsl  + dt(j) * (pest(j)-psig(j));  % lower envelope
    %             dsu = dsu  + dt(j) * (pest(j)+psig(j));  % upper envelope
    %         end
    %         pfit(i) = dm;
    %         sfitl(i) = dsl;
    %         sfitu(i) = dsu;
    %     end % loop over epochs
    for i=2:numel(tfit)
        dm = 0;
        dsl = 0;
        dsu = 0;       
        dt = time_function4(tfunc,tfit(1),tfit(i),tbreaks);       % time from beginning      
        for j=1:numel(dt)
            dm  = dm   + dt(j) * pest(j);                % accumulate modeled displacement
            dsl = dsl  + dt(j) * (pest(j)-psig(j));  % lower envelope
            dsu = dsu  + dt(j) * (pest(j)+psig(j));  % upper envelope
        end
        pfit(i) = dm;
        sfitl(i) = dsl;
        sfitu(i) = dsu;
    end % loop over epochs
    
end

fprintf(1,'i,pest(i), psig(i)\n');
for i=1:mparam
    fprintf (1,'%5d %#12.4e %#12.4e\n',i,pest(i),psig(i));
end

res = data-dmod;
%rfit=res;
ndat=numel(res);
%mparam=4;

fprintf(1,   'index  dateM dateS observed modeled residual res/sigma\n');
for i = 1:ndat
    fprintf (1,'%5d %#12.4f %#12.4f %#12.4g %#12.4g %#12.4g %#12.4g %#10.4f\n',i,tm(i),ts(i),data(i),dmod(i),res(i),data_sigma(i),res(i)./data_sigma(i));
end

% figure;
% hist(res./dsig);
% xlabel('Normalized residual');
% ylabel('Number of occurrences');
%
% figure;
% hist(res);
% xlabel('residual');
% ylabel('Number of occurrences');
%
% figure;
% plot(data,dmod,'ro');
% xlabel('Observed value');
% ylabel('Modeled value');

%
% calculate chi-squared ourselves
sswr = sum((res./dsig).^2)/numel(res);
var=sum((res).^2)/(numel(res)-mparam);
chisquare=sum((res./dsig).^2)/(numel(res));
wvar=sum((res./dsig).^2)/(numel(res)-mparam);
fprintf(1,'MSE,       mean standard error (or factor used to scale variance of estimated parameters) is %20.4f\n',mse);
fprintf(1,'SSWR,      sum of squared weighted residuls                                               is %20.4f\n',sswr);
fprintf(1,'sqrt(MSE), square root of MSE                                                             is %20.4f\n',sqrt(mse));
fprintf(1,'sqrt(SSWR),square root SSWR                                                               is %20.4f\n',sqrt(sswr));
fprintf(1,'var, Sample variance in units of data                                                     is %20.4e\n',var);
fprintf(1,'sqrt(var), Sample standard deviation in units of data                                     is %20.4e\n',sqrt(var));
fprintf(1,'chisquare, Chisquared                                                                     is %20.4f\n',chisquare);
fprintf(1,'wvar, estimate of normalized sample variance                                              is %20.4f\n',wvar);
return



