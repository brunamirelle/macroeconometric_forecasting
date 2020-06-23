pageselect m2_fiji   'Set the default page to fiji
close @objects  	'Close all open objects to reduce clutter...
smpl @all 			'Set the smpl period to the maximum possible (i.e., pagefile range)
genr ln_rgdp_fiji = log(rgdp_fiji)   'Generate the log transform of real GDP of fiji (saved to workfile)
genr ln_rgdp_aus  = log(rgdp_aus) 'Generate the log transform of real GDP of Australia (saved to workfile)
line ln_rgdp_fiji ln_rgdp_aus 'Graph fiji real GDP against Australian real GDP
line dlog(rgdp_fiji) dlog(rgdp_aus)  'Graph their growth rates - fiji is more volatile, though volatility is declining in recent years.
scat  log(rgdp_aus) log(rgdp_fiji) 'Scatter plot of log(rgdp_aus) against log(rgdp_fiji)
scat  dlog(rgdp_aus) dlog(rgdp_fiji) 'Scatter plot of log(rgdp_aus) against log(rgdp_fiji)
equation e1.ls ln_rgdp_fiji c ln_rgdp_aus 'Run OLS...long-run, log-log regression
equation e2.ls log(rgdp_fiji) c log(rgdp_aus)	 'Run OLS with auto variables...
group g1 dlog(rgdp_fiji) dlog(rgdp_aus) 'Create a group
g1.stats(i) 'Calculate basic statistics for the group
g1.cov 'Covariance matrix
g1.corr 'Correlation matrix
e2.wald c(2)=1 'Test the null hypothesis that c(2)=1
e2.representations 'Show the various internal/algebriac representations of the model..
show c 'The "c" object contains the most recent parameter estimates...
e2.resids(t) 'Display a table view of the residuals...	
e2.resids(g) 'Now display the residuals as a graph
e2.auto(2) 'Calculate the LM test for autocorrelation (lags= 2)
'Note: sugaroutput begins in 1990, so the sample period in what follows will be much shorter compared to equations e1 and e2.
equation e3.ls log(rgdp_fiji) c log(rgdp_aus) log(sugaroutput_fiji) 'Same regression as above, but with sugar production added.
show e3
'Now let's create a dummy (0/1) variable for the global financial crisis
smpl @all
genr dum = 0
smpl 2007 2010
genr dum = 1
smpl @all
equation e3.ls log(rgdp_fiji) c log(rgdp_aus) log(sugaroutput_fiji) dum
show e3
'Now allow for dynamic effects using lagged variables (dependent and independent)
equation e4.ls log(rgdp_fiji) c log(rgdp_fiji(-1)) log(rgdp_aus) log(rgdp_aus(-1)) log(sugaroutput_fiji) dum
show e4
smpl @first 2011 'Prepare to forecast one year ahead.
e4.ls 're-estimate
'Dynamic forecast (errors accumulate)
smpl 2011 2013
e4.forecast(e) rgdp_fiji_dyn rgdp_fiji_dyn_se 'first is the forecast; second is the standard error of the forecast.
'Static forecast; won't differ by much because forecasting just 3 years ahead
e4.fit(e) rgdp_fiji_static rgdp_fiji_static_se
smpl 2010 2013
line rgdp_fiji rgdp_fiji_static rgdp_fiji_dyn
'Now use the model simulator to produce the same forecast
'First step is to create a model from eq5
e4.makemodel(md_e4)
smpl 2011 2013
'Solve using dynamic solver; solution is/should be identical (see rgdp_Fiji_dyn) to e4.forecast above
md_e4.solve(s=d,d=d)
delete(noerr) rgdp_fiji_model_dyn
rename rgdp_fiji_0 rgdp_fiji_model_dyn
show rgdp_fiji rgdp_fiji_model_dyn rgdp_fiji_dyn
'Solve using static solver (determined by the second argument, d=s); solution is identical to e4.fit above
md_e4.solve(s=d,d=s)
delete(noerr) rgdp_fiji_model_static
rename rgdp_fiji_0 rgdp_fiji_model_static
show rgdp_fiji rgdp_fiji_model_static rgdp_fiji_static
'Now perform a stochastic / dynamic solution using the bootstrap approach to re-sample the shock to rgdp_Fiji
'Setup the stochastic options; bootstrap (i=b); 95 percent confidence intervals (b=0.90); allow for coefficient uncertainty (c=t)
'Number of iterations = 10000
md_e4.stochastic(i=b,r=10000,b=0.90,c=t)
md_e4.solve(s=a,d=d)
show rgdp_fiji rgdp_fiji_0m rgdp_fiji_0l rgdp_fiji_0h 'View actual against mean, lower and the upper bound
line rgdp_fiji rgdp_fiji_0m rgdp_fiji_0l rgdp_fiji_0h 'Graph actual against mean, lower and the upper bound
'Lastly, let's learn how to do an alternate scenario
'Suppose there is a +10 percent shock to sugar output through out 2011-12.  What is the impact on the forecast?
'Create the variable that reflects the shock
smpl @all
genr sugaroutput_fiji_1 = sugaroutput_fiji
smpl 2011 2012
genr sugaroutput_fiji_1 = 1.1*sugaroutput_fiji '10 percent increase in sugar production for 2011 and 2012
'The next step is to inform the simulator that it needs to override sugaroutput_fiji using  sugaroutput_fiji_1 under the alternative
md_e4.scenario "Scenario 1" 'Active scenario is now "Scenario 1"
md_e4.override sugaroutput_Fiji 'Override  sugaroutput_fiji using  sugaroutput_fiji_1
md_e4.scenario "Baseline" 'Revert to the baseline scenario
md_e4.scenario(c) "Scenario 1" 'Set the comparator scenario to "Scenario 1"
delete(noerr) rgdp_*_0 rgdp_*_1
smpl 2011 2013
md_e4.solve(s=d,d=d,a=t) 'Note: a=t means solve the active and the alternative together
show md_e4
show rgdp_fiji rgdp_fiji_0 rgdp_fiji_1 'View the results; deterministic solution, actual, baseline, and scenario 1
line rgdp_fiji rgdp_fiji_0 rgdp_fiji_1 'Graph the results; deterministic solution, actual, baseline, and scenario 1


