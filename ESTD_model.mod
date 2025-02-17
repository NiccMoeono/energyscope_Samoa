#   -------------------------------------------------------------------------------------------------------------------------													
#	EnergyScope TD is an open-source energy model suitable for country scale analysis. It is a simplified representation of an urban or national energy system accounting for the energy flows												
#	within its boundaries. Based on a hourly resolution, it optimises the design and operation of the energy system while minimizing the cost of the system.												
#													
#	Copyright (C) <2018-2019> <Ecole Polytechnique Fédérale de Lausanne (EPFL), Switzerland and Université catholique de Louvain (UCLouvain), Belgium>
#													
#	Licensed under the Apache License, Version 2.0 (the "License");												
#	you may not use this file except in compliance with the License.												
#	You may obtain a copy of the License at												
#													
#		http://www.apache.org/licenses/LICENSE-2.0												
#													
#	Unless required by applicable law or agreed to in writing, software												
#	distributed under the License is distributed on an "AS IS" BASIS,												
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.												
#	See the License for the specific language governing permissions and												
#	limitations under the License.												
#													
#	Description and complete License: see LICENSE file.												
# -------------------------------------------------------------------------------------------------------------------------		
#########################
###  SETS [Figure 2.7]  ###
#########################

## MAIN SETS: Sets whose elements are input directly in the data file
set PERIODS := 1 .. 8760; # time periods (hours of the year)
set HOURS := 1 .. 24; # hours of the day
set TYPICAL_DAYS:= 1 .. 12; # typical days
set T_H_TD within {PERIODS, HOURS, TYPICAL_DAYS}; # set linking periods, hours, days, typical days
set SECTORS; # sectors of the energy system
set END_USES_INPUT; # Types of demand (end-uses). Input to the model
set END_USES_CATEGORIES; # Categories of demand (end-uses): electricity, heat, mobility
set END_USES_TYPES_OF_CATEGORY {END_USES_CATEGORIES}; # Types of demand (end-uses).
set RESOURCES; # Resources: fuels (renewables and fossils) and electricity imports
set RES_IMPORT_CONSTANT within RESOURCES; # resources imported at constant power (e.g. NG, diesel, ...)
#set BIOFUELS within RESOURCES; # imported biofuels.
#set EXPORT within RESOURCES; # exported resources
set RENEWABLE_FUELS; #added set here in the model to read from ESTD_data.dat file
set END_USES_TYPES := setof {i in END_USES_CATEGORIES, j in END_USES_TYPES_OF_CATEGORY [i]} j; # secondary set
set TECHNOLOGIES_OF_END_USES_TYPE {END_USES_TYPES}; # set all energy conversion technologies (excluding storage technologies and infrastructure)

set STORAGE_TECH; #  set of storage technologies 
set STORAGE_OF_END_USES_TYPES {END_USES_TYPES} within STORAGE_TECH; # set all storage technologies related to an end-use types (used for thermal solar (TS))

set INFRASTRUCTURE;

## SECONDARY SETS: a secondary set is defined by operations on MAIN SETS
set LAYERS := (RESOURCES) union END_USES_TYPES union {INFRASTRUCTURE}; # Layers are used to balance resources/products in the system
set TECHNOLOGIES := (setof {i in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE [i]} j) union STORAGE_TECH union INFRASTRUCTURE; 
set TECHNOLOGIES_OF_END_USES_CATEGORY {i in END_USES_CATEGORIES} within TECHNOLOGIES := setof {j in END_USES_TYPES_OF_CATEGORY[i], k in TECHNOLOGIES_OF_END_USES_TYPE [j]} k;
set RE_RESOURCES within RESOURCES; # List of RE resources (including wind hydro solar), used to compute the RE share
set STORAGE_DAILY within STORAGE_TECH;# Storages technologies for daily application 

##Additional SETS added just to simplify equations.
set TYPICAL_DAY_OF_PERIOD {t in PERIODS} := setof {h in HOURS, td in TYPICAL_DAYS: (t,h,td) in T_H_TD} td; #TD_OF_PERIOD(T)
set HOUR_OF_PERIOD {t in PERIODS} := setof {h in HOURS, td in TYPICAL_DAYS: (t,h,td) in T_H_TD} h; #H_OF_PERIOD(T)

