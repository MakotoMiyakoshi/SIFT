function [ n_data, a, b, x, fx ] = beta_cdf_values ( n_data )

%% BETA_CDF_VALUES returns some values of the Beta CDF.
%
%  Discussion:
%
%    In Mathematica, the function can be evaluated by:
%
%      Needs["Statistics`ContinuousDistributions`"]
%      dist = BetaDistribution [ a, b ]
%      CDF [ dist, x ]
%
%  Modified:
%
%    02 September 2004
%
%  Author:
%
%    John Burkardt
%
%  Reference:
%
%    Milton Abramowitz and Irene Stegun,
%    Handbook of Mathematical Functions,
%    US Department of Commerce, 1964.
%
%    Karl Pearson,
%    Tables of the Incomplete Beta Function,
%    Cambridge University Press, 1968.
%
%    Stephen Wolfram,
%    The Mathematica Book,
%    Fourth Edition,
%    Wolfram Media / Cambridge University Press, 1999.
%
%  Parameters:
%
%    Input/output, integer N_DATA.  The user sets N_DATA to 0 before the
%    first call.  On each call, the routine increments N_DATA by 1, and
%    returns the corresponding data; when there is no more data, the
%    output value of N_DATA will be 0 again.
%
%    Output, real A, B, the parameters of the function.
%
%    Output, real X, the argument of the function.
%
%    Output, real FX, the value of the function.
%
  n_max = 12;

  a_vec = [ ...
      0.10E+01, ...
      0.10E+01, ...
      0.10E+01, ...
      0.10E+01, ...
      0.10E+01, ...
      0.10E+01, ...
      0.10E+01, ...
      0.10E+01, ...
      0.20E+01, ...
      0.30E+01, ...
      0.40E+01, ...
      0.50E+01 ];

  b_vec = [ ...
      0.50E+00, ...
      0.50E+00, ...
      0.50E+00, ...
      0.50E+00, ...
      0.20E+01, ...
      0.30E+01, ...
      0.40E+01, ...
      0.50E+01, ...
      0.20E+01, ...
      0.20E+01, ...
      0.20E+01, ...
      0.20E+01 ];

  fx_vec = [ ...
     0.5131670194948620E-01, ...
     0.1055728090000841E+00, ...
     0.1633399734659245E+00, ...
     0.2254033307585166E+00, ...
     0.3600000000000000E+00, ...
     0.4880000000000000E+00, ...
     0.5904000000000000E+00, ...
     0.6723200000000000E+00, ...
     0.2160000000000000E+00, ...
     0.8370000000000000E-01, ...
     0.3078000000000000E-01, ...
     0.1093500000000000E-01 ];

  x_vec = [ ...
     0.10E+00, ...
     0.20E+00, ...
     0.30E+00, ...
     0.40E+00, ...
     0.20E+00, ...
     0.20E+00, ...
     0.20E+00, ...
     0.20E+00, ...
     0.30E+00, ...
     0.30E+00, ...
     0.30E+00, ...
     0.30E+00 ];

  if ( n_data < 0 )
    n_data = 0;
  end

  n_data = n_data + 1;

  if ( n_max < n_data )
    n_data = 0;
    a = 0.0;
    b = 0.0;
    x = 0.0;
    fx = 0.0;
  else
    a = a_vec(n_data);
    b = b_vec(n_data);
    x = x_vec(n_data);
    fx = fx_vec(n_data);
  end

