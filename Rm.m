function Results = Rm(spx,cf0,est,Rf,mode)

% MATLAB Rm & ERP Calculator: A simple calculator for determining the
% Market Rate of Return and Equity Risk Premium, for use in valuation

%{
Notes:
Required input arguments consist of the following:
spx = The current price of the S&P 500 equities index (SPX)
cf0 = The most recent 4 quarters' dividends and share repurchases on the S&P
est = A 3-year set of estimates as to the growth of earnings on the S&P
Rf  = The Risk Free Rate (Often the yield to maturity on the 10-Year US Treasury)

Using Dr. Aswath Damodaran's algorithm for the forward-looking equity risk
premium, we are forecasting the growth in dividends and share repurchases
on the component companies of the S&P 500, then determining the discount
rate such as will equate the present value of the cash flows to the price of the
index. This is analogous to the yield to maturity on a coupon bond.

To test that this equation holds, we can decompose the function into a
script, and calculate the following,
% Sum(PV(CF)) This should equal the index
sumpvcf = sum(erpmatrix(3,2:end));
round(sumpvcf-spx,3)

The output of this function will consist of either the Market Rate of Return (Rm), 
under the default settings or a column vector of Rm, Rf, and the quantity (Rm-Rf).

The value Rm is used in the calculation of the cost of equity capital in
valuation by Discounted Cash Flow analysis,

Re = Rf + Beta*(Rm-Rf),

where this value would then go into the further calculation of the Weighted
Average Cost of Capital (WACC), used as the discount rate in that method.
%}

% Default mode
if nargin==4
  % Under the default mode, only output Rm
  mode = 1;
end

% Define the ERP matrix
erpmatrix = nan(5,7);
% Add cf0
erpmatrix(1,1) = cf0;

% Define the Earnings to CAGR function
function CAGR = earnings(est,Rf)
% Transpose to vertical if horizontal
xsize = size(est);
if xsize(2) > xsize(1)
    est = est.';
end
% Define the rates matrix (y,x)
rmatrix = nan(7,2);
% Add the earnings estimates
rmatrix(1:3,2) = est;
% Add the growth rates
rmatrix(2,1) = rmatrix(2,2)/rmatrix(1,2)-1;
rmatrix(3,1) = rmatrix(3,2)/rmatrix(2,2)-1;
% Add the risk free rate
rmatrix(6,1) = Rf;
rmatrix(4,1) = rmatrix(3,1)-(rmatrix(3,1)-rmatrix(6,1))/3;
rmatrix(5,1) = rmatrix(4,1)-(rmatrix(3,1)-rmatrix(6,1))/3;
% Add the CAGR
rmatrix(7,1) = (((1+rmatrix(2,1))*(1+rmatrix(3,1))*(1+rmatrix(4,1))*(1+rmatrix(5,1))*(1+rmatrix(6,1)))^(1/5)-1);
CAGR = rmatrix(7,1);
end

% Determine CAGR as a function of projected earnings and the risk free rate
CAGR = earnings(est,Rf);
% Add the CAGR
erpmatrix(2,1) = CAGR;
% Add the Risk Free Rate
erpmatrix(3,1) = Rf;
% Add the projected years
erpmatrix(1,2) = erpmatrix(1,1)*((1+erpmatrix(2,1))^1);
erpmatrix(1,3) = erpmatrix(1,1)*((1+erpmatrix(2,1))^2);
erpmatrix(1,4) = erpmatrix(1,1)*((1+erpmatrix(2,1))^3);
erpmatrix(1,5) = erpmatrix(1,1)*((1+erpmatrix(2,1))^4);
erpmatrix(1,6) = erpmatrix(1,1)*((1+erpmatrix(2,1))^5);
% Add the terminal year
erpmatrix(1,7) = erpmatrix(1,6)*(1+erpmatrix(3,1));

% Calculate the discount rate
pvcf = @(x) (erpmatrix(1,2)/((1+x)^1))+(erpmatrix(1,3)/((1+x)^2))+(erpmatrix(1,4)/((1+x)^3))+(erpmatrix(1,5)/((1+x)^4))+(erpmatrix(1,6)/((1+x)^5))+(erpmatrix(1,7)/((x-Rf)*(1+x)^5))-spx;
options = optimoptions('fsolve','Display','none');
erpmatrix(4,1) = fsolve(pvcf,0.08,options);

% Add discount factors
% FY+1 ~ FY+5 discount factors are calculated as (1+Rm)^t
erpmatrix(2,2) = (1+erpmatrix(4,1))^1;
erpmatrix(2,3) = (1+erpmatrix(4,1))^2;
erpmatrix(2,4) = (1+erpmatrix(4,1))^3;
erpmatrix(2,5) = (1+erpmatrix(4,1))^4;
erpmatrix(2,6) = (1+erpmatrix(4,1))^5;
% Terminal Year discount factor is calculated as (Rm-Rf)*(1+Rm)^5
erpmatrix(2,7) = (erpmatrix(4,1)-erpmatrix(3,1))*(1+erpmatrix(4,1))^5;

% Calculate the present value of the future cash flows
% PV(CF) = CF/Discount Factor
erpmatrix(3,2) = erpmatrix(1,2)/erpmatrix(2,2);
erpmatrix(3,3) = erpmatrix(1,3)/erpmatrix(2,3);
erpmatrix(3,4) = erpmatrix(1,4)/erpmatrix(2,4);
erpmatrix(3,5) = erpmatrix(1,5)/erpmatrix(2,5);
erpmatrix(3,6) = erpmatrix(1,6)/erpmatrix(2,6);
erpmatrix(3,7) = erpmatrix(1,7)/erpmatrix(2,7);

% Add equity risk premium (Rm-Rf)
erpmatrix(5,1) = erpmatrix(4,1)-erpmatrix(3,1);

% Define the output matrix as either Rm, Rf, (Rm-Rf) or Rm
% Modes
if mode==1
  % Output = Rm
  x = erpmatrix(4,1);
  Results = x;
elseif mode==2
  % Output = Rm, Rf, and (Rm-Rf)
  c = categorical({'1.Rm','2.Rf','3.(Rm-Rf)'});
  x = nan(3,1);
  x(1,1) = erpmatrix(4,1);
  x(2,1) = erpmatrix(3,1);
  x(3,1) = x(1,1)-x(2,1);
  bar(c,x,'FaceColor',[31/255 73/255 125/255],'EdgeColor','none');
  % Adjust y proportions
  ylim([0 round(max(x),1)]);
  % Horizontal grid
  ax=gca; ax.YGrid='on';
  % Get rid of tick marks
  set(gca,'TickLength',[0,0]);
  % Percentage formatted y-ticks
  yt = get(gca, 'ytick');
  yt100 = round(yt*100,0);
  ytstr = num2str(yt100');
  ytcell = cellstr(ytstr);
  ytcell_trim = strtrim(ytcell);
  ytpercent = strcat(ytcell_trim, '%');
  set(gca, 'yticklabel', ytpercent);
  % Title and attributes
  title('Calculation of Market Rate of Return and ERP');
  ylabel('Rates of Return');
  % Results table
  Results = x;
  names = {'Rm','Rf','(Rm-Rf)'};
  Results = table(Results,'RowNames',names);
end
end