#################################
### PARAMETERS [Tables 2.2]   ###
#################################
## Parameters added to include time series in the model:

param electricity_time_series {HOURS, TYPICAL_DAYS} >= 0, <= 1; # %_elec [-]: factor for sharing lighting across typical days (adding up to 1)
param c_p_t {TECHNOLOGIES, HOURS, TYPICAL_DAYS} default 1; #Hourly capacity factor [-]. If = 1 (default value) <=> no impact.

## Parameters added to define scenarios and technologies:
param end_uses_demand_year {END_USES_INPUT, SECTORS} >= 0 default 0; # end_uses_year [GWh]: table end-uses demand vs sectors (input to the model). Yearly values. [Mpkm] or [Mtkm] for passenger or freight mobility.
param end_uses_input {i in END_USES_INPUT} := sum {s in SECTORS} (end_uses_demand_year [i,s]); # end_uses_input (Figure 1.4) [GWh]: total demand for each type of end-uses across sectors (yearly energy) as input from the demand-side model. [Mpkm] or [Mtkm] for passenger or freight mobility.
param i_rate > 0; # discount rate [-]: real discount rate
param re_share_primary >= 0; # re_share [-]: minimum share of primary energy coming from RE
param gwp_limit >= 0;    # [ktCO2-eq./year] maximum gwp emissions allowed.
param share_electricity_grid_min >= 0, <= 1; # %_grid,min [-]: min limit for penetration of electricity over grid 
param share_electricity_grid_max >= 0, <= 1; # %_grid,max [-]: max limit for penetration of electricity over grid 
param share_ned {END_USES_TYPES_OF_CATEGORY["NON_ENERGY"]} >= 0, <= 1; # %_ned [-] share of non-energy demand per type of feedstocks.
param t_op {HOURS, TYPICAL_DAYS} default 1;# [h]: operating time 
param f_max {TECHNOLOGIES} >= 0; # Maximum feasible installed capacity [GW], refers to main output. storage level [GWh] for STORAGE_TECH
param f_min {TECHNOLOGIES} >= 0; # Minimum feasible installed capacity [GW], refers to main output. storage level [GWh] for STORAGE_TECH
param fmax_perc {TECHNOLOGIES} >= 0, <= 1 default 1; # value in [0,1]: this is to fix that a technology can at max produce a certain % of the total output of its sector over the entire year
param fmin_perc {TECHNOLOGIES} >= 0, <= 1 default 0; # value in [0,1]: this is to fix that a technology can at min produce a certain % of the total output of its sector over the entire year
param avail {RESOURCES} >= 0; # Yearly availability of resources [GWh/y]
param c_op {RESOURCES} >= 0; # cost of resources in the different periods [Meuros/GWh]
param layers_in_out {RESOURCES union TECHNOLOGIES diff STORAGE_TECH , LAYERS} default 0; #new add here f: input/output Resources/Technologies to Layers. Reference is one unit ([GW] or [Mpkm/h] or [Mtkm/h]) of (main) output of the resource/technology. input to layer (output of technology) > 0.
param c_inv {TECHNOLOGIES} >= 0; # Specific investment cost [Meuros/GW].[Meuros/GWh] for STORAGE_TECH
param c_maint {TECHNOLOGIES} >= 0; # O&M cost [Meuros/GW/year]: O&M cost does not include resource (fuel) cost. [Meuros/GWh/year] for STORAGE_TECH
param lifetime {TECHNOLOGIES} >= 0; # n: lifetime [years]
param tau {i in TECHNOLOGIES} := i_rate * (1 + i_rate)^lifetime [i] / (((1 + i_rate)^lifetime [i]) - 1); # Annualisation factor ([-]) for each different technology [Eq. 2.2]
param gwp_constr {TECHNOLOGIES} >= 0; # GWP emissions associated to the construction of technologies [ktCO2-eq./GW]. Refers to [GW] of main output
param gwp_op {RESOURCES} >= 0; # GWP emissions associated to the use of resources [ktCO2-eq./GWh]. Includes extraction/production/transportation and combustion
param c_p {TECHNOLOGIES} >= 0, <= 1 default 1; # yearly capacity factor of each technology [-], defined on annual basis. Different than 1 if sum {t in PERIODS} F_t (t) <= c_p * F
param storage_eff_in {STORAGE_TECH , LAYERS} >= 0, <= 1; # eta_sto_in [-]: efficiency of input to storage from layers.  If 0 storage_tech/layer are incompatible
param storage_eff_out {STORAGE_TECH , LAYERS} >= 0, <= 1; # eta_sto_out [-]: efficiency of output from storage to layers. If 0 storage_tech/layer are incompatible
param storage_losses {STORAGE_TECH} >= 0, <= 1; # %_sto_loss [-]: Self losses in storage (required for Li-ion batteries). Value = self discharge in 1 hour.
param storage_charge_time    {STORAGE_TECH} >= 0; # t_sto_in [h]: Time to charge storage (Energy to Power ratio). If value =  5 <=>  5h for a full charge.
param storage_discharge_time {STORAGE_TECH} >= 0; # t_sto_out [h]: Time to discharge storage (Energy to Power ratio). If value =  5 <=>  5h for a full discharge.
param storage_availability {STORAGE_TECH} >=0, default 1;# %_sto_avail [-]: Storage technology availability to charge/discharge. Used for EVs 
param loss_network {END_USES_TYPES} >= 0 default 0; # %_net_loss: Losses coefficient [0; 1] in the networks (grid and DHN)
param c_grid_extra >=0; # Cost to reinforce the grid due to IRE penetration [Meuros/GW of (PV + Wind)].
param import_capacity >= 0; # Maximum electricity import capacity [GW]
param solar_area >= 0; # Maximum land available for PV deployment [km2]
param power_density_pv >=0 default 0;# Maximum power irradiance for PV.
param peak_sh_factor >= 0;   # %_Peak_sh [-]: ratio between highest yearly demand and highest TDs demand

##Additional parameter (hard coded as '8760' in the thesis)
param total_time := sum {t in PERIODS, h in HOUR_OF_PERIOD [t], td in TYPICAL_DAY_OF_PERIOD [t]} (t_op [h, td]); # [h]. added just to simplify equations

#####################################
###   VARIABLES [Tables 2.3-2.4]  ###
#####################################
##Independent variables [Table 2.3] :

var Share_electricity_grid >= share_electricity_grid_min, <= share_electricity_grid_max; # %_grid: Ratio [0; 1] electricity over total grid
var F {TECHNOLOGIES} >= 0; # F: Installed capacity ([GW]) with respect to main output (see layers_in_out). [GWh] for STORAGE_TECH.
var F_t {RESOURCES union TECHNOLOGIES, HOURS, TYPICAL_DAYS} >= 0; # F_t: Operation in each period [GW] or, for STORAGE_TECH, storage level [GWh]. multiplication factor with respect to the values in layers_in_out table. Takes into account c_p
var Storage_in {i in STORAGE_TECH, LAYERS, HOURS, TYPICAL_DAYS} >= 0; # Sto_in [GW]: Power input to the storage in a certain period
var Storage_out {i in STORAGE_TECH, LAYERS, HOURS, TYPICAL_DAYS} >= 0; # Sto_out [GW]: Power output from the storage in a certain period
var Import_Constant {RES_IMPORT_CONSTANT} >= 0; # [GW] Resources imported at a constant flow (such as gas, electrofuels, ...)

##Dependent variables [Table 2.4] :
var End_uses {LAYERS, HOURS, TYPICAL_DAYS} >= 0; #EndUses [GW]: total demand for each type of end-uses (hourly power). Defined for all layers (0 if not demand). [Mpkm] or [Mtkm] for passenger or freight mobility.
var TotalCost >= 0; # C_tot [ktCO2-eq./year]: Total GWP emissions in the system.
var C_inv {TECHNOLOGIES} >= 0; #C_inv [Meuros]: Total investment cost of each technology
var C_maint {TECHNOLOGIES} >= 0; #C_maint [Meuros/year]: Total O&M cost of each technology (excluding resource cost)
var C_op {RESOURCES} >= 0; #C_op [Meuros/year]: Total O&M cost of each resource
var TotalGWP >= 0; # GWP_tot [ktCO2-eq./year]: Total global warming potential (GWP) emissions in the system
var GWP_constr {TECHNOLOGIES} >= 0; # GWP_constr [ktCO2-eq.]: Total emissions of the technologies
var GWP_op {RESOURCES} >= 0; #  GWP_op [ktCO2-eq.]: Total yearly emissions of the resources [ktCO2-eq./y]
var Network_losses {END_USES_TYPES, HOURS, TYPICAL_DAYS} >= 0; # Net_loss [GW]: Losses in the networks (normally electricity grid and DHN)
var Storage_level {STORAGE_TECH, PERIODS} >= 0; # Sto_level [GWh]: Energy stored at each period

#############################################
###      CONSTRAINTS Eqs [2.1-2.39]       ###
#############################################
## End-uses demand calculation constraints 
#-----------------------------------------

# [Figure 2.8] From annual energy demand to hourly power demand. End_uses is non-zero only for demand layers.
subject to end_uses_t {l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
	End_uses [l, h, td] = (if l == "ELECTRICITY" 
		then
			(end_uses_input[l] / total_time + end_uses_input["LIGHTING"] * electricity_time_series [h, td] / t_op [h, td] ) + Network_losses [l,h,td]) ; # For all layers which don't have an end-use demand

## Cost
#------
# [Eq. 2.1]	
subject to totalcost_cal:
	TotalCost = sum {j in TECHNOLOGIES} (tau [j]  * C_inv [j] + C_maint [j]) + sum {i in RESOURCES} C_op [i];
	
# [Eq. 2.3] Investment cost of each technology
subject to investment_cost_calc {j in TECHNOLOGIES}: 
	C_inv [j] = c_inv [j] * F [j];
		
# [Eq. 2.4] O&M cost of each technology
subject to main_cost_calc {j in TECHNOLOGIES}: 
	C_maint [j] = c_maint [j] * F [j];		
# [Eq. 2.5] Total cost of each resource
subject to op_cost_calc {i in RESOURCES}:
	C_op [i] = sum {t in PERIODS, h in HOUR_OF_PERIOD [t], td in TYPICAL_DAY_OF_PERIOD [t]} (c_op [i] * F_t [i, h, td] * t_op [h, td] ) ;

## Emissions
#-----------
# [Eq. 2.6]
subject to totalGWP_calc:
	TotalGWP =  sum {i in RESOURCES} GWP_op [i];
	#JUST RESOURCES :          TotalGWP = sum {i in RESOURCES} GWP_op [i];
	#INCLUDING GREY EMISSIONS: TotalGWP = sum {j in TECHNOLOGIES} (GWP_constr [j] / lifetime [j]) + sum {i in RESOURCES} GWP_op [i];
	
# [Eq. 2.7]
subject to gwp_constr_calc {j in TECHNOLOGIES}:
	GWP_constr [j] = gwp_constr [j] * F [j];
# [Eq. 2.8]
subject to gwp_op_calc {i in RESOURCES}:
	GWP_op [i] = gwp_op [i] * sum {t in PERIODS, h in HOUR_OF_PERIOD [t], td in TYPICAL_DAY_OF_PERIOD [t]} ( F_t [i, h, td] * t_op [h, td] );	
	
## Multiplication factor
#-----------------------
	
# [Eq. 2.9] min & max limit to the size of each technology
subject to size_limit {j in TECHNOLOGIES}:
	f_min [j] <= F [j] <= f_max [j];
	
# [Eq. 2.10] relation between power and capacity via period capacity factor. This forces max hourly output (e.g. renewables)
subject to capacity_factor_t {j in TECHNOLOGIES, h in HOURS, td in TYPICAL_DAYS}:
	F_t [j, h, td] <= F [j] * c_p_t [j, h, td];
	
# [Eq. 2.11] relation between mult_t and mult via yearly capacity factor. This one forces total annual output
subject to capacity_factor {j in TECHNOLOGIES}:
	sum {t in PERIODS, h in HOUR_OF_PERIOD [t], td in TYPICAL_DAY_OF_PERIOD [t]} (F_t [j, h, td] * t_op [h, td]) <= F [j] * c_p [j] * total_time;	
		
## Resources
#-----------
# [Eq. 2.12] Resources availability equation
subject to resource_availability {i in RESOURCES}:
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [i, h, td] * t_op [h, td]) <= avail [i];

## Layers
#--------
# [Eq. 2.13] Layer balance equation with storage. Layers: input > 0, output < 0. Demand > 0. Storage: in > 0, out > 0;
# output from technologies/resources/storage - input to technologies/storage = demand. Demand has default value of 0 for layers which are not end_uses
subject to layer_balance {l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
		sum {i in RESOURCES union TECHNOLOGIES diff STORAGE_TECH: layers_in_out[i,l] !=0 } #new add here
		(layers_in_out[i, l] * F_t [i, h, td]) 
		+ sum {j in STORAGE_TECH} ( Storage_out [j, l, h, td] - Storage_in [j, l, h, td] )
		- End_uses [l, h, td]
		= 0;
		
## Storage	
#---------
# [Eq. 2.14] The level of the storage represents the amount of energy stored at a certain time.
subject to storage_level {j in STORAGE_TECH, t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]}:
	Storage_level [j, t] = (if t == 1 then
	 			Storage_level [j, card(PERIODS)] * (1.0 -  storage_losses[j])
				+ t_op [h, td] * (   (sum {l in LAYERS: storage_eff_in [j,l] > 0}  (Storage_in [j, l, h, td]  * storage_eff_in  [j, l])) 
				                   - (sum {l in LAYERS: storage_eff_out [j,l] > 0} (Storage_out [j, l, h, td] / storage_eff_out [j, l])))
	else
	 			Storage_level [j, t-1] * (1.0 -  storage_losses[j])
				+ t_op [h, td] * (   (sum {l in LAYERS: storage_eff_in [j,l] > 0}  (Storage_in [j, l, h, td]  * storage_eff_in  [j, l])) 
				                   - (sum {l in LAYERS: storage_eff_out [j,l] > 0} (Storage_out [j, l, h, td] / storage_eff_out [j, l])))
				);
# [Eq. 2.15] Bounding daily storage
subject to impose_daily_storage {j in STORAGE_DAILY, t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]}:
	Storage_level [j, t] = F_t [j, h, td];
	
# [Eq. 2.16] Bounding seasonal storage
subject to limit_energy_stored_to_maximum {j in STORAGE_TECH diff STORAGE_DAILY , t in PERIODS}:
	Storage_level [j, t] <= F [j];# Never exceed the size of the storage unit
	
# [Eqs. 2.17-2.18] Each storage technology can have input/output only to certain layers. If incompatible then the variable is set to 0
subject to storage_layer_in {j in STORAGE_TECH, l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
	Storage_in [j, l, h, td] * (ceil (storage_eff_in [j, l]) - 1) = 0;
subject to storage_layer_out {j in STORAGE_TECH, l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
	Storage_out [j, l, h, td] * (ceil (storage_eff_out [j, l]) - 1) = 0;
		
# [Eq. 2.19] limit the Energy to power ratio for storage technologies except EV batteries
subject to limit_energy_to_power_ratio {j in STORAGE_TECH diff {"BEV_BATT","PHEV_BATT"}, l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
	Storage_in [j, l, h, td] * storage_charge_time[j] + Storage_out [j, l, h, td] * storage_discharge_time[j] <=  F [j] * storage_availability[j];
	
## Networks
#----------------
# [Eq. 2.20] Calculation of losses for each end-use demand type (normally for electricity and DHN)
subject to network_losses {eut in END_USES_TYPES, h in HOURS, td in TYPICAL_DAYS}:
	Network_losses [eut,h,td] = (sum {j in RESOURCES union TECHNOLOGIES diff STORAGE_TECH: layers_in_out [j, eut] > 0} ((layers_in_out[j, eut]) * F_t [j, h, td])) * loss_network [eut];

# [Eq. 2.21]  Extra grid cost for integrating 1 GW of RE is estimated to 367.8Meuros per GW of intermittent renewable (27beuros to integrate the overall potential) 
subject to extra_grid:
	F ["GRID"] = 1 +  (c_grid_extra / c_inv["GRID"]) *(    (F ["WIND_ONSHORE"]      + F ["PV"]      )
					                                     - (f_min ["PV"]) );

## Adaptation for the case study: Constraints needed for the application to Switzerland (not needed in standard LP formulation)
#-----------------------------------------------------------------------------------------------------------------------
# [Eq. 2.34]  constraint to reduce the GWP subject to Minimum_gwp_reduction :
subject to Minimum_GWP_reduction :
	TotalGWP <= gwp_limit;
# [Eq. 2.35] Minimum share of RE in primary energy supply
subject to Minimum_RE_share :
	sum {j in RE_RESOURCES, t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} F_t [j, h, td] * t_op [h, td] 
	>=	re_share_primary *
	sum {j in RESOURCES, t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} F_t [j, h, td] * t_op [h, td]	;
		
# [Eq. 2.36] Definition of min/max output of each technology as % of total output in a given layer. 
subject to f_max_perc {eut in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE[eut]}:
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [j,h,td] * t_op[h,td]) <= fmax_perc [j] * sum {j2 in TECHNOLOGIES_OF_END_USES_TYPE[eut], t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [j2, h, td] * t_op[h,td]);
subject to f_min_perc {eut in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE[eut]}:
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [j,h,td] * t_op[h,td]) >= fmin_perc [j] * sum {j2 in TECHNOLOGIES_OF_END_USES_TYPE[eut], t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [j2, h, td] * t_op[h,td]);

# # [Eq. 2.37] Energy efficiency is a fixed cost
# subject to extra_efficiency:
# 	F ["EFFICIENCY"] = 1 / (1 + i_rate);	

# # [Eq. 2.38] Limit electricity import capacity
# subject to max_elec_import {h in HOURS, td in TYPICAL_DAYS}:
# 	F_t ["ELECTRICITY", h, td] * t_op [h, td] <= import_capacity; 

##########################
### OBJECTIVE FUNCTION ###

##########################
# Can choose between TotalGWP and TotalCost
minimize obj: TotalCost;
##############################################
###            GLPK version                ###
##############################################
solve;
##############################################
###              OUTPUTS                   ###
##############################################
## Saving sets and parameters to output file
## Print cost breakdown to txt file.
printf "%s\t%s\t%s\t%s\n", "Name", "C_inv", "C_maint", "C_op" > "output/cost_breakdown.txt"; 
for {i in TECHNOLOGIES union RESOURCES}{
	printf "%s\t%.6f\t%.6f\t%.6f\n", i, if i in TECHNOLOGIES then (tau[i] * C_inv[i]) else 0, if i in TECHNOLOGIES then C_maint [i] else 0, if i in RESOURCES then C_op [i] else 0 >> "output/cost_breakdown.txt";
}
## Print GWP breakdown
printf "%s\t%s\t%s\n", "Name", "GWP_constr", "GWP_op" > "output/gwp_breakdown.txt"; 
for {i in TECHNOLOGIES union RESOURCES}{
	printf "%s\t%.6f\t%.6f\n", i, if i in TECHNOLOGIES then GWP_constr [i] / lifetime [i] else 0, if i in RESOURCES then GWP_op [i] else 0 >> "output/gwp_breakdown.txt";
}
## Print resources breakdown to txt file.
printf "%s\t%s\t%s\n", "Name", "Used", "Potential" > "output/resources_breakdown.txt"; 
for {i in RESOURCES}{
	printf "%s\t%.6f\t%.6f\n", i, sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [i, h, td] * t_op [h, td]) , avail [i] >> "output/resources_breakdown.txt";
}
## Print losses to txt file
printf "%s\t%s\n", "End use", "Losses" > "output/losses.txt";
for {i in END_USES_TYPES}{
		printf "%s\t%.3f\n",i,  sum{t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t] }(Network_losses [i,h,td] * t_op [h,td])  >> "output/losses.txt";
}
## Print ASSETS to txt file
printf "TECHNOLOGIES\t c_inv\t c_maint\t lifetime\t  f_min\t f\t f_max\t fmin_perc\t" > "output/assets.txt"; 
printf "f_perc\t fmax_perc\t c_p\t c_p_max\t tau\t gwp_constr" >> "output/assets.txt"; # Must be split in 2 parts, otherwise too long for GLPK
printf "\n UNITS\t[MWSTCapitalf/GW]\t [MWSTCapitalf/GW]\t [y]\t [GW or GWh]\t" >> "output/assets.txt"; 
printf " [GW or GWh]\t [GW or GWh]\t [0-1]\t [0-1]\t [0-1]\t [0-1]\t [0-1]\t [-]\t [ktCO2-eq./GW or GWh] " >> "output/assets.txt"; 
for {i in END_USES_TYPES, tech in TECHNOLOGIES_OF_END_USES_TYPE[i]}{
	printf "\n%s\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t",tech,
C_inv[tech],C_maint[tech],lifetime[tech],f_min[tech],F[tech],f_max[tech],
fmin_perc[tech],
sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [tech,h,td] ) / max(sum {j2 in 
TECHNOLOGIES_OF_END_USES_TYPE[i], t2 in PERIODS, h2 in HOUR_OF_PERIOD[t2], td2 in TYPICAL_DAY_OF_PERIOD[t2]} (F_t [j2, h2, 
td2] ) , 0.00001) ,fmax_perc[tech],
sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [tech,h,td] * t_op[h,td]) / 8760 / max(F[tech],0.0001),
c_p[tech],tau[tech],GWP_constr[tech] >> "output/assets.txt";
}
for {tech in STORAGE_TECH}{
	printf "\n%s\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t",tech,
C_inv[tech],C_maint[tech],lifetime[tech],f_min[tech],F[tech],f_max[tech],
fmin_perc[tech],
-1,
fmax_perc[tech],
sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t],l in LAYERS: storage_eff_out [tech,l] > 0} -min(0,Storage_out [tech, l, h, td] / storage_eff_out [tech, l] - Storage_in [tech, l, h, td] * storage_eff_in [tech, l]) / 8760 / max(F[tech],0.0001)
,c_p[tech],tau[tech],GWP_constr[tech] >> "output/assets.txt"; 
}
for {tech in INFRASTRUCTURE}{
	printf "\n%s\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t",tech,
C_inv[tech],C_maint[tech],lifetime[tech],f_min[tech],F[tech],f_max[tech],
fmin_perc[tech],
-1,
fmax_perc[tech],
sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [tech,h,td] * t_op[h,td]) / 8760 / max(F[tech],0.0001)
,c_p[tech],tau[tech],GWP_constr[tech] >> "output/assets.txt"; 
}
## STORAGE distribution CURVES
printf "Time\t" > "output/hourly_data/energy_stored.txt";
for {i in STORAGE_TECH }{
	printf "%s\t", i >> "output/hourly_data/energy_stored.txt";
}
for {i in STORAGE_TECH }{
	printf "%s_in\t" , i >> "output/hourly_data/energy_stored.txt";
	printf "%s_out\t", i >> "output/hourly_data/energy_stored.txt";
}
for {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]}{
	printf "\n %d\t",t  >> "output/hourly_data/energy_stored.txt";
	for {i in STORAGE_TECH}{
		printf "%f\t", Storage_level[i, t] >> "output/hourly_data/energy_stored.txt";
	}
	for {i in STORAGE_TECH}{
		printf "%f\t", (sum {l in LAYERS: storage_eff_in [i,l] > 0}
-(Storage_in [i, l, h, td] * storage_eff_in [i, l]))
	>> "output/hourly_data/energy_stored.txt";
		printf "%f\t", (sum {l in LAYERS: storage_eff_in [i,l] > 0}
(Storage_out [i, l, h, td] / storage_eff_out [i, l]))
	>> "output/hourly_data/energy_stored.txt";
	}
} 
## LAYERS FLUXES
for {l in LAYERS}{
	printf "Td \t Time\t" > "output/hourly_data/layer_" & l &".txt"; 
	for {i in RESOURCES union TECHNOLOGIES diff STORAGE_TECH }{
		printf "%s\t",i >> "output/hourly_data/layer_" & l &".txt"; 
	}
	for {j in STORAGE_TECH }{
		printf "%s_Pin\t",j >> "output/hourly_data/layer_" & l &".txt"; 
		printf "%s_Pout\t",j >> "output/hourly_data/layer_" & l &".txt"; 
	}
	printf "END_USE\t" >> "output/hourly_data/layer_" & l &".txt"; 
	for {td in TYPICAL_DAYS, h in HOURS}{
		printf "\n %d \t %d\t",td,h   >> "output/hourly_data/layer_" & l &".txt"; 
		for {i in RESOURCES union TECHNOLOGIES diff STORAGE_TECH}{
	printf "%f\t",(layers_in_out[i, l] * F_t [i, h, td]) >> "output/hourly_data/layer_" & l &".txt"; 
		}
		for {j in STORAGE_TECH}{
	printf "%f\t",(-Storage_in [j, l, h, td]) >> "output/hourly_data/layer_" & l &".txt"; 
	printf "%f\t", (Storage_out [j, l, h, td])>> "output/hourly_data/layer_" & l &".txt"; 
		}
		printf "%f\t", -End_uses [l, h, td]  >> "output/hourly_data/layer_" & l &".txt"; 
	}
}
## Energy yearly balance
printf "Tech\t" > "output/year_balance.txt";
for {l in LAYERS}{
	printf "%s\t",l >> "output/year_balance.txt";
}
for {i in RESOURCES union TECHNOLOGIES diff STORAGE_TECH}{
	printf "\n %s \t", i >> "output/year_balance.txt";
	for {l in LAYERS}{
		printf " %f\t", sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]}
layers_in_out[i, l] * F_t [i, h, td] >> "output/year_balance.txt";
	}
}
for {j in STORAGE_TECH}{
	printf "\n %s \t", j >> "output/year_balance.txt";
	for {l in LAYERS}{
		printf " %f\t", sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]}
(Storage_out [j, l, h, td] - Storage_in [j, l, h, td]) >> "output/year_balance.txt";
	}
}
printf "\n End_uses_DEMAND \t" >> "output/year_balance.txt";
for {l in LAYERS}{
	printf " %f\t", sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]}
		End_uses [l, h, td] >> "output/year_balance.txt";
}
## Print Sankey (beta version), check YearBalance.txt for exact values.
## Generate CSV file to be used as input to Sankey diagram
# Notes:
printf "%s,%s,%s,%s,%s,%s\n", "source" , "target", "realValue", "layerID", "layerColor", "layerUnit" > "output/Sankey/input2sankey.csv";

# Resources to layers
for {i in RESOURCES union TECHNOLOGIES diff STORAGE_TECH, l in LAYERS: 
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} 
	(layers_in_out[i, l] * F_t[i, h, td]) > 0 } {
	printf "%s,%s,%.2f,%s,%s,%s\n", i, l, 
		sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} 
		(layers_in_out[i, l] * F_t[i, h, td]), 
		l, "blue", "GWh" >> "output/Sankey/input2sankey.csv";
}

# Layers to end-uses
for {l in LAYERS: 
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} 
	End_uses[l, h, td] > 0 } {
	printf "%s,%s,%.2f,%s,%s,%s\n", l, "End_uses", 
		sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} 
		End_uses[l, h, td], 
		l, "red", "GWh" >> "output/Sankey/input2sankey.csv";
}

# Layers to storage
for {j in STORAGE_TECH, l in LAYERS: 
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} 
	(Storage_out[j, l, h, td] - Storage_in[j, l, h, td]) > 0 } {
	printf "%s,%s,%.2f,%s,%s,%s\n", l, j, 
		sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} 
		(Storage_out[j, l, h, td] - Storage_in[j, l, h, td]), 
		l, "green", "GWh" >> "output/Sankey/input2sankey.csv";
}
	
end;